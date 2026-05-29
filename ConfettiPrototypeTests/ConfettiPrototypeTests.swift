import XCTest

final class ConfettiPrototypeTests: XCTestCase {
    func test_webPane_tweakPanelUsesLightTheme() throws {
        let html = try loadBundledConfettiHTML()

        XCTAssertTrue(html.contains("<meta name=\"color-scheme\" content=\"light\">"))
        XCTAssertTrue(html.contains("color-scheme: light;"))
        XCTAssertTrue(html.contains(".tweak-panel {"))
        XCTAssertTrue(html.contains("background: #ffffff;"))
        XCTAssertTrue(html.contains("color: #1f2933;"))
        XCTAssertFalse(html.contains("background: rgba(9, 15, 18, 0.92);"))
    }

    func test_webPane_tweakPanelIsLeftColumnLayout() throws {
        let html = try loadBundledConfettiHTML()

        XCTAssertTrue(html.contains("body {"))
        XCTAssertTrue(html.contains("display: flex;"))
        XCTAssertTrue(html.contains("justify-content: flex-start;"))
        XCTAssertTrue(html.contains("flex: 0 0 50%;"))
        XCTAssertTrue(html.contains("padding: 36px 16px 20px;"))
        XCTAssertTrue(html.contains(".preview-column {"))
        XCTAssertTrue(html.contains("padding: 44px 24px;"))
        XCTAssertTrue(html.contains("<div class=\"preview-column\" id=\"preview-column\">"))
        XCTAssertFalse(html.contains("width: 280px;"))
        XCTAssertFalse(html.contains("position: fixed;"))
    }

    func test_contentView_allocatesEqualWidthPanes() throws {
        let contentViewSource = try loadRepoFile(relativePath: "ConfettiPrototype/ContentView.swift")

        XCTAssertTrue(contentViewSource.contains(".frame(maxWidth: .infinity, maxHeight: geo.size.height)"))
        XCTAssertFalse(contentViewSource.contains("let columnWidth = geo.size.width / 3"))
    }

    func test_webAndNativePreviewUseMatchingSizingConstants() throws {
        let html = try loadBundledConfettiHTML()
        let nativePaneSource = try loadRepoFile(relativePath: "ConfettiPrototype/NativePane.swift")

        XCTAssertTrue(html.contains("var VERTICAL_INSET = 44;"))
        XCTAssertTrue(html.contains("var PADDING = 0.925;"))
        XCTAssertTrue(html.contains("var availableHeight = Math.max(h - (VERTICAL_INSET * 2), 1);"))
        XCTAssertTrue(nativePaneSource.contains("private static let verticalInset: CGFloat = 44"))
        XCTAssertTrue(nativePaneSource.contains(") * 0.925"))
    }

    func test_webPane_tweakPanelControlsParticleSizeAndVariation() throws {
        let html = try loadBundledConfettiHTML()

        XCTAssertTrue(html.contains("id=\"setting-size\""))
        XCTAssertTrue(html.contains("id=\"setting-sizeVariation\""))
        XCTAssertTrue(html.contains("size: 1,"))
        XCTAssertTrue(html.contains("sizeVariation: 1,"))
        XCTAssertTrue(html.contains("var size = settings.size;"))
        XCTAssertTrue(html.contains("var sizeVariation = settings.sizeVariation;"))
        XCTAssertTrue(html.contains("var pieceSize = 6 * size + Math.random() * 6 * size * sizeVariation;"))
        XCTAssertTrue(html.contains("bindSetting('size',"))
        XCTAssertTrue(html.contains("bindSetting('sizeVariation',"))
    }

