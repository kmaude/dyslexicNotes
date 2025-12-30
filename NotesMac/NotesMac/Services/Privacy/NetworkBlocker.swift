import Foundation

/// Central place to guard networking calls when School Mode is enabled.
enum NetworkBlocker {
    static func ensureAllowed(settings: SettingsStore) throws {
        if settings.model.schoolModeEnabled {
            throw NSError(domain: "Notes.NetworkBlocked", code: 1, userInfo: [NSLocalizedDescriptionKey: "Networking blocked (School Mode ON)."])
        }
    }
}
