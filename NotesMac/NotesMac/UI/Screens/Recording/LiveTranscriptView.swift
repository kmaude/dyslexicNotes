import SwiftUI

struct LiveTranscriptView: View {
    let isMuted: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Live transcript (simulated in M1)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(isMuted ? "⏸ MUTED" : "Listening…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
