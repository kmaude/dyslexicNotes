import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var vm = SettingsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings").font(.title2.weight(.semibold))

            Picker("", selection: $vm.selectedTab) {
                Text("Classes").tag(0)
                Text("Audio").tag(1)
                Text("Capture").tag(2)
                Text("Reading").tag(3)
                Text("Privacy").tag(4)
                Text("Models").tag(5)
            }
            .pickerStyle(.segmented)

            Group {
                switch vm.selectedTab {
                case 0: ClassesSettingsView()
                case 1: AudioSettingsView()
                case 2: CaptureSettingsView()
                case 3: ReadingSettingsView()
                case 4: PrivacySettingsView()
                default: ModelsSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(16)
        .frame(minWidth: 760, minHeight: 520)
    }
}
