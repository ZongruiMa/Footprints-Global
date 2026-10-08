import Foundation
import SwiftData

@Model final class AppSettings {
    @Attribute(.unique) var id: String
    var selectedTheme: String
    var photoSortMode: String
    var lastPhotoScanDate: Date?
    var hasCompletedOnboarding: Bool
    var automaticSync: Bool
    init() {
        id = "settings"
        selectedTheme = "blue"
        photoSortMode = "newest"
        hasCompletedOnboarding = false
        automaticSync = false
    }
}
