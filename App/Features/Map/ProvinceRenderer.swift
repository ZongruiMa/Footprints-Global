import SwiftUI

struct ProvinceShape: Identifiable {
    let province: ProvinceDefinition
    let path: Path
    var id: String { province.id }
}
enum ProvinceRenderer {
    static func shapes(for provinces: [ProvinceDefinition], size: CGSize) -> [ProvinceShape] {
        let projection = MapProjection(provinces: provinces, size: size)
        return provinces.map { province in
            var path = Path()
            for polygon in province.geometry {
                for ring in polygon.rings {
                    guard let first = ring.first else { continue }
                    path.move(to: projection.point(first))
                    for point in ring.dropFirst() { path.addLine(to: projection.point(point)) }
                    path.closeSubpath()
                }
            }
            return ProvinceShape(province: province, path: path)
        }
    }
}
enum ProvinceHitTester {
    static func province(at point: CGPoint, shapes: [ProvinceShape]) -> ProvinceDefinition? {
        shapes.sorted { $0.path.boundingRect.width * $0.path.boundingRect.height < $1.path.boundingRect.width * $1.path.boundingRect.height }
            .first { $0.path.cgPath.contains(point, using: .evenOdd, transform: .identity) }?.province
    }
}
