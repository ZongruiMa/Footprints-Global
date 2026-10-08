import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import TravelCore
#else
@testable import TravelMemory
#endif

struct PointInPolygonTests {
    private func ring(_ low: Double, _ high: Double) -> [GeoCoordinate] {
        [(low,low),(high,low),(high,high),(low,high),(low,low)].map { GeoCoordinate(longitude: $0.0, latitude: $0.1) }
    }
    @Test func holesAndBoundaries() {
        let polygon = GeoPolygon(rings: [ring(0, 10), ring(3, 7)])
        #expect(PointInPolygon.contains(.init(longitude: 1, latitude: 1), polygon: polygon))
        #expect(!PointInPolygon.contains(.init(longitude: 5, latitude: 5), polygon: polygon))
        #expect(PointInPolygon.contains(.init(longitude: 0, latitude: 0), polygon: polygon))
        #expect(PointInPolygon.contains(.init(longitude: 3, latitude: 5), polygon: polygon))
        #expect(!PointInPolygon.contains(.init(longitude: 10.0001, latitude: 5), polygon: polygon))
        #expect(!PointInPolygon.contains(.init(longitude: .nan, latitude: 0), polygon: polygon))
    }
    @Test func windingDirectionDoesNotMatter() {
        let reversed = GeoPolygon(rings: [Array(ring(0, 10).reversed()), Array(ring(3, 7).reversed())])
        #expect(PointInPolygon.contains(.init(longitude: 2, latitude: 5), polygon: reversed))
        #expect(!PointInPolygon.contains(.init(longitude: 5, latitude: 5), polygon: reversed))
    }
    @Test func multiPolygonIslandAndBoundingBoxAreNotEnough() {
        let province = ProvinceDefinition(id: "a", name: "a", center: .init(longitude: 1, latitude: 1), geometry: [GeoPolygon(rings: [ring(0, 2)]), GeoPolygon(rings: [ring(8, 10)])])
        let matcher = GeoMatcher(provinces: [province])
        #expect(matcher.province(for: .init(longitude: 9, latitude: 9))?.id == "a")
        #expect(matcher.province(for: .init(longitude: 5, latitude: 5)) == nil)
    }
    @Test func duplicateVertexIsNotEverywhereBoundary() {
        var r = ring(0, 2); r.insert(r[0], at: 0)
        #expect(PointInPolygon.relation(.init(longitude: 5, latitude: 5), ring: r) == .outside)
    }
}
