import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var model: SettingsModel

    private let url: URL

    init(url: URL = .notesSettingsURL) {
        self.url = url
        self.model = DefaultSettings.model
        load()
    }

    func update(_ mutate: (inout SettingsModel) -> Void) {
        var m = model
        mutate(&m)
        model = m
        save()
    }

    func load() {
        do {
            try FileSafety.ensureDirectory(url.deletingLastPathComponent())
            guard FileManager.default.fileExists(atPath: url.path) else {
                save()
                return
            }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(SettingsModel.self, from: data)
            model = decoded
        } catch {
            // If settings are corrupted, fall back to defaults.
            model = DefaultSettings.model
            save()
        }
    }

    func save() {
        do {
            try FileSafety.ensureDirectory(url.deletingLastPathComponent())
            let data = try JSONEncoder().encode(model)
            try data.write(to: url, options: [.atomic])
        } catch {
            assertionFailure("Failed saving settings: \(error)")
        }
    }
}
