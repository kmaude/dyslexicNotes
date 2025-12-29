import Foundation
import AVFoundation

@MainActor
final class PlaybackService: ObservableObject {
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTimeSec: Double = 0
    @Published var baseRate: Float = 1.0 {
        didSet { applyRateIfNeeded() }
    }
    @Published var clarityMode: PlaybackClarityMode = .normal {
        didSet { applyClarityMode() }
    }

    private var player: AVPlayer?
    private var timeObserver: Any?

    func load(url: URL) {
        stop()
        let item = AVPlayerItem(url: url)
        item.audioTimePitchAlgorithm = .spectral
        let p = AVPlayer(playerItem: item)
        player = p
        observeTime(player: p)
    }

    func play() {
        guard let player else { return }
        player.playImmediately(atRate: effectiveRate())
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        if let player, let obs = timeObserver {
            player.removeTimeObserver(obs)
        }
        timeObserver = nil
        player = nil
        isPlaying = false
        currentTimeSec = 0
    }

    func seek(to seconds: Double) {
        guard let player else { return }
        let t = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
        player.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTimeSec = max(0, seconds)
    }

    private func observeTime(player: AVPlayer) {
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTimeSec = time.seconds
        }
    }

    private func applyRateIfNeeded() {
        guard isPlaying else { return }
        player?.rate = effectiveRate()
    }

    private func applyClarityMode() {
        guard let item = player?.currentItem else { return }
        switch clarityMode {
        case .normal:
            item.audioTimePitchAlgorithm = .spectral
        case .classroom:
            item.audioTimePitchAlgorithm = .timeDomain
        case .slowClear:
            item.audioTimePitchAlgorithm = .timeDomain
        }
        applyRateIfNeeded()
    }

    private func effectiveRate() -> Float {
        switch clarityMode {
        case .normal, .classroom:
            return baseRate
        case .slowClear:
            return min(baseRate, 0.85)
        }
    }
}
