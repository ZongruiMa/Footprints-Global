import Foundation

enum PhotoSyncPolicy {
    static func needsRematch(previous: String?, incoming: String, force: Bool) -> Bool {
        force || previous != incoming
    }
    static func availability(seen: Bool, access: PhotoAccess, previouslyMissing: Bool) -> (missing: Bool, unavailable: Bool) {
        if seen { return (false, false) }
        return (access == .authorized ? true : previouslyMissing, true)
    }
    static func effectiveProvince(manual: String?, automatic: String?) -> String? { manual ?? automatic }
    static func isVisited(manual: Bool, validPhotoCount: Int) -> Bool { manual || validPhotoCount > 0 }
}
