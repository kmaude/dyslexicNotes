import Foundation
import GRDB

@MainActor
final class AppEnvironment: ObservableObject {
    let settingsStore: SettingsStore
    let dbManager: DatabaseManager

    init() {
        self.settingsStore = SettingsStore()
        self.dbManager = DatabaseManager()
    }

    func start() throws {
        try dbManager.start()
        try dbManager.seedIfNeeded(settings: settingsStore)
    }
}
