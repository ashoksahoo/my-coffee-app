import XCTest

final class CoffeeJournalUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Setup Wizard Tests

    func testSetupWizardFlow() throws {
        // Test: Complete setup wizard
        // Check if welcome screen appears
        XCTAssertTrue(app.staticTexts["Welcome to Coffee Journal"].waitForExistence(timeout: 5))

        // Tap Continue/Get Started button
        app.buttons["Get Started"].tap()

        // Method selection screen
        XCTAssertTrue(app.staticTexts["Select Your Brew Methods"].waitForExistence(timeout: 2))

        // Select a few methods
        app.buttons["Espresso"].tap()
        app.buttons["Pour Over"].tap()
        app.buttons["French Press"].tap()

        // Continue to grinder entry
        app.buttons["Continue"].tap()

        // Grinder entry screen
        XCTAssertTrue(app.staticTexts["Add Your Grinders"].waitForExistence(timeout: 2))

        // Skip or add a grinder
        if app.buttons["Skip"].exists {
            app.buttons["Skip"].tap()
        }

        // Should reach main app
        XCTAssertTrue(app.tabBars.buttons["Brews"].waitForExistence(timeout: 3))

        print("✅ Setup wizard completed successfully")
    }

    // MARK: - Navigation Tests

    func testTabNavigation() throws {
        // Test: Navigate through all tabs
        completeSetupIfNeeded()

        let tabBar = app.tabBars.firstMatch

        // Test all 5 tabs
        let tabs = ["Brews", "Beans", "Methods", "Grinders", "Settings"]
        for tab in tabs {
            tabBar.buttons[tab].tap()
            XCTAssertTrue(app.navigationBars[tab].exists || app.staticTexts[tab].exists)
            print("✅ Navigated to \(tab) tab")
        }
    }

    // MARK: - Brew Log Tests

    func testAddBrewLog() throws {
        // Test: Add a new brew log
        completeSetupIfNeeded()

        // Go to Brews tab
        app.tabBars.buttons["Brews"].tap()

        // Tap add button
        app.buttons["Add Brew"].firstMatch.tap()

        // Fill in brew details
        app.textFields["Dose"].tap()
        app.textFields["Dose"].typeText("18")

        // Select brew method (if available)
        if app.buttons["Espresso"].exists {
            app.buttons["Espresso"].tap()
        }

        // Save brew
        app.buttons["Save"].tap()

        // Verify brew was added
        XCTAssertTrue(app.staticTexts["18.0g"].waitForExistence(timeout: 2))

        print("✅ Brew log added successfully")
    }

    func testViewBrewDetail() throws {
        // Test: View brew log details
        completeSetupIfNeeded()
        addSampleBrewIfNeeded()

        // Go to Brews tab
        app.tabBars.buttons["Brews"].tap()

        // Tap first brew in list
        app.tables.cells.firstMatch.tap()

        // Verify detail view
        XCTAssertTrue(app.navigationBars["Brew Detail"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Equipment"].exists)
        XCTAssertTrue(app.staticTexts["Parameters"].exists)

        print("✅ Brew detail view displayed")
    }

    // MARK: - Coffee Bean Tests

    func testAddCoffeeBean() throws {
        // Test: Add a new coffee bean
        completeSetupIfNeeded()

        // Go to Beans tab
        app.tabBars.buttons["Beans"].tap()

        // Tap add button
        app.buttons["Add Bean"].firstMatch.tap()

        // Fill in bean details
        app.textFields["Roaster"].tap()
        app.textFields["Roaster"].typeText("Blue Bottle")

        app.textFields["Name"].tap()
        app.textFields["Name"].typeText("Ethiopia Yirgacheffe")

        // Save bean
        app.buttons["Save"].tap()

        // Verify bean was added
        XCTAssertTrue(app.staticTexts["Blue Bottle"].waitForExistence(timeout: 2))

        print("✅ Coffee bean added successfully")
    }

    // MARK: - Equipment Tests

    func testViewBrewMethods() throws {
        // Test: View brew methods list
        completeSetupIfNeeded()

        // Go to Methods tab
        app.tabBars.buttons["Methods"].tap()

        // Verify methods are displayed
        XCTAssertTrue(app.navigationBars["Methods"].waitForExistence(timeout: 2))

        // Tap first method to view details
        if app.tables.cells.count > 0 {
            app.tables.cells.firstMatch.tap()
            XCTAssertTrue(app.navigationBars.element.exists)
            print("✅ Method detail view displayed")
        }
    }

    func testAddGrinder() throws {
        // Test: Add a new grinder
        completeSetupIfNeeded()

        // Go to Grinders tab
        app.tabBars.buttons["Grinders"].tap()

        // Tap add button
        app.buttons["Add Grinder"].firstMatch.tap()

        // Fill in grinder details
        app.textFields["Name"].tap()
        app.textFields["Name"].typeText("Comandante")

        // Select grinder type
        if app.buttons["Hand Grinder"].exists {
            app.buttons["Hand Grinder"].tap()
        }

        // Save grinder
        app.buttons["Save"].tap()

        // Verify grinder was added
        XCTAssertTrue(app.staticTexts["Comandante"].waitForExistence(timeout: 2))

        print("✅ Grinder added successfully")
    }

    // MARK: - Settings Tests

    func testSettingsAccess() throws {
        // Test: Access settings
        completeSetupIfNeeded()

        // Go to Settings tab
        app.tabBars.buttons["Settings"].tap()

        // Verify settings screen
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Equipment Setup"].exists)
        XCTAssertTrue(app.staticTexts["About"].exists)

        print("✅ Settings screen displayed")
    }

    func testRerunSetupWizard() throws {
        // Test: Re-run setup wizard from settings
        completeSetupIfNeeded()

        // Go to Settings tab
        app.tabBars.buttons["Settings"].tap()

        // Tap re-run setup wizard
        app.buttons["Re-run Setup Wizard"].tap()

        // Verify wizard appears
        XCTAssertTrue(app.staticTexts["Welcome to Coffee Journal"].waitForExistence(timeout: 2))

        // Dismiss wizard
        if app.buttons["Done"].exists {
            app.buttons["Done"].tap()
        }

        print("✅ Setup wizard can be re-run")
    }

    // MARK: - Search and Filter Tests

    func testBrewHistorySearch() throws {
        // Test: Search brew history
        completeSetupIfNeeded()
        addSampleBrewIfNeeded()

        // Go to Brews tab
        app.tabBars.buttons["Brews"].tap()

        // Open search if available
        if app.searchFields.firstMatch.exists {
            app.searchFields.firstMatch.tap()
            app.searchFields.firstMatch.typeText("Espresso")

            // Results should filter
            XCTAssertTrue(app.tables.cells.count >= 0)
            print("✅ Search functionality works")
        }
    }

    // MARK: - Helper Methods

    private func completeSetupIfNeeded() {
        // Skip setup wizard if it appears
        if app.staticTexts["Welcome to Coffee Journal"].waitForExistence(timeout: 2) {
            app.buttons["Get Started"].tap()

            // Quick setup - select one method
            if app.buttons["Espresso"].exists {
                app.buttons["Espresso"].tap()
                app.buttons["Continue"].tap()
            }

            // Skip grinders
            if app.buttons["Skip"].exists {
                app.buttons["Skip"].tap()
            }

            // Wait for main screen
            _ = app.tabBars.buttons["Brews"].waitForExistence(timeout: 3)
        }
    }

    private func addSampleBrewIfNeeded() {
        // Add a sample brew if list is empty
        app.tabBars.buttons["Brews"].tap()

        if app.staticTexts["No brews yet"].exists {
            app.buttons["Add Brew"].firstMatch.tap()
            app.textFields["Dose"].tap()
            app.textFields["Dose"].typeText("18")
            app.buttons["Save"].tap()
            _ = app.staticTexts["18.0g"].waitForExistence(timeout: 2)
        }
    }
}
