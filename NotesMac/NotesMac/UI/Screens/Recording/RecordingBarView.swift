import SwiftUI

struct RecordingBarView: View {
    @EnvironmentObject private var env: AppEnvironment
    @ObservedObject var vm: RecordingBarViewModel

    var body: some View {
        VStack(spacing: 8) {
            DragHandleView()

            HStack(spacing: 10) {
                Picker("Class", selection: Binding(
                    get: { vm.selectedClassID ?? "" },
                    set: { vm.selectedClassID = $0 }
                )) {
                    ForEach(vm.classOptions) { c in
                        Text(c.name).tag(c.classID)
                    }
                }
                .frame(width: 200)

                Text(TimeFormatting.mmss(vm.elapsed))
                    .font(.system(.body, design: .monospaced).weight(.semibold))
                    .frame(width: 70, alignment: .leading)

                Button(vm.isMuted ? "Muted" : "Mute") { vm.toggleMute() }
                    .buttonStyle(.bordered)

                Button(vm.state == .paused ? "Resume" : "Pause") { vm.togglePause() }
                    .buttonStyle(.bordered)

                Button("Stop") { vm.stop() }
                    .buttonStyle(.borderedProminent)

                Divider().frame(height: 18)

                Button("⭐ \(vm.starCount)") { vm.addStar() }.buttonStyle(.bordered)
                Button("❓ \(vm.questionCount)") { vm.addQuestion() }.buttonStyle(.bordered)

                Spacer()

                Button(vm.isExpanded ? "Collapse" : "Expand") { vm.isExpanded.toggle() }
                    .buttonStyle(.bordered)
            }

            if vm.isExpanded {
                LiveTranscriptView(isMuted: vm.isMuted)
                    .padding(.top, 4)
            }
        }
        .padding(10)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
        .frame(minWidth: 840)
        .task {
            await vm.loadClasses(env: env)
            if vm.state == .idle {
                vm.start(env: env)
            }
        }
    }
}
