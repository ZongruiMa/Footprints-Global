import SwiftUI

struct ProvinceNoteView: View {
    @Environment(AppState.self) private var state
    @Environment(\.scenePhase) private var scenePhase
    let provinceID: String
    @State private var text = ""
    @State private var initialized = false
    @State private var saveTask: Task<Void, Never>?
    var body: some View {
        TextEditor(text: $text)
            .font(.body).scrollContentBackground(.hidden)
            .padding(.horizontal, 18)
            .overlay(alignment: .topLeading) {
                if text.isEmpty { Text(L("Write a memory…")).foregroundStyle(.tertiary).padding(.leading, 23).padding(.top, 8).allowsHitTesting(false) }
            }
            .accessibilityLabel(L("Place notes"))
            .onAppear {
                text = state.noteDrafts[provinceID] ?? state.snapshot.provinces[provinceID]?.note ?? ""
                initialized = true
            }
            .onChange(of: text) { _, value in
                guard initialized else { return }
                state.noteDrafts[provinceID] = value
                saveTask?.cancel()
                saveTask = Task {
                    do { try await Task.sleep(for: .milliseconds(650)) } catch { return }
                    await state.saveNote(provinceID, value)
                }
            }
            .onChange(of: scenePhase) { _, phase in if phase != .active { flush() } }
            .onDisappear { flush() }
    }
    private func flush() {
        saveTask?.cancel()
        guard initialized else { return }
        let value = text
        Task { await state.saveNote(provinceID, value) }
    }
}
