import XCTest

// MARK: - Page Objects for UI Test Automation

/// Page object for setup wizard interactions.
struct SetupWizardPage {
    let app: XCUIApplication

    var isVisible: Bool {
        app.staticTexts[AccessibilityID.Setup.welcomeTitle].waitForExistence(timeout: 3)
    }

    func tapGetStarted() {
        let button = app.buttons[AccessibilityID.Setup.getStartedButton]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Get Started button should exist")
        button.tap()
    }

    func selectMethod(_ name: String) {
        let button = app.buttons[name]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Method '\(name)' button should exist")
        button.tap()
    }

    func tapContinue() {
        let button = app.buttons[AccessibilityID.Setup.continueButton]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Continue button should exist")
        button.tap()
    }

    func skipGrinder() {
        // The Skip button on WelcomeStepView doubles as skip-grinder;
        // on grinder step the "Next" button (continueButton) advances.
        // Actually, the grinder step just has "Next" to skip/continue.
        let nextButton = app.buttons[AccessibilityID.Setup.continueButton]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3), "Next/Continue button should exist on grinder step")
        nextButton.tap()
    }

    func enterGrinderName(_ name: String) {
        let field = app.textFields[AccessibilityID.Equipment.grinderNameField]
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Grinder name field should exist")
        field.tap()
        field.typeText(name)
    }

    func tapDone() {
        // On the complete step, the button says "Done" but uses continueButton identifier
        let button = app.buttons[AccessibilityID.Setup.continueButton]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Done button should exist")
        button.tap()
    }

    /// Complete setup with default selections: Get Started -> select Espresso -> Continue -> skip grinder -> Done
    func completeWithDefaults() {
        if isVisible {
            tapGetStarted()
            selectMethod("Espresso")
            tapContinue()
            skipGrinder() // advances past grinder step
            tapDone()     // completes from the "You're Ready!" step
        }
    }
}

/// Page object for brew log interactions.
struct BrewsPage {
    let app: XCUIApplication

    func tapAdd() {
        let button = app.buttons[AccessibilityID.Brews.addButton]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Add brew button should exist")
        button.tap()
    }

    func enterDose(_ value: String) {
        let field = app.textFields[AccessibilityID.Brews.doseField]
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Dose field should exist")
        field.tap()
        field.typeText(value)
    }

    func enterWaterAmount(_ value: String) {
        let field = app.textFields[AccessibilityID.Brews.waterAmountField]
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Water amount field should exist")
        field.tap()
        field.typeText(value)
    }

    func tapSave() {
        let button = app.buttons[AccessibilityID.Brews.saveButton]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Save button should exist")
        button.tap()
    }

    func tapCancel() {
        let button = app.buttons[AccessibilityID.Brews.cancelButton]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Cancel button should exist")
        button.tap()
    }
}

/// Page object for bean interactions.
struct BeansPage {
    let app: XCUIApplication

    func tapAdd() {
        let button = app.buttons[AccessibilityID.Beans.addButton]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Add bean button should exist")
        button.tap()
    }

    func tapAddManually() {
        let button = app.buttons["Add Manually"]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Add Manually button should exist")
        button.tap()
    }

    func enterRoaster(_ value: String) {
        let field = app.textFields[AccessibilityID.Beans.roasterField]
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Roaster field should exist")
        field.tap()
        field.typeText(value)
    }

    func enterName(_ value: String) {
        let field = app.textFields[AccessibilityID.Beans.nameField]
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Name field should exist")
        field.tap()
        field.typeText(value)
    }

    func enterOrigin(_ value: String) {
        let field = app.textFields[AccessibilityID.Beans.originField]
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Origin field should exist")
        field.tap()
        field.typeText(value)
    }

    func tapSave() {
        let button = app.buttons[AccessibilityID.Beans.saveButton]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Save button should exist")
        button.tap()
    }
}

/// Page object for equipment interactions.
struct EquipmentPage {
    let app: XCUIApplication

    func tapAddGrinder() {
        let button = app.buttons[AccessibilityID.Equipment.addGrinderButton]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Add grinder button should exist")
        button.tap()
    }

    func enterGrinderName(_ value: String) {
        let field = app.textFields[AccessibilityID.Equipment.grinderNameField]
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Grinder name field should exist")
        field.tap()
        field.typeText(value)
    }

    func tapGrinderSave() {
        let button = app.buttons[AccessibilityID.Equipment.grinderSaveButton]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Grinder save button should exist")
        button.tap()
    }

    func tapAddMethod() {
        let button = app.buttons[AccessibilityID.Equipment.addMethodButton]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Add method button should exist")
        button.tap()
    }
}

/// Page object for tab bar navigation.
struct TabBar {
    let app: XCUIApplication

    func tapBrews() {
        app.tabBars.buttons["Brews"].tap()
    }

    func tapBeans() {
        app.tabBars.buttons["Beans"].tap()
    }

    func tapMethods() {
        app.tabBars.buttons["Methods"].tap()
    }

    func tapGrinders() {
        app.tabBars.buttons["Grinders"].tap()
    }

    func tapSettings() {
        app.tabBars.buttons["Settings"].tap()
    }

    func waitForTabBar() -> Bool {
        app.tabBars.buttons["Brews"].waitForExistence(timeout: 5)
    }
}
