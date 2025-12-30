import SwiftUI

struct MarkersView: View {
    let markers: [MarkerRow]
    let onJumpTo: (Double) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if markers.isEmpty {
                    ContentUnavailableView("No markers", systemImage: "bookmark", description: Text("Add ⭐ or ❓ during recording."))
                        .padding(.top, 24)
                } else {
                    ForEach(markers) { m in
                        Button {
                            onJumpTo(m.atSec)
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Text(m.type == "STAR" ? "⭐" : "❓")
                                    .font(.title3)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(TimeFormatting.mmss(m.atSec))")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                    Text(m.contextText.isEmpty ? "(context pending)" : m.contextText)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(.quaternary.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .padding(12)
        .background(.quaternary.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
