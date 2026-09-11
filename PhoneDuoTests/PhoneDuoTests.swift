import Testing
import Foundation
import simd
@testable import PhoneDuo

@MainActor struct PhoneDuoTests {
    @Test func neutralOrientationRemainsFlat() {
        let angle = FoldMath.filteredTilt(relative: matrix_identity_double3x3, screenX: [1,0,0], screenY: [0,1,0], rotationRate: .zero, previous: 0)
        #expect(abs(angle) < 0.00001)
    }
    @Test func leftAndRightMotionHaveOppositeSigns() {
        for degrees in [10.0, 25.0, 45.0] {
            let radians = degrees * .pi / 180
            let right = simd_double3x3(simd_quatd(angle: radians, axis: [0,1,0]))
            let left = simd_double3x3(simd_quatd(angle: -radians, axis: [0,1,0]))
            let a = FoldMath.filteredTilt(relative: right, screenX: [1,0,0], screenY: [0,1,0], rotationRate: .zero, previous: 0)
            let b = FoldMath.filteredTilt(relative: left, screenX: [1,0,0], screenY: [0,1,0], rotationRate: .zero, previous: 0)
            #expect(a > 0)
            #expect(b < 0)
            #expect(abs(a + b) < 0.00001)
        }
    }
    @Test func pitchDoesNotCreateVerticalHingeTilt() {
        let pitch = simd_double3x3(simd_quatd(angle: 0.4, axis: [1,0,0]))
        let angle = FoldMath.filteredTilt(relative: pitch, screenX: [1,0,0], screenY: [0,1,0], rotationRate: .zero, previous: 0)
        #expect(abs(angle) < 0.00001)
    }
    @Test func gyroPredictsAlongTheHingeAxisOnly() {
        let aroundHinge = FoldMath.filteredTilt(relative: matrix_identity_double3x3, screenX: [1,0,0], screenY: [0,1,0], rotationRate: [0,1,0], previous: 0)
        let otherAxis = FoldMath.filteredTilt(relative: matrix_identity_double3x3, screenX: [1,0,0], screenY: [0,1,0], rotationRate: [1,0,0], previous: 0)
        #expect(aroundHinge > 0)
        #expect(otherAxis == 0)
    }
    @Test func invalidAndExtremeAnglesAreBounded() {
        #expect(FoldMath.radians(degrees: .nan) == 0)
        #expect(FoldMath.radians(degrees: .infinity) == 0)
        #expect(FoldMath.radians(degrees: 1000) == FoldMath.radians(degrees: 65))
        #expect(FoldMath.radians(degrees: -1000) == -FoldMath.radians(degrees: 65))
        let invalid = FoldMath.filteredTilt(relative: matrix_identity_double3x3, screenX: [1,0,0], screenY: [0,1,0], rotationRate: [0,.nan,0], previous: 0.2)
        #expect(invalid == 0.2)
    }
    @Test func calibratedRelativeOrientationIsIdentity() {
        let pose = simd_double3x3(simd_quatd(angle: 0.7, axis: simd_normalize(SIMD3(1.0,2.0,3.0))))
        let angle = FoldMath.filteredTilt(relative: pose.transpose * pose, screenX: [1,0,0], screenY: [0,1,0], rotationRate: .zero, previous: 0)
        #expect(abs(angle) < 0.00001)
    }
    @Test func neutralSensorNoiseDoesNotFlipTheHinge() {
        for degrees in [-0.19, -0.01, 0.01, 0.19] {
            let pose = simd_double3x3(simd_quatd(angle: degrees * .pi / 180, axis: [0,1,0]))
            let angle = FoldMath.filteredTilt(relative: pose, screenX: [1,0,0], screenY: [0,1,0], rotationRate: .zero, previous: 0)
            #expect(angle == 0)
        }
    }
    @Test func smoothingIsConsistentAcrossRefreshRates() {
        let pose = simd_double3x3(simd_quatd(angle: 0.4, axis: [0,1,0]))
        func settle(hz: Int) -> Double {
            var angle = 0.0
            for _ in 0..<(hz / 10) {
                angle = FoldMath.filteredTilt(relative: pose, screenX: [1,0,0], screenY: [0,1,0], rotationRate: .zero, previous: angle, elapsed: 1.0 / Double(hz))
            }
            return angle
        }
        #expect(abs(settle(hz: 30) - settle(hz: 60)) < 0.000001)
        #expect(abs(settle(hz: 60) - settle(hz: 120)) < 0.000001)
    }
    @Test func predictionCannotOvershootByMoreThanThreeDegrees() {
        let angle = FoldMath.filteredTilt(relative: matrix_identity_double3x3, screenX: [1,0,0], screenY: [0,1,0], rotationRate: [0,100,0], previous: 0)
        #expect(angle > 0)
        #expect(angle < 3 * .pi / 180)
    }
    @Test func samplingBoundsCoverTheWarpAndBlur() {
        for size in [CGSize(width: 428, height: 926), CGSize(width: 926, height: 428)] {
            let eye = 1920.0
            let radius = 14.0
            let offset = FoldSampling.maximumOffset(size: size, eyeDistance: eye, maxAngle: 65 * .pi / 180, radius: radius)
            for degrees in stride(from: -65.0, through: 65.0, by: 5) {
                let tilt = abs(degrees) * .pi / 180
                let hinge = degrees > 0 ? size.width : 0
                let side = degrees > 0 ? -1.0 : 1.0
                for fraction in stride(from: 0.0, through: 1.0, by: 0.05) {
                    let x = size.width * fraction
                    let d = abs(x - hinge)
                    let scale = eye / (eye - d * sin(tilt))
                    let hitX = size.width / 2 + (hinge + side * d * cos(tilt) - size.width / 2) * scale
                    #expect(abs(hitX - x) + radius <= offset.width)
                    #expect(size.height / 2 * (scale - 1) + radius <= offset.height)
                }
            }
        }
    }
}
