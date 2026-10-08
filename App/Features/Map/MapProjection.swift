import CoreGraphics
import Foundation

struct MapProjection {
    private let bounds: CGRect
    private let target: CGRect
    private let scale: CGFloat
    private let longitudeStart: Double
    private let longitudeFactor: Double
    init(provinces: [ProvinceDefinition], size: CGSize) {
        let coordinates = provinces.flatMap { $0.geometry.flatMap { $0.rings.flatMap { $0 } } }
        let world = provinces.filter(\.isCountry).count > 1
        let start = world ? -180 : LongitudeWindow.start(for: coordinates.map(\.longitude))
        let latitude = provinces.isEmpty ? 0 : provinces.map(\.center.latitude).reduce(0, +) / Double(provinces.count)
        let factor = world ? 1 : cos(min(75, max(-75, latitude)) * .pi / 180)
        longitudeStart = start
        longitudeFactor = factor
        let points = coordinates.map { CGPoint(x: LongitudeWindow.unwrap($0.longitude, start: start) * factor, y: -$0.latitude) }
        let xs = points.map(\.x), ys = points.map(\.y)
        bounds = CGRect(x: xs.min() ?? 0, y: ys.min() ?? 0,
                        width: max(0.001, (xs.max() ?? 1) - (xs.min() ?? 0)),
                        height: max(0.001, (ys.max() ?? 1) - (ys.min() ?? 0)))
        target = CGRect(origin: .zero, size: size).insetBy(dx: 20, dy: 32)
        scale = max(0.01, min(target.width / bounds.width, target.height / bounds.height))
    }
    func point(_ coordinate: GeoCoordinate) -> CGPoint {
        let p = CGPoint(x: LongitudeWindow.unwrap(coordinate.longitude, start: longitudeStart) * longitudeFactor, y: -coordinate.latitude)
        return CGPoint(x: (p.x - bounds.midX) * scale + target.midX,
                       y: (p.y - bounds.midY) * scale + target.midY)
    }
}
