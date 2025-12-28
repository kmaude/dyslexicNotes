import SwiftUI
import AppKit

@MainActor
final class RecordingHUDWindow: ObservableObject {
    private var window: NSPanel?
    private let vm = RecordingBarViewModel()

    func showOrStart(env: AppEnvironment) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingView(rootView: RecordingBarView(vm: vm).environmentObject(env))
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 140),
            styleMask: [.titled, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.contentView = hosting

        if let x = env.settingsStore.model.recordingBarWindowOriginX,
           let y = env.settingsStore.model.recordingBarWindowOriginY {
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.midX - 440, y: frame.minY + 40))
        }

        NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: panel, queue: .main) { _ in
            let origin = panel.frame.origin
            env.settingsStore.update {
                $0.recordingBarWindowOriginX = origin.x
                $0.recordingBarWindowOriginY = origin.y
            }
        }

        self.window = panel
        panel.makeKeyAndOrderFront(nil)
    }
}
