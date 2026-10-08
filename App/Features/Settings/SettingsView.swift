import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    @State private var picked: [PhotosPickerItem] = []
    private var busy: Bool { state.isSyncing || state.isImporting || state.isResetting || state.isRequestingPhotoAccess || state.pendingWrites > 0 }
    var body: some View {
        NavigationStack {
            Form {
                Section(L("Language")) {
                    Picker(L("Language"), selection: Binding(get: { state.language }, set: { state.setLanguage($0) })) {
                        Text(L("System language")).tag("system")
                        ForEach(Array(zip(AppLanguage.codes, AppLanguage.names)), id: \.0) { code, name in Text(name).tag(code) }
                    }
                }
                Section(L("Color")) {
                    Picker(L("Color"), selection: Binding(get: { state.theme.rawValue }, set: { value in Task { await state.change { try await $0.setTheme(value) } } })) {
                        ForEach(ThemeDefinition.allCases) { theme in Text(theme.name).tag(theme.rawValue) }
                    }
                }
                Section {
                    LabeledContent(L("Photo access"), value: state.access.title)
                    if state.access == .notDetermined {
                        Button(state.isRequestingPhotoAccess ? L("Waiting for permission…") : L("Allow photo library access")) {
                            Task { await state.requestPhotoAccess() }
                        }.disabled(busy)
                    }
                    Button(L("Open system settings")) { PhotoAuthorizationService.openSettings() }
                    if state.access == .limited {
                        Button(L("Manage selected photos")) { PhotoAuthorizationService.manageLimited() }
                    }
                    PhotosPicker(selection: $picked, maxSelectionCount: 200, matching: .images, preferredItemEncoding: .current, photoLibrary: .shared()) {
                        Label(L("Choose photos to classify"), systemImage: "wand.and.stars")
                    }.disabled(busy)
                    Text(L("Choose up to 200 photos. GPS stays on this device; iCloud originals may need a download.")).font(.footnote).foregroundStyle(.secondary)
                    if let summary = state.photoImportSummary { Text(summary).font(.footnote).textSelection(.enabled) }
                    Toggle(L("Scan on opening"), isOn: Binding(get: { state.snapshot.settings.automaticSync }, set: { value in
                        Task { await state.change { try await $0.setAutomaticSync(value) }; if value { await state.becameActive() } }
                    })).disabled(!state.access.canRead || busy)
                    Button(state.isSyncing ? L("Scanning…") : L("Scan photos")) { Task { await state.sync() } }.disabled(!state.access.canRead || busy)
                    Button(L("Rescan all photos")) { Task { await state.sync(force: true) } }.disabled(!state.access.canRead || busy)
                    if let last = state.snapshot.settings.lastPhotoScanDate {
                        Text(L("Last scan: {0}", last.formatted(.dateTime.locale(state.locale)))).font(.caption)
                    }
                    if let summary = state.photoScanSummary { Text(summary).font(.caption) }
                    NavigationLink { PendingPhotosView() } label: { LabeledContent(L("Unsorted photos"), value: "\(state.pendingPhotos.count)") }
                    DisclosureGroup(L("Diagnostics")) {
                        Text(L("Permission status: {0}", state.access.title))
                        Text(state.photoAuthorizationNote ?? PhotoAuthorizationService.diagnostic).textSelection(.enabled)
                        Text(L("Version {0} · Build {1}", Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?", Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"))
                    }.font(.caption)
                } header: { Text(L("Photos")) } footer: { Text(L("Automatic scanning needs photo access. Private Access only shares photos you choose.")) }
                Section {
                    NavigationLink(L("Visited places")) {
                        List(state.atlas.classificationPlaces.filter { state.mapVisitedIDs.contains($0.id) }.sorted { state.placeName($0) < state.placeName($1) }) { place in
                            NavigationLink(state.placeName(place)) { ProvinceSheet(province: place) }
                        }.navigationTitle(L("Visited places"))
                    }
                    NavigationLink(L("About Footprints")) { AboutView() }
                    NavigationLink(L("Map data and licenses")) { ThirdPartyNoticesView() }
                    Button(L("Delete local records"), role: .destructive) { confirmReset = true }.disabled(busy)
                }
            }.navigationTitle(L("Settings")).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L("Done")) { dismiss() } } }
                .onChange(of: picked) { _, items in
                    guard !items.isEmpty else { return }
                    Task { await state.importPhotosAutomatically(items); picked = [] }
                }
                .confirmationDialog(L("Reset Footprints?"), isPresented: $confirmReset, titleVisibility: .visible) {
                    Button(L("Delete local records"), role: .destructive) { Task { await state.reset() } }
                    Button(L("Cancel"), role: .cancel) {}
                } message: { Text(L("Notes, marks and imported copies will be deleted. System photos stay untouched.")) }
        }
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section { Text("Footprints").font(.title2); Text(L("Your world, one memory at a time.")) }
            Section(L("Offline and private")) {
                Text(L("No accounts, ads, analytics, or photo uploads."))
                Text(L("Uninstalling deletes local notes and imported copies."))
            }
            Section(L("Offline maps")) {
                Text("Natural Earth · Public domain\ngeoBoundaries · CC BY 4.0")
                Text(L("Borders are approximate. Missing GPS cannot be recovered; assign a place manually."))
            }
        }.navigationTitle(L("About"))
    }
}

struct ThirdPartyNoticesView: View {
    @State private var text = ""
    var body: some View {
        ScrollView { Text(text).font(.footnote).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(20) }
            .navigationTitle(L("Map data and licenses")).navigationBarTitleDisplayMode(.inline)
            .task {
                guard let url = Bundle.main.url(forResource: "THIRD_PARTY_NOTICES", withExtension: "md") else { return }
                text = (try? String(contentsOf: url, encoding: .utf8)) ?? "Natural Earth: Public domain. geoBoundaries: CC BY 4.0."
            }
    }
}
