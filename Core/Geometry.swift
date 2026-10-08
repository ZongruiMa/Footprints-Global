import Foundation

struct GeoCoordinate: Equatable, Sendable {
    let longitude: Double
    let latitude: Double
    var isValid: Bool {
        longitude.isFinite && latitude.isFinite && (-180...180).contains(longitude) && (-90...90).contains(latitude)
    }
}
struct GeoBounds: Sendable {
    let minX: Double
    let minY: Double
    let maxX: Double
    let maxY: Double
    init(points: [GeoCoordinate]) {
        minX = points.map(\.longitude).min() ?? 0
        minY = points.map(\.latitude).min() ?? 0
        maxX = points.map(\.longitude).max() ?? 0
        maxY = points.map(\.latitude).max() ?? 0
    }
    func contains(_ p: GeoCoordinate, epsilon: Double = 1e-9) -> Bool {
        p.longitude >= minX - epsilon && p.longitude <= maxX + epsilon &&
        p.latitude >= minY - epsilon && p.latitude <= maxY + epsilon
    }
}
struct GeoPolygon: Sendable {
    let rings: [[GeoCoordinate]]
    let bounds: GeoBounds
    init(rings: [[GeoCoordinate]]) {
        self.rings = rings
        bounds = GeoBounds(points: rings.first ?? [])
    }
}
struct ProvinceDefinition: Identifiable, Sendable {
    let id: String
    let name: String
    let displayName: String
    let countryID: String?
    let isCountry: Bool
    let names: [String: String]
    let center: GeoCoordinate
    let geometry: [GeoPolygon]
    let bounds: GeoBounds
    init(id: String, name: String, displayName: String? = nil, center: GeoCoordinate, geometry: [GeoPolygon], countryID: String? = nil, isCountry: Bool = false, names: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.displayName = displayName ?? name
        self.countryID = countryID
        self.isCountry = isCountry
        self.names = names
        self.center = center
        self.geometry = geometry
        bounds = GeoBounds(points: geometry.flatMap { $0.rings.first ?? [] })
    }
    func localizedName(language: String) -> String {
        names[language] ?? names[String(language.prefix(2))] ?? names["en"] ?? displayName
    }
}
