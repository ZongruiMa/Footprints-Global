import Foundation
import SwiftData

@ModelActor actor DataStore {
    private var revision = 0
    var noteVersions: [String: Int] = [:]
    static func open() async throws -> DataStore {
        // A single owned background root ensures ModelContext gets a non-main executor.
        try await Task.detached(priority: .userInitiated) {
            let schema = Schema([ProvinceRecord.self, PhotoRecord.self, AppSettings.self])
            let url = try LocalPaths.directory("PrivateStore").appendingPathComponent("memories.store")
            let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            return DataStore(modelContainer: container)
        }.value
    }
    func snapshot() throws -> StoreSnapshot {
        let provinces = try modelContext.fetch(FetchDescriptor<ProvinceRecord>())
        let s = try settings()
        var result = StoreSnapshot(revision: revision)
        for p in provinces { result.provinces[p.provinceID] = ProvinceSnapshot(note: p.note, manualVisited: p.manualVisited) }
        result.settings = SettingsSnapshot(selectedTheme: s.selectedTheme, photoSortMode: s.photoSortMode,
                                           lastPhotoScanDate: s.lastPhotoScanDate, hasCompletedOnboarding: s.hasCompletedOnboarding, automaticSync: s.automaticSync)
        let photos = try modelContext.fetch(FetchDescriptor<PhotoRecord>(predicate: #Predicate { !$0.isRemoved }))
        result.photos = photos.map(PhotoSnapshot.init)
        let visible = result.photos.filter(\.isVisible)
        let mode = PhotoSortMode(rawValue: s.photoSortMode) ?? .newest
        result.photosByProvince = Dictionary(grouping: visible.filter { $0.effectiveProvinceID != nil }, by: { $0.effectiveProvinceID ?? "" }).mapValues { mode.sorted($0) }
        result.pendingPhotos = PhotoSortMode.newest.sorted(visible.filter { $0.effectiveProvinceID == nil && !$0.isScreenshot })
        return result
    }
    func setVisited(_ id: String, value: Bool) throws {
        let p = try province(id)
        p.manualVisited = value
        p.updatedAt = .now
        try save()
    }
    func setNote(_ id: String, text: String, editVersion: Int? = nil) throws {
        if let editVersion, editVersion < (noteVersions[id] ?? 0) { return }
        let p = try province(id)
        p.note = text
        p.updatedAt = .now
        try save()
        if let editVersion { noteVersions[id] = editVersion }
    }
    func setTheme(_ value: String) throws {
        try settings().selectedTheme = value
        try save()
    }
    func finishOnboarding(automatic: Bool) throws {
        let s = try settings()
        s.hasCompletedOnboarding = true
        s.automaticSync = automatic
        try save()
    }
    func settings() throws -> AppSettings {
        if let existing = try modelContext.fetch(FetchDescriptor<AppSettings>()).first { return existing }
        let value = AppSettings()
        modelContext.insert(value)
        try save()
        return value
    }
    private func province(_ id: String) throws -> ProvinceRecord {
        let descriptor = FetchDescriptor<ProvinceRecord>(predicate: #Predicate { $0.provinceID == id })
        if let existing = try modelContext.fetch(descriptor).first { return existing }
        let record = ProvinceRecord(provinceID: id)
        modelContext.insert(record)
        return record
    }
    func save() throws {
        do { try modelContext.save(); revision += 1 }
        catch { modelContext.rollback(); throw error }
    }
}
