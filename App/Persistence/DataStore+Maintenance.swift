import Foundation
import SwiftData

extension DataStore {
    func setAutomaticSync(_ enabled: Bool) throws {
        try settings().automaticSync = enabled
        try save()
    }
    func cleanMissing() throws {
        let photos = try modelContext.fetch(FetchDescriptor<PhotoRecord>())
        for photo in photos where photo.isMissing && photo.source == "library" && !photo.isRemoved { modelContext.delete(photo) }
        try save()
    }
    func reset() throws {
        for record in try modelContext.fetch(FetchDescriptor<PhotoRecord>()) { modelContext.delete(record) }
        for record in try modelContext.fetch(FetchDescriptor<ProvinceRecord>()) { modelContext.delete(record) }
        let s = try settings()
        s.selectedTheme = "blue"
        s.photoSortMode = "newest"
        s.lastPhotoScanDate = nil
        s.hasCompletedOnboarding = true
        s.automaticSync = false
        try save()
        noteVersions.removeAll()
    }
}
