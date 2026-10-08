import Foundation

struct WorldAtlas: Sendable {
    let countries: [ProvinceDefinition]
    let regions: [ProvinceDefinition]
    let regionsByCountry: [String: [ProvinceDefinition]]
    let placesByID: [String: ProvinceDefinition]

    init(countries: [ProvinceDefinition] = [], regions: [ProvinceDefinition] = []) {
        self.countries = countries
        self.regions = regions
        regionsByCountry = Dictionary(grouping: regions, by: { $0.countryID ?? "" })
        placesByID = Dictionary(uniqueKeysWithValues: (countries + regions).map { ($0.id, $0) })
    }
    var classificationPlaces: [ProvinceDefinition] { regions + countries }
    func places(on map: String) -> [ProvinceDefinition] {
        if map == "world" { return countries }
        return regionsByCountry[map] ?? placesByID[map].map { [$0] } ?? []
    }
    func visitedIncludingCountries(_ ids: Set<String>) -> Set<String> {
        ids.union(ids.compactMap { placesByID[$0]?.countryID })
    }
}
