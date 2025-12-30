import SwiftUI

enum NotesTypography {
    static func readingFont(name: String?, size: CGFloat) -> Font {
        if let name, !name.isEmpty {
            return .custom(name, size: size)
        }
        // OpenDyslexic is not bundled in this repo by default (license-dependent).
        return .system(size: size)
    }
}
