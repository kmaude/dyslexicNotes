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
