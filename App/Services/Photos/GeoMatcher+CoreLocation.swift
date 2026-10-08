import CoreLocation

extension GeoMatcher {
    func province(for coordinate: CLLocationCoordinate2D) -> ProvinceDefinition? {
        province(for: GeoCoordinate(longitude: coordinate.longitude, latitude: coordinate.latitude))
    }
}
