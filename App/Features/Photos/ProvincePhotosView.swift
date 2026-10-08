import SwiftUI
import PhotosUI

struct ProvincePhotosView: View {
    @Environment(AppState.self) private var state
    let provinceID: String
    @State private var picked: [PhotosPickerItem] = []
    @State private var viewing: PhotoSnapshot?
    private var photos: [PhotoSnapshot] { state.photos(in: provinceID) }
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Menu {
                    ForEach(PhotoSortMode.allCases) { mode in
                        Button(mode.title) { Task { await state.change { try await $0.setSort(mode.rawValue) } } }
                    }
                } label: { Label(state.sortMode.title, systemImage: "arrow.up.arrow.down").font(.caption) }
                Spacer()
                if state.isImporting { ProgressView().controlSize(.small) }
                PhotosPicker(selection: $picked, maxSelectionCount: 50, matching: .images, photoLibrary: .shared()) {
                    Image(systemName: "plus").frame(width: 44, height: 32)
                }.disabled(state.isImporting || state.isResetting).accessibilityLabel(L("Add photos"))
            }.padding(.horizontal, 24)
        if photos.isEmpty {
            ContentUnavailableView(L("No photos yet"), systemImage: "photo", description: Text(L("Tap + to add photos.")))
        } else {
            GeometryReader { geometry in
                let edge = (geometry.size.width - 48 - 12) / 3
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                        ForEach(photos) { photo in
                            Button { viewing = photo } label: {
                                PhotoThumbnailView(photo: photo).frame(width: edge, height: edge).clipShape(RoundedRectangle(cornerRadius: 8))
                            }.buttonStyle(.plain)
                            .contextMenu {
                                Button(L("Move to start")) { Task { await state.change { try await $0.movePhoto(photo.id, front: true) } } }
                                Button(L("Move to end")) { Task { await state.change { try await $0.movePhoto(photo.id, front: false) } } }
                                Button(L("Remove from Footprints"), role: .destructive) { Task { await state.removePhoto(photo.id) } }
                            }
                        }
                    }.padding(.horizontal, 24)
                }
            }
        }
        }
        .onChange(of: picked) { _, items in
            guard !items.isEmpty else { return }
            Task { await state.importPhotos(items, to: provinceID); picked = [] }
        }
        .fullScreenCover(item: $viewing) { photo in PhotoViewer(provinceID: provinceID, initialID: photo.id) }
    }
}
