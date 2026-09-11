//
//  FoldMotionModel.swift
//  PhoneDuo
//

import CoreMotion
import Observation
import UIKit
import simd

/// Derives the device's tilt around the screen-space Y axis from Core Motion attitude,
/// relative to a calibrated "zero tilt" pose.
@Observable @MainActor
final class FoldMotionModel {
    /// Tilt fed to the shader, in radians. Positive means the right edge is farther from the viewer.
    var tiltAngle: Double {
        usesManualTilt ? FoldMath.radians(degrees: manualDegrees) : motionTilt
    }

    var usesManualTilt: Bool
    var manualDegrees: Double
    private(set) var isMotionAvailable: Bool

    private(set) var motionTilt: Double = 0
    private(set) var errorMessage: String?
    @ObservationIgnored private var lastOrientation: UIInterfaceOrientation?
    @ObservationIgnored private var displayLink: CADisplayLink?
    @ObservationIgnored private var previousFrameTime: CFTimeInterval?
    @ObservationIgnored private var lastSampleTime: TimeInterval?
    @ObservationIgnored private var startedAt: CFTimeInterval = 0
    // Explicit QA launch option; normal launches always use the real sensor on iPhone.
    @ObservationIgnored private let performanceSweep = ProcessInfo.processInfo.arguments.contains("--performance-sweep")

    @ObservationIgnored private let motionManager = CMMotionManager()
    @ObservationIgnored private var reference: simd_double3x3?
    /// Whether `CMRotationMatrix` rows hold the device axes expressed in the reference frame.
    /// Resolved empirically against the gravity vector on the first informative sample.
    @ObservationIgnored private var rowsAreDeviceAxes: Bool?

    init() {
        // Launch-time override for simulator runs: `-tiltDegrees 20` or TILT_DEGREES=-20.
        let defaults = UserDefaults.standard
        let environment = ProcessInfo.processInfo.environment
        manualDegrees = environment["TILT_DEGREES"].flatMap(Double.init) ?? defaults.double(forKey: "tiltDegrees")
        isMotionAvailable = motionManager.isDeviceMotionAvailable
        #if targetEnvironment(simulator)
        usesManualTilt = true
        #else
        usesManualTilt = defaults.bool(forKey: "manualTilt") || !motionManager.isDeviceMotionAvailable || performanceSweep
        #endif
    }

    func start() {
        guard displayLink == nil, performanceSweep || (isMotionAvailable && !usesManualTilt) else { return }
        errorMessage = nil
        previousFrameTime = nil
        lastSampleTime = nil
        startedAt = CACurrentMediaTime()
        if performanceSweep {
            usesManualTilt = true
        } else {
            // Pull the latest sample at display time. Never queue obsolete sensor callbacks
            // on the UI thread when a frame takes longer than the sensor interval.
            motionManager.deviceMotionUpdateInterval = 1.0 / 120.0
            motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
        }
        let link = CADisplayLink(target: MotionFrameTarget(model: self), selector: #selector(MotionFrameTarget.tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        previousFrameTime = nil
        motionManager.stopDeviceMotionUpdates()
    }

    fileprivate func frame(_ link: CADisplayLink) {
        let elapsed = link.timestamp - (previousFrameTime ?? (link.timestamp - 1.0 / 60.0))
        previousFrameTime = link.timestamp
        if performanceSweep {
            manualDegrees = 30 * sin((link.timestamp - startedAt) * .pi / 2)
            return
        }
        guard let motion = motionManager.deviceMotion,
              motion.timestamp != lastSampleTime else {
            if link.timestamp - startedAt > 3,
               link.timestamp - (lastSampleTime ?? startedAt) > 3 {
                errorMessage = "Motion updates stopped. Tap Retry motion."
                stop()
            }
            return
        }
        lastSampleTime = motion.timestamp
        process(motion, elapsed: elapsed)
    }

    /// Makes the current pose the zero-tilt pose: the plane the UI stays in.
    func recalibrate() {
        reference = nil
        motionTilt = 0
    }

    private func process(_ motion: CMDeviceMotion, elapsed: TimeInterval) {
        let orientation = currentOrientation
        if let lastOrientation, lastOrientation != orientation { recalibrate() }
        lastOrientation = orientation
        let convention = rowsAreDeviceAxes
        let deviceToReference = deviceToReferenceMatrix(motion)
        if convention != rowsAreDeviceAxes { recalibrate() }
        guard let reference else {
            reference = deviceToReference
            return
        }

        // Current device axes expressed in the calibrated device frame.
        let relative = reference.transpose * deviceToReference
        let (screenX, screenY) = screenAxesInDeviceSpace(orientation)
        let rate = SIMD3(motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z)
        motionTilt = FoldMath.filteredTilt(relative: relative, screenX: screenX, screenY: screenY,
                                           rotationRate: rate, previous: motionTilt, elapsed: elapsed)
    }

    /// Rotation taking device-frame vectors to reference-frame vectors (column-vector convention).
    private func deviceToReferenceMatrix(_ motion: CMDeviceMotion) -> simd_double3x3 {
        let m = motion.attitude.rotationMatrix
        let asRows = simd_double3x3(rows: [
            SIMD3(m.m11, m.m12, m.m13),
            SIMD3(m.m21, m.m22, m.m23),
            SIMD3(m.m31, m.m32, m.m33),
        ])

        if rowsAreDeviceAxes == nil {
            // Gravity is reported in the device frame and points down (-Z in a Z-vertical reference).
            // Compare it against what each matrix convention predicts and latch the better match.
            let gravity = simd_normalize(SIMD3(motion.gravity.x, motion.gravity.y, motion.gravity.z))
            let down = SIMD3(0.0, 0.0, -1.0)
            let rowsScore = simd_dot(gravity, asRows * down)
            let columnsScore = simd_dot(gravity, asRows.transpose * down)
            if abs(rowsScore - columnsScore) > 0.2 {
                rowsAreDeviceAxes = rowsScore > columnsScore
            }
        }
        return (rowsAreDeviceAxes ?? true) ? asRows.transpose : asRows
    }

    private var currentOrientation: UIInterfaceOrientation {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?.interfaceOrientation ?? .portrait
    }

    /// Screen-space X (right) and Y (up) axes of the interface, in device coordinates.
    private func screenAxesInDeviceSpace(_ orientation: UIInterfaceOrientation) -> (x: SIMD3<Double>, y: SIMD3<Double>) {
        switch orientation {
        case .landscapeLeft:        return (SIMD3(0, 1, 0), SIMD3(-1, 0, 0))
        case .landscapeRight:       return (SIMD3(0, -1, 0), SIMD3(1, 0, 0))
        case .portraitUpsideDown:   return (SIMD3(-1, 0, 0), SIMD3(0, -1, 0))
        default:                    return (SIMD3(1, 0, 0), SIMD3(0, 1, 0))
        }
    }
}

/// CADisplayLink retains its target; the weak model reference avoids a retain cycle.
@MainActor private final class MotionFrameTarget: NSObject {
    weak var model: FoldMotionModel?
    init(model: FoldMotionModel) { self.model = model }
    @objc func tick(_ link: CADisplayLink) { model?.frame(link) }
}
