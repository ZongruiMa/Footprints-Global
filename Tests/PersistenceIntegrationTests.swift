#if !SWIFT_PACKAGE
import Foundation
import SwiftData
import Testing
import ImageIO
import UniformTypeIdentifiers
@testable import TravelMemory

struct PersistenceIntegrationTests {
    @MainActor @Test func authorizationTimeoutAllowsLateReplyWithoutDoubleResume() async {
        var reply: (@Sendable (PhotoAccess) -> Void)?
        let result = await PhotoAuthorizationWaiter().wait(timeout: .milliseconds(5)) { reply = $0 }
        #expect(result == nil)
        reply?(.authorized)
        await Task.yield()
        let immediate = await PhotoAuthorizationWaiter().wait { $0(.limited) }
        #expect(immediate == .limited)
    }

    private func imageFile(withGPS: Bool) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        let context = try #require(CGContext(data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 16,
                                           space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        let image = try #require(context.makeImage())
        let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil))
        var properties: [CFString: Any] = [kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2026:09:01 12:30:00"]]
        if withGPS {
            properties[kCGImagePropertyGPSDictionary] = [kCGImagePropertyGPSLatitude: 32.0603,
                kCGImagePropertyGPSLongitude: 118.7969, kCGImagePropertyGPSLatitudeRef: "N", kCGImagePropertyGPSLongitudeRef: "E"]
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return url
    }

    @Test func pickerFileGPSClassifiesAndRemainsVisibleWithoutLibraryAccess() async throws {
        let store = try await makeStore()
        let provinces = try bundledProvinces()
        let file = try await ImportedFileStore.shared.ingest(imageFile(withGPS: true))
        let result = try await store.addAutomaticallyClassified(file, identifier: "selected-only", provinces: provinces)
        #expect(result.provinceID == "320000")
        #expect(file.date != nil && file.width == 4 && file.height == 4)
        #expect(file.contentHash?.count == 64)
        try await store.setAccessUnavailable()
        try await store.updateAvailability([], access: .limited)
        try await store.reconcile([], access: .authorized, provinces: provinces)
        // A later PhotoKit scan must not hide an explicitly imported copy.
        let screenshot = AssetMetadata(identifier: "selected-only", creationDate: nil, modificationDate: nil,
                                       pixelWidth: 4, pixelHeight: 4, coordinate: nil, mediaSubtypes: 0, isScreenshot: true)
        try await store.reconcile([screenshot], access: .authorized, provinces: provinces, force: true)
        let snapshot = try await store.snapshot()
        #expect(snapshot.photosByProvince["320000"]?.count == 1)
        #expect(snapshot.photos.first?.isVisible == true)
        #expect(await ImportedFileStore.shared.thumbnail(name: file.fileName, pixels: 20) != nil)
        try await ImportedFileStore.shared.remove(name: file.fileName)
    }

    @Test func fileWithoutGPSIsPendingAndReimportPreservesManualAssignmentWithoutIdentifier() async throws {
        let store = try await makeStore()
        let provinces = try bundledProvinces()
        let staged = try imageFile(withGPS: false)
        let duplicate = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        try FileManager.default.copyItem(at: staged, to: duplicate)
        let first = try await ImportedFileStore.shared.ingest(staged)
        #expect(first.coordinate == nil)
        _ = try await store.addAutomaticallyClassified(first, identifier: nil, provinces: provinces)
        let initial = try await store.snapshot()
        #expect(initial.pendingPhotos.count == 1)
        let id = try #require(initial.pendingPhotos.first?.id)
        try await store.assign([id], to: "510000")
        let second = try await ImportedFileStore.shared.ingest(duplicate)
        #expect(second.contentHash == first.contentHash)
        let result = try await store.addAutomaticallyClassified(second, identifier: nil, provinces: provinces)
        #expect(result.oldFile == first.fileName)
        #expect(result.provinceID == "510000")
        let final = try await store.snapshot()
        #expect(final.photos.count == 1 && final.pendingPhotos.isEmpty)
        #expect(final.photosByProvince["510000"]?.count == 1)
        try await ImportedFileStore.shared.remove(name: first.fileName)
        try await ImportedFileStore.shared.remove(name: second.fileName)
    }

    @Test func GPSValidationHandlesHemisphereAndInvalidMetadata() {
        func coordinate(_ lat: Double, _ lon: Double, _ latRef: String, _ lonRef: String) -> GeoCoordinate? {
            ImageLocationMetadata.coordinate(in: [kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: lat,
                kCGImagePropertyGPSLongitude: lon, kCGImagePropertyGPSLatitudeRef: latRef, kCGImagePropertyGPSLongitudeRef: lonRef]])
        }
        #expect(coordinate(33, 70, "S", "W")?.latitude == -33)
        #expect(coordinate(33, 70, "S", "W")?.longitude == -70)
        #expect(coordinate(91, 70, "N", "E") == nil)
        #expect(coordinate(33, 181, "N", "E") == nil)
        #expect(coordinate(33, 70, "?", "E") == nil)
        #expect(ImageLocationMetadata.coordinate(in: [:]) == nil)
    }

    @MainActor @Test func enteringMapDoesNotWaitForOrRequestPhotoAccess() async throws {
        var permissionRequests = 0
        let state = AppState(requestAuthorization: {
            permissionRequests += 1
            return .denied
        })
        state.store = try await makeStore()
        await state.completeOnboarding()
        #expect(state.snapshot.settings.hasCompletedOnboarding)
        #expect(!state.snapshot.settings.automaticSync)
        #expect(permissionRequests == 0)
        await state.setVisited("320000", true)
        await state.saveNote("320000", "无需照片权限也能记录")
        #expect(state.snapshot.provinces["320000"]?.manualVisited == true)
        #expect(state.snapshot.provinces["320000"]?.note == "无需照片权限也能记录")
        await state.requestPhotoAccess()
        #expect(permissionRequests == 1)
        #expect(state.access == .denied)
        #expect(!state.isRequestingPhotoAccess)
        #expect(state.snapshot.settings.hasCompletedOnboarding)
        #expect(!state.snapshot.settings.automaticSync)
    }

    private func makeStore() async throws -> TravelMemory.DataStore {
        try await Task.detached {
            let schema = Schema([ProvinceRecord.self, PhotoRecord.self, AppSettings.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            return TravelMemory.DataStore(modelContainer: try ModelContainer(for: schema, configurations: [config]))
        }.value
    }
    private func metadata(_ id: String, modified: Date? = nil) -> AssetMetadata {
        AssetMetadata(identifier: id, creationDate: nil, modificationDate: modified, pixelWidth: 300, pixelHeight: 200,
                      coordinate: .init(longitude: 118.7969, latitude: 32.0603), mediaSubtypes: 0, isScreenshot: false)
    }
    @Test func manualAssignmentSurvivesFullRescanAndRemovalStaysRemoved() async throws {
        let store = try await makeStore()
        let provinces = try bundledProvinces()
        try await store.reconcile([metadata("one")], access: .authorized, provinces: provinces)
        try await store.assign(["asset:one"], to: "510000")
        try await store.reconcile([metadata("one", modified: .now)], access: .authorized, provinces: provinces, force: true)
        let assigned = try await store.snapshot()
        #expect(assigned.photos.first?.effectiveProvinceID == "510000")
        _ = try await store.removePhoto("asset:one")
        try await store.reconcile([metadata("one")], access: .authorized, provinces: provinces, force: true)
        #expect(try await store.snapshot().photos.isEmpty)
    }
    @Test func limitedCleanupCannotLoseManualHistory() async throws {
        let store = try await makeStore()
        let provinces = try bundledProvinces()
        try await store.reconcile([metadata("one")], access: .authorized, provinces: provinces)
        try await store.assign(["asset:one"], to: "530000")
        try await store.reconcile([], access: .limited, provinces: provinces)
        var snapshot = try await store.snapshot()
        #expect(snapshot.photos.first?.isMissing == false)
        #expect(snapshot.photos.first?.isUnavailable == true)
        try await store.cleanMissing()
        try await store.reconcile([metadata("one")], access: .limited, provinces: provinces)
        snapshot = try await store.snapshot()
        #expect(snapshot.photos.first?.effectiveProvinceID == "530000")
        #expect(snapshot.photos.first?.isVisible == true)
    }
    @Test func resetClearsRecordsAndDoesNotImmediatelyRescan() async throws {
        let store = try await makeStore()
        try await store.setVisited("320000", value: true)
        try await store.setNote("320000", text: "雨\n🌧️")
        try await store.finishOnboarding(automatic: true)
        try await store.reset()
        let snapshot = try await store.snapshot()
        #expect(snapshot.provinces.isEmpty && snapshot.photos.isEmpty)
        #expect(snapshot.settings.hasCompletedOnboarding)
        #expect(!snapshot.settings.automaticSync)
    }
    @Test func staleNoteSaveCannotOverwriteNewerText() async throws {
        let store = try await makeStore()
        try await store.setNote("320000", text: "新的留言", editVersion: 2)
        try await store.setNote("320000", text: "旧的留言", editVersion: 1)
        let snapshot = try await store.snapshot()
        #expect(snapshot.provinces["320000"]?.note == "新的留言")
    }
    @Test func noteAndVisitSurviveReopeningDatabase() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        func open() async throws -> TravelMemory.DataStore {
            try await Task.detached {
                let schema = Schema([ProvinceRecord.self, PhotoRecord.self, AppSettings.self])
                let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
                return TravelMemory.DataStore(modelContainer: try ModelContainer(for: schema, configurations: [config]))
            }.value
        }
        let first = try await open()
        try await first.setNote("320000", text: "梅子黄时雨\n🌧️")
        try await first.setVisited("320000", value: true)
        let reopened = try await open()
        let snapshot = try await reopened.snapshot()
        #expect(snapshot.provinces["320000"]?.note == "梅子黄时雨\n🌧️")
        #expect(snapshot.provinces["320000"]?.manualVisited == true)
    }
}
#endif
