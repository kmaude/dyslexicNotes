import Foundation
import AVFoundation

struct AudioInputDevice: Identifiable, Hashable {
    var id: String { uniqueID }
    let name: String
    let uniqueID: String
}

@MainActor
final class AudioInputManager: ObservableObject {
    @Published private(set) var availableInputs: [AudioInputDevice] = []

    func refresh() {
        // macOS input device selection with AVAudioEngine is non-trivial; we at least enumerate devices for Settings UI.
        let devices = AVCaptureDevice.devices(for: .audio)
        availableInputs = devices.map { AudioInputDevice(name: $0.localizedName, uniqueID: $0.uniqueID) }
            .sorted { $0.name < $1.name }
    }
}
