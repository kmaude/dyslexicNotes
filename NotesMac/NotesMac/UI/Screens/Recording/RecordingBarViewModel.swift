import Foundation

@MainActor
final class RecordingBarViewModel: ObservableObject {
    enum State { case idle, recording, paused, stopped }

    @Published var state: State = .idle
    @Published var isMuted: Bool = false
    @Published var isExpanded: Bool = false
    @Published var elapsed: TimeInterval = 0

    @Published var classOptions: [ClassModel] = []
    @Published var selectedClassID: String?

    @Published var starCount: Int = 0
    @Published var questionCount: Int = 0

    private var timer: Timer?

    func loadClasses(env: AppEnvironment) async {
        guard let db = env.dbManager.dbWriter else { return }
        do {
            classOptions = try await ClassesDAO(db: db).fetchAll()
            if selectedClassID == nil {
                selectedClassID = env.settingsStore.model.lastClassID ?? classOptions.first?.classID
            }
        } catch {
            classOptions = []
        }
    }

    func start(env: AppEnvironment) {
        state = .recording
        isMuted = false
        elapsed = 0
        starCount = 0
        questionCount = 0
        env.settingsStore.update { $0.lastClassID = selectedClassID }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.state == .recording { self.elapsed += 1 }
        }
    }

    func togglePause() {
        switch state {
        case .recording: state = .paused
        case .paused: state = .recording
        default: break
        }
    }

    func stop() {
        state = .stopped
        timer?.invalidate()
        timer = nil
    }

    func toggleMute() {
        guard state == .recording || state == .paused else { return }
        isMuted.toggle()
    }

    func addStar() { starCount += 1 }
    func addQuestion() { questionCount += 1 }
}
