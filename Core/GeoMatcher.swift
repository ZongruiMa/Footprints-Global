import Foundation

enum PointInPolygon {
    enum Relation: Equatable { case outside, inside, boundary }
    /// Fixed angular tolerance (~0.1 mm); this is numerical tolerance, not a coastal buffer.
    static func relation(_ point: GeoCoordinate, ring: [GeoCoordinate]) -> Relation {
        guard point.isValid, ring.count >= 4 else { return .outside }
        var inside = false
        let epsilon = 1e-9
        for index in 0..<(ring.count - 1) {
            let a = ring[index], b = ring[index + 1]
            let dx = b.longitude - a.longitude, dy = b.latitude - a.latitude
            let px = point.longitude - a.longitude, py = point.latitude - a.latitude
            let length = hypot(dx, dy)
            if length < epsilon {
                if hypot(px, py) <= epsilon { return .boundary }
                continue
            }
            let cross = abs(px * dy - py * dx) / length
            let dot = px * dx + py * dy
            if cross <= epsilon && dot >= -epsilon * length && dot <= length * length + epsilon * length { return .boundary }
            if (a.latitude > point.latitude) != (b.latitude > point.latitude) {
                let intersection = a.longitude + (point.latitude - a.latitude) * dx / dy
                if point.longitude < intersection { inside.toggle() }
            }
        }
        return inside ? .inside : .outside
    }
    static func contains(_ point: GeoCoordinate, polygon: GeoPolygon) -> Bool {
        guard polygon.bounds.contains(point), let outer = polygon.rings.first else { return false }
        switch relation(point, ring: outer) {
        case .outside: return false
        case .boundary: return true
        case .inside: break
        }
        for hole in polygon.rings.dropFirst() {
            switch relation(point, ring: hole) {
            case .inside: return false
            case .boundary: return true
            case .outside: continue
            }
        }
        return true
    }
}

struct GeoMatcher: Sendable {
    let provinces: [ProvinceDefinition]
    private let cells: [Int: [Int]]
    init(provinces: [ProvinceDefinition]) {
        self.provinces = provinces.sorted {
            if $0.isCountry != $1.isCountry { return !$0.isCountry }
            let a = ($0.bounds.maxX - $0.bounds.minX) * ($0.bounds.maxY - $0.bounds.minY)
            let b = ($1.bounds.maxX - $1.bounds.minX) * ($1.bounds.maxY - $1.bounds.minY)
            return a == b ? $0.id < $1.id : a < b
        }
        var index: [Int: [Int]] = [:]
        for (i, region) in self.provinces.enumerated() {
            let b = region.bounds
            for x in Self.xCell(b.minX)...Self.xCell(b.maxX) {
                for y in Self.yCell(b.minY)...Self.yCell(b.maxY) { index[y * 36 + x, default: []].append(i) }
            }
        }
        cells = index
    }
    private static func xCell(_ x: Double) -> Int { min(35, max(0, Int(floor((x + 180) / 10)))) }
    private static func yCell(_ y: Double) -> Int { min(17, max(0, Int(floor((y + 90) / 10)))) }
    func province(for coordinate: GeoCoordinate) -> ProvinceDefinition? {
        guard coordinate.isValid else { return nil }
        for i in cells[Self.yCell(coordinate.latitude) * 36 + Self.xCell(coordinate.longitude)] ?? [] {
            let province = provinces[i]
            if province.bounds.contains(coordinate) && province.geometry.contains(where: { PointInPolygon.contains(coordinate, polygon: $0) }) { return province }
        }
        return nil
    }
}

protocol PhotoClassificationService: Sendable {
    func shouldLocate(_ photo: AssetMetadata) -> Bool
}
struct BasicPhotoClassifier: PhotoClassificationService {
    func shouldLocate(_ photo: AssetMetadata) -> Bool { !photo.isScreenshot && photo.coordinate?.isValid == true }
}
