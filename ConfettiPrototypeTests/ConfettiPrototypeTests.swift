import XCTest
@testable import ConfettiPrototype

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
        XCTAssertTrue(html.contains("flex: 0 0 300px;"))
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
        XCTAssertTrue(html.contains("id=\"setting-size\" type=\"range\" min=\"0.5\" max=\"3\""))
        XCTAssertTrue(html.contains("size: 3,"))
        XCTAssertTrue(html.contains("sizeVariation: 1.6,"))
        XCTAssertTrue(html.contains("var size = settings.size;"))
        XCTAssertTrue(html.contains("var sizeVariation = settings.sizeVariation;"))
        XCTAssertTrue(html.contains("var pieceSize = 6 * size + Math.random() * 6 * size * sizeVariation;"))
        XCTAssertTrue(html.contains("var sizeDepth = pieceSize / Math.max(6 * size, 1);"))
        XCTAssertTrue(html.contains("var depthGravity = gravity * (1 + (sizeDepth - 1) * 0.35);"))
        XCTAssertTrue(html.contains("gravity: depthGravity,"))
        XCTAssertTrue(html.contains("bindSetting('size',"))
        XCTAssertTrue(html.contains("bindSetting('sizeVariation',"))
    }

    func test_nativePane_tweakPanelControlsParticleDepthSize() throws {
        let nativePanelSource = try loadRepoFile(relativePath: "ConfettiPrototype/NativeTweakPanel.swift")
        let nativeBurstSource = try loadRepoFile(relativePath: "ConfettiPrototype/ConfettiBurstView.swift")

        XCTAssertTrue(nativePanelSource.contains("Slider(value: $settings.size, in: 0.5...3, step: 0.1)"))
        XCTAssertTrue(nativeBurstSource.contains("let sizeDepth = pieceSize / max(6 * settings.size, 1)"))
        XCTAssertTrue(nativeBurstSource.contains("let depthGravity = settings.gravity * (1 + (sizeDepth - 1) * 0.35)"))
        XCTAssertTrue(nativeBurstSource.contains("gravity: depthGravity,"))
    }

    func test_tweakPanelsControlPictogramPulseScale() throws {
        let html = try loadBundledConfettiHTML()
        let nativeSettingsSource = try loadRepoFile(relativePath: "ConfettiPrototype/NativeConfettiSettings.swift")
        let nativePanelSource = try loadRepoFile(relativePath: "ConfettiPrototype/NativeTweakPanel.swift")
        let nativeBurstSource = try loadRepoFile(relativePath: "ConfettiPrototype/ConfettiBurstView.swift")

        XCTAssertTrue(html.contains("id=\"setting-pictogramScaleSize\""))
        XCTAssertTrue(html.contains("id=\"setting-pictogramScaleDuration\""))
        XCTAssertTrue(html.contains("pictogramScaleSize: 1.1,"))
        XCTAssertTrue(html.contains("pictogramScaleDuration: 0.6,"))
        XCTAssertTrue(html.contains("function pulseHero()"))
        XCTAssertTrue(html.contains("settings.pictogramScaleSize"))
        XCTAssertTrue(html.contains("settings.pictogramScaleDuration"))
        XCTAssertTrue(html.contains("cubic-bezier(0.16, 1, 0.3, 1)"))
        XCTAssertTrue(html.contains("bindSetting('pictogramScaleSize',"))
        XCTAssertTrue(html.contains("bindSetting('pictogramScaleDuration',"))
        XCTAssertTrue(nativeSettingsSource.contains("@Published var pictogramScaleSize: Double = 1.1"))
        XCTAssertTrue(nativeSettingsSource.contains("@Published var pictogramScaleDuration: Double = 0.6"))
        XCTAssertTrue(nativePanelSource.contains("sliderRow(title: \"pictogramScaleSize\""))
        XCTAssertTrue(nativePanelSource.contains("sliderRow(title: \"pictogramScaleDuration\""))
        XCTAssertTrue(nativePanelSource.contains("NativeTweakPictogramScaleSize"))
        XCTAssertTrue(nativePanelSource.contains("NativeTweakPictogramScaleDuration"))
        XCTAssertTrue(nativeBurstSource.contains("pulseHero(to: settings.pictogramScaleSize, duration: settings.pictogramScaleDuration)"))
        XCTAssertTrue(nativeBurstSource.contains("CAKeyframeAnimation(keyPath: \"transform.scale\")"))
        XCTAssertTrue(nativeBurstSource.contains("CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1)"))
    }

    func test_webPane_tweakPanelControlsFadeOutVariance() throws {
        let html = try loadBundledConfettiHTML()

        XCTAssertTrue(html.contains("id=\"setting-gravity\""))
        XCTAssertTrue(html.contains("gravity: 1.4,"))
        XCTAssertTrue(html.contains("id=\"setting-fadeOutVariance\""))
        XCTAssertTrue(html.contains("fadeOutVariance: 0.6,"))
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
        XCTAssertTrue(html.contains("id=\"setting-zSpin\""))
        XCTAssertTrue(html.contains("xSpin: 0,"))
        XCTAssertTrue(html.contains("ySpin: 0,"))
        XCTAssertTrue(html.contains("zSpin: 0.2,"))
        XCTAssertTrue(html.contains("var xSpin = settings.xSpin;"))
        XCTAssertTrue(html.contains("var ySpin = settings.ySpin;"))
        XCTAssertTrue(html.contains("var zSpin = settings.zSpin;"))
        XCTAssertTrue(html.contains("var rotateX = xTiltRotations * 360 * t;"))
        XCTAssertTrue(html.contains("var rotateZ = zTiltRotations * 360 * t + rotation;"))
        XCTAssertTrue(html.contains("rotateX(' + rotateX + 'deg) rotateY(' + rotateY + 'deg) rotate(' + rotateZ + 'deg)'"))
        XCTAssertTrue(html.contains("xTiltRotations: tiltRotations * xSpin,"))
        XCTAssertTrue(html.contains("tiltRotations: tiltRotations * ySpin,"))
        XCTAssertTrue(html.contains("zTiltRotations: tiltRotations * zSpin,"))
        XCTAssertTrue(html.contains("bindSetting('xSpin',"))
        XCTAssertTrue(html.contains("bindSetting('ySpin',"))
        XCTAssertTrue(html.contains("bindSetting('zSpin',"))
        XCTAssertTrue(nativeSettingsSource.contains("@Published var xSpin: Double = 0"))
        XCTAssertTrue(nativeSettingsSource.contains("@Published var ySpin: Double = 0"))
        XCTAssertTrue(nativeSettingsSource.contains("@Published var zSpin: Double = 0.2"))
        XCTAssertTrue(nativePanelSource.contains("sliderRow(title: \"xSpin\""))
        XCTAssertTrue(nativePanelSource.contains("sliderRow(title: \"ySpin\""))
        XCTAssertTrue(nativePanelSource.contains("sliderRow(title: \"zSpin\""))
        XCTAssertTrue(nativeBurstSource.contains("xTiltRotations: tiltRotations * settings.xSpin"))
        XCTAssertTrue(nativeBurstSource.contains("tiltRotations: tiltRotations * settings.ySpin"))
        XCTAssertTrue(nativeBurstSource.contains("zTiltRotations: tiltRotations * settings.zSpin"))
    }

    func test_defaultConfettiSettings_matchTunedProfile() throws {
        let html = try loadBundledConfettiHTML()
        let nativeSettings = NativeConfettiSettings()
        let snapshot = nativeSettings.snapshot

        XCTAssertEqual(snapshot.particleCount, 60)
        XCTAssertEqual(snapshot.startVelocity, 33)
        XCTAssertEqual(snapshot.spread, 96)
        XCTAssertEqual(snapshot.decay, 0.92)
        XCTAssertEqual(snapshot.gravity, 1.4)
        XCTAssertEqual(snapshot.duration, 5)
        XCTAssertEqual(snapshot.fadeOutVariance, 0.6)
        XCTAssertEqual(snapshot.xSpin, 0)
        XCTAssertEqual(snapshot.ySpin, 0)
        XCTAssertEqual(snapshot.zSpin, 0.2)
        XCTAssertEqual(snapshot.size, 3)
        XCTAssertEqual(snapshot.sizeVariation, 1.6)
        XCTAssertEqual(snapshot.pictogramScaleSize, 1.1)
        XCTAssertEqual(snapshot.pictogramScaleDuration, 0.6)
        XCTAssertEqual(snapshot.enabledShapes, [.star, .blob, .rect])
        XCTAssertEqual(snapshot.enabledColorFamilies, [.mandarin, .blossom, .pollen])

        XCTAssertTrue(html.contains("particleCount: 60,"))
        XCTAssertTrue(html.contains("startVelocity: 33,"))
        XCTAssertTrue(html.contains("decay: 0.92,"))
        XCTAssertTrue(html.contains("gravity: 1.4,"))
        XCTAssertTrue(html.contains("duration: 5,"))
        XCTAssertTrue(html.contains("zSpin: 0.2,"))
        XCTAssertTrue(html.contains("size: 3,"))
        XCTAssertTrue(html.contains("sizeVariation: 1.6,"))
        XCTAssertTrue(html.contains("pictogramScaleSize: 1.1,"))
        XCTAssertTrue(html.contains("pictogramScaleDuration: 0.6,"))
        XCTAssertTrue(html.contains("pondwater: false,"))
        XCTAssertTrue(html.contains("lilypad: false,"))
        XCTAssertTrue(html.contains("strip: false,"))
    }

    func test_webPane_tweakPanelControlsParticleColorFamilies() throws {
        let html = try loadBundledConfettiHTML()

        XCTAssertTrue(html.contains("Mandarin"))
        XCTAssertTrue(html.contains("Pondwater"))
        XCTAssertTrue(html.contains("Lilypad"))
        XCTAssertTrue(html.contains("Blossom"))
        XCTAssertTrue(html.contains("Pollen"))
        XCTAssertTrue(html.contains("{ fill: '#F05F2B', stroke: '#9E2B08' }"))
        XCTAssertTrue(html.contains("{ fill: '#FF8D5C', stroke: '#CC3B0A' }"))
        XCTAssertTrue(html.contains("{ fill: '#FFB294', stroke: '#F05F2B' }"))
        XCTAssertTrue(html.contains("{ fill: '#4397E0', stroke: '#045EB2' }"))
        XCTAssertTrue(html.contains("{ fill: '#75B6EB', stroke: '#1074CC' }"))
        XCTAssertTrue(html.contains("{ fill: '#A1D0F7', stroke: '#4397E0' }"))
        XCTAssertTrue(html.contains("{ fill: '#589D88', stroke: '#11604D' }"))
        XCTAssertTrue(html.contains("{ fill: '#84BBA8', stroke: '#247A64' }"))
        XCTAssertTrue(html.contains("{ fill: '#AED5C2', stroke: '#589D88' }"))
        XCTAssertTrue(html.contains("{ fill: '#9F6EB8', stroke: '#682A7A' }"))
        XCTAssertTrue(html.contains("{ fill: '#C19EDB', stroke: '#7D4794' }"))
        XCTAssertTrue(html.contains("{ fill: '#D3B9EB', stroke: '#9F6EB8' }"))
        XCTAssertTrue(html.contains("{ fill: '#FAB341', stroke: '#B66A1F' }"))
        XCTAssertTrue(html.contains("{ fill: '#FFC95C', stroke: '#F5A031' }"))
        XCTAssertTrue(html.contains("{ fill: '#FFD885', stroke: '#FAB341' }"))
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

        XCTAssertTrue(html.contains("<span>Star</span>"))
        XCTAssertTrue(html.contains("<span>Blob</span>"))
        XCTAssertTrue(html.contains("<span>Rectangle</span>"))
        XCTAssertTrue(html.contains("<span>Strip</span>"))
        XCTAssertTrue(html.contains("data-shape=\"rect\""))
        XCTAssertTrue(html.contains("data-shape=\"strip\""))
        XCTAssertTrue(html.contains("data-shape=\"star\""))
        XCTAssertTrue(html.contains("data-shape=\"blob\""))
        XCTAssertTrue(html.contains("var enabledShapes = {"))
        XCTAssertTrue(html.contains("var SHAPE_VARIANTS = JSON.parse("))
        XCTAssertTrue(html.contains("function getActiveShapes()"))
        XCTAssertTrue(html.contains("if (!enabledShapes[shape]) continue;"))
        XCTAssertTrue(html.contains("if (shapes.length === 0) return;"))
        XCTAssertTrue(html.contains("var shape = shapes[Math.floor(Math.random() * shapes.length)];"))
        XCTAssertTrue(html.contains("node.style.setProperty('--fill-0', color.fill);"))
        XCTAssertTrue(html.contains("node.style.setProperty('--stroke-0', color.stroke);"))
        XCTAssertTrue(html.contains("node.innerHTML = createShapeSVG(variant, particleSerial);"))
        XCTAssertTrue(html.contains("function createShapeSVG(variant, serial)"))
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
