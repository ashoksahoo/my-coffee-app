import XCTest

// MARK: - Equipment UI Tests

final class EquipmentUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITESTING", "-hasCompletedSetup", "YES"]
        app.launch()

        // Safety fallback: complete setup wizard if it appears
        let wizard = SetupWizardPage(app: app)
        wizard.completeWithDefaults()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - View Brew Methods

    func testViewBrewMethods() throws {
        let tabBar = TabBar(app: app)
        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should be visible")

        // Navigate to Methods tab
        tabBar.tapMethods()
        XCTAssertTrue(app.navigationBars["Methods"].waitForExistence(timeout: 3), "Methods screen should load")
    }

    // MARK: - Add Grinder

    func testAddGrinder() throws {
        let tabBar = TabBar(app: app)
        let equipment = EquipmentPage(app: app)

        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should be visible")

        // Navigate to Grinders tab
        tabBar.tapGrinders()
        XCTAssertTrue(app.navigationBars["Grinders"].waitForExistence(timeout: 3), "Grinders screen should load")

        // Tap add grinder
        equipment.tapAddGrinder()

        // Enter grinder name
        equipment.enterGrinderName("Comandante")

        // Save
        equipment.tapGrinderSave()

        // Verify grinder appears in list
        XCTAssertTrue(
            app.staticTexts["Comandante"].waitForExistence(timeout: 3),
            "Comandante should appear in grinder list"
        )
    }
}
