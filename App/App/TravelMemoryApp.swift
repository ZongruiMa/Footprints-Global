import SwiftUI

@main
@MainActor
struct TravelMemoryApp: App {
    @State private var state = AppState()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            Group {
                if state.isLoading { ProgressView().tint(.gray) }
                else if let error = state.startupError {
                    ContentUnavailableView {
                        Label(L("Could not open local records."), systemImage: "externaldrive")
                    } description: { Text(error) } actions: {
                        Button(L("Retry")) { Task { await state.start() } }
                    }
                } else { MapScreen() }
            }
            .id(state.language)
            .environment(state)
            .environment(\.locale, state.locale)
            .environment(\.layoutDirection, AppLanguage.current == "ar" ? .rightToLeft : .leftToRight)
            .preferredColorScheme(.light)
            .tint(state.theme.accent)
            .task { await state.start() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active && !state.isLoading { Task { await state.becameActive() } }
            }
            .alert(L("Notice"), isPresented: Binding(get: { state.message != nil }, set: { if !$0 { state.message = nil } })) {
                Button(L("OK")) { state.message = nil }
            } message: { Text(state.message ?? "") }
        }
    }
}

extension View {
    /// Presentation roots may otherwise adopt the device's layout direction.
    func appLocalization() -> some View {
        environment(\.locale, Locale(identifier: AppLanguage.current))
            .environment(\.layoutDirection, AppLanguage.current == "ar" ? .rightToLeft : .leftToRight)
    }
}
