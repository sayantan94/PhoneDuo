import Testing
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
}
