import XCTest

// MARK: - Bean UI Tests

final class BeanUITests: XCTestCase {
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

    // MARK: - Add Coffee Bean

    func testAddCoffeeBean() throws {
        let tabBar = TabBar(app: app)
        let beans = BeansPage(app: app)

        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should be visible")

        // Navigate to Beans tab
        tabBar.tapBeans()
        XCTAssertTrue(app.navigationBars["Beans"].waitForExistence(timeout: 3), "Beans screen should load")

        // Tap add (opens menu) then "Add Manually"
        beans.tapAdd()
        beans.tapAddManually()

        // Enter bean details
        beans.enterRoaster("Blue Bottle")
        beans.enterOrigin("Ethiopia")

        // Save
        beans.tapSave()

        // Verify bean appears in list
        // The bean displayName will be "Roaster - Origin" format
        let beanText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Blue Bottle")).firstMatch
        XCTAssertTrue(
            beanText.waitForExistence(timeout: 5),
            "Blue Bottle bean should appear in bean list"
        )
    }
}
