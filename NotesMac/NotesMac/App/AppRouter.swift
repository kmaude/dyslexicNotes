import SwiftUI

enum AppRoute: Hashable {
    case dashboard
    case noteDetail(noteID: String)
    case settings
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var route: AppRoute = .dashboard

    func openDashboard() { route = .dashboard }
    func openSettings() { route = .settings }
    func openNote(noteID: String) { route = .noteDetail(noteID: noteID) }
}

struct AppRouterView: View {
    @StateObject private var router = AppRouter()

    var body: some View {
        NavigationStack {
            content
        }
        .environmentObject(router)
    }

    @ViewBuilder
    private var content: some View {
        switch router.route {
        case .dashboard:
            DashboardView()
        case .settings:
            SettingsView()
        case .noteDetail(let noteID):
            NoteDetailView(noteID: noteID)
        }
    }
}
