import Foundation

struct ProvinceSnapshot: Sendable {
    var note = ""
    var manualVisited = false
}
struct SettingsSnapshot: Sendable {
    var selectedTheme = "blue"
    var photoSortMode = "newest"
    var lastPhotoScanDate: Date?
    var hasCompletedOnboarding = false
    var automaticSync = false
}
struct StoreSnapshot: Sendable {
    var revision = 0
    var provinces: [String: ProvinceSnapshot] = [:]
    var settings = SettingsSnapshot()
    var photos: [PhotoSnapshot] = []
    var photosByProvince: [String: [PhotoSnapshot]] = [:]
    var pendingPhotos: [PhotoSnapshot] = []
}

struct PhotoSnapshot: Identifiable, Sendable, Hashable {
    let id: String
    let assetLocalIdentifier: String?
    let localFileName: String?
    let effectiveProvinceID: String?
    let creationDate: Date?
    let manualSortIndex: Double
    let isMissing: Bool
    let isUnavailable: Bool
    let isScreenshot: Bool
    let fingerprint: String
    var isVisible: Bool { !isMissing && !isUnavailable }
    init(_ record: PhotoRecord) {
        id = record.id
        assetLocalIdentifier = record.assetLocalIdentifier
        localFileName = record.localFileName
        effectiveProvinceID = record.effectiveProvinceID
        creationDate = record.creationDate
        manualSortIndex = record.manualSortIndex
        isMissing = record.isMissing
        isUnavailable = record.isUnavailable
        isScreenshot = record.isScreenshot
        fingerprint = record.fingerprint
    }
}
