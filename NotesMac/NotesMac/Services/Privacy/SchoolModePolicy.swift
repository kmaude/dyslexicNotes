import Foundation

@MainActor
final class SchoolModePolicy: ObservableObject {
    @Published private(set) var enabled: Bool = false

    func bind(to settings: SettingsStore) {
        enabled = settings.model.schoolModeEnabled
    }

    func canUseNetwork(settings: SettingsStore) -> Bool {
        settings.model.schoolModeEnabled == false
    }
}
