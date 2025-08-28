//
//  NoGoLogoUITests.swift
//  NoGoLogoUITests
//
//  Created by Jared Maxwell on 8/26/25.
//

import XCTest

class NoGoLogoUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    func testSettingsView() {
        let app = XCUIApplication()
        let settingsButton = app.buttons["gear"]
        XCTAssertTrue(settingsButton.exists)
        settingsButton.tap()

        let apiKeyField = app.textFields["xAI API Key"]
        XCTAssertTrue(apiKeyField.exists)
        apiKeyField.typeText("test-api-key")

        let saveButton = app.buttons["Save API Key"]
        XCTAssertTrue(saveButton.exists)
        saveButton.tap()
    }
}
