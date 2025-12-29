import Foundation
import GRDB

@MainActor
final class AppEnvironment: ObservableObject {
    let settingsStore: SettingsStore
    let dbManager: DatabaseManager
    let fileStore: FileStore
    let audioCapture: AudioCaptureService
    let audioInputs: AudioInputManager
    let warnings: AudioWarningsMonitor
    let transcription: TranscriptionService
    let models: WhisperModelManager
    let playback: PlaybackService
    let tapToSpeak: TapToSpeakCoordinator
    let explainSimply: ExplainSimplyEngine
    let exportService: ExportService

    init() {
        self.settingsStore = SettingsStore()
        self.dbManager = DatabaseManager()
        self.fileStore = FileStore()
        self.audioCapture = AudioCaptureService()
        self.audioInputs = AudioInputManager()
        self.warnings = AudioWarningsMonitor()
        self.models = WhisperModelManager()
        self.transcription = TranscriptionService()
        self.playback = PlaybackService()
        self.tapToSpeak = TapToSpeakCoordinator()
        self.explainSimply = ExplainSimplyEngine()
        self.exportService = ExportService()
    }

    func start() throws {
        try dbManager.start()
        try dbManager.seedIfNeeded(settings: settingsStore)
        audioInputs.refresh()
        models.start(settings: settingsStore)
    }
}
