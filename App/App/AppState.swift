import Foundation
import Observation

@MainActor @Observable final class AppState {
    var provinces: [ProvinceDefinition] = []
    var atlas = WorldAtlas()
    var selectedMap = UserDefaults.standard.string(forKey: "selectedMap") ?? "world"
    var language = UserDefaults.standard.string(forKey: "interfaceLanguage") ?? "system"
    var locale: Locale { Locale(identifier: AppLanguage.current) }
    var mapTitle: String { selectedMap == "world" ? L("World") : atlas.placesByID[selectedMap].map(placeName) ?? L("World") }
    var mapVisitedIDs: Set<String> { atlas.visitedIncludingCountries(visitedIDs) }
    func placeName(_ place: ProvinceDefinition) -> String { place.localizedName(language: AppLanguage.current) }
    func setLanguage(_ code: String) {
        UserDefaults.standard.set(code, forKey: "interfaceLanguage")
        language = code
    }
    func selectMap(_ id: String) {
        selectedMap = id
        UserDefaults.standard.set(id, forKey: "selectedMap")
        provinces = atlas.places(on: id)
    }
    var snapshot = StoreSnapshot()
    var isLoading = true
    var mapFailed = false
    var startupError: String?
    var message: String?
    var access: PhotoAccess = .notDetermined
    var isSyncing = false
    var isResetting = false
    var isImporting = false
    var isRequestingPhotoAccess = false
    var pendingWrites = 0
    var noteDrafts: [String: String] = [:]
    @ObservationIgnored private var noteVersions: [String: Int] = [:]
    var photosByProvince: [String: [PhotoSnapshot]] = [:]
    var pendingPhotos: [PhotoSnapshot] = []
    var photoScanSummary: String?
    var photoImportSummary: String?
    var photoAuthorizationNote: String?
    @ObservationIgnored let scanner = PhotoScanner()
    @ObservationIgnored private var observer: PhotoLibraryObserver?
    @ObservationIgnored private var scheduledSync: Task<Void, Never>?
    @ObservationIgnored private var syncAgain = false
    @ObservationIgnored private var forceNextSync = false
    @ObservationIgnored var store: DataStore?
    @ObservationIgnored private let maps = MapRepository()
    @ObservationIgnored private let requestAuthorization: @MainActor () async -> PhotoAccess

    init(requestAuthorization: @escaping @MainActor () async -> PhotoAccess = { await PhotoAuthorizationService.request() }) {
        self.requestAuthorization = requestAuthorization
    }
    var theme: ThemeDefinition { ThemeDefinition(rawValue: snapshot.settings.selectedTheme) ?? .blue }
    var visitedIDs: Set<String> { Set(snapshot.provinces.filter { $0.value.manualVisited }.map(\.key)).union(photosByProvince.keys) }

