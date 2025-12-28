import SwiftUI

struct CardBackground: View {
    let stripeHex: String

    var body: some View {
        let stripe = NotesColors.classStripe(stripeHex)
        let tint = NotesColors.classTint(stripeHex)

        HStack(spacing: 0) {
            Rectangle().fill(stripe).frame(width: 8)
            Rectangle().fill(tint)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.black.opacity(0.05), lineWidth: 1)
        )
    }
}
