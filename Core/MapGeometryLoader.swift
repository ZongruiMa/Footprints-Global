import Foundation

enum MapDataError: Error { case invalidCollection, invalidGeometry, invalidCoordinate, duplicateID, missingResource }
enum MapGeometryLoader {
    private struct Collection: Decodable {
        let type: String
        let features: [Feature]
    }
    private struct Feature: Decodable {
        struct Properties: Decodable {
            let id: String
            let name: String
            let displayName: String
            let center: [Double]
            let countryID: String?
            let isCountry: Bool?
            let names: [String: String]?
        }
        let properties: Properties
        let geometry: Geometry
    }
    private struct Geometry: Decodable {
        let polygons: [[[[Double]]]]
        enum CodingKeys: String, CodingKey { case type, coordinates }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            switch try c.decode(String.self, forKey: .type) {
            case "Polygon": polygons = [try c.decode([[[Double]]].self, forKey: .coordinates)]
            case "MultiPolygon": polygons = try c.decode([[[[Double]]]].self, forKey: .coordinates)
            default: throw MapDataError.invalidGeometry
            }
        }
    }
    static func decode(_ data: Data) throws -> [ProvinceDefinition] {
        let collection = try JSONDecoder().decode(Collection.self, from: data)
        guard collection.type == "FeatureCollection", !collection.features.isEmpty else { throw MapDataError.invalidCollection }
        var ids = Set<String>()
        return try collection.features.map { feature in
            let p = feature.properties
            guard !p.id.isEmpty, ids.insert(p.id).inserted else { throw MapDataError.duplicateID }
            let center = try coordinate(p.center)
            guard !feature.geometry.polygons.isEmpty else { throw MapDataError.invalidGeometry }
            let polygons = try feature.geometry.polygons.map { rings in
                guard !rings.isEmpty else { throw MapDataError.invalidGeometry }
                return GeoPolygon(rings: try rings.map { raw in
                    let ring = try raw.map(coordinate)
                    guard ring.count >= 4, ring.first == ring.last else { throw MapDataError.invalidGeometry }
                    return ring
                })
            }
            return ProvinceDefinition(id: p.id, name: p.name, displayName: p.displayName, center: center, geometry: polygons,
                                      countryID: p.countryID, isCountry: p.isCountry ?? false, names: p.names ?? [:])
        }.sorted { $0.id < $1.id }
    }
    private static func coordinate(_ values: [Double]) throws -> GeoCoordinate {
        guard values.count >= 2 else { throw MapDataError.invalidCoordinate }
        let coordinate = GeoCoordinate(longitude: values[0], latitude: values[1])
        guard coordinate.isValid else { throw MapDataError.invalidCoordinate }
        return coordinate
    }
}
actor MapRepository {
    private var cached: [URL: [ProvinceDefinition]] = [:]
    func load(url: URL) throws -> [ProvinceDefinition] {
        if let result = cached[url] { return result }
        let result = try MapGeometryLoader.decode(Data(contentsOf: url))
        cached[url] = result
        return result
    }
}
