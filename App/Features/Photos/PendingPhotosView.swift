import SwiftUI

struct PendingPhotosView: View {
    @Environment(AppState.self) private var state
    @State private var selected = Set<String>()
    @State private var choosing = false
    var body: some View {
        GeometryReader { geometry in
            let edge = (geometry.size.width - 44) / 3
            if state.pendingPhotos.isEmpty {
                ContentUnavailableView(L("No unsorted photos"), systemImage: "photo.on.rectangle", description: Text(L("Photos without a matched location appear here.")))
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                        ForEach(state.pendingPhotos) { photo in
                            Button { if !selected.insert(photo.id).inserted { selected.remove(photo.id) } } label: {
                                PhotoThumbnailView(photo: photo).frame(width: edge, height: edge)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(alignment: .bottomTrailing) {
                                        Image(systemName: selected.contains(photo.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(.white, state.theme.accent).padding(8)
                                    }
                            }.buttonStyle(.plain).accessibilityLabel(selected.contains(photo.id) ? L("Deselect photo") : L("Select photo"))
                        }
                    }.padding(16)
                }
            }
        }
        .navigationTitle(L("Unsorted photos")).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) {
            Button(selected.count == state.pendingPhotos.count ? L("Deselect all") : L("Select all")) {
                selected = selected.count == state.pendingPhotos.count ? [] : Set(state.pendingPhotos.map(\.id))
            }.disabled(state.pendingPhotos.isEmpty)
        } }
        .safeAreaInset(edge: .bottom) {
            if !selected.isEmpty {
                Button(L("Assign {0} photos…", String(selected.count))) { choosing = true }
                    .buttonStyle(.borderedProminent).padding().frame(maxWidth: .infinity).background(.regularMaterial)
            }
        }
        .sheet(isPresented: $choosing) { ProvincePicker { id in
            let ids = selected
            Task { await state.assign(ids, to: id); selected.removeAll() }
        } }
        .onChange(of: state.pendingPhotos.map(\.id)) { _, ids in selected.formIntersection(ids) }
    }
}
