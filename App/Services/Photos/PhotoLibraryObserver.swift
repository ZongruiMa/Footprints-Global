import Photos

final class PhotoLibraryObserver: NSObject, PHPhotoLibraryChangeObserver {
    private let changed: @Sendable () -> Void
    init(changed: @escaping @Sendable () -> Void) {
        self.changed = changed
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    func photoLibraryDidChange(_ changeInstance: PHChange) { changed() }
    deinit { PHPhotoLibrary.shared().unregisterChangeObserver(self) }
}
