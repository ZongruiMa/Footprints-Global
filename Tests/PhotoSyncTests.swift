import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import TravelCore
#else
@testable import TravelMemory
#endif

struct PhotoSyncTests {
    @Test func incrementalAndForcedScan() {
        #expect(!PhotoSyncPolicy.needsRematch(previous: "same", incoming: "same", force: false))
        #expect(PhotoSyncPolicy.needsRematch(previous: nil, incoming: "old-date-new-id", force: false))
        #expect(PhotoSyncPolicy.needsRematch(previous: "same", incoming: "same", force: true))
        #expect(PhotoSyncPolicy.needsRematch(previous: "old", incoming: "edited", force: false))
    }
    @Test func limitedIsNotDeletionAndRegrantRestores() {
        let limited = PhotoSyncPolicy.availability(seen: false, access: .limited, previouslyMissing: false)
        #expect(!limited.missing && limited.unavailable)
        #expect(PhotoSyncPolicy.availability(seen: false, access: .authorized, previouslyMissing: false).missing)
        let restored = PhotoSyncPolicy.availability(seen: true, access: .limited, previouslyMissing: true)
        #expect(!restored.missing && !restored.unavailable)
    }
    @Test func manualClassificationAndVisitedArePreserved() {
        #expect(PhotoSyncPolicy.effectiveProvince(manual: "320000", automatic: "510000") == "320000")
        #expect(PhotoSyncPolicy.isVisited(manual: false, validPhotoCount: 1))
        #expect(PhotoSyncPolicy.isVisited(manual: true, validPhotoCount: 0))
        #expect(!PhotoSyncPolicy.isVisited(manual: false, validPhotoCount: 0))
    }
    @Test func screenshotsAndMissingGPS() {
        let classifier = BasicPhotoClassifier()
        let screenshot = AssetMetadata(identifier: "x", creationDate: nil, modificationDate: nil, pixelWidth: 100, pixelHeight: 100, coordinate: .init(longitude: 116, latitude: 40), mediaSubtypes: 0, isScreenshot: true)
        #expect(!classifier.shouldLocate(screenshot))
        let noGPS = AssetMetadata(identifier: "y", creationDate: nil, modificationDate: nil, pixelWidth: 100, pixelHeight: 100, coordinate: nil, mediaSubtypes: 0, isScreenshot: false)
        #expect(!classifier.shouldLocate(noGPS))
    }
}
