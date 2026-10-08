import Foundation

enum LongitudeWindow {
    static func start(for longitudes: [Double]) -> Double {
        let values = longitudes.sorted()
        guard let first = values.first, let last = values.last else { return -180 }
        var largestGap = first + 360 - last
        var start = first
        for index in values.indices.dropFirst() {
            let gap = values[index] - values[index - 1]
            if gap > largestGap { largestGap = gap; start = values[index] }
        }
        return start
    }
    static func unwrap(_ longitude: Double, start: Double) -> Double {
        longitude < start - 0.000000001 ? longitude + 360 : longitude
    }
}
