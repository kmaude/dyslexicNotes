import SwiftUI

struct NoteCardView: View {
    let row: NoteCardRow
    let onOpen: () -> Void
    let onPlay: () -> Void
    let onReprocess: () -> Void
    let onExport: () -> Void
    let onRename: () -> Void

    var body: some View {
        ZStack {
            CardBackground(stripeHex: row.classColorHex)
            content
                .padding(12)
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(row.title)
                        .font(.headline)
                    Spacer()
                    if row.hasCleanCopy {
                        BadgeView(text: "Clean Copy", color: .green)
                    }
                }

                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        ColorDot(color: NotesColors.classStripe(row.classColorHex))
                        Text(row.className).font(.subheadline.weight(.semibold))
                    }
                    Text("•").foregroundStyle(.secondary)
                    Text(row.createdAtLocal).font(.subheadline).foregroundStyle(.secondary)
                }

                HStack(spacing: 14) {
                    Label(TimeFormatting.mmss(TimeInterval(row.durationSeconds)), systemImage: "timer")
                    Label("\(row.starCount)", systemImage: "star.fill")
                    Label("\(row.questionCount)", systemImage: "questionmark.circle.fill")
                    Label("\(row.segmentCount)", systemImage: "square.stack.3d.up")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button("Open", action: onOpen)
                    Button("Play", action: onPlay)
                    Button("Reprocess", action: onReprocess)
                    Button("Export", action: onExport)
                    Button("Rename", action: onRename)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}
