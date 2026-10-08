import Photos
import SwiftUI

struct PhotoThumbnailView: View {
    @Environment(\.scenePhase) private var scenePhase
    let photo: PhotoSnapshot
    var fit = false
    var pixels: CGFloat = 400
    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?
    @State private var token = UUID()
    @State private var completed = false
    @State private var localTask: Task<Void, Never>?
    var body: some View {
        ZStack {
            #if DEBUG
            if photo.id.hasPrefix("preview:") {
                Rectangle().fill(Color(hex: 0xDDE7E8))
                Image(systemName: "mountain.2").font(.largeTitle).foregroundStyle(Color(hex: 0x93A9AB))
            }
            #endif
            if let image {
                Image(uiImage: image).resizable().aspectRatio(contentMode: fit ? .fit : .fill)
            } else if !photo.id.hasPrefix("preview:") {
                Rectangle().fill(fit ? Color.black : Color(hex: 0xECEFF1))
                VStack(spacing: 8) {
                    Image(systemName: completed ? "photo.badge.exclamationmark" : "photo")
                    if fit && completed {
                        Text(L("Photo unavailable") + "\n" + L("Download in Photos, then retry.")).font(.footnote).multilineTextAlignment(.center)
                        Button(L("Retry")) { cancel(); load() }.font(.footnote).tint(.white)
                    }
                }.foregroundStyle(.gray)
            }
        }
        .clipped()
        .onAppear { load() }
        .onChange(of: photo.fingerprint) { _, _ in cancel(); load() }
        .onChange(of: scenePhase) { _, phase in if phase == .active && image == nil { cancel(); load() } }
        .onDisappear { cancel(); image = nil }
        .accessibilityLabel(L("Photos"))
    }
    private func load() {
        #if DEBUG
        if photo.id.hasPrefix("preview:") { return }
        #endif
        completed = false
        token = UUID()
        let current = token
        if let file = photo.localFileName {
            localTask = Task {
                let data = await ImportedFileStore.shared.thumbnail(name: file, pixels: Int(pixels))
                guard !Task.isCancelled, token == current else { return }
                image = data.flatMap { UIImage(data: $0) }
                completed = true
            }
        } else if let id = photo.assetLocalIdentifier {
            requestID = PhotoLibraryService.shared.request(identifier: id, pixels: pixels, fit: fit) { value in
                guard token == current else { return }
                if let value { image = value }
                completed = true
            }
        } else { completed = true }
    }
    private func cancel() {
        localTask?.cancel()
        token = UUID()
        if let requestID { PhotoLibraryService.shared.cancel(requestID, fit: fit) }
        requestID = nil
    }
}
