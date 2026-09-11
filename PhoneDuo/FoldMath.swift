import Foundation
import simd

/// Pure motion math shared by the live sensor path and deterministic tests.
enum FoldMath {
    static let limitDegrees = 65.0

    static func radians(degrees: Double) -> Double {
        guard degrees.isFinite else { return 0 }
        return min(limitDegrees, max(-limitDegrees, degrees)) * .pi / 180
    }

    static func filteredTilt(relative: simd_double3x3, screenX: SIMD3<Double>, screenY: SIMD3<Double>,
                             rotationRate: SIMD3<Double>, previous: Double, prediction: Double = 1.0 / 60.0, elapsed: Double = 1.0 / 60.0) -> Double {
        let normal = relative.columns.2
        let measured = atan2(simd_dot(normal, screenX), normal.z)
        let correction = simd_dot(rotationRate, screenY) * prediction
        guard correction.isFinite else { return previous.isFinite ? previous : 0 }
        let predicted = measured + min(0.05, max(-0.05, correction))
        guard predicted.isFinite else { return previous.isFinite ? previous : 0 }
        let limit = limitDegrees * .pi / 180
        let bounded = min(limit, max(-limit, predicted))
        let prior = previous.isFinite ? previous : 0
        // A continuous neutral zone prevents tiny sensor noise from flipping the hinge.
        let deadZone = 0.2 * .pi / 180
        let target = copysign(max(0, abs(bounded) - deadZone), bounded)
        let dt = elapsed.isFinite ? min(0.1, max(0, elapsed)) : 1.0 / 60.0
        let alpha = 1 - exp(-dt / 0.018)
        return prior + (target - prior) * alpha
    }
}
