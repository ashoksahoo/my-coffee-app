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
        // Try to find button containing the method name
        // The method buttons have complex structure with nested elements
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", name)
        let button = app.buttons.containing(predicate).firstMatch

        // Wait for it to exist
        let exists = button.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Method '\(name)' button should exist")

        if exists {
            button.tap()
        }
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
        // Try multiple strategies to find the dose field
        var field = app.textFields[AccessibilityID.Brews.doseField]

        if !field.waitForExistence(timeout: 2) {
            // Fallback: look for text field with placeholder "g" (dose unit)
            field = app.textFields["g"]
        }

        if !field.exists {
            // Last resort: find any text field in the brew parameters section
            field = app.textFields.firstMatch
        }

        XCTAssertTrue(field.exists, "Dose field should exist")
        field.tap()
        // Clear any existing value first
        if let currentValue = field.value as? String, !currentValue.isEmpty {
            field.doubleTap()
            field.typeText(XCUIKeyboardKey.delete.rawValue)
        }
        field.typeText(value)
    }

    func enterWaterAmount(_ value: String) {
        let field = app.textFields[AccessibilityID.Brews.waterAmountField]
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Water amount field should exist")
        field.tap()
        field.typeText(value)
    }

    func tapSave() {
        var button = app.buttons[AccessibilityID.Brews.saveButton]

        if !button.waitForExistence(timeout: 2) {
            button = app.buttons["Save"]
        }

        XCTAssertTrue(button.exists, "Save button should exist")
        button.tap()
    }

    func tapCancel() {
        var button = app.buttons[AccessibilityID.Brews.cancelButton]

        if !button.waitForExistence(timeout: 2) {
            button = app.buttons["Cancel"]
        }

        XCTAssertTrue(button.exists, "Cancel button should exist")
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
        // The "Add Manually" option is in a menu that appears after tapping the add button
        // So it should already be visible after tapAdd() is called
        // Try multiple query strategies
        let manualButton = app.buttons["Add Manually"]
        let menuItem = app.menuItems["Add Manually"]

        if manualButton.waitForExistence(timeout: 3) {
            manualButton.tap()
        } else if menuItem.waitForExistence(timeout: 3) {
            menuItem.tap()
        } else {
            XCTFail("Could not find 'Add Manually' button or menu item")
        }
    }

    func enterRoaster(_ value: String) {
        var field = app.textFields[AccessibilityID.Beans.roasterField]

        if !field.waitForExistence(timeout: 2) {
            // Fallback: look for "Roaster" placeholder or label
            field = app.textFields["Roaster"]
        }

        if !field.exists {
            // Try looking for any text field in a form
            let textFields = app.textFields
            if textFields.count > 0 {
                field = textFields.element(boundBy: 0)
            }
        }

        XCTAssertTrue(field.exists, "Roaster field should exist")
        field.tap()
        field.typeText(value)
    }

    func enterName(_ value: String) {
        var field = app.textFields[AccessibilityID.Beans.nameField]

        if !field.waitForExistence(timeout: 2) {
            field = app.textFields["Name"]
        }

        XCTAssertTrue(field.exists, "Name field should exist")
        field.tap()
        field.typeText(value)
    }

    func enterOrigin(_ value: String) {
        var field = app.textFields[AccessibilityID.Beans.originField]

        if !field.waitForExistence(timeout: 2) {
            field = app.textFields["Origin"]
        }

        XCTAssertTrue(field.exists, "Origin field should exist")
        field.tap()
        field.typeText(value)
    }

    func tapSave() {
        var button = app.buttons[AccessibilityID.Beans.saveButton]

        if !button.waitForExistence(timeout: 2) {
            button = app.buttons["Save"]
        }

        XCTAssertTrue(button.exists, "Save button should exist")
        button.tap()
    }
}

/// Page object for equipment interactions.
struct EquipmentPage {
    let app: XCUIApplication

    func tapAddGrinder() {
        // Look for the + button in toolbar
        var button = app.buttons[AccessibilityID.Equipment.addGrinderButton]

        if !button.waitForExistence(timeout: 2) {
            // Fallback: look for any + button or "Add Grinder" button
            button = app.buttons["plus"].firstMatch
            if !button.exists {
                button = app.buttons["Add Grinder"]
            }
        }

        XCTAssertTrue(button.exists, "Add grinder button should exist")
        button.tap()
    }

    func enterGrinderName(_ value: String) {
        // Try to find grinder name field
        var field = app.textFields[AccessibilityID.Equipment.grinderNameField]

        if !field.waitForExistence(timeout: 2) {
            // Fallback: look for "Grinder Name" placeholder
            field = app.textFields["Grinder Name"]
        }

        if !field.exists {
            // Last resort: first text field
            field = app.textFields.firstMatch
        }

        XCTAssertTrue(field.exists, "Grinder name field should exist")
        field.tap()
        field.typeText(value)
    }

    func tapGrinderSave() {
        // Look for Save button
        var button = app.buttons[AccessibilityID.Equipment.grinderSaveButton]

        if !button.waitForExistence(timeout: 2) {
            // Fallback: look for any "Save" button
            button = app.buttons["Save"]
        }

        XCTAssertTrue(button.exists, "Grinder save button should exist")
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
