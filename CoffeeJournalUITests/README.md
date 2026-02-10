# Coffee Journal UI Tests

Automated UI tests for all major features of the Coffee Journal app.

## 🧪 Test Coverage

### Setup & Navigation
- ✅ Complete setup wizard flow
- ✅ Navigate through all 5 tabs

### Brew Logs
- ✅ Add new brew log
- ✅ View brew details
- ✅ Search brew history

### Coffee Beans
- ✅ Add new coffee bean
- ✅ View bean list

### Equipment
- ✅ View brew methods
- ✅ Add grinder
- ✅ View grinder details

### Settings
- ✅ Access settings
- ✅ Re-run setup wizard

## 🚀 Running Tests

### Option 1: Xcode UI (Easiest)

1. **Open project in Xcode**
   ```bash
   open CoffeeJournal.xcodeproj
   ```

2. **Select test target**
   - Press `⌘6` to open Test Navigator
   - You'll see `CoffeeJournalUITests`

3. **Run all tests**
   - Click ▶️ next to `CoffeeJournalUITests`
   - Or press `⌘U` to run all tests

4. **Run individual test**
   - Click ▶️ next to any specific test function
   - Example: `testAddBrewLog()`

5. **Watch the magic!**
   - Simulator will launch automatically
   - App will open and perform all actions
   - Tests run in ~2-5 minutes

### Option 2: Command Line

Run all UI tests:
```bash
xcodebuild test \
  -project CoffeeJournal.xcodeproj \
  -scheme CoffeeJournal \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:CoffeeJournalUITests
```

Run specific test:
```bash
xcodebuild test \
  -project CoffeeJournal.xcodeproj \
  -scheme CoffeeJournal \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:CoffeeJournalUITests/CoffeeJournalUITests/testAddBrewLog
```

### Option 3: Record New Tests

1. Open `CoffeeJournalUITests.swift` in Xcode
2. Place cursor in a new test function
3. Click **Record** button (red circle) at bottom of editor
4. Perform actions in simulator
5. Xcode generates test code automatically!

## 📊 Test Results

After tests run, you'll see:
- ✅ Green checkmarks for passing tests
- ❌ Red X for failing tests
- Detailed logs in Console
- Screenshots on failures

## 🎯 What Gets Tested

**Functional Tests:**
- User workflows (setup, add brew, etc.)
- Navigation between screens
- Data entry and validation
- Button interactions

**Visual Tests:**
- UI elements exist
- Text labels display correctly
- Navigation bars appear

**Integration Tests:**
- Multiple features working together
- Data persistence
- State management

## 🔧 Adding New Tests

1. Open `CoffeeJournalUITests.swift`
2. Add new test function:
   ```swift
   func testYourFeature() throws {
       completeSetupIfNeeded()

       // Your test code here
       app.buttons["Button Name"].tap()
       XCTAssertTrue(app.staticTexts["Expected Text"].exists)

       print("✅ Test passed")
   }
   ```

3. Run it!

## 💡 Tips

- Tests run in isolated environment
- Each test starts fresh (no shared state)
- Use `waitForExistence(timeout:)` for async elements
- Record interactions to generate test code
- Run tests before pushing to verify nothing broke

## 🐛 Troubleshooting

**Test fails with timeout:**
- Increase timeout values
- Check if UI element identifiers changed

**Simulator not launching:**
- Select correct device in Xcode
- Try different simulator

**Test hangs:**
- Check for blocking operations
- Ensure UI elements are accessible

## 📈 CI/CD Integration

These tests can run automatically:
- On every commit (GitHub Actions)
- Before merge (PR checks)
- Scheduled nightly builds

Example GitHub Actions:
```yaml
- name: Run UI Tests
  run: |
    xcodebuild test \
      -project CoffeeJournal.xcodeproj \
      -scheme CoffeeJournal \
      -destination 'platform=iOS Simulator,name=iPhone 17' \
      -only-testing:CoffeeJournalUITests
```

## 🎉 Benefits

- ✅ Catch bugs before users do
- ✅ Verify features work end-to-end
- ✅ Safe refactoring (tests ensure nothing breaks)
- ✅ Documentation of expected behavior
- ✅ Faster than manual testing
