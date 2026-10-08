import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import TravelCore
#else
@testable import TravelMemory
#endif

func bundledProvinces() throws -> [ProvinceDefinition] {
    #if SWIFT_PACKAGE
    let url = try #require(Bundle.module.url(forResource: "china_provinces", withExtension: "geojson", subdirectory: "Fixtures"))
    #else
    let url = try #require(Bundle.main.url(forResource: "china_provinces", withExtension: "geojson"))
    #endif
    return try MapGeometryLoader.decode(Data(contentsOf: url))
}
struct GeoJSONLoaderTests {
    @Test func bundledDataHas34UniqueRegions() throws {
        let regions = try bundledProvinces()
        #expect(regions.count == 34)
        #expect(Set(regions.map(\.id)).count == 34)
        #expect(regions.allSatisfy { !$0.geometry.isEmpty })
    }
    @Test func rejectsInvalidJSONAndEmptyCollection() {
        #expect(throws: (any Error).self) { try MapGeometryLoader.decode(Data("bad".utf8)) }
        #expect(throws: (any Error).self) { try MapGeometryLoader.decode(Data(#"{"type":"FeatureCollection","features":[]}"#.utf8)) }
    }
}
