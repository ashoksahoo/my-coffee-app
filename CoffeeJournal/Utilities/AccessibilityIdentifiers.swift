import Foundation

// MARK: - Centralized Accessibility Identifiers

/// Shared between app and test targets for stable UI test element selection.
enum AccessibilityID {

    // MARK: - Setup Wizard

    enum Setup {
        static let welcomeTitle = "setup.welcome.title"
        static let getStartedButton = "setup.welcome.getStarted"
        static let methodSelectionTitle = "setup.methods.title"
        static let continueButton = "setup.continue"
        static let skipButton = "setup.skip"
        static let completeTitle = "setup.complete.title"
    }

    // MARK: - Tab Bar

    enum Tabs {
        static let brews = "tab.brews"
        static let beans = "tab.beans"
        static let methods = "tab.methods"
        static let grinders = "tab.grinders"
        static let settings = "tab.settings"
    }

    // MARK: - Brews

    enum Brews {
        static let addButton = "brews.add"
        static let list = "brews.list"
        static let doseField = "brews.form.dose"
        static let waterAmountField = "brews.form.waterAmount"
        static let saveButton = "brews.form.save"
        static let cancelButton = "brews.form.cancel"
        static let searchField = "brews.search"
    }

    // MARK: - Beans

    enum Beans {
        static let addButton = "beans.add"
        static let list = "beans.list"
        static let roasterField = "beans.form.roaster"
        static let nameField = "beans.form.name"
        static let originField = "beans.form.origin"
        static let saveButton = "beans.form.save"
    }

    // MARK: - Equipment

    enum Equipment {
        static let addMethodButton = "equipment.methods.add"
        static let addGrinderButton = "equipment.grinders.add"
        static let grinderNameField = "equipment.grinder.name"
        static let grinderSaveButton = "equipment.grinder.save"
        static let methodList = "equipment.methods.list"
        static let grinderList = "equipment.grinders.list"
    }

    // MARK: - Settings

    enum Settings {
        static let rerunWizardButton = "settings.rerunWizard"
        static let syncSection = "settings.sync"
    }
}
