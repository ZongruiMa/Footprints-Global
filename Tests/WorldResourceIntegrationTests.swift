#if !SWIFT_PACKAGE
import Foundation
import Testing
@testable import TravelMemory

struct WorldResourceIntegrationTests {
    private func atlas() throws -> WorldAtlas {
        func load(_ name: String) throws -> [ProvinceDefinition] {
            let url = try #require(Bundle.main.url(forResource: name, withExtension: "geojson"))
            return try MapGeometryLoader.decode(Data(contentsOf: url))
        }
        return try WorldAtlas(countries: load("world_countries"), regions: load("world_regions"))
    }
    @Test func bundledWorldClassifiesAcrossContinentsAndPreservesChina() throws {
        let atlas = try atlas()
        #expect(atlas.countries.count == 258 && atlas.regions.count == 4558)
        let matcher = GeoMatcher(provinces: atlas.classificationPlaces)
        for (country, longitude, latitude) in [("JPN",139.6917,35.6895),("FRA",2.3522,48.8566),("USA",-74.006,40.7128),("BRA",-46.6333,-23.5505),("AUS",151.2093,-33.8688),("ZAF",28.0473,-26.2041),("EGY",31.2357,30.0444),("IND",77.209,28.6139),("GBR",-0.1276,51.5072)] {
            let match = matcher.province(for: .init(longitude: longitude, latitude: latitude))
            #expect(match?.countryID == "country:" + country)
            #expect(match?.isCountry == false)
        }
        #expect(matcher.province(for: .init(longitude: 118.7969, latitude: 32.0603))?.id == "320000")
        #expect(matcher.province(for: .init(longitude: -140, latitude: 0)) == nil)
    }
    @Test func translationAndSystemPermissionResourcesAreBundled() throws {
        #expect(AppLanguage.catalog.count == 104)
        #expect(AppLanguage.text("World", language: "fr") == "Monde")
        #expect(AppLanguage.text("Settings", language: "zh-Hans") == "设置")
        for language in AppLanguage.codes {
            #expect(Bundle.main.url(forResource: "InfoPlist", withExtension: "strings", subdirectory: language + ".lproj") != nil)
        }
    }
    @MainActor @Test func countryAlbumAggregatesChildrenAndMapSwitchRetainsRecords() throws {
        let state = AppState()
        state.atlas = try atlas()
        let record = PhotoRecord(id: "test-photo")
        record.manualProvinceID = "320000"
        state.photosByProvince["320000"] = [PhotoSnapshot(record)]
        state.snapshot.provinces["320000"] = ProvinceSnapshot(note: "Keeps memories", manualVisited: true)
        let savedMap = UserDefaults.standard.object(forKey: "selectedMap")
        defer { UserDefaults.standard.set(savedMap, forKey: "selectedMap") }
        state.selectMap("country:JPN")
        #expect(state.provinces.allSatisfy { $0.countryID == "country:JPN" })
        #expect(state.photos(in: "country:CHN").count == 1)
        #expect(state.mapVisitedIDs.contains("country:CHN"))
        #expect(state.snapshot.provinces["320000"]?.note == "Keeps memories")
    }
}
#endif
