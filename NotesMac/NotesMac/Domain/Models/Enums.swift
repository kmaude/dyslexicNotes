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

enum PlaybackClarityMode: String, Codable, CaseIterable {
    case normal
    case classroom
    case slowClear
}