    func test_webPane_tweakPanelControlsFadeOutVariance() throws {
        let html = try loadBundledConfettiHTML()

        XCTAssertTrue(html.contains("id=\"setting-fadeOutVariance\""))
        XCTAssertTrue(html.contains("fadeOutVariance: 0.3,"))
        XCTAssertTrue(html.contains("var fadeOutVariance = settings.fadeOutVariance;"))
        XCTAssertTrue(html.contains("var fadeOutEnd = 1 - Math.random() * fadeOutVariance;"))
        XCTAssertTrue(html.contains("var fadeOutStart = Math.max(0, fadeOutEnd - 0.5);"))
        XCTAssertTrue(html.contains("opacityKeyframe = 0;"))
        XCTAssertTrue(html.contains("fadeOutEnd: fadeOutEnd,"))
        XCTAssertTrue(html.contains("bindSetting('fadeOutVariance',"))
    }

    func test_tweakPanelsControlAxisSpin() throws {
        let html = try loadBundledConfettiHTML()
        let nativeSettingsSource = try loadRepoFile(relativePath: "ConfettiPrototype/NativeConfettiSettings.swift")
        let nativePanelSource = try loadRepoFile(relativePath: "ConfettiPrototype/NativeTweakPanel.swift")
        let nativeBurstSource = try loadRepoFile(relativePath: "ConfettiPrototype/ConfettiBurstView.swift")

        XCTAssertTrue(html.contains("id=\"setting-xSpin\""))
        XCTAssertTrue(html.contains("id=\"setting-ySpin\""))
        XCTAssertTrue(html.contains("xSpin: 0,"))
        XCTAssertTrue(html.contains("ySpin: 1,"))
        XCTAssertTrue(html.contains("var xSpin = settings.xSpin;"))
        XCTAssertTrue(html.contains("var ySpin = settings.ySpin;"))
        XCTAssertTrue(html.contains("var rotateX = xTiltRotations * 360 * t;"))
        XCTAssertTrue(html.contains("rotateX(' + rotateX + 'deg) rotateY(' + rotateY + 'deg)"))
        XCTAssertTrue(html.contains("xTiltRotations: tiltRotations * xSpin,"))
        XCTAssertTrue(html.contains("tiltRotations: tiltRotations * ySpin,"))
        XCTAssertTrue(html.contains("bindSetting('xSpin',"))
        XCTAssertTrue(html.contains("bindSetting('ySpin',"))
        XCTAssertTrue(nativeSettingsSource.contains("@Published var xSpin: Double = 0"))
        XCTAssertTrue(nativeSettingsSource.contains("@Published var ySpin: Double = 1"))
        XCTAssertTrue(nativePanelSource.contains("sliderRow(title: \"xSpin\""))
        XCTAssertTrue(nativePanelSource.contains("sliderRow(title: \"ySpin\""))
        XCTAssertTrue(nativeBurstSource.contains("xTiltRotations: tiltRotations * settings.xSpin"))
        XCTAssertTrue(nativeBurstSource.contains("tiltRotations: tiltRotations * settings.ySpin"))
    }

    func test_webPane_tweakPanelControlsParticleColorFamilies() throws {
        let html = try loadBundledConfettiHTML()

        XCTAssertTrue(html.contains("Mandarin"))
        XCTAssertTrue(html.contains("Pondwater"))
        XCTAssertTrue(html.contains("Lilypad"))
        XCTAssertTrue(html.contains("Blossom"))
        XCTAssertTrue(html.contains("Pollen"))
        XCTAssertTrue(html.contains("mandarin: ['#F05F2B', '#CC3B0A', '#9E2B08']"))
        XCTAssertTrue(html.contains("pondwater: ['#4397E0', '#1074CC', '#045EB2']"))
        XCTAssertTrue(html.contains("lilypad: ['#589D88', '#247A64', '#11604D']"))
        XCTAssertTrue(html.contains("blossom: ['#9F6EB8', '#7D4794', '#682A7A']"))
        XCTAssertTrue(html.contains("pollen: ['#FAB341', '#F5A031', '#B66A1F']"))
        XCTAssertTrue(html.contains("data-color-family=\"mandarin\""))
        XCTAssertTrue(html.contains("data-color-family=\"pondwater\""))
        XCTAssertTrue(html.contains("data-color-family=\"lilypad\""))
        XCTAssertTrue(html.contains("data-color-family=\"blossom\""))
        XCTAssertTrue(html.contains("data-color-family=\"pollen\""))
        XCTAssertTrue(html.contains("function getActiveColors()"))
        XCTAssertTrue(html.contains("if (!enabledColorFamilies[familyName]) continue;"))
        XCTAssertTrue(html.contains("if (colors.length === 0) return;"))
    }

