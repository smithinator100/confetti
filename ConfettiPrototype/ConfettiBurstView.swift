import SwiftUI
import AppKit
import QuartzCore

struct ConfettiBurstView: NSViewRepresentable {
    @ObservedObject var settings: NativeConfettiSettings
    let burstID: Int

    func makeNSView(context: Context) -> ConfettiBurstHostView {
        ConfettiBurstHostView()
    }

    func updateNSView(_ nsView: ConfettiBurstHostView, context: Context) {
        nsView.currentSettings = settings.snapshot
        if nsView.lastBurstID != burstID {
            nsView.lastBurstID = burstID
            nsView.performBurst()
        }
    }
}

final class ConfettiBurstHostView: NSView {
    private static let emissionPoint = CGPoint(x: 201, y: 192)
    private static let stageCornerRadius: CGFloat = 56
    private static let heroFrame = CGRect(x: 147, y: 138, width: 108, height: 108)
    private static let rasterPixelSize: CGFloat = 96
    // How long particles stay behind the hero (the initial pop) before
    // moving to the front layer to rain down in front of it.
    // How long the hero cover stays up (the initial pop) before it is removed
    // so the confetti rains down in front of the pictogram.
    private static let frontTransitionDelay: TimeInterval = 0.2
    // Build + animate this many particles per frame so no single frame absorbs
    // the whole spawn cost (the burst-start min-FPS spike). Mirrors the web
    // SPAWN_CHUNK in confetti.html.
    private static let spawnChunkSize = 20

    var currentSettings: NativeConfettiSettingsSnapshot = NativeConfettiSettings().snapshot
    var lastBurstID: Int = 0

    // Particles always live in front of the hero. heroCoverLayer is an identical
    // pictogram shown on top during the initial pop so the burst reads as coming
    // from behind it, then hidden so the rain falls in front. heroLayer underneath
    // stays visible throughout.
    private let heroLayer = CALayer()
    private let particleContainer = CALayer()
    private let heroCoverLayer = CALayer()
    private let heroPulseAnimationKey = "hero-pulse"
    private var coverGeneration = 0
    private var activeParticleLayers: [CALayer] = []
    private var removalWorkItem: DispatchWorkItem?
    private var particleBitmapCache: [String: CGImage] = [:]

    // In-flight chunked spawn state. spawnWorkItem is the next scheduled chunk
    // so a re-fire can cancel it (mirrors the web spawnHandle).
    private var spawnWorkItem: DispatchWorkItem?
    private var spawnRemaining = 0
    private var spawnSettings: NativeConfettiSettingsSnapshot?
    private var spawnShapes: [ConfettiShape] = []
    private var spawnShades: [ConfettiShade] = []
    private var spawnTicks = 0

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = Self.stageCornerRadius

        for hero in [heroLayer, heroCoverLayer] {
            hero.frame = Self.heroFrame
            hero.contentsGravity = .resizeAspect
            hero.contentsScale = 3
            hero.contents = Self.heroImage
        }
        heroCoverLayer.isHidden = true

        layer?.addSublayer(heroLayer)
        layer?.addSublayer(particleContainer)
        layer?.addSublayer(heroCoverLayer)

