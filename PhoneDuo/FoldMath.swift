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
                             rotationRate: SIMD3<Double>, previous: Double, prediction: Double = 0.04) -> Double {
        let normal = relative.columns.2
        let measured = atan2(simd_dot(normal, screenX), normal.z)
        let predicted = measured + simd_dot(rotationRate, screenY) * prediction
        guard predicted.isFinite else { return previous.isFinite ? previous : 0 }
        let limit = limitDegrees * .pi / 180
        let bounded = min(limit, max(-limit, predicted))
        let prior = previous.isFinite ? previous : 0
        return prior + (bounded - prior) * 0.7
    }
}
