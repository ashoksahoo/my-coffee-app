# Setup Screenshot Generation

Quick setup guide to enable automated screenshot generation.

## Step 1: Add ScreenshotTests.swift to Xcode Project

The file `CoffeeJournalUITests/ScreenshotTests.swift` has been created but needs to be added to your Xcode project:

### Option A: Using Xcode (Recommended)

1. Open `CoffeeJournal.xcodeproj` in Xcode
2. Right-click on the `CoffeeJournalUITests` folder in the Project Navigator
3. Select "Add Files to 'CoffeeJournal'..."
4. Navigate to `CoffeeJournalUITests/ScreenshotTests.swift`
5. Make sure "CoffeeJournalUITests" target is checked
6. Click "Add"

### Option B: Using Command Line

```bash
# Add the file to git first
git add CoffeeJournalUITests/ScreenshotTests.swift

# Then open Xcode - it may prompt you to add the file automatically
open CoffeeJournal.xcodeproj
```

## Step 2: Verify Setup

Run a quick test to verify everything works:

```bash
./generate-screenshots.sh
```

Or manually in Xcode:
1. Open the project
2. Select the CoffeeJournalUITests scheme
3. Open ScreenshotTests.swift
4. Click the diamond icon next to `testGenerateAllScreenshots`
5. The test will be skipped (expected - we need to set the flag)

## Step 3: Generate Screenshots

Once added to the project, run:

```bash
./generate-screenshots.sh
```

Screenshots will be generated in the `screenshots/` directory.

## Troubleshooting

**"Test target does not contain that test":**
- The file hasn't been added to the Xcode project yet
- Follow Step 1 above

**"Test skipped":**
- This is expected when running without the flag
- The script handles this automatically
- To run manually, set `GENERATE_SCREENSHOTS=1` environment variable

**"Build failed":**
- Open the project in Xcode
- Build the CoffeeJournalUITests target
- Check for any compilation errors
