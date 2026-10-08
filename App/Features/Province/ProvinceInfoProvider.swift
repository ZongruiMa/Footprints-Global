import Foundation

protocol ProvinceInfoProvider: Sendable {
    func text(for provinceID: String) async -> String
}
struct EmptyProvinceInfoProvider: ProvinceInfoProvider {
    func text(for provinceID: String) async -> String { L("Borders are approximate. Missing GPS cannot be recovered; assign a place manually.") }
}
