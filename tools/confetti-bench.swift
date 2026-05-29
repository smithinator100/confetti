// Confetti web-view FPS benchmark harness.
//
// Drives the bundled `confetti.html` in a real, on-screen WKWebView and fires a
// burst at a sweep of particle counts, reading back the in-page rAF FPS probe
// (window.__confettiBench) for each run. Prints a markdown table of avg/min FPS
// and dropped frames.
//
// Run:  swift tools/confetti-bench.swift [count ...]
// Env:  CONFETTI_BENCH_MS = burst window per run in ms (default 3000)
//
// Must run from a logged-in GUI session (a window is shown so WebKit composites
// at the display refresh rate; offscreen views are throttled and would lie).

import Cocoa
import WebKit

let scriptURL = URL(fileURLWithPath: #filePath)
let repoRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let resourcesDir = repoRoot.appendingPathComponent("ConfettiPrototype/Resources")
let htmlURL = resourcesDir.appendingPathComponent("confetti.html")

let argCounts = CommandLine.arguments.dropFirst().compactMap { Int($0) }
let counts = argCounts.isEmpty ? [30, 60, 120, 200, 300] : argCounts
let durationMs = Double(ProcessInfo.processInfo.environment["CONFETTI_BENCH_MS"] ?? "") ?? 3000

struct BenchResult {
    let particles: Int
    let avgFps: Double
    let minFps: Double
    let dropped: Int
    let frames: Int
}

final class BenchController: NSObject, WKNavigationDelegate {
    let window: NSWindow
    let webView: WKWebView
    let counts: [Int]
    let durationMs: Double
    var index = 0
    var results: [BenchResult] = []
    var watchdog: DispatchWorkItem?

    init(counts: [Int], durationMs: Double) {
        self.counts = counts
        self.durationMs = durationMs
        let frame = NSRect(x: 0, y: 0, width: 700, height: 1000)
        webView = WKWebView(frame: frame)
        window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        super.init()
        window.title = "Confetti Benchmark"
        window.contentView = webView
        webView.navigationDelegate = self
    }

    func start() {
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        webView.loadFileURL(htmlURL, allowingReadAccessTo: resourcesDir)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        waitForReady()
    }

    func waitForReady(attempt: Int = 0) {
        webView.evaluateJavaScript("typeof window.__confettiBench === 'function'") { value, _ in
            if (value as? Bool) == true {
                self.runWarmup()
            } else if attempt < 100 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.waitForReady(attempt: attempt + 1)
                }
            } else {
                FileHandle.standardError.write(Data("error: window.__confettiBench not found\n".utf8))
                NSApp.terminate(nil)
            }
        }
    }

    // One discarded run to warm the JIT and prime the particle bitmap cache so
    // the first measured count isn't penalized for cold-start work.
    func runWarmup() {
        fire(count: 60) { _ in self.runNext() }
    }

    func runNext() {
        guard index < counts.count else {
            finish()
            return
        }
        let count = counts[index]
        index += 1
        fire(count: count) { result in
            if let result = result {
                self.results.append(result)
                FileHandle.standardError.write(Data("  ran \(count) particles → avg \(String(format: "%.1f", result.avgFps)) fps\n".utf8))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { self.runNext() }
        }
    }

    func fire(count: Int, completion: @escaping (BenchResult?) -> Void) {
        var finished = false
        let watchdog = DispatchWorkItem {
            if !finished {
                finished = true
                FileHandle.standardError.write(Data("  warning: run for \(count) particles timed out\n".utf8))
                completion(nil)
            }
        }
        self.watchdog = watchdog
        DispatchQueue.main.asyncAfter(deadline: .now() + (durationMs / 1000) + 5, execute: watchdog)

        let js = "return await window.__confettiBench(count, durationMs);"
        webView.callAsyncJavaScript(
            js,
            arguments: ["count": count, "durationMs": durationMs],
            in: nil,
            in: .page
        ) { result in
            guard !finished else { return }
            finished = true
            watchdog.cancel()
            switch result {
            case .success(let value):
                guard let dict = value as? [String: Any] else {
                    completion(nil)
                    return
                }
                completion(BenchResult(
                    particles: (dict["particles"] as? NSNumber)?.intValue ?? count,
                    avgFps: (dict["avgFps"] as? NSNumber)?.doubleValue ?? 0,
                    minFps: (dict["minFps"] as? NSNumber)?.doubleValue ?? 0,
                    dropped: (dict["dropped"] as? NSNumber)?.intValue ?? 0,
                    frames: (dict["frames"] as? NSNumber)?.intValue ?? 0
                ))
            case .failure(let error):
                FileHandle.standardError.write(Data("  run failed: \(error)\n".utf8))
                completion(nil)
            }
        }
    }

    func finish() {
        let refresh = NSScreen.main?.maximumFramesPerSecond ?? 60
        var out = "\n# Web confetti FPS benchmark\n\n"
        out += "- window: \(Int(window.frame.width))×\(Int(window.frame.height)) pt\n"
        out += "- display: \(refresh) Hz\n"
        out += "- burst window: \(Int(durationMs)) ms per run\n\n"
        out += "| particles | avg fps | min fps | dropped frames | sampled frames |\n"
        out += "|---:|---:|---:|---:|---:|\n"
        for r in results {
            out += "| \(r.particles) | \(String(format: "%.1f", r.avgFps)) | \(String(format: "%.1f", r.minFps)) | \(r.dropped) | \(r.frames) |\n"
        }
        FileHandle.standardOutput.write(Data(out.utf8))
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let controller = BenchController(counts: counts, durationMs: durationMs)
controller.start()
app.run()
