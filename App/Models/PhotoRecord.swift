import Foundation
import SwiftData

@Model final class PhotoRecord {
    @Attribute(.unique) var id: String
    var assetLocalIdentifier: String?
    var provinceID: String?
    var manualProvinceID: String?
    var creationDate: Date?
    var modificationDate: Date?
    var latitude: Double?
    var longitude: Double?
    var pixelWidth: Int
    var pixelHeight: Int
    var mediaSubtypes: Int
    var manualSortIndex: Double
    var source: String
    var localFileName: String?
    var isScreenshot: Bool
    var isMissing: Bool
    var isUnavailable: Bool
    var isRemoved: Bool
    var fingerprint: String
    var createdAt: Date
    var updatedAt: Date
    var effectiveProvinceID: String? { PhotoSyncPolicy.effectiveProvince(manual: manualProvinceID, automatic: provinceID) }
    init(id: String, assetLocalIdentifier: String? = nil) {
        self.id = id
        self.assetLocalIdentifier = assetLocalIdentifier
        pixelWidth = 0
        pixelHeight = 0
        mediaSubtypes = 0
        manualSortIndex = Date.now.timeIntervalSince1970
        source = "library"
        isScreenshot = false
        isMissing = false
        isUnavailable = false
        isRemoved = false
        fingerprint = ""
        createdAt = .now
        updatedAt = .now
    }
    func apply(_ metadata: AssetMetadata) {
        creationDate = metadata.creationDate
        modificationDate = metadata.modificationDate
        latitude = metadata.coordinate?.latitude
        longitude = metadata.coordinate?.longitude
        pixelWidth = metadata.pixelWidth
        pixelHeight = metadata.pixelHeight
        mediaSubtypes = Int(metadata.mediaSubtypes)
        isScreenshot = metadata.isScreenshot
        fingerprint = metadata.fingerprint
        updatedAt = .now
    }
}
