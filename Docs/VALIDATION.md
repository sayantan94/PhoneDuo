# Validation — 10 September 2026

Environment: Apple silicon Mac, Xcode 26.1.1, iPhone 17 Pro simulator running iOS 26.1. Deployment target: iOS 17.0.

| Check | Result |
| --- | --- |
| Simulator app and Metal shader build | Passed |
| Six motion-math unit tests | Passed |
| Three simulator UI tests | Passed |
| Final simulator build after concurrency-warning cleanup | Passed |
| Unsigned Release build for a real iPhone target | Passed |
| Neutral / −25° / +25° simulator captures | Visually inspected; opposite folds, increasing blur, fixed controls |
| Screenshot pixel-difference checks | Passed for all three pairings |

UI automation changed the actual slider, reset it to zero, paused and resumed a nonzero angle, opened/closed the controls, and selected Frost. The math suite checked neutral pose, symmetric left/right rotation, cross-axis rejection, gyro prediction, finite bounds, and calibration identity.

The final two source adjustments precompute an immutable shader parameter outside its Sendable closure and use a consistent light appearance. Both final simulator and device builds passed; the final screenshots were captured from that build.

Run `swift scripts/check-screenshots.swift` from the repository root to repeat the read-only screenshot comparison. Screenshots contain only the app's own generated interface and simulator system chrome.

Physical iPhone testing is still required for Core Motion tracking direction, responsiveness, calibration in hand, background/resume, landscape behavior, and battery/thermal impact. No app was installed on a physical phone, signed for distribution, or uploaded to TestFlight/App Store.
