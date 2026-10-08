import Foundation
import SwiftData

extension DataStore {
    func updateAvailability(_ visible: Set<String>, access: PhotoAccess) throws {
        var changed = false
        for record in try modelContext.fetch(FetchDescriptor<PhotoRecord>()) where record.source == "library" && !record.isRemoved {
            guard let id = record.assetLocalIdentifier else { continue }
            let status = PhotoSyncPolicy.availability(seen: visible.contains(id), access: access, previouslyMissing: record.isMissing)
            if record.isUnavailable != status.unavailable { record.isUnavailable = status.unavailable; changed = true }
            if record.isMissing != status.missing { record.isMissing = status.missing; changed = true }
        }
        if changed { try save() }
    }
    func reconcile(_ assets: [AssetMetadata], access: PhotoAccess, provinces: [ProvinceDefinition], force: Bool = false, scanStartedAt: Date = .distantFuture) throws {
        guard access.canRead else { return }
        let records = try modelContext.fetch(FetchDescriptor<PhotoRecord>())
        let byID = Dictionary(uniqueKeysWithValues: records.compactMap { record in record.assetLocalIdentifier.map { ($0, record) } })
        let seen = Set(assets.map(\.identifier))
        let matcher = GeoMatcher(provinces: provinces)
        let classifier = BasicPhotoClassifier()
        for metadata in assets {
            let record: PhotoRecord
            if let existing = byID[metadata.identifier] {
                // A selected local copy owns its metadata and remains independent
                // of later library permission changes or screenshot filtering.
                if existing.source == "imported" { continue }
                record = existing
            }
            else {
                record = PhotoRecord(id: "asset:" + metadata.identifier, assetLocalIdentifier: metadata.identifier)
                modelContext.insert(record)
            }
            if PhotoSyncPolicy.needsRematch(previous: record.fingerprint, incoming: metadata.fingerprint, force: force) || record.provinceID == nil {
                record.apply(metadata)
                if !record.isRemoved {
                    record.provinceID = classifier.shouldLocate(metadata) ? metadata.coordinate.flatMap { matcher.province(for: $0)?.id } : nil
                }
            }
            if record.isMissing { record.isMissing = false }
            if record.isUnavailable { record.isUnavailable = false }
        }
        for record in records where record.source == "library" && record.createdAt <= scanStartedAt {
            if let id = record.assetLocalIdentifier, !seen.contains(id) {
                let status = PhotoSyncPolicy.availability(seen: false, access: access, previouslyMissing: record.isMissing)
                if record.isUnavailable != status.unavailable { record.isUnavailable = status.unavailable }
                if record.isMissing != status.missing { record.isMissing = status.missing }
            }
        }
        try settings().lastPhotoScanDate = .now
        try save()
    }
    func setAccessUnavailable() throws {
        for record in try modelContext.fetch(FetchDescriptor<PhotoRecord>()) where record.source == "library" {
            if !record.isUnavailable { record.isUnavailable = true }
        }
        try save()
    }
    func assign(_ ids: Set<String>, to provinceID: String) throws {
        for record in try modelContext.fetch(FetchDescriptor<PhotoRecord>()) where ids.contains(record.id) {
            record.manualProvinceID = provinceID
            record.isRemoved = false
            record.updatedAt = .now
        }
        try save()
    }
    func addReference(_ metadata: AssetMetadata, to provinceID: String) throws -> String? {
        let id = "asset:" + metadata.identifier
        let record = try findPhoto(id) ?? PhotoRecord(id: id, assetLocalIdentifier: metadata.identifier)
        if record.modelContext == nil { modelContext.insert(record) }
        let oldFile = record.localFileName
        record.localFileName = nil
        record.source = "library"
        record.apply(metadata)
        record.manualProvinceID = provinceID
        record.isRemoved = false
        record.isMissing = false
        record.isUnavailable = false
        try save()
        return oldFile
    }

    func addAutomaticallyClassified(_ file: ImportedImage, identifier: String?, provinces: [ProvinceDefinition], matcher: GeoMatcher? = nil) throws -> (oldFile: String?, provinceID: String?) {
        let id = identifier.map { "asset:" + $0 } ?? "import:" + (file.contentHash ?? file.fileName)
        let record = try findPhoto(id) ?? PhotoRecord(id: id, assetLocalIdentifier: identifier)
        if record.modelContext == nil { modelContext.insert(record) }
        let oldFile = record.localFileName
        record.source = "imported"
        record.localFileName = file.fileName
        record.creationDate = file.date
        record.latitude = file.coordinate?.latitude
        record.longitude = file.coordinate?.longitude
        record.pixelWidth = file.width
        record.pixelHeight = file.height
        record.fingerprint = file.fileName
        record.provinceID = file.coordinate.flatMap { (matcher ?? GeoMatcher(provinces: provinces)).province(for: $0)?.id }
        // Explicitly selected files remain available without PhotoKit permission.
        // Preserve the user's manual assignment, including on repeated imports.
        record.isScreenshot = false
        record.isRemoved = false
        record.isMissing = false
        record.isUnavailable = false
        record.updatedAt = .now
        let effectiveProvinceID = record.effectiveProvinceID
        try save()
        return (oldFile, effectiveProvinceID)
    }
    func addImported(_ file: ImportedImage, identifier: String?, to provinceID: String) throws -> String? {
        let id = identifier.map { "asset:" + $0 } ?? "import:" + (file.contentHash ?? file.fileName)
        let record = try findPhoto(id) ?? PhotoRecord(id: id, assetLocalIdentifier: identifier)
        if record.modelContext == nil { modelContext.insert(record) }
        let oldFile = record.localFileName
        record.localFileName = file.fileName
        record.source = "imported"
        record.pixelWidth = file.width
        record.pixelHeight = file.height
        record.creationDate = file.date
        record.latitude = file.coordinate?.latitude
        record.longitude = file.coordinate?.longitude
        record.fingerprint = file.fileName
        record.manualProvinceID = provinceID
        record.isRemoved = false
        record.isMissing = false
        record.isUnavailable = false
        try save()
        return oldFile
    }
    func removePhoto(_ id: String) throws -> String? {
        guard let record = try findPhoto(id) else { return nil }
        let file = record.localFileName
        record.isRemoved = true
        record.localFileName = nil
        record.updatedAt = .now
        try save()
        return file
    }
    func setSort(_ mode: String) throws {
        try settings().photoSortMode = mode
        try save()
    }
    func movePhoto(_ id: String, front: Bool) throws {
        guard let photo = try findPhoto(id), let province = photo.effectiveProvinceID else { return }
        let records = try modelContext.fetch(FetchDescriptor<PhotoRecord>()).filter { !$0.isRemoved && $0.effectiveProvinceID == province }
        let mode = PhotoSortMode(rawValue: try settings().photoSortMode) ?? .newest
        var ids = mode.sorted(records.map(PhotoSnapshot.init)).map(\.id).filter { $0 != id }
        if front { ids.insert(id, at: 0) } else { ids.append(id) }
        let indices = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($0.element, Double($0.offset)) })
        for record in records { record.manualSortIndex = indices[record.id] ?? 0 }
        try settings().photoSortMode = PhotoSortMode.manual.rawValue
        try save()
    }
    private func findPhoto(_ id: String) throws -> PhotoRecord? {
        try modelContext.fetch(FetchDescriptor<PhotoRecord>(predicate: #Predicate { $0.id == id })).first
    }
}
