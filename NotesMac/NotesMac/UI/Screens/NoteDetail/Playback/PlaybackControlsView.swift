import SwiftUI

struct PlaybackControlsView: View {
    let isPlaying: Bool
    @Binding var rate: Double
    @Binding var clarityMode: PlaybackClarityMode
    let onPlayPause: () -> Void
    let onReplaySentence: () -> Void
    @Binding var autoLoopEnabled: Bool
    let onReprocess: () -> Void
    let onExport: () -> Void
    let onCreateCleanCopy: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(isPlaying ? "Pause" : "Play", action: onPlayPause)
                .buttonStyle(.borderedProminent)

            SpeedSliderView(rate: $rate)
                .frame(width: 200)

            Picker("", selection: $clarityMode) {
                Text("Normal").tag(PlaybackClarityMode.normal)
                Text("Classroom").tag(PlaybackClarityMode.classroom)
                Text("Slow+Clear").tag(PlaybackClarityMode.slowClear)
            }
            .pickerStyle(.menu)
            .frame(width: 120)

            Button("Replay sentence", action: onReplaySentence)
                .buttonStyle(.bordered)

            Toggle("Auto-loop", isOn: $autoLoopEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .help("Auto-loop current sentence")

            Divider().frame(height: 18)

            Button("Reprocess", action: onReprocess).buttonStyle(.bordered)
            Button("Export", action: onExport).buttonStyle(.bordered)
            Button("Create Clean Copy", action: onCreateCleanCopy).buttonStyle(.bordered)
        }
        .controlSize(.small)
    }
}
