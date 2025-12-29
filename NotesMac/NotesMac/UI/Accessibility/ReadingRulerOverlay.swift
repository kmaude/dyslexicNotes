import SwiftUI
import AppKit

struct ReadingRulerOverlay<Content: View>: View {
    let enabled: Bool
    let lines: Int
    let opacity: Double
    let lineHeight: CGFloat
    @ViewBuilder let content: () -> Content

    @State private var mouseY: CGFloat? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            content()
                .background(MouseTrackingView { p in
                    mouseY = p.y
                })

            if enabled, let mouseY {
                GeometryReader { proxy in
                    let h = max(1, min(3, lines))
                    let bandHeight = lineHeight * CGFloat(h)
                    let snapped = (round(mouseY / lineHeight) * lineHeight) - (bandHeight / 2) + (lineHeight / 2)

                    Rectangle()
                        .fill(Color.accentColor)
                        .opacity(opacity)
                        .frame(width: proxy.size.width, height: bandHeight)
                        .offset(x: 0, y: max(0, min(proxy.size.height - bandHeight, snapped)))
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

private struct MouseTrackingView: NSViewRepresentable {
    let onMove: (CGPoint) -> Void

    func makeNSView(context: Context) -> NSView {
        let v = TrackingNSView()
        v.onMove = onMove
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) { }

    private final class TrackingNSView: NSView {
        var onMove: ((CGPoint) -> Void)?
        private var tracking: NSTrackingArea?

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let tracking { removeTrackingArea(tracking) }
            let options: NSTrackingArea.Options = [.mouseMoved, .activeInKeyWindow, .inVisibleRect]
            let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
            addTrackingArea(area)
            tracking = area
        }

        override func mouseMoved(with event: NSEvent) {
            let p = convert(event.locationInWindow, from: nil)
            onMove?(p)
        }
    }
}
