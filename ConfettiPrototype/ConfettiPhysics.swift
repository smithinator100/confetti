import Foundation
import QuartzCore

enum ConfettiPhysics {
    static let keyframeSteps = 40
    static let scaleDurationFraction = 0.08

    struct Input {
        let angle: Double
        let startVelocity: Double
        let decay: Double
        let gravity: Double
        let drift: Double
        let wobbleSpeed: Double
        let wobbleOffset: Double
        let size: Double
        let ticks: Int
        let xTiltRotations: Double
        let tiltRotations: Double
        let zTiltRotations: Double
        let rotation: Double
        let fadeOutEnd: Double
    }

    struct Output {
        let transforms: [CATransform3D]
        let opacities: [Float]
    }

    static func computeKeyframes(_ input: Input) -> Output {
        let fadeOutStart = max(0, input.fadeOutEnd - 0.5)
        let fadeOutMid = fadeOutStart + (input.fadeOutEnd - fadeOutStart) * 0.6
        var transforms: [CATransform3D] = []
        var opacities: [Float] = []

        var velocity = input.startVelocity
        var x = 0.0
        var y = 0.0
        var wobble = input.wobbleOffset
        var tick = 0

        for step in 0...keyframeSteps {
            let t = Double(step) / Double(keyframeSteps)

            if step > 0 {
                let targetTick = Int(round((Double(step) * Double(input.ticks)) / Double(keyframeSteps)))
                while tick < targetTick {
                    x += cos(input.angle) * velocity + input.drift
                    y += sin(input.angle) * velocity + input.gravity * 3
                    velocity *= input.decay
                    wobble += input.wobbleSpeed
                    tick += 1
                }
            }

            let wx = step == 0 ? 0 : x + cos(wobble) * 15 * input.size
            let wy = y
            let scale = computeScale(progress: t)
            let rotateX = degreesToRadians(input.xTiltRotations * 360 * t)
            let rotateY = degreesToRadians(input.tiltRotations * 360 * t)
            let rotateZ = degreesToRadians(input.rotation + input.zTiltRotations * 360 * t)
            let opacity = computeOpacity(
                progress: t,
                fadeOutStart: fadeOutStart,
                fadeOutMid: fadeOutMid,
                fadeOutEnd: input.fadeOutEnd
            )

            var transform = CATransform3DIdentity
            transform = CATransform3DTranslate(transform, wx, wy, 0)
            transform = CATransform3DScale(transform, scale, scale, 1)
            transform = CATransform3DRotate(transform, rotateX, 1, 0, 0)
            transform = CATransform3DRotate(transform, rotateY, 0, 1, 0)
            transform = CATransform3DRotate(transform, rotateZ, 0, 0, 1)
            transform.m34 = -1.0 / 500.0

            transforms.append(transform)
            opacities.append(Float(opacity))
        }

        return Output(transforms: transforms, opacities: opacities)
    }

    private static func computeScale(progress: Double) -> Double {
        let earlyGrow = scaleDurationFraction * 0.6
        if progress < earlyGrow {
            return (progress / earlyGrow) * 1.15
        }
        if progress < scaleDurationFraction {
            let st = (progress - earlyGrow) / (scaleDurationFraction * 0.4)
            return 1.15 - st * 0.15
        }
        return 1
    }

    private static func computeOpacity(progress: Double, fadeOutStart: Double, fadeOutMid: Double, fadeOutEnd: Double) -> Double {
        if progress <= fadeOutStart {
            return 1
        }
        if progress <= fadeOutMid {
            return 1 - ((progress - fadeOutStart) / (fadeOutMid - fadeOutStart)) * 0.5
        }
        if progress <= fadeOutEnd {
            return 0.5 - ((progress - fadeOutMid) / (fadeOutEnd - fadeOutMid)) * 0.5
        }
        return 0
    }

    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}
