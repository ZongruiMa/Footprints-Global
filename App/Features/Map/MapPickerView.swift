import SwiftUI

struct MapPickerView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    private var countries: [ProvinceDefinition] {
        state.atlas.countries.filter { search.isEmpty || state.placeName($0).localizedStandardContains(search) || $0.name.localizedStandardContains(search) }
            .sorted { state.placeName($0).localizedStandardCompare(state.placeName($1)) == .orderedAscending }
    }
    var body: some View {
        NavigationStack {
            List {
                Button { state.selectMap("world"); dismiss() } label: { Label(L("World"), systemImage: "globe") }
                Section(L("Countries and territories")) {
                    ForEach(countries) { country in
                        Button { state.selectMap(country.id); dismiss() } label: {
                            HStack { Text(state.placeName(country)); Spacer(); if state.selectedMap == country.id { Image(systemName: "checkmark") } }
                        }.foregroundStyle(.primary)
                    }
                }
            }.searchable(text: $search, prompt: L("Search places"))
                .navigationTitle(L("Maps"))
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L("Done")) { dismiss() } } }
        }
    }
}

struct PlaceListView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    let places: [ProvinceDefinition]
    let title: String
    let select: (ProvinceDefinition) -> Void
    private var filtered: [ProvinceDefinition] {
        places.filter { search.isEmpty || state.placeName($0).localizedStandardContains(search) || $0.name.localizedStandardContains(search) }
            .sorted { state.placeName($0).localizedStandardCompare(state.placeName($1)) == .orderedAscending }
    }
    var body: some View {
        NavigationStack {
            List(filtered) { place in
                Button { select(place); dismiss() } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(state.placeName(place))
                            if !place.isCountry, let countryID = place.countryID, let country = state.atlas.placesByID[countryID] {
                                Text(state.placeName(country)).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if state.mapVisitedIDs.contains(place.id) { Image(systemName: "checkmark.circle").foregroundStyle(state.theme.accent) }
                    }
                }.foregroundStyle(.primary)
            }.searchable(text: $search, prompt: L("Search places"))
                .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L("Cancel")) { dismiss() } } }
        }
    }
}
