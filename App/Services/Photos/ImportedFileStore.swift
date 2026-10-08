import Foundation
import CoreTransferable
import ImageIO
import UniformTypeIdentifiers
import CryptoKit

struct PickedImageFile: Transferable, Sendable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("PhotoTransfers", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let destination = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(received.file.pathExtension)
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedImageFile(url: destination)
        }
    }
}
struct ImportedImage: Sendable {
    let fileName: String
    let width: Int
    let height: Int
    let date: Date?
    var coordinate: GeoCoordinate? = nil
    var contentHash: String? = nil
}

enum ImageLocationMetadata {
    static func coordinate(in properties: [CFString: Any]) -> GeoCoordinate? {
        guard let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              let latitude = gps[kCGImagePropertyGPSLatitude] as? NSNumber,
              let longitude = gps[kCGImagePropertyGPSLongitude] as? NSNumber,
              let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
              let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String,
              ["N", "S"].contains(latRef.uppercased()), ["E", "W"].contains(lonRef.uppercased()),
              (0...90).contains(latitude.doubleValue), (0...180).contains(longitude.doubleValue) else { return nil }
        let point = GeoCoordinate(longitude: longitude.doubleValue * (lonRef.uppercased() == "W" ? -1 : 1),
                                  latitude: latitude.doubleValue * (latRef.uppercased() == "S" ? -1 : 1))
        return point.isValid ? point : nil
    }
}
enum LocalPaths {
    static func directory(_ name: String) throws -> URL {
        let root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var url = root.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
        return url
    }
}
actor ImportedFileStore {
    static let shared = ImportedFileStore()
    enum Failure: Error { case invalidImage, unsafeName }
    private func url(_ name: String) throws -> URL {
        guard name == (name as NSString).lastPathComponent, !name.isEmpty else { throw Failure.unsafeName }
        return try LocalPaths.directory("Imports").appendingPathComponent(name)
    }
    func ingest(_ staged: URL) throws -> ImportedImage {
        defer { try? FileManager.default.removeItem(at: staged) }
        guard let source = CGImageSourceCreateWithURL(staged as CFURL, nil), CGImageSourceGetCount(source) > 0,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { throw Failure.invalidImage }
        let width = (properties[kCGImagePropertyPixelWidth] as? Int) ?? 0
        let height = (properties[kCGImagePropertyPixelHeight] as? Int) ?? 0
        guard width > 0, height > 0 else { throw Failure.invalidImage }
        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        let date = (exif?[kCGImagePropertyExifDateTimeOriginal] as? String).flatMap { formatter.date(from: $0) }
        let name = UUID().uuidString + "." + (staged.pathExtension.isEmpty ? "image" : staged.pathExtension)
        let destination = try url(name)
        do {
            try FileManager.default.copyItem(at: staged, to: destination)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: destination.path)
        } catch {
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
        // Stream the digest so a large selected photo does not need another full-size allocation.
        var digest = SHA256()
        do {
            let handle = try FileHandle(forReadingFrom: destination)
            defer { try? handle.close() }
            while let chunk = try handle.read(upToCount: 1_048_576), !chunk.isEmpty { digest.update(data: chunk) }
        } catch {
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
        return ImportedImage(fileName: name, width: width, height: height, date: date,
                             coordinate: ImageLocationMetadata.coordinate(in: properties),
                             contentHash: digest.finalize().map { String(format: "%02x", $0) }.joined())
    }
    func thumbnail(name: String, pixels: Int) -> Data? {
        guard let file = try? url(name), let source = CGImageSourceCreateWithURL(file as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: pixels,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.88] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
    func remove(name: String) throws {
        let file = try url(name)
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
    }
    func clear() throws {
        let directory = try LocalPaths.directory("Imports")
        for file in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            try FileManager.default.removeItem(at: file)
        }
    }
}
