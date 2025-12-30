import SwiftUI

struct SpeedSliderView: View {
    @Binding var rate: Double
    private let range: ClosedRange<Double> = 0.7...1.6

    var body: some View {
        HStack(spacing: 8) {
            Text(String(format: "%.2fx", rate))
                .font(.caption.weight(.semibold))
                .frame(width: 52, alignment: .leading)

            Slider(value: $rate, in: range, step: 0.05)
        }
        .accessibilityLabel("Playback speed")
    }
}
