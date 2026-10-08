import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import TravelCore
#else
@testable import TravelMemory
#endif

struct WorldAtlasTests {
    private func square(_ id: String, country: String, isCountry: Bool = false, low: Double = 0, high: Double = 10) -> ProvinceDefinition {
        let ring = [(low, low), (high, low), (high, high), (low, high), (low, low)].map { GeoCoordinate(longitude: $0.0, latitude: $0.1) }
        return ProvinceDefinition(id: id, name: id, center: .init(longitude: low, latitude: low), geometry: [GeoPolygon(rings: [ring])], countryID: country, isCountry: isCountry)
    }
    @Test func classificationPrefersRegionAndFallsBackToCountry() {
        let country = square("country:X", country: "country:X", isCountry: true)
        let region = square("region:X1", country: country.id, low: 2, high: 4)
        let matcher = GeoMatcher(provinces: [country, region])
        #expect(matcher.province(for: .init(longitude: 3, latitude: 3))?.id == region.id)
        #expect(matcher.province(for: .init(longitude: 8, latitude: 8))?.id == country.id)
        #expect(matcher.province(for: .init(longitude: 40, latitude: 40)) == nil)
        #expect(matcher.province(for: .init(longitude: 10, latitude: 10))?.id == country.id)
    }
    @Test func hierarchyRetainsLegacyIDsAndDoesNotConfuseDisplayedMapWithClassifier() {
        let china = square("country:CHN", country: "country:CHN", isCountry: true)
        let france = square("country:FRA", country: "country:FRA", isCountry: true)
        let jiangsu = square("320000", country: china.id)
        let atlas = WorldAtlas(countries: [china, france], regions: [jiangsu])
        #expect(atlas.places(on: "world").count == 2)
        #expect(atlas.places(on: china.id).map(\.id) == ["320000"])
        #expect(atlas.places(on: france.id).map(\.id) == [france.id])
        #expect(atlas.classificationPlaces.count == 3)
        #expect(atlas.visitedIncludingCountries(["320000"]) == ["320000", china.id])
        #expect(!atlas.visitedIncludingCountries([china.id]).contains("320000"))
    }
    @Test func dateLineFitsCompactly() {
        let values = [178.0, 179.0, -179.0, -178.0]
        let start = LongitudeWindow.start(for: values)
        let unwrapped = values.map { LongitudeWindow.unwrap($0, start: start) }
        #expect((unwrapped.max() ?? 0) - (unwrapped.min() ?? 0) == 4)
        #expect(LongitudeWindow.unwrap(180, start: -180) == 180)
    }
    @Test func localeResolution() {
        #expect(AppLanguage.resolve(["zh-HK"]) == "zh-Hant")
        #expect(AppLanguage.resolve(["zh-CN"]) == "zh-Hans")
        #expect(AppLanguage.resolve(["pt-BR"]) == "pt")
        #expect(AppLanguage.resolve(["xx", "ar-EG"]) == "ar")
        #expect(AppLanguage.resolve(["xx"]) == "en")
        #expect(AppLanguage.text("Total {0}", language: "xx", arguments: ["2"]) == "Total 2")
    }
}
