import SwiftUI
import AppKit
import WebKit

struct WebPane: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(srgbRed: 0xFA/255.0, green: 0xFA/255.0, blue: 0xFA/255.0, alpha: 1).cgColor
        container.setAccessibilityIdentifier("WebPane")
        container.setAccessibilityElement(true)

        let webView = WKWebView(frame: .zero)
        webView.setValue(false, forKey: "drawsBackground")
        webView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        if let url = Bundle.main.url(forResource: "confetti", withExtension: "html"),
           let resourceDir = Bundle.main.resourceURL {
            webView.loadFileURL(url, allowingReadAccessTo: resourceDir)
        }

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
