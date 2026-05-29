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
        if activeShapes.isEmpty { return }

        let activeColors = settings.enabledColorFamilies
            .compactMap { NativeConfettiSettings.colorFamilies[$0] }
            .flatMap { $0 }
            .map { NSColor($0) }
        if activeColors.isEmpty { return }

        let ticks = Int(round(settings.duration * 60))

        coverGeneration += 1
        let generation = coverGeneration
        heroCoverLayer.isHidden = false
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
            let tiltRotations = 2 + Double.random(in: 0...4)
            let rotation = Double.random(in: 0...360)
            let fadeOutEnd = 1 - Double.random(in: 0...settings.fadeOutVariance)

            guard let shape = activeShapes.randomElement(),
                  let color = activeColors.randomElement() else { continue }

            let keyframes = ConfettiPhysics.computeKeyframes(
                .init(
                    angle: angle,
                    startVelocity: velocity,
                    decay: settings.decay,
                    gravity: settings.gravity,
                    drift: 0,
                    wobbleSpeed: wobbleSpeed,
                    wobbleOffset: wobbleOffset,
                    size: settings.size,
                    ticks: ticks,
                    xTiltRotations: tiltRotations * settings.xSpin,
                    tiltRotations: tiltRotations * settings.ySpin,
                    rotation: rotation,
                    fadeOutEnd: fadeOutEnd
                )
            )

            let width = shape == .strip ? pieceSize * 0.3 : shape == .rect ? pieceSize * 0.7 : pieceSize
            let height = shape == .strip ? pieceSize * 2 : pieceSize
            let particleLayer = makeParticleLayer(shape: shape, color: color.cgColor, width: width, height: height)
            particleLayer.frame = CGRect(
                x: Self.emissionPoint.x,
                y: Self.emissionPoint.y,
                width: width,
                height: height
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

    private func makeParticleLayer(shape: ConfettiShape, color: CGColor, width: Double, height: Double) -> CALayer {
        if shape == .circle {
            let layer = CAShapeLayer()
            layer.path = blobPath(width: width, height: height)
            layer.fillColor = color
            return layer
        }

        if shape == .star {
            let layer = CAShapeLayer()
            layer.path = starPath(width: width, height: height)
            layer.fillColor = color
            return layer
        }

        if shape == .triangle {
            let layer = CAShapeLayer()
            layer.path = trianglePath(width: width, height: height)
            layer.fillColor = color
            return layer
        }

        let layer = CALayer()
        layer.backgroundColor = color
        if shape == .strip {
            layer.cornerRadius = CGFloat(min(width, height) / 2)
        } else {
            layer.cornerRadius = CGFloat(max(4, min(width, height) * 0.5))
        }
        return layer
    }

    private func blobPath(width: Double, height: Double) -> CGPath {
        let points = [
            CGPoint(x: 0.5, y: 0.0),
            CGPoint(x: 0.69, y: 0.08),
            CGPoint(x: 0.92, y: 0.24),
            CGPoint(x: 1.0, y: 0.49),
            CGPoint(x: 0.86, y: 0.76),
            CGPoint(x: 0.63, y: 0.97),
            CGPoint(x: 0.38, y: 0.94),
            CGPoint(x: 0.13, y: 0.82),
            CGPoint(x: 0.02, y: 0.58),
            CGPoint(x: 0.09, y: 0.29),
            CGPoint(x: 0.28, y: 0.07),
        ]
        let path = CGMutablePath()
        for (index, point) in points.enumerated() {
            let mapped = CGPoint(x: point.x * width, y: point.y * height)
            if index == 0 {
                path.move(to: mapped)
            } else {
                path.addLine(to: mapped)
            }
        }
        path.closeSubpath()
        return path
    }

    private func starPath(width: Double, height: Double) -> CGPath {
        let points = [
            CGPoint(x: 0.5, y: 0.0),
            CGPoint(x: 0.61, y: 0.35),
            CGPoint(x: 0.98, y: 0.35),
            CGPoint(x: 0.68, y: 0.56),
            CGPoint(x: 0.79, y: 0.91),
            CGPoint(x: 0.5, y: 0.7),
            CGPoint(x: 0.21, y: 0.91),
            CGPoint(x: 0.32, y: 0.56),
            CGPoint(x: 0.02, y: 0.35),
            CGPoint(x: 0.39, y: 0.35),
        ]
        let path = CGMutablePath()
        for (index, point) in points.enumerated() {
            let mapped = CGPoint(x: point.x * width, y: point.y * height)
            if index == 0 {
                path.move(to: mapped)
            } else {
                path.addLine(to: mapped)
            }
        }
        path.closeSubpath()
        return path
    }

    private func trianglePath(width: Double, height: Double) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}
