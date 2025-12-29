import Foundation

enum FileSafety {
    static func ensureDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    static func atomicWrite(_ data: Data, to url: URL) throws {
        try ensureDirectory(url.deletingLastPathComponent())
        let tmp = url.deletingLastPathComponent().appendingPathComponent(UUID().uuidString + ".tmp")
        try data.write(to: tmp, options: [.atomic])
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try FileManager.default.moveItem(at: tmp, to: url)
    }
}
