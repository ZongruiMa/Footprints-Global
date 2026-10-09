import SwiftUI

struct ProvincePicker: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let select: (String) -> Void
    var body: some View {
        PlaceListView(places: state.atlas.classificationPlaces, title: L("Assign to…")) { select($0.id) }.appLocalization()
    }
}
