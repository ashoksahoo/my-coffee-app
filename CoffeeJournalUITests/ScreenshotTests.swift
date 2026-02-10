import XCTest
import Foundation

/// Automated screenshot generation for README and App Store
///
/// Run with: xcodebuild test -scheme CoffeeJournal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CoffeeJournalUITests/ScreenshotTests GENERATE_SCREENSHOTS=1
final class ScreenshotTests: XCTestCase {
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

    // MARK: - Screenshot Helpers

    /// Take a screenshot and save it with the given name
    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Small delay to ensure UI is settled
        sleep(1)
    }

    /// Wait for animations to complete
    private func waitForAnimations() {
        usleep(500_000) // 0.5 seconds
    }

    // MARK: - Screenshot Tests

    func testGenerateAllScreenshots() throws {
        let tabBar = TabBar(app: app)
        let wizard = SetupWizardPage(app: app)
        let brewsPage = BrewsPage(app: app)
        let beansPage = BeansPage(app: app)
        let equipmentPage = EquipmentPage(app: app)

        // Complete setup if needed
        wizard.completeWithDefaults()
        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should be visible")

        waitForAnimations()

        // Screenshot 1: Brews List (Home)
        tabBar.tapBrews()
        waitForAnimations()
        takeScreenshot(named: "01-brews-list")

        // Screenshot 2: Empty Brews State
        // (If there are brews, this will show the list instead)
        takeScreenshot(named: "02-brews-empty-state")

        // Screenshot 3: Beans List
        tabBar.tapBeans()
        waitForAnimations()
        takeScreenshot(named: "03-beans-list")

        // Screenshot 4: Methods List
        tabBar.tapMethods()
        waitForAnimations()
        takeScreenshot(named: "04-methods-list")

        // Screenshot 5: Grinders List
        tabBar.tapGrinders()
        waitForAnimations()
        takeScreenshot(named: "05-grinders-list")

        // Screenshot 6: Settings
        tabBar.tapSettings()
        waitForAnimations()
        takeScreenshot(named: "06-settings")
    }

    func testGenerateBrewFlowScreenshots() throws {
        let tabBar = TabBar(app: app)
        let wizard = SetupWizardPage(app: app)
        let brewsPage = BrewsPage(app: app)

        wizard.completeWithDefaults()
        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should be visible")

        // Navigate to Brews
        tabBar.tapBrews()
        waitForAnimations()

        // Screenshot: Add Brew Button
        takeScreenshot(named: "07-brews-with-add-button")

        // Tap add to open brew log form
        brewsPage.tapAdd()
        waitForAnimations()
        takeScreenshot(named: "08-brew-log-form-empty")

        // Fill in some fields
        brewsPage.enterDose("18")
        waitForAnimations()
        takeScreenshot(named: "09-brew-log-form-filled")

        // Cancel to return to list
        brewsPage.tapCancel()
        waitForAnimations()
    }

    func testGenerateBeanFlowScreenshots() throws {
        let tabBar = TabBar(app: app)
        let wizard = SetupWizardPage(app: app)
        let beansPage = BeansPage(app: app)

        wizard.completeWithDefaults()
        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should be visible")

        // Navigate to Beans
        tabBar.tapBeans()
        waitForAnimations()

        // Tap add bean
        beansPage.tapAdd()
        waitForAnimations()
        takeScreenshot(named: "10-bean-add-options")

        // Select manual entry
        beansPage.tapAddManually()
        waitForAnimations()
        takeScreenshot(named: "11-bean-form-empty")

        // Fill in bean details
        beansPage.enterRoaster("Heart Coffee")
        beansPage.enterName("Ethiopia Guji")
        beansPage.enterOrigin("Ethiopia")
        waitForAnimations()
        takeScreenshot(named: "12-bean-form-filled")

        // Save the bean
        beansPage.tapSave()
        waitForAnimations()
        takeScreenshot(named: "13-beans-list-with-bean")
    }

    func testGenerateEquipmentScreenshots() throws {
        let tabBar = TabBar(app: app)
        let wizard = SetupWizardPage(app: app)
        let equipmentPage = EquipmentPage(app: app)

        wizard.completeWithDefaults()
        XCTAssertTrue(tabBar.waitForTabBar(), "Tab bar should be visible")

        // Grinders
        tabBar.tapGrinders()
        waitForAnimations()
        takeScreenshot(named: "14-grinders-list")

        equipmentPage.tapAddGrinder()
        waitForAnimations()
        takeScreenshot(named: "15-grinder-form")

        equipmentPage.enterGrinderName("Baratza Encore")
        waitForAnimations()
        equipmentPage.tapGrinderSave()
        waitForAnimations()
        takeScreenshot(named: "16-grinders-with-grinder")

        // Methods
        tabBar.tapMethods()
        waitForAnimations()

        equipmentPage.tapAddMethod()
        waitForAnimations()
        takeScreenshot(named: "17-method-selection")
    }

    func testGenerateSetupWizardScreenshots() throws {
        // Launch without hasCompletedSetup to show wizard
        app.launchArguments = ["UITESTING"]
        app.launch()

        let wizard = SetupWizardPage(app: app)

        // Screenshot 1: Welcome screen
        XCTAssertTrue(wizard.isVisible, "Setup wizard should be visible")
        waitForAnimations()
        takeScreenshot(named: "18-setup-welcome")

        // Screenshot 2: Method selection
        wizard.tapGetStarted()
        waitForAnimations()
        takeScreenshot(named: "19-setup-methods")

        // Screenshot 3: After selecting a method
        wizard.selectMethod("Espresso")
        waitForAnimations()
        takeScreenshot(named: "20-setup-method-selected")

        wizard.tapContinue()
        waitForAnimations()
        takeScreenshot(named: "21-setup-grinder")

        wizard.skipGrinder()
        waitForAnimations()
        takeScreenshot(named: "22-setup-complete")
    }
}
