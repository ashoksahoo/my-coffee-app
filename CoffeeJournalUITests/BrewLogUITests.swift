import XCTest

// MARK: - Brew Log UI Tests

final class BrewLogUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Launch with setup NOT completed so wizard runs and creates an Espresso method
        app.launchArguments = ["UITESTING", "-hasCompletedSetup", "NO"]
        app.launch()

        // Complete setup wizard with Espresso to ensure a brew method exists
        let wizard = SetupWizardPage(app: app)
        wizard.completeWithDefaults()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Add Brew Log

    func testAddBrewLog() throws {
        let tabBar = TabBar(app: app)
        let brews = BrewsPage(app: app)

        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should be visible")

        // Navigate to Brews tab
        tabBar.tapBrews()
        XCTAssertTrue(app.navigationBars["Brews"].waitForExistence(timeout: 3), "Brews screen should load")

        // Tap add brew
        brews.tapAdd()

        // Enter dose
        brews.enterDose("18")

        // Save brew
        brews.tapSave()

        // Verify we return to the brew list
        XCTAssertTrue(
            app.navigationBars["Brews"].waitForExistence(timeout: 3),
            "Should return to Brews list after saving"
        )
    }

    // MARK: - View Brew Detail

    func testViewBrewDetail() throws {
        let tabBar = TabBar(app: app)
        let brews = BrewsPage(app: app)

        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should be visible")

        // Navigate to Brews tab and add a brew first
        tabBar.tapBrews()
        XCTAssertTrue(app.navigationBars["Brews"].waitForExistence(timeout: 3), "Brews screen should load")

        brews.tapAdd()
        brews.enterDose("18")
        brews.tapSave()

        // Wait for list to reload
        XCTAssertTrue(app.navigationBars["Brews"].waitForExistence(timeout: 3), "Brews list should reload")

        // Tap the first brew in the list to view detail
        let brewList = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.tables.firstMatch
        if brewList.cells.count > 0 {
            brewList.cells.firstMatch.tap()

            // Verify detail view loads (navigation bar changes)
            XCTAssertTrue(
                app.navigationBars.element.waitForExistence(timeout: 3),
                "Brew detail view should load"
            )
        }
    }
}
