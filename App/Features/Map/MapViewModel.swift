import SwiftUI
import Observation

@MainActor @Observable
final class MapViewModel {
    private(set) var shapes: [ProvinceShape] = []
    private var cachedSize = CGSize.zero
    private var cachedIDs: [String] = []
    func prepare(provinces: [ProvinceDefinition], size: CGSize) {
        guard size != cachedSize || provinces.map(\.id) != cachedIDs else { return }
        shapes = ProvinceRenderer.shapes(for: provinces, size: size)
        cachedSize = size
        cachedIDs = provinces.map(\.id)
    }
}
