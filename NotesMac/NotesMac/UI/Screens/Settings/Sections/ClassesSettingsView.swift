import SwiftUI

struct ClassesSettingsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @State private var classes: [ClassModel] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Classes").font(.headline)
                Spacer()
                Button("Add class") { }
                    .buttonStyle(.bordered)
            }
            List(classes) { c in
                HStack {
                    ColorDot(color: NotesColors.classStripe(c.colorHex))
                    Text(c.name)
                    Spacer()
                    if c.isSystem { BadgeView(text: "System", color: .secondary) }
                }
            }
        }
        .task {
            guard let db = env.dbManager.dbWriter else { return }
            classes = (try? await ClassesDAO(db: db).fetchAll()) ?? []
        }
    }
}
