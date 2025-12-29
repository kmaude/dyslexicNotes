import Foundation

enum Paths {
    static var notesBundlesBase: URL { .notesBundlesBase }
    static var appSupport: URL { .notesAppSupport }
    static var modelsFolder: URL { .notesModelsFolder }

    static func classFolderURL(className: String) -> URL {
        notesBundlesBase.appendingPathComponent(safeFolderName(className), isDirectory: true)
    }

    static func dateFolderURL(className: String, dateLocalYYYYMMDD: String) -> URL {
        classFolderURL(className: className).appendingPathComponent(dateLocalYYYYMMDD, isDirectory: true)
    }

    static func safeFolderName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return cleaned.isEmpty ? "Untitled" : cleaned
    }

    static func safeFileStem(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return cleaned.isEmpty ? "Untitled" : cleaned
    }
}
