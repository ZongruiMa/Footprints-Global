import Photos
import UIKit
import OSLog

// A system callback may arrive after our UI timeout. Resume at most once;
// timing out only releases the UI and does not cancel the system request.
@MainActor final class PhotoAuthorizationWaiter {
    private var continuation: CheckedContinuation<PhotoAccess?, Never>?
    private var timeoutTask: Task<Void, Never>?

    func wait(timeout: Duration = .seconds(15), start: (@escaping @Sendable (PhotoAccess) -> Void) -> Void) async -> PhotoAccess? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            timeoutTask = Task {
                do { try await Task.sleep(for: timeout) } catch { return }
                finish(nil)
            }
            start { access in Task { @MainActor in self.finish(access) } }
        }
    }
    private func finish(_ access: PhotoAccess?) {
        guard let continuation else { return }
        self.continuation = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        continuation.resume(returning: access)
    }
}

@MainActor enum PhotoAuthorizationService {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Footprints", category: "PhotoAuthorization")
    private static var requestInFlight = false
    static private(set) var diagnostic = L("Not requested")
    static var current: PhotoAccess {
        map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }
    private static func map(_ status: PHAuthorizationStatus) -> PhotoAccess {
        switch status {
        case .authorized: .authorized
        case .limited: .limited
        case .denied: .denied
        case .restricted: .restricted
        case .notDetermined: .notDetermined
        @unknown default: .restricted
        }
    }
    static func request() async -> PhotoAccess {
        let before = current
        guard before == .notDetermined else {
            diagnostic = L("Permission status: {0}", before.title)
            return before
        }
        guard !requestInFlight else {
            diagnostic = L("Permission request did not finish. You can still choose photos to import.")
            return current
        }
        guard UIApplication.shared.applicationState == .active else {
            diagnostic = L("Permission request did not finish. You can still choose photos to import.")
            return current
        }
        requestInFlight = true
        logger.info("Requesting PhotoKit readWrite authorization")
        let result = await PhotoAuthorizationWaiter().wait { reply in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                Task { @MainActor in
                    requestInFlight = false
                    let access = map(status)
                    diagnostic = L("Permission status: {0}", access.title)
                    logger.info("PhotoKit callback status=\(status.rawValue)")
                    reply(access)
                }
            }
        }
        if result == nil {
            diagnostic = L("Permission request did not finish. You can still choose photos to import.")
            logger.notice("UI wait timed out; system request may still complete")
        }
        return current
    }
    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    static func manageLimited() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard var controller = scenes.flatMap(\.windows).first(where: \.isKeyWindow)?.rootViewController else { return }
        while let presented = controller.presentedViewController { controller = presented }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: controller)
    }
}