    func test_webPane_tweakPanelControlsParticleShapes() throws {
        let html = try loadBundledConfettiHTML()

        XCTAssertTrue(html.contains("<span>Circle</span>"))
        XCTAssertTrue(html.contains("<span>Rectangle</span>"))
        XCTAssertTrue(html.contains("<span>Strip</span>"))
        XCTAssertTrue(html.contains("<span>Star</span>"))
        XCTAssertTrue(html.contains("<span>Triangle</span>"))
        XCTAssertTrue(html.contains("data-shape=\"circle\""))
        XCTAssertTrue(html.contains("data-shape=\"rect\""))
        XCTAssertTrue(html.contains("data-shape=\"strip\""))
        XCTAssertTrue(html.contains("data-shape=\"star\""))
        XCTAssertTrue(html.contains("data-shape=\"triangle\""))
        XCTAssertTrue(html.contains("var enabledShapes = {"))
        XCTAssertTrue(html.contains("function getActiveShapes()"))
        XCTAssertTrue(html.contains("if (!enabledShapes[shape]) continue;"))
        XCTAssertTrue(html.contains("if (shapes.length === 0) return;"))
        XCTAssertTrue(html.contains("var shape = shapes[Math.floor(Math.random() * shapes.length)];"))
        XCTAssertTrue(html.contains("function getShapeBorderRadius(shape, width, height)"))
        XCTAssertTrue(html.contains("if (shape === 'strip') return '999px';"))
        XCTAssertTrue(html.contains("return Math.max(4, Math.min(width, height) * 0.5) + 'px';"))
        XCTAssertTrue(html.contains("function getShapeClipPath(shape)"))
        XCTAssertTrue(html.contains("if (shape === 'triangle') return 'polygon(50% 0%, 0% 100%, 100% 100%)';"))
        XCTAssertTrue(html.contains("node.style.webkitClipPath = clipPath;"))
    }

    func test_nativePane_hasExtraTopAndBottomPaddingLogic() throws {
        let nativePaneSource = try loadRepoFile(relativePath: "ConfettiPrototype/NativePane.swift")

        XCTAssertTrue(nativePaneSource.contains("private static let verticalInset: CGFloat = 44"))
        XCTAssertTrue(nativePaneSource.contains("let availableHeight = max(geo.size.height - (Self.verticalInset * 2), 1)"))
        XCTAssertTrue(nativePaneSource.contains("availableHeight / Self.stageHeight"))
    }

    private func loadBundledConfettiHTML() throws -> String {
        let appBundle = Bundle.main
        guard let htmlURL = appBundle.url(forResource: "confetti", withExtension: "html") else {
            XCTFail("Bundled confetti.html not found in app bundle: \(appBundle.bundlePath)")
            throw NSError(domain: "ConfettiPrototypeTests", code: 1)
        }
        return try String(contentsOf: htmlURL, encoding: .utf8)
    }

    private func loadRepoFile(relativePath: String) throws -> String {
        let sourceFileURL = URL(fileURLWithPath: #filePath)
        let repoRootURL = sourceFileURL
            .deletingLastPathComponent() // ConfettiPrototypeTests
            .deletingLastPathComponent() // repo root
        let targetURL = repoRootURL.appendingPathComponent(relativePath)
        return try String(contentsOf: targetURL, encoding: .utf8)
    }
}
