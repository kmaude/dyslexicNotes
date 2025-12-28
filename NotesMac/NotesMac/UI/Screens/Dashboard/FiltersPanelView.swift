import SwiftUI

struct FiltersPanelView: View {
    // M1: visual placeholder (class/date/star/question/has-clean-copy filters arrive next).
    var body: some View {
        HStack(spacing: 10) {
            Text("Today")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.quaternary.opacity(0.6))
                .clipShape(Capsule())

            Text("Filters (M2)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}
