import SwiftUI

struct ProvinceSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let province: ProvinceDefinition
    @State private var tab = 0
    @State private var info = ""
    private var manualVisited: Bool { state.snapshot.provinces[province.id]?.manualVisited ?? false }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(state.placeName(province)).font(.system(size: 22, weight: .medium))
                Spacer()
                if state.mapVisitedIDs.contains(province.id) {
                    Menu {
                        Button(manualVisited ? L("Remove manual mark") : L("Keep a manual mark")) {
                            let value = !manualVisited
                            Task { await state.setVisited(province.id, value) }
                        }
                        if !(state.photosByProvince[province.id] ?? []).isEmpty {
                            Text(L("Photos keep this place marked."))
                        }
                    } label: { Label(L("Visited"), systemImage: manualVisited ? "checkmark.circle.fill" : "checkmark.circle") }.font(.subheadline)
                } else {
                    Button(L("Mark as visited")) { Task { await state.setVisited(province.id, true) } }.font(.subheadline)
                }
            }.padding(.horizontal, 24).padding(.top, 28)
            if province.isCountry, !(state.atlas.regionsByCountry[province.id] ?? []).isEmpty {
                Button { state.selectMap(province.id); dismiss() } label: {
                    Label(L("Explore regions"), systemImage: "map")
                }.padding(.horizontal, 24)
            }
            HStack(spacing: 28) {
                ForEach(Array([L("Photos"), L("Notes"), L("About")].enumerated()), id: \.offset) { index, title in
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { tab = index }
                    } label: {
                        VStack(spacing: 10) {
                            Text(title).foregroundStyle(tab == index ? state.theme.primaryText : state.theme.secondaryText)
                            Rectangle().fill(tab == index ? state.theme.accent : .clear).frame(height: 1.5)
                        }.fixedSize(horizontal: true, vertical: false)
                    }.buttonStyle(.plain).accessibilityAddTraits(tab == index ? .isSelected : [])
                }
                Spacer()
            }.padding(.horizontal, 24)
            Group {
                if tab == 0 {
                    ProvincePhotosView(provinceID: province.id)
                } else if tab == 1 { ProvinceNoteView(provinceID: province.id) }
                else { VStack { Spacer(); Text(info).font(.subheadline).foregroundStyle(.secondary); Spacer() } }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task { info = await EmptyProvinceInfoProvider().text(for: province.id) }
    }
}
