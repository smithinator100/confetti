import XCTest
@testable import ConfettiPrototype

final class ConfettiPhysicsTests: XCTestCase {
    func test_computeKeyframes_returns41Frames() {
        let output = ConfettiPhysics.computeKeyframes(
            .init(
                angle: -.pi / 2,
                startVelocity: 25,
                decay: 0.91,
                gravity: 1,
                drift: 0,
                wobbleSpeed: 0.08,
                wobbleOffset: 1,
                size: 1,
                ticks: 150,
                xTiltRotations: 0,
                tiltRotations: 3,
                zTiltRotations: 0,
                rotation: 45,
                fadeOutEnd: 0.8
            )
        )

        XCTAssertEqual(output.transforms.count, 41)
        XCTAssertEqual(output.opacities.count, 41)
    }

    func test_computeKeyframes_zeroVelocity_holdsAtOrigin() {
        let output = ConfettiPhysics.computeKeyframes(
            .init(
                angle: -.pi / 2,
                startVelocity: 0,
                decay: 1,
                gravity: 0,
                drift: 0,
                wobbleSpeed: 0,
                wobbleOffset: 0,
                size: 0,
                ticks: 10,
                xTiltRotations: 0,
                tiltRotations: 0,
                zTiltRotations: 0,
                rotation: 0,
                fadeOutEnd: 1
            )
        )

        let finalTransform = output.transforms.last ?? CATransform3DIdentity
        XCTAssertEqual(finalTransform.m41, 0, accuracy: 0.0001)
        XCTAssertEqual(finalTransform.m42, 0, accuracy: 0.0001)
        XCTAssertEqual(finalTransform.m11, 1, accuracy: 0.0001)
    }
}
