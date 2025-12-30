import Foundation

@MainActor final class SettingsViewModel: ObservableObject { @Published var selectedTab: Int = 0 }
