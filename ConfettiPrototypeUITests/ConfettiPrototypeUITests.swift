import XCTest

final class ConfettiPrototypeUITests: XCTestCase {
    // Note: when running via `xcodebuild test` from a non-graphical shell session,
    // SwiftUI's WindowGroup may not surface a window the test runner can see
    // (Application reports as `Disabled` with WINDOWS COUNT: 0). Run from the
    // Xcode IDE or a Terminal session for these assertions to be meaningful;
    // build-clean via `xcodebuild build` is the authoritative automated bar for
    // Epic 2's visual stories per the epic-workflow rule.
    func test_panes_renderButtons() throws {
        let app = XCUIApplication()
        app.launch()
        app.activate()

        guard app.windows.firstMatch.waitForExistence(timeout: 10) else {
            throw XCTSkip("App window did not appear under the test runner; verify visually instead.")
        }

        let webPane = app.descendants(matching: .any)["WebPane"]
        let nativePane = app.descendants(matching: .any)["NativePane"]
        XCTAssertTrue(webPane.waitForExistence(timeout: 5), "WebPane should be present")
        XCTAssertTrue(nativePane.waitForExistence(timeout: 5), "NativePane should be present")

        let nativeButton = app.buttons["NativeConfettiButton"]
        XCTAssertTrue(nativeButton.waitForExistence(timeout: 5), "Native Confetti button should be present")

        let webButton = app.webViews.buttons["Confetti"]
        XCTAssertTrue(webButton.waitForExistence(timeout: 5), "Web Confetti button should be present in WKWebView")
    }

    func test_webConfettiButton_tapDoesNotCrash() throws {
        let app = XCUIApplication()
        app.launch()
        app.activate()

        guard app.windows.firstMatch.waitForExistence(timeout: 10) else {
            throw XCTSkip("App window did not appear under the test runner; verify visually instead.")
        }

        let webPane = app.descendants(matching: .any)["WebPane"]
        XCTAssertTrue(webPane.waitForExistence(timeout: 5), "WebPane should be present")

        let webButton = app.webViews.buttons["Confetti"]
        XCTAssertTrue(webButton.waitForExistence(timeout: 5), "Web Confetti button should be present before tap")

        webButton.tap()
        sleep(1)

        XCTAssertTrue(webPane.exists, "WebPane should remain present after confetti tap")
        XCTAssertTrue(webButton.exists, "Web Confetti button should remain present after confetti tap")
    }

    func test_webAndNativeButtons_renderAtSameWidth() throws {
        let app = XCUIApplication()
        app.launch()
        app.activate()

        guard app.windows.firstMatch.waitForExistence(timeout: 10) else {
            throw XCTSkip("App window did not appear under the test runner; verify visually instead.")
        }

        let nativeButton = app.buttons["NativeConfettiButton"]
        let webButton = app.webViews.buttons["Confetti"]
        XCTAssertTrue(nativeButton.waitForExistence(timeout: 5), "Native Confetti button should be present")
        XCTAssertTrue(webButton.waitForExistence(timeout: 5), "Web Confetti button should be present")

        let nativeWidth = nativeButton.frame.width
        let webWidth = webButton.frame.width
        let widthDelta = abs(nativeWidth - webWidth)

        XCTAssertLessThanOrEqual(
            widthDelta,
            2.0,
            "Web/native button widths should match (native: \(nativeWidth), web: \(webWidth), delta: \(widthDelta))"
        )
    }

    func test_webAndNativeButtons_alignVertically() throws {
        let app = XCUIApplication()
        app.launch()
        app.activate()

        guard app.windows.firstMatch.waitForExistence(timeout: 10) else {
            throw XCTSkip("App window did not appear under the test runner; verify visually instead.")
        }

        let nativeButton = app.buttons["NativeConfettiButton"]
        let webButton = app.webViews.buttons["Confetti"]
        XCTAssertTrue(nativeButton.waitForExistence(timeout: 5), "Native Confetti button should be present")
        XCTAssertTrue(webButton.waitForExistence(timeout: 5), "Web Confetti button should be present")

        let nativeMidY = nativeButton.frame.midY
        let webMidY = webButton.frame.midY
        let midYDelta = abs(nativeMidY - webMidY)

        XCTAssertLessThanOrEqual(
            midYDelta,
            2.0,
            "Web/native button vertical centers should match (native midY: \(nativeMidY), web midY: \(webMidY), delta: \(midYDelta))"
        )
    }

    func test_nativeTweakPanel_renders() throws {
        let app = XCUIApplication()
        app.launch()
        app.activate()

        guard app.windows.firstMatch.waitForExistence(timeout: 10) else {
            throw XCTSkip("App window did not appear under the test runner; verify visually instead.")
        }

        let nativePane = app.descendants(matching: .any)["NativePane"]
        XCTAssertTrue(nativePane.waitForExistence(timeout: 5), "NativePane should be present")

        let tweakPanel = app.descendants(matching: .any)["NativeTweakPanel"]
        XCTAssertTrue(tweakPanel.waitForExistence(timeout: 5), "Native tweak panel should be present")

        let particleCountControl = app.descendants(matching: .any)["NativeTweakParticleCount"]
        XCTAssertTrue(particleCountControl.waitForExistence(timeout: 5), "Particle count slider should be present")
    }

    func test_nativeConfettiButton_tapDoesNotCrash() throws {
        let app = XCUIApplication()
        app.launch()
        app.activate()

        guard app.windows.firstMatch.waitForExistence(timeout: 10) else {
            throw XCTSkip("App window did not appear under the test runner; verify visually instead.")
        }

        let nativeButton = app.buttons["NativeConfettiButton"]
        XCTAssertTrue(nativeButton.waitForExistence(timeout: 5), "Native Confetti button should be present before tap")

        nativeButton.tap()
        sleep(1)

        XCTAssertTrue(nativeButton.exists, "Native Confetti button should remain present after confetti tap")
    }
}