        prewarmParticleBitmaps()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        layer?.masksToBounds = true
        layer?.cornerRadius = Self.stageCornerRadius

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        particleContainer.frame = bounds
        for hero in [heroLayer, heroCoverLayer] {
            hero.frame = Self.heroFrame
            hero.transform = CATransform3DIdentity
        }
        CATransaction.commit()
    }

    func performBurst() {
        let settings = currentSettings
        let activeShapes = NativeConfettiSettings.weightedShapes.filter { settings.enabledShapes.contains($0) }
        if activeShapes.isEmpty {
            pulseHero(to: settings.pictogramScaleSize, duration: settings.pictogramScaleDuration)
            return
        }

        let activeShades = settings.enabledColorFamilies
            .compactMap { NativeConfettiSettings.colorFamilies[$0] }
            .flatMap { $0 }
        if activeShades.isEmpty {
            pulseHero(to: settings.pictogramScaleSize, duration: settings.pictogramScaleDuration)
            return
        }

        removalWorkItem?.cancel()
        removalWorkItem = nil
        spawnWorkItem?.cancel()
        spawnWorkItem = nil
        spawnRemaining = 0
        activeParticleLayers.forEach { $0.removeFromSuperlayer() }
        activeParticleLayers.removeAll(keepingCapacity: true)

        let ticks = Int(round(settings.duration * 60))

        coverGeneration += 1
        let generation = coverGeneration
        heroCoverLayer.isHidden = false
        pulseHero(to: settings.pictogramScaleSize, duration: settings.pictogramScaleDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.frontTransitionDelay) { [weak self] in
            guard let self, self.coverGeneration == generation else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.heroCoverLayer.isHidden = true
            CATransaction.commit()
        }

        // Spread the spawn across frames (see spawnChunkSize). Mirrors the web
        // confetti's chunked, frame-aligned spawn so the burst start doesn't
        // block one frame building + animating every particle at once.
        spawnSettings = settings
        spawnShapes = activeShapes
        spawnShades = activeShades
        spawnTicks = ticks
        spawnRemaining = settings.particleCount
        scheduleSpawnChunk()
    }

    private func scheduleSpawnChunk() {
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.spawnWorkItem = nil
            self.runSpawnChunk()
        }
        spawnWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 60.0, execute: work)
    }

    private func runSpawnChunk() {
        guard let settings = spawnSettings, spawnRemaining > 0 else { return }
        let count = min(Self.spawnChunkSize, spawnRemaining)
        for _ in 0..<count {
            spawnParticle(settings: settings, activeShapes: spawnShapes, activeShades: spawnShades, ticks: spawnTicks)
        }
        spawnRemaining -= count

        if spawnRemaining > 0 {
            scheduleSpawnChunk()
            return
        }

        let layersToRemove = activeParticleLayers
        let workItem = DispatchWorkItem { [weak self] in
            layersToRemove.forEach { $0.removeFromSuperlayer() }
            guard let self else { return }
            if self.activeParticleLayers.elementsEqual(layersToRemove, by: { $0 === $1 }) {
                self.activeParticleLayers.removeAll(keepingCapacity: true)
            }
            self.removalWorkItem = nil
        }
        removalWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + settings.duration + 0.5, execute: workItem)
    }

    private func spawnParticle(
        settings: NativeConfettiSettingsSnapshot,
        activeShapes: [ConfettiShape],
        activeShades: [ConfettiShade],
        ticks: Int
    ) {
        let spreadRadians = settings.spread * (.pi / 180)
        let angle = -Double.pi / 2 + (0.5 * spreadRadians - Double.random(in: 0...spreadRadians))
        let velocity = settings.startVelocity * 0.5 + Double.random(in: 0...settings.startVelocity)
        let wobbleSpeed = min(0.11, Double.random(in: 0...0.1) + 0.05)
        let wobbleOffset = Double.random(in: 0...10)
        let pieceSize = 6 * settings.size + Double.random(in: 0...(6 * settings.size * settings.sizeVariation))
        let sizeDepth = pieceSize / max(6 * settings.size, 1)
        let depthGravity = settings.gravity * (1 + (sizeDepth - 1) * 0.35)
        let tiltRotations = 2 + Double.random(in: 0...4)
        let rotation = Double.random(in: 0...360)
        let fadeOutEnd = 1 - Double.random(in: 0...settings.fadeOutVariance)

        guard let shape = activeShapes.randomElement(),
              let shade = activeShades.randomElement(),
              let variant = ConfettiShapeArt.randomVariant(for: shape) else { return }

        let keyframes = ConfettiPhysics.computeKeyframes(
            .init(
                angle: angle,
                startVelocity: velocity,
                decay: settings.decay,
                gravity: depthGravity,
                drift: 0,
                wobbleSpeed: wobbleSpeed,
                wobbleOffset: wobbleOffset,
                size: settings.size,
                ticks: ticks,
                xTiltRotations: tiltRotations * settings.xSpin,
                tiltRotations: tiltRotations * settings.ySpin,
                zTiltRotations: tiltRotations * settings.zSpin,
                rotation: rotation,
                fadeOutEnd: fadeOutEnd
            )
        )

        let particleLayer = makeParticleLayer(shape: shape, variant: variant, shade: shade, size: pieceSize)
        particleLayer.frame = CGRect(
            x: Self.emissionPoint.x,
            y: Self.emissionPoint.y,
            width: pieceSize,
            height: pieceSize
        )
        particleContainer.addSublayer(particleLayer)
        activeParticleLayers.append(particleLayer)

        let keyTimes = (0...ConfettiPhysics.keyframeSteps).map { NSNumber(value: Double($0) / Double(ConfettiPhysics.keyframeSteps)) }

        let transformAnimation = CAKeyframeAnimation(keyPath: "transform")
        transformAnimation.values = keyframes.transforms.map { NSValue(caTransform3D: $0) }
        transformAnimation.keyTimes = keyTimes

        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = keyframes.opacities.map(NSNumber.init(value:))
        opacityAnimation.keyTimes = keyTimes

        let group = CAAnimationGroup()
        group.animations = [transformAnimation, opacityAnimation]
        group.duration = settings.duration
        group.timingFunction = CAMediaTimingFunction(name: .linear)
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards
        particleLayer.add(group, forKey: "burst")
    }

    private func pulseHero(to scale: Double, duration: Double) {
        let scale = max(1, scale)
        let duration = max(0.1, duration)
        for hero in [heroLayer, heroCoverLayer] {
            hero.removeAnimation(forKey: heroPulseAnimationKey)

            let animation = CAKeyframeAnimation(keyPath: "transform.scale")
            animation.values = [1, scale, 1]
            animation.keyTimes = [0, 0.35, 1].map(NSNumber.init(value:))
            animation.duration = duration
            animation.timingFunctions = [
                CAMediaTimingFunction(name: .easeOut),
                CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1),
            ]
            animation.isRemovedOnCompletion = true

            hero.add(animation, forKey: heroPulseAnimationKey)
        }
    }

    private static let heroImage: CGImage? = {
        guard let url = Bundle.main.url(forResource: "subscription-check-hero", withExtension: "svg"),
              let nsImage = NSImage(contentsOf: url) else {
            return nil
        }
        let points = 108
        let scale = 3
        let pixels = points * scale
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixels,
            pixelsHigh: pixels,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }
        rep.size = NSSize(width: points, height: points)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        nsImage.draw(in: NSRect(x: 0, y: 0, width: points, height: points))
        NSGraphicsContext.restoreGraphicsState()
        return rep.cgImage
    }()

    private func makeParticleLayer(shape: ConfettiShape, variant: ConfettiShapeVariant, shade: ConfettiShade, size: Double) -> CALayer {
        let side = CGFloat(size)
        let bounds = CGRect(x: 0, y: 0, width: side, height: side)
        let particleLayer = CALayer()
        particleLayer.bounds = bounds
        particleLayer.contentsGravity = .resize
        particleLayer.contentsScale = 3

        if let bitmap = particleBitmap(for: shape, variant: variant, shade: shade) {
            particleLayer.contents = bitmap
            return particleLayer
        }

        particleLayer.backgroundColor = NSColor(shade.fill).cgColor
        particleLayer.cornerRadius = side / 2
        return particleLayer
    }

    // Rasterize every shape+variant+shade combination once at init so the
    // expensive CGContext path fill never lands on a burst frame. Mirrors the
    // web prewarmParticleBitmaps().
    private func prewarmParticleBitmaps() {
        for (shape, variants) in ConfettiShapeArt.variants {
            for variant in variants {
                for shades in NativeConfettiSettings.colorFamilies.values {
                    for shade in shades {
                        _ = particleBitmap(for: shape, variant: variant, shade: shade)
                    }
                }
            }
        }
    }

    private func particleBitmap(for shape: ConfettiShape, variant: ConfettiShapeVariant, shade: ConfettiShade) -> CGImage? {
        let fillColor = NSColor(shade.fill).cgColor
        let strokeColor = NSColor(shade.stroke).cgColor
        let key = [
            shape.rawValue,
            variant.fillPath,
            variant.strokePath,
            String(describing: fillColor),
            String(describing: strokeColor),
        ].joined(separator: "|")
        if let cached = particleBitmapCache[key] { return cached }

        let drawRect = CGRect(x: 0, y: 0, width: Self.rasterPixelSize, height: Self.rasterPixelSize)
        guard let shapePaths = ConfettiShapeArt.paths(for: variant, in: drawRect) else { return nil }
        guard let context = CGContext(
            data: nil,
            width: Int(Self.rasterPixelSize),
            height: Int(Self.rasterPixelSize),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.setFillColor(fillColor)
        context.addPath(shapePaths.fill)
        context.fillPath()

        context.setFillColor(strokeColor)
        if variant.clipStrokeToFill {
            context.saveGState()
            context.addPath(shapePaths.fill)
            context.clip()
            context.addPath(shapePaths.stroke)
            context.fillPath()
            context.restoreGState()
        } else {
            context.addPath(shapePaths.stroke)
            context.fillPath()
        }

        guard let image = context.makeImage() else { return nil }
        particleBitmapCache[key] = image
        return image
    }
}
