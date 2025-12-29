import Foundation

@MainActor
final class WhisperModelManager: ObservableObject {
    enum Model: String, CaseIterable, Identifiable {
        case small
        case medium

        var id: String { rawValue }

        var filename: String {
            switch self {
            case .small: return "ggml-small.bin"
            case .medium: return "ggml-medium.bin"
            }
        }

        var downloadURL: URL {
            // whisper.cpp canonical model hosting (works when online at home)
            switch self {
            case .small:
                return URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin")!
            case .medium:
                return URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin")!
            }
        }
    }

    struct Status: Hashable {
        var installed: Set<Model>
        var downloading: Model?
        var progress: Double
        var lastError: String?
    }

    @Published private(set) var status = Status(installed: [], downloading: nil, progress: 0, lastError: nil)

    private var settings: SettingsStore?

    func start(settings: SettingsStore) {
        self.settings = settings
        refreshInstalled()
    }

    func refreshInstalled() {
        let folder = URL.notesModelsFolder
        try? FileSafety.ensureDirectory(folder)
        let files = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        var installed: Set<Model> = []
        for m in Model.allCases where files.contains(m.filename) {
            installed.insert(m)
        }
        status.installed = installed
    }

    func localURL(for model: Model) -> URL {
        URL.notesModelsFolder.appendingPathComponent(model.filename)
    }

    func download(model: Model) async {
        guard settings?.model.schoolModeEnabled != true else {
            status.lastError = "School Mode is ON. Downloads are blocked."
            return
        }
        if status.downloading != nil { return }

        status.downloading = model
        status.progress = 0
        status.lastError = nil

        let tmp = URL.notesModelsFolder.appendingPathComponent(model.filename + ".download")
        let out = localURL(for: model)
        try? FileManager.default.removeItem(at: tmp)

        do {
            let (data, _) = try await URLSession.shared.data(from: model.downloadURL)
            try FileSafety.atomicWrite(data, to: tmp)
            if FileManager.default.fileExists(atPath: out.path) { try FileManager.default.removeItem(at: out) }
            try FileManager.default.moveItem(at: tmp, to: out)
            refreshInstalled()
        } catch {
            status.lastError = "Download failed: \(error)"
        }

        status.downloading = nil
        status.progress = 0
    }

    func delete(model: Model) {
        let url = localURL(for: model)
        try? FileManager.default.removeItem(at: url)
        refreshInstalled()
    }
}
