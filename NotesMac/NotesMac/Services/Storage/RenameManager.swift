import Foundation

enum RenameManager {
    /// Renames a note's bundle files by changing the filename stem, while keeping `note_id` stable.
    static func renameBundleFiles(bundle: NoteBundlePaths, newTitle: String) throws -> NoteBundlePaths {
        let oldStem = bundle.baseStem
        let parts = oldStem.split(separator: "-", maxSplits: 2, omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        // Expected: ["YYYY-MM-DD", "HHMM", "<Title>"]
        if parts.count < 2 { return bundle }
        let date = parts[0]
        let hhmm = parts[1]
        let newStem = "\(date) - \(hhmm) - \(Paths.safeFileStem(newTitle))"
        if newStem == oldStem { return bundle }

        let folder = bundle.folder
        let fm = FileManager.default

        func moveIfExists(_ fromName: String, to toName: String) throws {
            let from = folder.appendingPathComponent(fromName)
            let to = folder.appendingPathComponent(toName)
            if fm.fileExists(atPath: from.path) {
                if fm.fileExists(atPath: to.path) { try fm.removeItem(at: to) }
                try fm.moveItem(at: from, to: to)
            }
        }

        try moveIfExists(oldStem + ".m4a", to: newStem + ".m4a")
        try moveIfExists(oldStem + " - meta.json", to: newStem + " - meta.json")
        try moveIfExists(oldStem + " - transcript.json", to: newStem + " - transcript.json")
        try moveIfExists(oldStem + " - transcript.txt", to: newStem + " - transcript.txt")
        try moveIfExists(oldStem + " - markers.json", to: newStem + " - markers.json")
        try moveIfExists(oldStem + " - notes.md", to: newStem + " - notes.md")

        // Clean copies
        if let items = try? fm.contentsOfDirectory(atPath: folder.path) {
            for name in items where name.hasPrefix(oldStem + " - notes (Clean Copy ") {
                let suffix = name.replacingOccurrences(of: oldStem, with: "")
                try moveIfExists(name, to: newStem + suffix)
            }
        }

        return NoteBundlePaths(folder: folder, baseStem: newStem)
    }
}
