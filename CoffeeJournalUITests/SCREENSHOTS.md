# Automated Screenshot Generation

This directory contains automated UI tests that generate screenshots for the README and App Store listings.

## Quick Start

Generate all screenshots with one command:

```bash
./generate-screenshots.sh
```

Or specify a device:

```bash
./generate-screenshots.sh "iPhone 17 Pro Max"
```

## How It Works

The `ScreenshotTests.swift` file contains UI tests that:
1. Navigate through the app systematically
2. Capture screenshots at key moments
3. Save them with descriptive names
4. Only run when explicitly enabled via flag

## Generated Screenshots

The tests generate approximately 20+ screenshots covering:

- **Main Flow** (testGenerateAllScreenshots):
  - 01-brews-list.png - Home screen with brews
  - 02-brews-empty-state.png - Empty state
  - 03-beans-list.png - Coffee beans list
  - 04-methods-list.png - Brew methods
  - 05-grinders-list.png - Grinders
  - 06-settings.png - Settings screen

- **Brew Flow** (testGenerateBrewFlowScreenshots):
  - 07-brews-with-add-button.png - Add button visible
  - 08-brew-log-form-empty.png - Empty brew log form
  - 09-brew-log-form-filled.png - Filled brew log

- **Bean Flow** (testGenerateBeanFlowScreenshots):
  - 10-bean-add-options.png - Add bean options
  - 11-bean-form-empty.png - Empty bean form
  - 12-bean-form-filled.png - Filled bean form
  - 13-beans-list-with-bean.png - List with added bean

- **Equipment** (testGenerateEquipmentScreenshots):
  - 14-grinders-list.png - Grinders list
  - 15-grinder-form.png - Add grinder form
  - 16-grinders-with-grinder.png - List with grinder
  - 17-method-selection.png - Method selection

- **Setup Wizard** (testGenerateSetupWizardScreenshots):
  - 18-setup-welcome.png - Welcome screen
  - 19-setup-methods.png - Method selection
  - 20-setup-method-selected.png - After selecting method
  - 21-setup-grinder.png - Grinder setup
  - 22-setup-complete.png - Setup complete

## Manual Screenshot Generation

You can also run the tests directly with xcodebuild:

```bash
xcodebuild test \
  -project CoffeeJournal.xcodeproj \
  -scheme CoffeeJournal \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:CoffeeJournalUITests/ScreenshotTests \
  GENERATE_SCREENSHOTS=1
```

Or run individual test methods:

```bash
# Just the main flow
xcodebuild test \
  -project CoffeeJournal.xcodeproj \
  -scheme CoffeeJournal \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:CoffeeJournalUITests/ScreenshotTests/testGenerateAllScreenshots \
  GENERATE_SCREENSHOTS=1
```

## In Xcode

1. Open the project in Xcode
2. Select the CoffeeJournalUITests scheme
3. Open ScreenshotTests.swift
4. Click the diamond next to any test method to run it
5. Set environment variable: Edit Scheme → Test → Arguments → Environment Variables
   - Name: `GENERATE_SCREENSHOTS`
   - Value: `1`
6. Run the tests
7. View screenshots in the Test Report

## Updating Screenshots

When the UI changes:

1. Run `./generate-screenshots.sh`
2. Review the generated screenshots in `screenshots/`
3. Update README.md to reference new screenshots
4. Commit the updated images

## Tips

- Screenshots are taken with a 0.5s delay to let animations settle
- The flag-based approach prevents screenshots from running on every test
- Use different device sizes for App Store requirements:
  - `iPhone 17 Pro Max` - 6.7" display
  - `iPhone 17` - 6.1" display
  - `iPhone SE (3rd generation)` - 4.7" display

## Troubleshooting

**Tests are skipped:**
- Ensure `GENERATE_SCREENSHOTS=1` is set in environment variables

**Screenshots not found:**
- Check DerivedData/Logs/Test for test attachments
- Verify tests actually ran (check test logs)

**UI elements not found:**
- Check accessibility identifiers match between tests and app code
- Ensure app is in the expected state when tests run

**Wrong device size:**
- Specify device name: `./generate-screenshots.sh "iPhone 17 Pro Max"`
- Available simulators: `xcrun simctl list devices`
