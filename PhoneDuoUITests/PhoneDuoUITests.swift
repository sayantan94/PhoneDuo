import XCTest

final class PhoneDuoUITests: XCTestCase {
    @MainActor func testManualFoldAndReset() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--show-controls", "-tiltDegrees", "0"]
        app.launch()
        let slider = app.sliders["tiltSlider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        slider.adjust(toNormalizedSliderPosition: 0.8)
        let readout = app.staticTexts["tiltReadout"]
        XCTAssertNotEqual(readout.label, "0.0°")
        app.buttons["resetAngle"].tap()
        XCTAssertEqual(readout.label, "0.0°")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "PhoneDuo controls"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
    @MainActor func testPauseAndResume() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--show-controls", "-tiltDegrees", "25"]
        app.launch()
        let pause = app.buttons["pauseEffect"]
        XCTAssertTrue(pause.waitForExistence(timeout: 10))
        pause.tap()
        XCTAssertEqual(app.staticTexts["motionStatus"].label, "Paused")
        XCTAssertEqual(app.staticTexts["tiltReadout"].label, "0.0°")
        pause.tap()
        XCTAssertEqual(app.staticTexts["motionStatus"].label, "Manual preview")
        XCTAssertEqual(app.staticTexts["tiltReadout"].label, "25.0°")
    }
    @MainActor func testControlsCanBeClosedAndReopened() throws {
        let app = XCUIApplication()
        app.launch()
        let controls = app.buttons["toggleControls"]
        XCTAssertTrue(controls.waitForExistence(timeout: 10))
        controls.tap()
        XCTAssertTrue(app.sliders["tiltSlider"].waitForExistence(timeout: 3))
        controls.tap()
        XCTAssertFalse(app.sliders["tiltSlider"].exists)
        controls.tap()
        XCTAssertTrue(app.sliders["tiltSlider"].waitForExistence(timeout: 3))
        app.segmentedControls["finishPicker"].buttons["Frost"].tap()
        XCTAssertTrue(app.segmentedControls["finishPicker"].buttons["Frost"].isSelected)
    }
}
