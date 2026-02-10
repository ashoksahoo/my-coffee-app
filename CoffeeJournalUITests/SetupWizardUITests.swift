import XCTest

// MARK: - Setup Wizard UI Tests

final class SetupWizardUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITESTING", "-hasCompletedSetup", "NO"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Complete Flow

    func testCompleteSetupFlow() throws {
        let wizard = SetupWizardPage(app: app)
        let tabBar = TabBar(app: app)

        // Welcome screen should appear
        XCTAssertTrue(wizard.isVisible, "Welcome screen should be visible")

        // Tap Get Started
        wizard.tapGetStarted()

        // Method selection screen
        let methodTitle = app.staticTexts[AccessibilityID.Setup.methodSelectionTitle]
        XCTAssertTrue(methodTitle.waitForExistence(timeout: 3), "Method selection title should appear")

        // Select brew methods
        wizard.selectMethod("Espresso")
        wizard.selectMethod("Pour Over")

        // Continue to grinder
        wizard.tapContinue()

        // Skip grinder entry
        wizard.skipGrinder()

        // Complete screen should show
        let completeTitle = app.staticTexts[AccessibilityID.Setup.completeTitle]
        XCTAssertTrue(completeTitle.waitForExistence(timeout: 3), "Complete title should appear")

        // Tap Done to finish
        wizard.tapDone()

        // Should reach main app with tab bar
        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should appear after setup completion")
    }

    // MARK: - Flow with Grinder

    func testSetupWizardWithGrinder() throws {
        let wizard = SetupWizardPage(app: app)
        let tabBar = TabBar(app: app)

        XCTAssertTrue(wizard.isVisible, "Welcome screen should be visible")

        wizard.tapGetStarted()

        // Select a method
        wizard.selectMethod("Espresso")
        wizard.tapContinue()

        // Enter grinder name instead of skipping
        wizard.enterGrinderName("Comandante C40")

        // Advance past grinder step
        wizard.skipGrinder()

        // Complete screen
        let completeTitle = app.staticTexts[AccessibilityID.Setup.completeTitle]
        XCTAssertTrue(completeTitle.waitForExistence(timeout: 3), "Complete title should appear")

        wizard.tapDone()
        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should appear after setup with grinder")
    }

    // MARK: - Re-run Wizard from Settings

    func testRerunSetupWizard() throws {
        // First, launch with setup completed
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["UITESTING", "-hasCompletedSetup", "YES"]
        app.launch()

        let tabBar = TabBar(app: app)
        let wizard = SetupWizardPage(app: app)

        // Handle wizard if it appears despite hasCompletedSetup=YES
        wizard.completeWithDefaults()
        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should be visible")

        // Go to Settings
        tabBar.tapSettings()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3), "Settings should load")

        // Tap re-run wizard
        let rerunButton = app.buttons[AccessibilityID.Settings.rerunWizardButton]
        XCTAssertTrue(rerunButton.waitForExistence(timeout: 3), "Re-run wizard button should exist")
        rerunButton.tap()

        // Verify wizard appears
        XCTAssertTrue(wizard.isVisible, "Wizard should appear after re-run")
    }
}
