import Foundation
import PhotosUI
import SwiftUI

extension AppState {
    var sortMode: PhotoSortMode { PhotoSortMode(rawValue: snapshot.settings.photoSortMode) ?? .newest }
    func photos(in provinceID: String) -> [PhotoSnapshot] {
        guard atlas.placesByID[provinceID]?.isCountry == true else { return photosByProvince[provinceID] ?? [] }
        let ids = Set((atlas.regionsByCountry[provinceID] ?? []).map(\.id)).union([provinceID])
        return sortMode.sorted(ids.flatMap { photosByProvince[$0] ?? [] })
    }
    func importPhotos(_ items: [PhotosPickerItem], to provinceID: String) async {
        guard !isImporting, !isResetting, !isSyncing, let store else { return }
        isImporting = true
        defer {
            isImporting = false
            Task { await becameActive() }
        }
        var failures = 0
        for item in items {
            do {
                if PhotoAuthorizationService.current.canRead, let id = item.itemIdentifier,
                   let metadata = await scanner.metadata(identifier: id) {
                    let old = try await store.addReference(metadata, to: provinceID)
                    if let old { try? await ImportedFileStore.shared.remove(name: old) }
                } else {
                    guard let picked = try await item.loadTransferable(type: PickedImageFile.self) else { failures += 1; continue }
                    let file = try await ImportedFileStore.shared.ingest(picked.url)
                    let old: String?
                    do {
                        old = try await store.addImported(file, identifier: item.itemIdentifier, to: provinceID)
                    } catch {
                        try? await ImportedFileStore.shared.remove(name: file.fileName)
                        throw error
                    }
                    if let old { try? await ImportedFileStore.shared.remove(name: old) }
                }
            } catch { failures += 1 }
        }
        do { try await refresh() } catch { message = L("Photo processing failed. Please retry.") }
        if failures > 0 { message = L("Photo processing failed. Please retry.") + " " + L("Download in Photos, then retry.") }
    }

    func importPhotosAutomatically(_ items: [PhotosPickerItem]) async {
        guard !isImporting, !isResetting, !isSyncing, let store else { return }
        guard !provinces.isEmpty else { photoImportSummary = L("Map unavailable"); return }
        isImporting = true
        defer { isImporting = false }
        var classified = 0
        var withoutLocation = 0
        var outsideMap = 0
        var failures = 0
        var lastFailure: String?
        let matcher = GeoMatcher(provinces: atlas.classificationPlaces)
        for (index, item) in items.enumerated() {
            photoImportSummary = L("Importing…") + " \(index + 1) / \(items.count)"
            var stage = L("Importing…")
            do {
                // A picker identifier does not grant PhotoKit access. Always load
                // the file representation explicitly shared through the picker.
                guard let picked = try await item.loadTransferable(type: PickedImageFile.self) else {
                    failures += 1
                    lastFailure = L("Photo unavailable")
                    continue
                }
                stage = L("Importing…")
                let file = try await ImportedFileStore.shared.ingest(picked.url)
                let result: (oldFile: String?, provinceID: String?)
                do {
                    stage = L("Importing…")
                    result = try await store.addAutomaticallyClassified(file, identifier: item.itemIdentifier, provinces: atlas.classificationPlaces, matcher: matcher)
                } catch {
                    try? await ImportedFileStore.shared.remove(name: file.fileName)
                    throw error
                }
                if let old = result.oldFile { try? await ImportedFileStore.shared.remove(name: old) }
                if result.provinceID != nil { classified += 1 }
                else if file.coordinate == nil { withoutLocation += 1 }
                else { outsideMap += 1 }
            } catch {
                failures += 1
                lastFailure = stage + ": " + error.localizedDescription
            }
        }
        do { try await refresh() }
        catch { photoImportSummary = L("Photo processing failed. Please retry."); return }
        var text = L("Saved: {0}/{1}. Grouped: {2}. Unsorted: {3}. Failed: {4}.", String(classified + withoutLocation + outsideMap), String(items.count), String(classified), String(withoutLocation + outsideMap), String(failures))
        if let lastFailure { text += "\n" + lastFailure }
        photoImportSummary = text
    }
    func removePhoto(_ id: String) async {
        guard !isResetting, let store else { return }
        pendingWrites += 1
        defer { pendingWrites -= 1 }
        do {
            let file = try await store.removePhoto(id)
            try await refresh()
            if let file { try await ImportedFileStore.shared.remove(name: file) }
        } catch { message = L("Could not save. Please retry.") + "\n" + error.localizedDescription }
    }
}
