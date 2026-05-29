import SwiftUI
import AppKit

struct NativePane: View {
    private static let stageWidth: CGFloat = 402
    private static let stageHeight: CGFloat = 874
    private static let verticalInset: CGFloat = 44
    private static let horizontalInset: CGFloat = 24
    private static let paneBackground = Color(red: 0xF2/255, green: 0xF2/255, blue: 0xF2/255)

    @StateObject private var confettiSettings = NativeConfettiSettings()
    @State private var burstID: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            NativeTweakPanel(settings: confettiSettings)
                .frame(width: 300, alignment: .topLeading)
                .frame(maxHeight: .infinity, alignment: .topLeading)

            GeometryReader { geo in
                let availableWidth = max(geo.size.width - (Self.horizontalInset * 2), 1)
                let availableHeight = max(geo.size.height - (Self.verticalInset * 2), 1)
                let scale = min(availableWidth / Self.stageWidth,
                                availableHeight / Self.stageHeight) * 0.925
                ZStack {
                    Self.paneBackground
                    stage
                        .frame(width: Self.stageWidth, height: Self.stageHeight)
                        .scaleEffect(scale)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .background(Self.paneBackground)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("NativePane")
    }

    private var stage: some View {
        ZStack(alignment: .topLeading) {
            MockupImageView()
                .frame(width: Self.stageWidth + 2, height: Self.stageHeight + 2)
                .offset(x: -1, y: -1)

            ConfettiBurstView(settings: confettiSettings, burstID: burstID)
                .frame(width: Self.stageWidth, height: Self.stageHeight)

            Button(action: { burstID += 1 }) {
                Text("Confetti")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 370, height: 50)
            }
            .buttonStyle(ConfettiButtonStyle())
            .offset(x: 16, y: 795)
            .accessibilityIdentifier("NativeConfettiButton")
        }
        .frame(width: Self.stageWidth, height: Self.stageHeight, alignment: .topLeading)
    }
}

private struct MockupImageView: NSViewRepresentable {
    func makeNSView(context: Context) -> MockupDrawingView {
        MockupDrawingView()
    }

    func updateNSView(_ nsView: MockupDrawingView, context: Context) {}
}

private final class MockupDrawingView: NSView {
    private let image: NSImage? = {
        guard let url = Bundle.main.url(forResource: "iphone-screen", withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        image.size = NSSize(width: 404, height: 876)
        return image
    }()

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        image?.draw(
            in: bounds,
            from: NSRect(origin: .zero, size: NSSize(width: 404, height: 876)),
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: true,
            hints: [.interpolation: NSImageInterpolation.high]
        )
    }
}

private struct ConfettiButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(configuration.isPressed
                          ? Color(red: 0x0E/255, green: 0x66/255, blue: 0xB3/255)
                          : Color(red: 0x10/255, green: 0x74/255, blue: 0xCC/255))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
