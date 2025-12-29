import SwiftUI

struct VersionsView: View {
    var body: some View {
        ContentUnavailableView("No versions yet", systemImage: "doc.on.doc", description: Text("Clean copies are introduced in M7."))
            .padding(.top, 24)
    }
}
