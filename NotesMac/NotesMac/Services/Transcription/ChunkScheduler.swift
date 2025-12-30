import Foundation

@MainActor
final class ChunkScheduler {
    private var timer: Timer?
    private let interval: TimeInterval
    private let onTick: () -> Void

    init(interval: TimeInterval, onTick: @escaping () -> Void) {
        self.interval = interval
        self.onTick = onTick
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [onTick] _ in
            onTick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