    func start() async {
        isLoading = true
        startupError = nil
        do {
            if store == nil { store = try await DataStore.open() }
            try await refresh()
            await loadMap()
            access = PhotoAuthorizationService.current
        } catch { startupError = L("Could not open local records.") + "\n" + error.localizedDescription }
        isLoading = false
        if startupError == nil { await becameActive() }
    }
    func loadMap() async {
        mapFailed = false
        do {
            guard let countriesURL = Bundle.main.url(forResource: "world_countries", withExtension: "geojson"),
                  let regionsURL = Bundle.main.url(forResource: "world_regions", withExtension: "geojson") else { throw MapDataError.missingResource }
            let countries = try await maps.load(url: countriesURL)
            let regions = try await maps.load(url: regionsURL)
            atlas = WorldAtlas(countries: countries, regions: regions)
            selectMap(atlas.placesByID[selectedMap] != nil ? selectedMap : "world")
        } catch { mapFailed = true }
    }
    func refresh() async throws {
        guard let store else { return }
        let next = try await store.snapshot()
        if next.revision >= snapshot.revision {
            snapshot = next
            photosByProvince = next.photosByProvince
            pendingPhotos = next.pendingPhotos
        }
    }
    func change(_ operation: @Sendable (DataStore) async throws -> Void) async {
        guard !isResetting, let store else { return }
        pendingWrites += 1
        defer { pendingWrites -= 1 }
        do { try await operation(store); try await refresh() }
        catch { message = L("Could not save. Please retry.") + "\n" + error.localizedDescription }
    }
    func setVisited(_ id: String, _ value: Bool) async {
        await change { try await $0.setVisited(id, value: value) }
    }
    func saveNote(_ id: String, _ text: String) async {
        guard noteDrafts[id] == nil || noteDrafts[id] == text else { return }
        let version = (noteVersions[id] ?? 0) + 1
        noteVersions[id] = version
        await change { try await $0.setNote(id, text: text, editVersion: version) }
    }
    func completeOnboarding() async {
        await change { try await $0.finishOnboarding(automatic: false) }
    }
    func requestPhotoAccess() async {
        guard !isRequestingPhotoAccess, !isImporting, !isSyncing, !isResetting else { return }
        isRequestingPhotoAccess = true
        defer { isRequestingPhotoAccess = false }
        photoAuthorizationNote = L("Waiting for permission…")
        access = await requestAuthorization()
        photoAuthorizationNote = PhotoAuthorizationService.diagnostic
        isRequestingPhotoAccess = false
        guard access.canRead else { return }
        await change { try await $0.setAutomaticSync(true) }
        await becameActive()
    }
    func becameActive() async {
        let next = PhotoAuthorizationService.current
        if access != next { PhotoLibraryService.shared.clear() }
        access = next
        if access.canRead && observer == nil {
            observer = PhotoLibraryObserver { [weak self] in
                Task { @MainActor [weak self] in self?.scheduleSync() }
            }
        }
        if !access.canRead { observer = nil; await change { try await $0.setAccessUnavailable() } }
        if snapshot.settings.automaticSync { await sync() }
        else if access.canRead { await refreshAvailability() }
    }
    func scheduleSync() {
        scheduledSync?.cancel()
        scheduledSync = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
            await self?.becameActive()
        }
    }
    private func refreshAvailability() async {
        guard !isResetting, !isImporting, let store else { return }
        if isSyncing { syncAgain = true; return }
        isSyncing = true
        defer {
            isSyncing = false
            if syncAgain {
                let force = forceNextSync
                syncAgain = false
                forceNextSync = false
                if force { Task { await sync(force: true) } }
                else { Task { await becameActive() } }
            }
        }
        let expectedAccess = access
        let ids = snapshot.photos.compactMap(\.assetLocalIdentifier)
        do {
            let visible = try await scanner.availableIdentifiers(ids)
            guard PhotoAuthorizationService.current == expectedAccess else { syncAgain = true; return }
            try await store.updateAvailability(visible, access: expectedAccess)
            try await refresh()
        } catch is CancellationError { }
        catch { message = L("Photo processing failed. Please retry.") }
    }
    @discardableResult func sync(force: Bool = false) async -> Bool {
        guard !isResetting, !isImporting, let store else { return false }
        if isSyncing { syncAgain = true; forceNextSync = forceNextSync || force; return false }
        access = PhotoAuthorizationService.current
        guard access.canRead else {
            await change { try await $0.setAccessUnavailable() }
            return false
        }
        isSyncing = true
        defer {
            isSyncing = false
            if syncAgain {
                let nextForce = forceNextSync
                syncAgain = false
                forceNextSync = false
                if snapshot.settings.automaticSync || nextForce { Task { await sync(force: nextForce) } }
                else { Task { await becameActive() } }
            }
        }
        let scanAccess = access
        let scanStartedAt = Date.now
        do {
            let assets = try await scanner.scan()
            try Task.checkCancellation()
            guard PhotoAuthorizationService.current == scanAccess else { await becameActive(); return false }
            guard !provinces.isEmpty else { return false }
            try await store.reconcile(assets, access: scanAccess, provinces: atlas.classificationPlaces, force: force, scanStartedAt: scanStartedAt)
            if PhotoAuthorizationService.current != scanAccess {
                access = PhotoAuthorizationService.current
                try await store.setAccessUnavailable()
                syncAgain = access.canRead
            }
            try await refresh()
            let locatedCount = assets.filter { $0.coordinate?.isValid == true }.count
            let groupedCount = photosByProvince.values.reduce(0) { $0 + $1.count }
            photoScanSummary = L("Scanned: {0}. With GPS: {1}. Grouped: {2}. Unsorted: {3}.", String(assets.count), String(locatedCount), String(groupedCount), String(pendingPhotos.count))
            return PhotoAuthorizationService.current == scanAccess
        } catch is CancellationError { return false }
        catch { message = L("Photo processing failed. Please retry.") + "\n" + error.localizedDescription; return false }
    }
    func assign(_ ids: Set<String>, to provinceID: String) async {
        await change { try await $0.assign(ids, to: provinceID) }
    }
    func reset() async {
        guard !isSyncing, !isImporting, !isResetting, !isRequestingPhotoAccess, pendingWrites == 0, let store else { return }
        isResetting = true
        scheduledSync?.cancel()
        observer = nil
        defer { isResetting = false }
        do {
            try await store.reset()
            noteDrafts.removeAll()
            noteVersions.removeAll()
            photoImportSummary = nil
            photoScanSummary = nil
            try await refresh()
            PhotoLibraryService.shared.clear()
            try await ImportedFileStore.shared.clear()
        } catch { message = L("Could not save. Please retry.") + "\n" + error.localizedDescription }
    }
    func cleanMissing() async {
        guard !isSyncing, !isImporting, PhotoAuthorizationService.current == .authorized else { return }
        let succeeded = await sync()
        guard succeeded, !isSyncing, PhotoAuthorizationService.current == .authorized else { return }
        await change { try await $0.cleanMissing() }
    }
}
