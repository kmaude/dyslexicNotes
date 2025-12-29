import Foundation

struct NoteBundlePaths: Hashable {
    let folder: URL
    let baseStem: String

    var audioM4A: URL { folder.appendingPathComponent(baseStem + ".m4a") }
    var metaJSON: URL { folder.appendingPathComponent(baseStem + " - meta.json") }
    var transcriptJSON: URL { folder.appendingPathComponent(baseStem + " - transcript.json") }
    var transcriptTXT: URL { folder.appendingPathComponent(baseStem + " - transcript.txt") }
    var markersJSON: URL { folder.appendingPathComponent(baseStem + " - markers.json") }
    var notesMD: URL { folder.appendingPathComponent(baseStem + " - notes.md") }

    func cleanCopyRTF(index: Int) -> URL {
        folder.appendingPathComponent(baseStem + " - notes (Clean Copy \(index)).rtf")
    }

    func cleanCopyDOCX(index: Int) -> URL {
        folder.appendingPathComponent(baseStem + " - notes (Clean Copy \(index)).docx")
    }
}

final class FileStore {
    func createBundleFolder(className: String, createdAt: Date, title: String) throws -> NoteBundlePaths {
        let dateFolder = DateFormatters.isoLocalDate.string(from: createdAt)
        let folder = Paths.dateFolderURL(className: className, dateLocalYYYYMMDD: dateFolder)
        try FileSafety.ensureDirectory(folder)

        let hhmm = DateFormatters.hhmm.string(from: createdAt)
        let stem = "\(dateFolder) - \(hhmm) - \(Paths.safeFileStem(title))"
        return NoteBundlePaths(folder: folder, baseStem: stem)
    }

    /// Best-effort lookup by scanning `~/Documents/Notes/**` for a meta.json matching note_id.
    func locateBundle(noteID: String) -> NoteBundlePaths? {
        let base = Paths.notesBundlesBase
        guard let enumerator = FileManager.default.enumerator(
            at: base,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for case let url as URL in enumerator {
            guard url.lastPathComponent.hasSuffix(" - meta.json") else { continue }
            guard let data = try? Data(contentsOf: url),
                  let meta = try? JSONDecoder().decode(MetaJSON.self, from: data),
                  meta.noteID == noteID else { continue }

            let folder = url.deletingLastPathComponent()
            let name = url.lastPathComponent
            let stem = name.replacingOccurrences(of: " - meta.json", with: "")
            return NoteBundlePaths(folder: folder, baseStem: stem)
        }
        return nil
    }
}
