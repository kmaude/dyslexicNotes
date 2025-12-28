import SwiftUI

enum NotesColors {
    static let cardTintOpacity: Double = 0.08

    static func classStripe(_ hex: String) -> Color {
        Color(hex: hex) ?? .gray
    }

    static func classTint(_ hex: String) -> Color {
        (Color(hex: hex) ?? .gray).opacity(min(max(cardTintOpacity, 0.06), 0.10))
    }
}
