import Foundation

struct AssetMetadata: Sendable {
    let identifier: String
    let creationDate: Date?
    let modificationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let coordinate: GeoCoordinate?
    let mediaSubtypes: UInt
    let isScreenshot: Bool
    var fingerprint: String {
        "\(creationDate?.timeIntervalSince1970 ?? -1)|\(modificationDate?.timeIntervalSince1970 ?? -1)|\(pixelWidth)|\(pixelHeight)|\(coordinate?.latitude ?? 999)|\(coordinate?.longitude ?? 999)|\(mediaSubtypes)"
    }
}
enum PhotoAccess: String, Sendable {
    case notDetermined, authorized, limited, denied, restricted
    var canRead: Bool { self == .authorized || self == .limited }
    var title: String {
        switch self {
        case .notDetermined: L("Not requested")
        case .authorized: L("Full access")
        case .limited: L("Selected photos only")
        case .denied: L("Access denied")
        case .restricted: L("Restricted by the system")
        }
    }
}
