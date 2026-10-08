import SwiftUI

struct MapScreen: View {
    @Environment(AppState.self) private var state
    @State private var selected: ProvinceDefinition?
    @State private var showingSettings = false
    @State private var showingMaps = false
    @State private var showingPlaces = false
    @State private var pendingSelection: ProvinceDefinition?
    var body: some View {
        ZStack {
            state.theme.background.ignoresSafeArea()
            if state.mapFailed {
                ContentUnavailableView {
                    Label(L("Map unavailable"), systemImage: "map")
                } actions: { Button(L("Retry")) { Task { await state.loadMap() } } }
            } else if state.provinces.isEmpty { ProgressView() }
            else {
                ChinaMapView(provinces: state.provinces, visited: state.mapVisitedIDs, selectedID: selected?.id, theme: state.theme) { selected = $0 }
                    .environment(\.layoutDirection, .leftToRight)
                    .id(state.selectedMap).padding(.top, 76).padding(.bottom, 70)
            }
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 8) {
                Text("FOOTPRINTS").font(.caption).tracking(3).foregroundStyle(state.theme.secondaryText)
                Button { showingMaps = true } label: {
                    HStack { Text(state.mapTitle).font(.title2); Image(systemName: "chevron.down").font(.caption) }
                }.tint(state.theme.primaryText).accessibilityLabel(L("Maps"))
            }.padding(24)
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 2) {
            Text("\(state.provinces.filter { state.mapVisitedIDs.contains($0.id) }.count) / \(state.provinces.count)")
                .font(.caption).padding(.horizontal, 12).accessibilityLabel(L("Visited places"))
            Button { showingPlaces = true } label: {
                Image(systemName: "list.bullet").font(.system(size: 17)).frame(width: 44, height: 44)
            }.accessibilityLabel(L("Regions"))
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape").font(.system(size: 17)).frame(width: 44, height: 44)
                }.accessibilityLabel(L("Settings"))
            }.tint(state.theme.secondaryText).padding(16)
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingMaps) { MapPickerView() }
        .sheet(isPresented: $showingPlaces, onDismiss: { selected = pendingSelection; pendingSelection = nil }) {
            PlaceListView(places: state.provinces, title: state.mapTitle) { pendingSelection = $0 }
        }
        .sheet(item: $selected) { province in ProvinceSheet(province: province).presentationDetents([.fraction(0.88)]).presentationDragIndicator(.visible) }
        .fullScreenCover(isPresented: Binding(get: { !state.snapshot.settings.hasCompletedOnboarding }, set: { _ in })) { OnboardingView() }
    }
}
