import Photos
import UIKit

@MainActor final class PhotoLibraryService {
    static let shared = PhotoLibraryService()
    private let manager = PHCachingImageManager()
    private var assets: [PHImageRequestID: (PHAsset, CGSize, PHImageRequestOptions)] = [:]
    func request(identifier: String, pixels: CGFloat, fit: Bool, completion: @escaping @MainActor (UIImage?) -> Void) -> PHImageRequestID? {
        guard PhotoAuthorizationService.current.canRead,
              let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else {
            completion(nil)
            return nil
        }
        let size = CGSize(width: pixels, height: pixels)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        let mode: PHImageContentMode = fit ? .aspectFit : .aspectFill
        manager.startCachingImages(for: [asset], targetSize: size, contentMode: mode, options: options)
        let request = manager.requestImage(for: asset, targetSize: size, contentMode: mode, options: options) { image, _ in
            Task { @MainActor in completion(image) }
        }
        assets[request] = (asset, size, options)
        return request
    }
    func cancel(_ id: PHImageRequestID, fit: Bool) {
        manager.cancelImageRequest(id)
        if let (asset, size, options) = assets.removeValue(forKey: id) {
            manager.stopCachingImages(for: [asset], targetSize: size, contentMode: fit ? .aspectFit : .aspectFill, options: options)
        }
    }
    func clear() {
        for id in assets.keys { manager.cancelImageRequest(id) }
        assets.removeAll()
        manager.stopCachingImagesForAllAssets()
    }
}
