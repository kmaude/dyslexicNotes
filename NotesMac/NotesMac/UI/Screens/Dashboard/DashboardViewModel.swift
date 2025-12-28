import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var rows: [NoteCardRow] = []
    @Published private(set) var isLoading: Bool = false

    private let debouncer = Debouncer(delay: 0.15)

    func onSearchChanged(env: AppEnvironment) {
        debouncer.schedule { [weak self] in
            guard let self else { return }
            Task { await self.reload(env: env) }
        }
    }

    func reload(env: AppEnvironment) async {
        guard let db = env.dbManager.dbWriter else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            rows = try await NotesDAO(db: db).fetchToday(search: searchText)
        } catch {
            rows = []
        }
    }
}
