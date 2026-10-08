import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import TravelCore
#else
@testable import TravelMemory
#endif

struct GeoMatcherTests {
    @Test(arguments: [
        ("320000",118.7969,32.0603),("510000",104.0665,30.5728),
        ("110000",116.4074,39.9042),("310000",121.4737,31.2304),
        ("440000",113.2644,23.1291),("530000",102.8329,24.8801),
        ("460000",110.1983,20.0442),("650000",87.6168,43.8256),
        ("540000",91.1172,29.6469),("810000",114.1694,22.3193),
        ("820000",113.5439,22.1987),("710000",121.5654,25.0330)
    ])
    func cities(id: String, longitude: Double, latitude: Double) throws {
        let matcher = GeoMatcher(provinces: try bundledProvinces())
        #expect(matcher.province(for: .init(longitude: longitude, latitude: latitude))?.id == id)
    }
    @Test func outsideAndNearBoundary() throws {
        let regions = try bundledProvinces()
        let matcher = GeoMatcher(provinces: regions)
        #expect(matcher.province(for: .init(longitude: 140, latitude: 20)) == nil)
        #expect(matcher.province(for: .init(longitude: 0, latitude: 0)) == nil)
        let p = try #require(regions.first?.geometry.first?.rings.first?.first)
        #expect(matcher.province(for: p) != nil)
        _ = matcher.province(for: .init(longitude: p.longitude + 1e-7, latitude: p.latitude - 1e-7))
    }
}
