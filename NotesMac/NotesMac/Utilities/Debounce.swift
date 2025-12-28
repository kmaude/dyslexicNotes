import Foundation

@MainActor
final class Debouncer {
    private var task: Task<Void, Never>?
    private let delayNanos: UInt64

    init(delay: TimeInterval) {
        self.delayNanos = UInt64(max(0, delay) * 1_000_000_000)
    }

    func schedule(_ action: @escaping @MainActor () -> Void) {
        task?.cancel()
        task = Task { [delayNanos] in
            try? await Task.sleep(nanoseconds: delayNanos)
            guard !Task.isCancelled else { return }
            action()
        }
    }
}
