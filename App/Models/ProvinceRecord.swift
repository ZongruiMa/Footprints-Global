import Foundation
import SwiftData

@Model final class ProvinceRecord {
    @Attribute(.unique) var provinceID: String
    var note: String
    var manualVisited: Bool
    var createdAt: Date
    var updatedAt: Date
    init(provinceID: String) {
        self.provinceID = provinceID
        note = ""
        manualVisited = false
        createdAt = .now
        updatedAt = .now
    }
}
