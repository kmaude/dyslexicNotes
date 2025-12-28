from __future__ import annotations

import json
import textwrap
from pathlib import Path


ROOT = Path("/workspace/NotesMac")
APP = ROOT / "NotesMac"
TESTS = ROOT / "NotesMacTests"


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def main() -> None:
    # ---------------------------
    # README
    # ---------------------------
    write(
        ROOT / "README.md",
        textwrap.dedent(
            """
            ## Notes (NotesMac)

            Personal, offline-first macOS (13+) SwiftUI app for dyslexic high school students.

            ### Setup
            - Open `NotesMac.xcodeproj` in Xcode (macOS 13+).
            - Build + Run on Apple Silicon.
            - On first launch, the app creates:
              - **Note bundles base**: `~/Documents/Notes/`
              - **App Support**: `~/Library/Application Support/Notes/`
                - `settings.json`
                - `notes.sqlite`
                - `Models/` (whisper.cpp models)

            ### Model download (Whisper)
            - Go to **Settings → Models**.
            - Download **Small** or **Medium**.
            - Downloads are **blocked when School Mode is ON**.
            - Models are stored in `~/Library/Application Support/Notes/Models/`.

            ### School Mode
            - **School Mode ON** disables all networking and blocks model downloads/updates.
            - Toggle from **Dashboard top bar** or **Settings → Privacy**.

            ### Folder structure (per note bundle)
            Notes are stored under:
            - `~/Documents/Notes/<Class Name>/<YYYY-MM-DD>/`

            Files (per note):
            - Audio: `YYYY-MM-DD - HHMM - <Title>.m4a`
            - Metadata/content:
              - `... - meta.json`
              - `... - transcript.json`
              - `... - transcript.txt`
              - `... - markers.json`
              - `... - notes.md`
              - `... - notes (Clean Copy N).rtf`
              - `... - notes (Clean Copy N).docx`

            ### Hotkeys (global)
            Planned mapping (implemented in later milestones):
            - Cmd+Shift+R: show/launch recording bar + start flow
            - Cmd+Shift+S: stop
            - Cmd+Shift+Space: pause/resume
            - Cmd+Shift+M: mute toggle
            - Cmd+Shift+1: add ⭐ marker
            - Cmd+Shift+2: add ❓ marker
            - Cmd+Shift+L: collapse/expand recording bar
            - Cmd+Shift+D: open Dashboard
            - Cmd+Shift+O: open most recent note

            ### Milestones
            - **M1**: App shell, settings store, GRDB schema + migrations, seed classes + one sample note, Dashboard UI, Recording Bar overlay (simulated timer).
            - **M2**: Real audio capture to `.m4a`, mute/pause/stop, segments + markers, `meta.json`.
            - **M3**: whisper.cpp integration + model downloads, chunk transcription + refine pass, transcript files + FTS.
            - **M4**: Playback + synced sentence highlighting + speed control + replay loop.
            - **M5**: Organizer Option A generates `notes.md`.
            - **M6**: Dyslexia supports 1–7 wired into Note Detail.
            - **M7**: Clean copies + RTF/DOCX export + rename flow (keep `note_id` stable).
            """
        ).lstrip(),
    )

    # ---------------------------
    # Info.plist
    # ---------------------------
    write(
        APP / "Resources" / "Info.plist",
        textwrap.dedent(
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
              <key>CFBundleDevelopmentRegion</key>
              <string>en</string>
              <key>CFBundleExecutable</key>
              <string>$(EXECUTABLE_NAME)</string>
              <key>CFBundleIdentifier</key>
              <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
              <key>CFBundleInfoDictionaryVersion</key>
              <string>6.0</string>
              <key>CFBundleName</key>
              <string>$(PRODUCT_NAME)</string>
              <key>CFBundlePackageType</key>
              <string>APPL</string>
              <key>CFBundleShortVersionString</key>
              <string>1.0</string>
              <key>CFBundleVersion</key>
              <string>1</string>
              <key>LSMinimumSystemVersion</key>
              <string>13.0</string>
              <key>NSMicrophoneUsageDescription</key>
              <string>Notes records class audio to create transcripts and organized notes.</string>
            </dict>
            </plist>
            """
        ).lstrip(),
    )

    # ---------------------------
    # Seed data (optional JSON artifacts; app seeds via code)
    # ---------------------------
    write(
        APP / "Resources" / "Seed" / "seed_classes.json",
        json.dumps(
            {
                "classes": [
                    {
                        "name": "Misc Notes",
                        "color_hex": "#9B9B9B",
                        "is_system": 1,
                        "language_mode": "EN_ONLY",
                        "special_language": None,
                    },
                    {
                        "name": "Biology",
                        "color_hex": "#4A90E2",
                        "is_system": 0,
                        "language_mode": "EN_ONLY",
                        "special_language": None,
                    },
                    {
                        "name": "History",
                        "color_hex": "#F5A623",
                        "is_system": 0,
                        "language_mode": "EN_ONLY",
                        "special_language": None,
                    },
                ]
            },
            indent=2,
        ),
    )

    # ---------------------------
    # Swift sources (M1 real implementations + stubs)
    # ---------------------------
    swift_files: dict[str, str] = {}

    # App
    swift_files["App/Constants.swift"] = textwrap.dedent(
        """
        import Foundation

        enum Constants {
            static let appName = "Notes"
            static let bundleBaseFolderName = "Notes"
            static let appSupportFolderName = "Notes"

            static let defaultChunkSeconds: Int = 10
            static let autosplitMinutes: Int = 50
            static let markerPreSeconds: Double = 10
            static let markerPostSeconds: Double = 15

            static let lowDiskWarningThresholdBytes: Int64 = 2 * 1024 * 1024 * 1024
            static let lowBatteryWarningThresholdPercent: Int = 20

            static let defaultHighlightHex = "#CDE9FF"

            static let classColorPaletteHex: [String] = [
                "#4A90E2","#50E3C2","#7ED321","#F5A623","#BD10E0","#9013FE","#D0021B","#F8E71C",
                "#8B572A","#417505","#B8E986","#9B9B9B","#4A4A4A","#00AEEF","#FF6F61","#6B7C93"
            ]
        }
        """
    ).lstrip()

    swift_files["App/AppEnvironment.swift"] = textwrap.dedent(
        """
        import Foundation
        import GRDB

        @MainActor
        final class AppEnvironment: ObservableObject {
            let settingsStore: SettingsStore
            let dbManager: DatabaseManager

            init() {
                self.settingsStore = SettingsStore()
                self.dbManager = DatabaseManager()
            }

            func start() throws {
                try dbManager.start()
                try dbManager.seedIfNeeded(settings: settingsStore)
            }
        }
        """
    ).lstrip()

    swift_files["App/AppRouter.swift"] = textwrap.dedent(
        """
        import SwiftUI

        enum AppRoute: Hashable {
            case dashboard
            case noteDetail(noteID: String)
            case settings
        }

        @MainActor
        final class AppRouter: ObservableObject {
            @Published var route: AppRoute = .dashboard

            func openDashboard() { route = .dashboard }
            func openSettings() { route = .settings }
            func openNote(noteID: String) { route = .noteDetail(noteID: noteID) }
        }

        struct AppRouterView: View {
            @EnvironmentObject private var env: AppEnvironment
            @StateObject private var router = AppRouter()

            var body: some View {
                NavigationStack {
                    content
                }
                .environmentObject(router)
            }

            @ViewBuilder
            private var content: some View {
                switch router.route {
                case .dashboard:
                    DashboardView()
                case .settings:
                    SettingsView()
                case .noteDetail(let noteID):
                    NoteDetailView(noteID: noteID)
                }
            }
        }
        """
    ).lstrip()

    swift_files["App/NotesApp.swift"] = textwrap.dedent(
        """
        import SwiftUI

        @main
        struct NotesApp: App {
            @StateObject private var env = AppEnvironment()

            var body: some Scene {
                WindowGroup {
                    AppRouterView()
                        .environmentObject(env)
                        .task {
                            do {
                                try env.start()
                            } catch {
                                // Minimal crash-avoidance for M1; production app would show a blocking error UI.
                                assertionFailure("Failed to start app: \\(error)")
                            }
                        }
                }
                Settings {
                    SettingsView()
                        .environmentObject(env)
                }
            }
        }
        """
    ).lstrip()

    # Utilities
    swift_files["Utilities/DateFormatters.swift"] = textwrap.dedent(
        """
        import Foundation

        enum DateFormatters {
            static let isoLocalDate: DateFormatter = {
                let f = DateFormatter()
                f.locale = Locale(identifier: "en_US_POSIX")
                f.timeZone = TimeZone.current
                f.dateFormat = "yyyy-MM-dd"
                return f
            }()

            static let isoLocalDateTime: DateFormatter = {
                let f = DateFormatter()
                f.locale = Locale(identifier: "en_US_POSIX")
                f.timeZone = TimeZone.current
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return f
            }()

            static let hhmm: DateFormatter = {
                let f = DateFormatter()
                f.locale = Locale(identifier: "en_US_POSIX")
                f.timeZone = TimeZone.current
                f.dateFormat = "HHmm"
                return f
            }()
        }
        """
    ).lstrip()

    swift_files["Utilities/TimeFormatting.swift"] = textwrap.dedent(
        """
        import Foundation

        enum TimeFormatting {
            static func mmss(_ seconds: TimeInterval) -> String {
                let s = max(0, Int(seconds.rounded(.down)))
                return String(format: "%02d:%02d", s / 60, s % 60)
            }
        }
        """
    ).lstrip()

    swift_files["Utilities/FileSafety.swift"] = textwrap.dedent(
        """
        import Foundation

        enum FileSafety {
            static func ensureDirectory(_ url: URL) throws {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            }
        }
        """
    ).lstrip()

    swift_files["Utilities/Extensions/Color+Hex.swift"] = textwrap.dedent(
        """
        import SwiftUI

        extension Color {
            init?(hex: String) {
                var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                if s.hasPrefix("#") { s.removeFirst() }
                guard s.count == 6, let v = Int(s, radix: 16) else { return nil }
                let r = Double((v >> 16) & 0xFF) / 255.0
                let g = Double((v >> 8) & 0xFF) / 255.0
                let b = Double(v & 0xFF) / 255.0
                self = Color(red: r, green: g, blue: b)
            }
        }
        """
    ).lstrip()

    swift_files["Utilities/Extensions/URL+NotesPaths.swift"] = textwrap.dedent(
        """
        import Foundation

        extension URL {
            static var notesAppSupport: URL {
                let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                return base.appendingPathComponent(Constants.appSupportFolderName, isDirectory: true)
            }

            static var notesDatabaseURL: URL {
                notesAppSupport.appendingPathComponent("notes.sqlite")
            }

            static var notesSettingsURL: URL {
                notesAppSupport.appendingPathComponent("settings.json")
            }

            static var notesModelsFolder: URL {
                notesAppSupport.appendingPathComponent("Models", isDirectory: true)
            }

            static var notesBundlesBase: URL {
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                return docs.appendingPathComponent(Constants.bundleBaseFolderName, isDirectory: true)
            }
        }
        """
    ).lstrip()

    # Domain enums + models (Enums included in build; other models exist but are not necessarily referenced in pbxproj in M1)
    swift_files["Domain/Models/Enums.swift"] = textwrap.dedent(
        """
        import Foundation

        enum LanguageMode: String, Codable, CaseIterable {
            case enOnly = "EN_ONLY"
            case specialOnly = "SPECIAL_ONLY"
            case enPlusSpecial = "EN_PLUS_SPECIAL"
        }

        enum NoiseMode: String, Codable, CaseIterable {
            case normal = "NORMAL"
            case classroom = "CLASSROOM"
        }

        enum MarkerType: String, Codable, CaseIterable {
            case star = "STAR"
            case question = "QUESTION"
        }

        enum DyslexiaSpacingPreset: String, Codable, CaseIterable {
            case normal
            case relaxed
            case extra
        }

        enum WordChunkMode: String, Codable, CaseIterable {
            case off
            case softChunking
            case syllableHinting
        }
        """
    ).lstrip()

    # Settings model
    swift_files["Domain/Models/SettingsModel.swift"] = textwrap.dedent(
        """
        import Foundation

        struct SettingsModel: Codable, Equatable {
            var schoolModeEnabled: Bool

            // Recording Bar
            var lastClassID: String?
            var recordingBarWindowOriginX: Double?
            var recordingBarWindowOriginY: Double?

            // Reading
            var fontName: String?
            var spacingPreset: DyslexiaSpacingPreset
            var highlightHex: String
            var readingRulerEnabled: Bool
            var readingRulerLines: Int
            var readingRulerOpacity: Double
            var wordChunkMode: WordChunkMode

            // Capture
            var chunkSeconds: Int

            static func `default`() -> SettingsModel {
                SettingsModel(
                    schoolModeEnabled: false,
                    lastClassID: nil,
                    recordingBarWindowOriginX: nil,
                    recordingBarWindowOriginY: nil,
                    fontName: nil,
                    spacingPreset: .relaxed,
                    highlightHex: Constants.defaultHighlightHex,
                    readingRulerEnabled: true,
                    readingRulerLines: 2,
                    readingRulerOpacity: 0.25,
                    wordChunkMode: .off,
                    chunkSeconds: Constants.defaultChunkSeconds
                )
            }
        }
        """
    ).lstrip()

    # Persistence settings
    swift_files["Persistence/Settings/DefaultSettings.swift"] = textwrap.dedent(
        """
        import Foundation

        enum DefaultSettings {
            static let model = SettingsModel.default()
        }
        """
    ).lstrip()

    swift_files["Persistence/Settings/SettingsStore.swift"] = textwrap.dedent(
        """
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
                    assertionFailure("Failed saving settings: \\(error)")
                }
            }
        }
        """
    ).lstrip()

    # Minimal UI scaffolding + GRDB schema/migrations is generated in the next step (kept in a smaller generator to avoid huge patch).
    # We'll write remaining Swift files as lightweight stubs to satisfy the required file tree.
    required_stub_paths = [
        # Domain models (stubs here; real ones are created in follow-up generator run)
        "Domain/Models/ClassModel.swift",
        "Domain/Models/NoteModel.swift",
        "Domain/Models/SegmentModel.swift",
        "Domain/Models/MutedRangeModel.swift",
        "Domain/Models/MarkerModel.swift",
        "Domain/Models/TranscriptSentenceModel.swift",
        "Domain/Models/CleanCopyModel.swift",
        # Metadata
        "Domain/Metadata/MetaJSON.swift",
        "Domain/Metadata/TranscriptJSON.swift",
        "Domain/Metadata/MarkersJSON.swift",
        # Organizer
        "Domain/Organizer/OptionAOrganizer.swift",
        "Domain/Organizer/SentenceScorer.swift",
        "Domain/Organizer/Deduper.swift",
        "Domain/Organizer/VocabularyExtractor.swift",
        "Domain/Organizer/QuestionAnswerLinker.swift",
        "Domain/Organizer/OrganizerOutputRenderer.swift",
        # Services
        "Services/Audio/AudioCaptureService.swift",
        "Services/Audio/AudioInputManager.swift",
        "Services/Audio/AudioWarningsMonitor.swift",
        "Services/Transcription/TranscriptionService.swift",
        "Services/Transcription/WhisperBridge.swift",
        "Services/Transcription/WhisperModelManager.swift",
        "Services/Transcription/ChunkScheduler.swift",
        "Services/Transcription/SentenceTimestampAligner.swift",
        "Services/Playback/PlaybackService.swift",
        "Services/Playback/PlaybackSyncService.swift",
        "Services/Storage/FileStore.swift",
        "Services/Storage/Paths.swift",
        "Services/Storage/JSONWriters.swift",
        "Services/Storage/MarkdownWriter.swift",
        "Services/Storage/RenameManager.swift",
        "Services/Storage/Export/RTFExporter.swift",
        "Services/Storage/Export/DOCXExporter.swift",
        "Services/Privacy/SchoolModePolicy.swift",
        "Services/Privacy/NetworkBlocker.swift",
        "Services/Notifications/ToastCenter.swift",
        "Services/Notifications/LocalAlerts.swift",
        # UI Accessibility
        "UI/Accessibility/ReadingRulerOverlay.swift",
        "UI/Accessibility/SpacingPresets.swift",
        "UI/Accessibility/WordChunkRenderer.swift",
        "UI/Accessibility/TapToSpeakCoordinator.swift",
        "UI/Accessibility/ReplayLoopController.swift",
        "UI/Accessibility/ExplainSimplyEngine.swift",
    ]
    for p in required_stub_paths:
        swift_files.setdefault(
            p,
            "import Foundation\n\n// Stub; implemented in later milestones.\n",
        )

    # Minimal tests placeholder
    for rel in [
        "OrganizerTests/OrganizerTests.swift",
        "StorageTests/StorageTests.swift",
        "DatabaseTests/DatabaseTests.swift",
    ]:
        write(TESTS / rel, "import XCTest\n\nfinal class PlaceholderTests: XCTestCase { }\n")

    # Write all swift files
    for rel, content in swift_files.items():
        write(APP / rel, content)

    print("Base generator wrote README + core settings + required stubs.")


if __name__ == "__main__":
    main()

