import XCTest

// MARK: - Navigation UI Tests

final class CoffeeJournalUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITESTING", "-hasCompletedSetup", "YES"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tab Navigation

    func testTabNavigation() throws {
        let tabBar = TabBar(app: app)
        let wizard = SetupWizardPage(app: app)

        // Safety: complete setup if wizard appears despite hasCompletedSetup=YES
        wizard.completeWithDefaults()

        // Verify tab bar is visible
        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should be visible")

        // Navigate to Brews tab
        tabBar.tapBrews()
        XCTAssertTrue(app.navigationBars["Brews"].waitForExistence(timeout: 3), "Brews navigation bar should exist")

        // Navigate to Beans tab
        tabBar.tapBeans()
        XCTAssertTrue(app.navigationBars["Beans"].waitForExistence(timeout: 3), "Beans navigation bar should exist")

        // Navigate to Methods tab
        tabBar.tapMethods()
        XCTAssertTrue(app.navigationBars["Methods"].waitForExistence(timeout: 3), "Methods navigation bar should exist")

        // Navigate to Grinders tab
        tabBar.tapGrinders()
        XCTAssertTrue(app.navigationBars["Grinders"].waitForExistence(timeout: 3), "Grinders navigation bar should exist")

        // Navigate to Settings tab
        tabBar.tapSettings()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3), "Settings navigation bar should exist")
    }

    // MARK: - Settings Screen

    func testSettingsScreen() throws {
        let tabBar = TabBar(app: app)
        let wizard = SetupWizardPage(app: app)

        wizard.completeWithDefaults()
        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should be visible")

        tabBar.tapSettings()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3), "Settings screen should load")

        // Verify Re-run Setup Wizard button exists via accessibility identifier
        let rerunButton = app.buttons[AccessibilityID.Settings.rerunWizardButton]
        XCTAssertTrue(rerunButton.waitForExistence(timeout: 3), "Re-run Setup Wizard button should exist")
    }
}
