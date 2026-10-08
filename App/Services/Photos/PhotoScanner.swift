import Foundation
import Photos

actor PhotoScanner {
    func availableIdentifiers(_ identifiers: [String]) throws -> Set<String> {
        var visible = Set<String>()
        for start in stride(from: 0, to: identifiers.count, by: 500) {
            try Task.checkCancellation()
            let batch = Array(identifiers[start..<min(start + 500, identifiers.count)])
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: batch, options: nil)
            for index in 0..<assets.count { visible.insert(assets.object(at: index).localIdentifier) }
        }
        return visible
    }
    func metadata(identifier: String) -> AssetMetadata? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else { return nil }
        return AssetMetadata(identifier: asset.localIdentifier, creationDate: asset.creationDate, modificationDate: asset.modificationDate,
                             pixelWidth: asset.pixelWidth, pixelHeight: asset.pixelHeight,
                             coordinate: asset.location.map { .init(longitude: $0.coordinate.longitude, latitude: $0.coordinate.latitude) },
                             mediaSubtypes: asset.mediaSubtypes.rawValue, isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot))
    }
    func scan() throws -> [AssetMetadata] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: .image, options: options)
        var result: [AssetMetadata] = []
        result.reserveCapacity(assets.count)
        for index in 0..<assets.count {
            try Task.checkCancellation()
            let metadata = autoreleasepool {
                let asset = assets.object(at: index)
                let coordinate = asset.location.map { GeoCoordinate(longitude: $0.coordinate.longitude, latitude: $0.coordinate.latitude) }
                return AssetMetadata(identifier: asset.localIdentifier, creationDate: asset.creationDate,
                                     modificationDate: asset.modificationDate, pixelWidth: asset.pixelWidth, pixelHeight: asset.pixelHeight,
                                     coordinate: coordinate, mediaSubtypes: asset.mediaSubtypes.rawValue,
                                     isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot))
            }
            result.append(metadata)
        }
        return result
    }
}
