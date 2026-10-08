import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var state
    @State private var entering = false
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "map").font(.system(size: 36, weight: .ultraLight)).foregroundStyle(state.theme.accent)
            Text(L("Your world, one memory at a time.")).font(.system(size: 26, weight: .regular)).multilineTextAlignment(.center)
            Text(L("Choose a map, mark places, and keep notes. Photos are optional.")).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(5)
            Spacer()
            Button {
                entering = true
                Task { await state.completeOnboarding(); entering = false }
            } label: {
                HStack {
                    if entering { ProgressView().tint(.white) }
                    Text(entering ? L("Opening…") : L("Explore the map"))
                }
            }.buttonStyle(.borderedProminent).controlSize(.large).disabled(entering)
            Spacer().frame(height: 30)
        }.padding(36).interactiveDismissDisabled()
    }
}
