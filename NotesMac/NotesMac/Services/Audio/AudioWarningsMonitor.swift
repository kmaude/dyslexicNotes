import Foundation
import IOKit.ps

struct AudioWarning: Hashable {
    enum Kind: Hashable { case lowDisk, lowBattery }
    let kind: Kind
    let message: String
}

@MainActor
final class AudioWarningsMonitor: ObservableObject {
    @Published private(set) var activeWarnings: [AudioWarning] = []

    private var timer: Timer?

    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
        poll()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        activeWarnings = []
    }

    private func poll() {
        var warnings: [AudioWarning] = []

        if let free = diskFreeBytes(at: URL.notesBundlesBase), free < Constants.lowDiskWarningThresholdBytes {
            warnings.append(AudioWarning(kind: .lowDisk, message: "Low disk space (< 2GB). Recording may stop."))
        }

        if let pct = batteryPercent(), pct < Constants.lowBatteryWarningThresholdPercent {
            warnings.append(AudioWarning(kind: .lowBattery, message: "Low battery (< 20%). Consider plugging in."))
        }

        activeWarnings = warnings
    }

    private func diskFreeBytes(at url: URL) -> Int64? {
        do {
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let cap = values.volumeAvailableCapacityForImportantUsage {
                return Int64(cap)
            }
            return nil
        } catch {
            return nil
        }
    }

    private func batteryPercent() -> Int? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for ps in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] else { continue }
            guard let cur = desc[kIOPSCurrentCapacityKey as String] as? Int,
                  let max = desc[kIOPSMaxCapacityKey as String] as? Int,
                  max > 0
            else { continue }
            return Int((Double(cur) / Double(max) * 100.0).rounded())
        }
        return nil
    }
}
