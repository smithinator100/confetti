import SwiftUI
import AppKit

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    WebPane()
                        .frame(maxWidth: .infinity, maxHeight: geo.size.height)
                    NativePane()
                        .frame(maxWidth: .infinity, maxHeight: geo.size.height)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }

            TitlebarDragArea()
                .frame(maxWidth: .infinity)
                .frame(height: 28)
        }
        .frame(minWidth: 960, minHeight: 600)
        .ignoresSafeArea()
    }
}

private struct TitlebarDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DraggableView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class DraggableView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(convert(point, from: superview)) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
