# Validation — 10 September 2026

Environment: Apple silicon Mac, Xcode 26.1.1, iPhone 17 Pro simulator on iOS 26.1, and a physical iPhone 12 Pro Max on iOS 26.6.1. Deployment target: iOS 17.0.

| Check | Result |
| --- | --- |
| Ten motion/sampling unit tests | Passed |
| Three simulator UI tests | Passed |
| Final simulator app and Metal shader build | Passed |
| Signed Release build for iPhone | Passed |
| Neutral / −25° / +25° simulator captures | Refreshed after blur changes |
| Installation and launch on iPhone 12 Pro Max | Passed |

The unit suite covers calibration, symmetric tilt, cross-axis rejection, finite angle bounds, bounded gyro prediction, suppression of neutral noise, consistent smoothing at 30/60/120 Hz, and sampling bounds across portrait/landscape and ±65°. UI automation changes the slider, resets, pauses/resumes, opens/closes controls, and selects Frost.

All 13 tests passed before the final shader-only blur-kernel refinement. Both simulator and signed device builds passed after that refinement; screenshots were regenerated from the final shader.

## Responsiveness changes

- Pull the latest Core Motion sample once per display frame rather than enqueue 120 UI-thread callbacks each second.
- Target 60 Hz, use elapsed-time filtering, limit prediction, and suppress tiny neutral-angle noise.
- Use a fixed 24-tap precomputed disk plus a center sample, with no square roots or trigonometry inside the sampling loop. Limit blur to 14 points and declare sufficient sample bounds.
- Keep the shader pipeline active across neutral and isolate angle-dependent view updates. Remove backdrop blur from the controls.
- Install an optimized Release build for phone testing.

A 10-second Time Profiler recording on the physical phone during an automatic tilt sweep reported no potential hangs over its 250 ms threshold. This recording used the first optimized kernel, before the final blur-quality refinement. It is a CPU responsiveness check, not a GPU frame-rate measurement. The Animation Hitches tool crashed with an internal `SignpostCAInstrumentationProcessor` exception, so no measured FPS or before/after speedup is claimed.

Run `swift scripts/check-screenshots.swift` to compare the README screenshots. They contain only the app's generated interface and simulator system chrome.

In-hand responsiveness, sensor direction, landscape behavior, background/resume, and sustained battery/thermal behavior still require physical testing. The user reported lag in the initial Debug build; the revised Release build needs their feedback. No TestFlight or App Store upload was performed.
