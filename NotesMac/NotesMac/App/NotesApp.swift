import SwiftUI

@main
struct NotesApp: App {
    @StateObject private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            AppRouterView()
                .environmentObject(env)
                .task {
                    do {
                        try env.start()
                    } catch {
                        // Minimal crash-avoidance for M1; production app would show a blocking error UI.
                        assertionFailure("Failed to start app: \(error)")
                    }
                }
        }
        Settings {
            SettingsView()
                .environmentObject(env)
        }
    }
}
