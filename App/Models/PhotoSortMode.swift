import Foundation

enum PhotoSortMode: String, CaseIterable, Identifiable, Sendable {
    case newest, oldest, manual
    var id: String { rawValue }
    var title: String {
        switch self { case .newest: L("Newest first"); case .oldest: L("Oldest first"); case .manual: L("Manual order") }
    }
    func sorted(_ photos: [PhotoSnapshot]) -> [PhotoSnapshot] {
        photos.sorted { a, b in
            if self == .manual && a.manualSortIndex != b.manualSortIndex { return a.manualSortIndex < b.manualSortIndex }
            let left = a.creationDate ?? .distantPast, right = b.creationDate ?? .distantPast
            if left == right { return a.id < b.id }
            return self == .oldest ? left < right : left > right
        }
    }
}
