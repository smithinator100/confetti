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
    // How long particles stay behind the hero (the initial pop) before
    // moving to the front layer to rain down in front of it.
    // How long the hero cover stays up (the initial pop) before it is removed
    // so the confetti rains down in front of the pictogram.
    private static let frontTransitionDelay: TimeInterval = 0.2

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

        for _ in 0..<settings.particleCount {
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
                  let variant = ConfettiShapeArt.randomVariant(for: shape) else { continue }

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

            let particleLayer = makeParticleLayer(
                variant: variant,
                fillColor: NSColor(shade.fill).cgColor,
                strokeColor: NSColor(shade.stroke).cgColor,
                size: pieceSize
            )
            particleLayer.frame = CGRect(
                x: Self.emissionPoint.x,
                y: Self.emissionPoint.y,
                width: pieceSize,
                height: pieceSize
            )
            particleContainer.addSublayer(particleLayer)

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

            DispatchQueue.main.asyncAfter(deadline: .now() + settings.duration + 0.5) {
                particleLayer.removeFromSuperlayer()
            }
        }
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

    private func makeParticleLayer(variant: ConfettiShapeVariant, fillColor: CGColor, strokeColor: CGColor, size: Double) -> CALayer {
        let side = CGFloat(size)
        let bounds = CGRect(x: 0, y: 0, width: side, height: side)

        guard let shapePaths = ConfettiShapeArt.paths(for: variant, in: bounds) else {
            let fallback = CALayer()
            fallback.backgroundColor = fillColor
            fallback.cornerRadius = side / 2
            return fallback
        }

        let container = CALayer()
        container.bounds = bounds

        let fillLayer = CAShapeLayer()
        fillLayer.path = shapePaths.fill
        fillLayer.fillColor = fillColor

        let strokeLayer = CAShapeLayer()
        strokeLayer.path = shapePaths.stroke
        strokeLayer.fillColor = strokeColor

        if variant.clipStrokeToFill {
            let clipMask = CAShapeLayer()
            clipMask.path = shapePaths.fill
            clipMask.fillColor = NSColor.black.cgColor
            strokeLayer.mask = clipMask
        }

        container.addSublayer(fillLayer)
        container.addSublayer(strokeLayer)
        return container
    }
}
