import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView(
            "No notes yet",
            systemImage: "note.text",
            description: Text("Start a class note to capture audio and build transcripts.")
        )
    }
}
