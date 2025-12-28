import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var env: AppEnvironment
    @EnvironmentObject private var router: AppRouter

    @StateObject private var vm = DashboardViewModel()
    @StateObject private var hud = RecordingHUDWindow()

    var body: some View {
        VStack(spacing: 12) {
            topBar
            FiltersPanelView()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if vm.isLoading {
                        ProgressView().padding(.top, 20)
                    }

                    ForEach(vm.rows) { row in
                        NoteCardView(
                            row: row,
                            onOpen: { router.openNote(noteID: row.noteID) },
                            onPlay: { router.openNote(noteID: row.noteID) },
                            onReprocess: { },
                            onExport: { },
                            onRename: { }
                        )
                    }

                    if vm.rows.isEmpty && !vm.isLoading {
                        EmptyStateView().padding(.top, 24)
                    }
                }
                .padding(.vertical, 4)
            }

            HStack {
                Spacer()
                Button {
                    hud.showOrStart(env: env)
                } label: {
                    Label("Start Class Note", systemImage: "record.circle")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { router.openSettings() } label: { Image(systemName: "gear") }
            }
        }
        .task { await vm.reload(env: env) }
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Toggle(isOn: Binding(
                get: { env.settingsStore.model.schoolModeEnabled },
                set: { env.settingsStore.update { $0.schoolModeEnabled = $1 } }
            )) {
                Text("School Mode").font(.subheadline.weight(.semibold))
            }
            .toggleStyle(.switch)

            if env.settingsStore.model.schoolModeEnabled {
                BadgeView(text: "ON", color: .red)
            }

            SearchBar(text: $vm.searchText)
                .onChange(of: vm.searchText) { _, _ in vm.onSearchChanged(env: env) }

            Spacer()
        }
    }
}
