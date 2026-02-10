# Phase 9: Automated QA Suite - Research

**Researched:** 2026-02-10
**Domain:** iOS Testing (XCTest, Swift Testing, SwiftData, XCUITest, CI/CD)
**Confidence:** HIGH

## Summary

Phase 9 adds a comprehensive automated QA suite to the Coffee Journal app. The app currently has a single UI test file (`CoffeeJournalUITests.swift`) with 10 skeleton test methods covering basic navigation and CRUD flows, but no unit test target exists, no accessibility identifiers are in the codebase, the existing UI tests use `app.launchArguments = ["UI_TESTING"]` but the app does NOT check for this argument to configure in-memory storage, and there is no CI/CD pipeline. The existing UI tests reference UI elements by text labels and may be fragile against UI changes.

The codebase has substantial testable business logic separated into ViewModels (`BrewLogViewModel`, `SetupWizardViewModel`, `TastingNoteViewModel`, `InsightsViewModel`), utility structs (`FreshnessCalculator`, `BagLabelParser`, `FlavorExtractor`, `BrewPatternAnalyzer`, `BrewSuggestionEngine`), and computed model properties (`BrewLog.brewRatio`, `CoffeeBean.displayName`, `CoffeeBean.freshnessLevel`). These are well-suited for unit testing. The UI layer (SwiftUI views with SwiftData `@Query`) requires XCUITest for end-to-end validation.

A critical environment constraint exists: the development environment has only Command Line Tools installed, NOT Xcode.app. SwiftData `@Model` macro expansion requires Xcode.app. This means `swift test` via SPM will likely fail for tests that import SwiftData models directly. The practical approach is: (1) unit test pure logic that does NOT depend on `@Model` (FreshnessCalculator, BagLabelParser, BrewPatternAnalyzer, etc.) via `swift test`, and (2) test SwiftData persistence and UI flows via `xcodebuild test` which requires Xcode.app (user has confirmed they can run Xcode builds). CI/CD on GitHub Actions has Xcode.app and can run both.

**Primary recommendation:** Use Swift Testing (`@Test`/`@Suite`) for new unit tests of pure business logic; use XCTest/XCUITest for UI tests; add accessibility identifiers to views for robust element selection; configure in-memory ModelContainer via launch arguments for test data isolation; set up GitHub Actions CI with `xcodebuild test`.

## Standard Stack

### Core
| Framework | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Swift Testing | Swift 6.0+ | Unit tests for pure business logic | Apple's modern testing framework, cleaner syntax with `@Test`/`@Suite`/`#expect`, parallel by default |
| XCTest | Xcode 16+ | UI tests (XCUITest) and SwiftData integration tests | Only framework that supports UI testing; required for `XCUIApplication` |
| XCUITest | Xcode 16+ | End-to-end UI automation | Built into Xcode, tests real user flows through the app |
| SwiftData (in-memory) | iOS 17+ | Test data isolation | `ModelConfiguration(isStoredInMemoryOnly: true)` prevents test data pollution |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| GitHub Actions | N/A | CI/CD pipeline | Automated test runs on push/PR |
| xcodebuild | Xcode 16+ | CLI test execution | `xcodebuild test` for both unit and UI tests |
| swift test | Swift 6.0 | SPM-based unit test execution | Pure logic tests only (no @Model dependencies) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Swift Testing | XCTest only | XCTest works everywhere but Swift Testing has better syntax, parallelism, and is Apple's future direction |
| XCUITest | Maestro | Maestro is simpler for basic flows but adds external dependency, less Xcode integration |
| GitHub Actions | Xcode Cloud | Xcode Cloud is Apple-native but costs money, less flexible |

## Architecture Patterns

### Recommended Project Structure
```
CoffeeJournalTests/                   # Unit + Integration test target
    Utilities/
        FreshnessCalculatorTests.swift    # Pure logic tests
        BagLabelParserTests.swift         # Pure logic tests
    Services/
        FlavorExtractorTests.swift        # NL framework tests
        BrewPatternAnalyzerTests.swift    # Pure logic tests
        BrewSuggestionEngineTests.swift   # Pure logic tests
    ViewModels/
        BrewLogViewModelTests.swift       # ViewModel logic tests
        SetupWizardViewModelTests.swift   # ViewModel logic tests
        TastingNoteViewModelTests.swift   # ViewModel logic tests
    Models/
        BrewLogComputedTests.swift        # Model computed property tests
        CoffeeBeanComputedTests.swift     # Model computed property tests
    Helpers/
        TestHelpers.swift                 # Shared test utilities

CoffeeJournalUITests/                  # UI test target (existing)
    Helpers/
        AccessibilityIdentifiers.swift    # Shared with main target
        UITestHelpers.swift               # Page object helpers
    CoffeeJournalUITests.swift            # Existing (rewritten)
    SetupWizardUITests.swift              # Wizard flow tests
    BrewLogUITests.swift                  # Brew CRUD tests
    BeanUITests.swift                     # Bean CRUD tests
    EquipmentUITests.swift                # Equipment CRUD tests
    NavigationUITests.swift               # Tab and navigation tests

CoffeeJournal/
    Utilities/
        AccessibilityIdentifiers.swift    # Shared enum file (both targets)
```

### Pattern 1: In-Memory ModelContainer for Test Isolation
**What:** Configure the app to use in-memory SwiftData storage during UI tests so each test run starts clean.
**When to use:** All XCUITest runs.
**Example:**
```swift
// In CoffeeJournalApp.swift - check for test launch argument
init() {
    let schema = Schema(versionedSchema: SchemaV1.self)

    var inMemory = false
    #if DEBUG
    if CommandLine.arguments.contains("UITESTING") {
        inMemory = true
    }
    #endif

    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: inMemory,
        cloudKitDatabase: .none
    )

    do {
        container = try ModelContainer(for: schema, configurations: [config])
    } catch {
        fatalError("Failed to create ModelContainer: \(error)")
    }
}
```
Source: [Hacking with Swift - SwiftData UI Tests](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-ui-tests-for-your-swiftdata-code)

### Pattern 2: Swift Testing for Pure Logic
**What:** Use `@Test` and `@Suite` for unit tests that don't require SwiftData models.
**When to use:** Testing FreshnessCalculator, BagLabelParser, BrewPatternAnalyzer, BrewSuggestionEngine, and ViewModel computed properties that don't require `@Model` instances.
**Example:**
```swift
import Testing
@testable import CoffeeJournal

@Suite("FreshnessCalculator Tests")
struct FreshnessCalculatorTests {

    @Test("Peak freshness within 14 days")
    func peakFreshness() {
        let level = FreshnessCalculator.freshnessLevel(daysSinceRoast: 7)
        #expect(level == .peak)
    }

    @Test("Stale after 30 days")
    func staleFreshness() {
        let level = FreshnessCalculator.freshnessLevel(daysSinceRoast: 45)
        #expect(level == .stale)
    }

    @Test("Boundary: day 14 is peak, day 15 is acceptable")
    func freshnessBoundary() {
        #expect(FreshnessCalculator.freshnessLevel(daysSinceRoast: 14) == .peak)
        #expect(FreshnessCalculator.freshnessLevel(daysSinceRoast: 15) == .acceptable)
    }
}
```

### Pattern 3: XCTest with In-Memory ModelContainer for Integration Tests
**What:** Use XCTest with `@MainActor` and in-memory ModelContainer for tests that need SwiftData persistence.
**When to use:** Testing ViewModel.save() methods, model relationships, computed properties on @Model classes.
**Example:**
```swift
import XCTest
import SwiftData
@testable import CoffeeJournal

@MainActor
final class BrewLogIntegrationTests: XCTestCase {
    var container: ModelContainer!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: BrewMethod.self, Grinder.self, CoffeeBean.self, BrewLog.self, TastingNote.self,
            configurations: config
        )
    }

    override func tearDownWithError() throws {
        container = nil
    }

    func testBrewRatioCalculation() throws {
        let context = container.mainContext
        let method = BrewMethod(name: "V60", category: .pourOver)
        context.insert(method)

        let log = BrewLog()
        log.dose = 15
        log.waterAmount = 250
        log.brewMethod = method
        context.insert(log)

        XCTAssertEqual(log.brewRatio, 250.0 / 15.0, accuracy: 0.01)
        XCTAssertEqual(log.brewRatioFormatted, "1:16.7")
    }
}
```
Source: [Hacking with Swift - SwiftData Unit Tests](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code)

### Pattern 4: Centralized Accessibility Identifiers
**What:** Define all accessibility identifiers in a single shared enum file, included in both main app and UI test targets.
**When to use:** Every view that needs UI test interaction.
**Example:**
```swift
// AccessibilityIdentifiers.swift (shared between app and UI test targets)
enum AccessibilityID {
    enum Setup {
        static let welcomeTitle = "setup.welcome.title"
        static let getStartedButton = "setup.welcome.getStarted"
        static let methodSelectionTitle = "setup.methods.title"
        static let continueButton = "setup.continue"
        static let skipButton = "setup.skip"
    }

    enum Brews {
        static let addButton = "brews.add"
        static let list = "brews.list"
        static let doseField = "brews.form.dose"
        static let saveButton = "brews.form.save"
        static let cancelButton = "brews.form.cancel"
    }

    enum Beans {
        static let addButton = "beans.add"
        static let list = "beans.list"
        static let roasterField = "beans.form.roaster"
        static let nameField = "beans.form.name"
        static let saveButton = "beans.form.save"
    }

    enum Equipment {
        static let addMethodButton = "equipment.methods.add"
        static let addGrinderButton = "equipment.grinders.add"
        static let grinderNameField = "equipment.grinder.name"
    }

    enum Tabs {
        static let brews = "tab.brews"
        static let beans = "tab.beans"
        static let methods = "tab.methods"
        static let grinders = "tab.grinders"
        static let settings = "tab.settings"
    }
}
```

### Pattern 5: Page Object Model for UI Tests
**What:** Encapsulate UI interactions in helper structs/classes so test methods read like user stories.
**When to use:** All XCUITest test classes.
**Example:**
```swift
// UITestHelpers.swift
struct SetupWizardPage {
    let app: XCUIApplication

    var isVisible: Bool {
        app.staticTexts[AccessibilityID.Setup.welcomeTitle].waitForExistence(timeout: 3)
    }

    func tapGetStarted() {
        app.buttons[AccessibilityID.Setup.getStartedButton].tap()
    }

    func selectMethod(_ name: String) {
        app.buttons[name].tap()
    }

    func tapContinue() {
        app.buttons[AccessibilityID.Setup.continueButton].tap()
    }

    func skipGrinder() {
        app.buttons[AccessibilityID.Setup.skipButton].tap()
    }

    func completeWithDefaults() {
        if isVisible {
            tapGetStarted()
            selectMethod("Espresso")
            tapContinue()
            skipGrinder()
        }
    }
}
```

### Anti-Patterns to Avoid
- **Hardcoded string identifiers in tests:** Use centralized `AccessibilityID` enum instead of inline strings like `app.buttons["Add Brew"]`. Inline strings break silently when UI text changes.
- **sleep() in tests:** Use `waitForExistence(timeout:)` instead. sleep() makes tests slow and flaky.
- **Testing SwiftData @Query in unit tests:** @Query only works within SwiftUI view lifecycle. Test persistence logic through ViewModels and ModelContext directly.
- **Shared mutable state between tests:** Each test must create its own in-memory container. Never share ModelContainer instances between test methods.
- **Monolithic test files:** Split into focused test files by feature area. One 300-line file is harder to maintain than five 60-line files.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Test data isolation | Custom database reset logic | `ModelConfiguration(isStoredInMemoryOnly: true)` | In-memory containers auto-clean; custom reset logic is error-prone |
| Element finding in UI tests | String-matching with `staticTexts["text"]` | `.accessibilityIdentifier()` + `AccessibilityID` enum | Text changes break tests; identifiers are stable |
| Test parallelism | Custom test orchestration | Swift Testing default parallelism + `@Suite(.serialized)` where needed | Framework handles parallel execution correctly |
| CI/CD pipeline | Custom scripts | GitHub Actions with `xcodebuild test` | Well-documented, maintained, macOS runners available |
| Test helpers | Repeated setup code in each test | `setUp()`/`tearDown()` (XCTest) or `init()`/`deinit` (Swift Testing) | Framework-level lifecycle management |

**Key insight:** Apple's testing frameworks handle the hard parts (simulator management, parallel execution, data isolation). Custom solutions add maintenance burden without benefit.

## Common Pitfalls

### Pitfall 1: SwiftData @Model Macro Expansion in CLI
**What goes wrong:** `swift test` fails because `@Model` macros cannot expand without Xcode.app's macro plugins.
**Why it happens:** The development environment uses Command Line Tools only. SwiftData macros are shipped as Xcode plugins, not standalone CLI components.
**How to avoid:** Split tests into two categories: (1) Pure logic tests (no @Model) that can run via `swift test`, and (2) SwiftData integration tests that require `xcodebuild test` (Xcode.app or CI). Structure test targets so pure-logic tests are in a separate SPM test target or clearly separated.
**Warning signs:** Build errors like "Unable to find plugin" or "@Model macro expansion failed" when running `swift test`.

### Pitfall 2: UI Tests Not Isolated from Previous State
**What goes wrong:** Tests pass individually but fail when run as a suite because state from a previous test persists.
**Why it happens:** App uses persistent SwiftData storage during tests. `@AppStorage(hasCompletedSetup)` persists across test runs via UserDefaults.
**How to avoid:** (1) Pass `UITESTING` launch argument and configure in-memory ModelContainer. (2) Reset UserDefaults in test launch arguments: `app.launchArguments += ["-hasCompletedSetup", "NO"]` (iOS automatically treats `-key value` arguments as UserDefaults overrides).
**Warning signs:** Tests pass when run individually but fail in suite. Tests behave differently on first vs subsequent runs.

### Pitfall 3: Flaky UI Tests Due to Animations and Timing
**What goes wrong:** UI tests intermittently fail because elements are not yet visible or tappable.
**Why it happens:** SwiftUI animations, sheet presentations, and navigation transitions take time. Tests execute faster than animations complete.
**How to avoid:** (1) Always use `waitForExistence(timeout:)` before interacting with elements. (2) Set `UIView.setAnimationsEnabled(false)` via launch argument. (3) Use reasonable timeouts (2-5 seconds, not 0.5).
**Warning signs:** Tests pass locally but fail in CI. Tests pass most of the time but occasionally fail.

### Pitfall 4: @MainActor Requirements for SwiftData Tests
**What goes wrong:** Compiler errors about accessing MainActor-isolated properties from non-isolated context.
**Why it happens:** `ModelContainer.mainContext` is `@MainActor`-isolated. Test methods need explicit `@MainActor` annotation.
**How to avoid:** Mark entire XCTestCase class with `@MainActor` when testing SwiftData persistence. For Swift Testing, use `@MainActor` on the `@Suite` struct/class.
**Warning signs:** Compile errors mentioning "cannot access 'mainContext' from non-isolated context".

### Pitfall 5: Forgetting to Add Files to Both Targets
**What goes wrong:** `AccessibilityIdentifiers.swift` or shared helpers compile in the main target but not in the test target (or vice versa).
**Why it happens:** Xcode target membership must be set explicitly for each file.
**How to avoid:** When creating shared files like `AccessibilityIdentifiers.swift`, ensure both the main app target and the test target are checked in Xcode's target membership.
**Warning signs:** "Cannot find 'AccessibilityID' in scope" errors in the test target.

### Pitfall 6: GitHub Actions macOS Runner + Simulator Issues
**What goes wrong:** CI tests fail with "Unable to find a destination matching the provided destination specifier" or tests run multiple times.
**Why it happens:** macOS runner images change available simulators across versions. Recent issues with macOS-15 runners and iOS 18.2 causing duplicate test runs.
**How to avoid:** (1) Pin to a specific macOS runner version (e.g., `macos-14`). (2) Use `-parallel-testing-enabled NO` for UI tests. (3) Use generic destination like `platform=iOS Simulator,name=iPhone 16,OS=latest`. (4) Disable code signing with `CODE_SIGNING_ALLOWED='NO'`.
**Warning signs:** CI passes locally but fails on GitHub. Tests report double the expected test count.

## Code Examples

Verified patterns from official sources:

### In-Memory ModelContainer for Tests
```swift
// Source: Apple Developer Documentation, Hacking with Swift
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(
    for: BrewMethod.self, Grinder.self, CoffeeBean.self, BrewLog.self, TastingNote.self,
    configurations: config
)
let context = container.mainContext
```

### Launch Argument Check for Test Mode
```swift
// Source: https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-ui-tests-for-your-swiftdata-code
// In App init:
#if DEBUG
if CommandLine.arguments.contains("UITESTING") {
    inMemory = true
}
#endif
```

### UserDefaults Reset via Launch Arguments
```swift
// Source: https://blog.codecentric.de/en/2018/06/resetting-ios-application-state-userdefaults-ui-tests/
// In UI test setUp:
app.launchArguments += ["-hasCompletedSetup", "NO"]  // Reset setup flag
// or
app.launchArguments += ["-hasCompletedSetup", "YES"]  // Skip setup wizard
```

### SwiftUI Accessibility Identifier
```swift
// Source: Apple Developer Documentation
Button("Add Brew") { /* action */ }
    .accessibilityIdentifier(AccessibilityID.Brews.addButton)
```

### XCUITest Element Queries
```swift
// Source: https://www.hackingwithswift.com/articles/148/xcode-ui-testing-cheat-sheet
let addButton = app.buttons[AccessibilityID.Brews.addButton]
XCTAssertTrue(addButton.waitForExistence(timeout: 3))
addButton.tap()
```

### GitHub Actions Workflow for iOS Tests
```yaml
# Source: https://qualitycoding.org/github-actions-ci-xcode/
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.0.app/Contents/Developer
      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -project CoffeeJournal.xcodeproj \
            -scheme CoffeeJournal \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
            -only-testing:CoffeeJournalTests \
            CODE_SIGNING_ALLOWED='NO' \
            -parallel-testing-enabled NO
      - name: Run UI Tests
        run: |
          xcodebuild test \
            -project CoffeeJournal.xcodeproj \
            -scheme CoffeeJournal \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
            -only-testing:CoffeeJournalUITests \
            CODE_SIGNING_ALLOWED='NO' \
            -parallel-testing-enabled NO
```

### BrewLogViewModel Unit Test (No @Model Dependencies)
```swift
import Testing
@testable import CoffeeJournal

@Suite("BrewLogViewModel Tests")
struct BrewLogViewModelTests {

    @Test("Brew ratio displays '--' when dose is zero")
    func ratioWithZeroDose() {
        let vm = BrewLogViewModel()
        vm.dose = 0
        vm.waterAmount = 250
        #expect(vm.brewRatio == "--")
    }

    @Test("Brew ratio calculates correctly for pour-over")
    func ratioForPourOver() {
        let vm = BrewLogViewModel()
        vm.dose = 15
        vm.waterAmount = 250
        // Note: selectedMethod is nil, so it defaults to non-espresso path
        #expect(vm.brewRatio == "1:16.7")
    }

    @Test("canSave requires method and dose")
    func canSaveValidation() {
        let vm = BrewLogViewModel()
        #expect(vm.canSave == false)
        vm.dose = 15
        #expect(vm.canSave == false)  // still no method
    }

    @Test("Timer state machine transitions")
    func timerTransitions() {
        let vm = BrewLogViewModel()
        #expect(vm.timerState == .idle)
        vm.startTimer()
        #expect(vm.timerState == .running)
        vm.pauseTimer()
        #expect(vm.timerState == .paused)
        vm.resumeTimer()
        #expect(vm.timerState == .running)
        vm.stopTimer()
        #expect(vm.timerState == .stopped)
        vm.resetTimer()
        #expect(vm.timerState == .idle)
    }
}
```

### BagLabelParser Unit Test
```swift
import Testing
@testable import CoffeeJournal

@Suite("BagLabelParser Tests")
struct BagLabelParserTests {

    @Test("Detects known origins")
    func originDetection() {
        let result = BagLabelParser.parse(recognizedTexts: ["Blue Bottle", "Ethiopia Yirgacheffe"])
        #expect(result.origin == "Ethiopia")
    }

    @Test("Detects roast level with multi-word priority")
    func roastLevelMultiWord() {
        let result = BagLabelParser.parse(recognizedTexts: ["Medium Light Roast"])
        #expect(result.roastLevel == "medium_light")
    }

    @Test("Parses ISO date format")
    func isoDateParsing() {
        let result = BagLabelParser.parse(recognizedTexts: ["Roasted 2026-01-15"])
        #expect(result.roastDate != nil)
    }

    @Test("First line becomes roaster")
    func roasterFromFirstLine() {
        let result = BagLabelParser.parse(recognizedTexts: ["Counter Culture", "Ethiopia"])
        #expect(result.roaster == "Counter Culture")
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| XCTest only (`XCTestCase`) | Swift Testing (`@Test`/`@Suite`) for unit tests | Xcode 16 / Swift 6.0 (2024) | Cleaner syntax, parallel by default, parameterized tests built-in |
| `XCTAssert*` assertions | `#expect()` and `#require()` | Swift Testing (2024) | Single unified assertion macro, better error messages |
| `setUp()`/`tearDown()` | `init()`/`deinit` (Swift Testing) | Swift Testing (2024) | More Swift-idiomatic, struct-based test suites |
| `func testX()` naming | `@Test("description") func x()` | Swift Testing (2024) | Free-form naming, display names separate from function names |
| XCUITest for UI + unit | Swift Testing for unit, XCUITest for UI | 2024-present | Swift Testing does NOT support UI testing yet |

**Deprecated/outdated:**
- `XCTest.setUp()/tearDown()` for unit tests: Still works but Swift Testing's `init()/deinit` is preferred for new code.
- `func testMethodName()` naming convention: Still required for XCTest but optional in Swift Testing where `@Test` attribute identifies tests.
- Note: Swift Testing and XCTest can coexist in the same test target. UI tests MUST use XCTest.

## Requirements Definition

The roadmap references TEST-01 through TEST-05 but these do not exist in REQUIREMENTS.md. Based on the phase goal and success criteria, the following requirements should be defined:

| Requirement | Description | Maps to Success Criteria |
|-------------|-------------|-------------------------|
| TEST-01 | Unit tests exist for all business logic utilities (FreshnessCalculator, BagLabelParser, BrewPatternAnalyzer, BrewSuggestionEngine, FlavorExtractor) | SC-2 (integration tests validate persistence) |
| TEST-02 | Unit tests exist for ViewModel computed properties and state logic (BrewLogViewModel, SetupWizardViewModel, TastingNoteViewModel) | SC-1 (verify user flows) |
| TEST-03 | UI tests verify CRUD flows for equipment (methods, grinders), beans, and brew logs including creation, viewing, editing, and deletion | SC-1, SC-4 (user flows + critical journeys) |
| TEST-04 | Integration tests validate SwiftData persistence with in-memory ModelContainer for model CRUD and relationships | SC-2 (SwiftData persistence validation) |
| TEST-05 | CI/CD pipeline runs full test suite on push/PR with clear pass/fail reporting | SC-3, SC-5 (CI pipeline + local execution) |

## Testable Components Inventory

### Pure Logic (No @Model dependency -- testable via `swift test`)
| Component | File | Key Logic to Test |
|-----------|------|-------------------|
| FreshnessCalculator | Utilities/FreshnessCalculator.swift | daysSinceRoast boundary, freshnessLevel thresholds |
| BagLabelParser | Utilities/BagLabelParser.swift | Origin/variety/roastLevel detection, date parsing, multi-word priority |
| BrewStepTemplates | Utilities/BrewStepTemplates.swift | Steps for each method category |
| BrewLogViewModel (partial) | ViewModels/BrewLogViewModel.swift | brewRatio, canSave, showsYield, timer state machine, manualBrewTimeTotal |
| SetupWizardViewModel (partial) | ViewModels/SetupWizardViewModel.swift | canProceed per step, nextStep/previousStep, stepTitle |
| TastingNoteViewModel (partial) | ViewModels/TastingNoteViewModel.swift | toggleFlavor, addCustomTag, removeCustomTag, hasChanges, allDisplayTags |

### SwiftData Integration (Requires `xcodebuild test`)
| Component | File | Key Logic to Test |
|-----------|------|-------------------|
| BrewLog computed properties | Models/BrewLog.swift | brewRatio with espresso vs non-espresso, brewTimeFormatted |
| CoffeeBean computed properties | Models/CoffeeBean.swift | displayName fallback logic, roastLevelEnum, processingMethodEnum |
| BrewLogViewModel.saveBrew | ViewModels/BrewLogViewModel.swift | Creates BrewLog with correct properties, updates equipment stats |
| SetupWizardViewModel.saveEquipment | ViewModels/SetupWizardViewModel.swift | Creates BrewMethods from templates, creates Grinder, trims whitespace |
| TastingNoteViewModel.save | ViewModels/TastingNoteViewModel.swift | Creates/updates TastingNote, JSON encodes flavor tags |
| BrewPatternAnalyzer | Services/Insights/BrewPatternAnalyzer.swift | Needs @Model instances for relationships (brewMethod, coffeeBean) |
| BrewSuggestionEngine | Services/Insights/BrewSuggestionEngine.swift | Needs @Model instances for bean.id, method.id comparisons |
| FlavorExtractor | Services/Insights/FlavorExtractor.swift | NLTagger/NLEmbedding (system framework, may need runtime environment) |

### UI Tests (XCUITest)
| User Journey | Views Involved | Key Verifications |
|-------------|----------------|-------------------|
| Setup Wizard | SetupWizardView, WelcomeStepView, MethodSelectionView, GrinderEntryView, SetupCompleteView | Complete flow, skip grinder, method selection |
| Add Brew Log | AddBrewLogView, BrewTimerView | Fill form, save, verify in list |
| View Brew Detail | BrewLogListView, BrewLogDetailView | Tap brew, see parameters |
| Add Coffee Bean | AddBeanView, BeanListView | Fill form, save, verify in list |
| Add Grinder | AddGrinderView, GrinderListView | Fill form, save, verify in list |
| Tab Navigation | MainTabView | Navigate all 5 tabs |
| Settings | SettingsView | Re-run wizard, sync status |
| Search Brews | BrewLogListView, BrewHistoryListContent | Search text, filter results |

## Open Questions

1. **Can BrewLogViewModel be unit-tested without @Model for selectedMethod?**
   - What we know: `brewRatio` checks `selectedMethod?.category == .espresso`. Without a real BrewMethod @Model instance, `selectedMethod` is nil and the espresso-specific path cannot be tested.
   - What's unclear: Whether a plain `BrewMethod(name:category:)` initializer works outside SwiftData context for read-only computed property testing.
   - Recommendation: Try it -- if BrewMethod can be instantiated outside a ModelContainer for read-only property access, this unlocks more pure-logic unit tests. If not, these tests move to the integration test category. The `@Model` class may still be instantiable without a container for computed property reads.

2. **Delete operation coverage**
   - What we know: The UI tests should cover deletion, but delete flows (swipe-to-delete on lists) are less straightforward in XCUITest.
   - What's unclear: Whether the app currently supports swipe-to-delete on all list views.
   - Recommendation: Verify swipe-to-delete is implemented in list views. If not, test "add then verify" flows without delete. Deletion can be verified at the integration test level via ModelContext.delete().

3. **Edit operation coverage in UI**
   - What we know: Detail views use `@Bindable` for editing. Equipment detail views have onChange modifiers that update timestamps.
   - What's unclear: Whether navigation from list to detail to edit and back is consistently testable via XCUITest.
   - Recommendation: Focus UI edit tests on the most critical flow (edit a brew method name, verify it appears updated in the list). More complex edit scenarios can be covered at the integration test level.

## Sources

### Primary (HIGH confidence)
- [Hacking with Swift - SwiftData Unit Tests](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code) - In-memory container setup, @MainActor requirement, test structure
- [Hacking with Swift - SwiftData UI Tests](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-ui-tests-for-your-swiftdata-code) - Launch arguments, in-memory config for UI tests, test isolation
- [Apple Developer Documentation - Adding Unit Tests](https://developer.apple.com/documentation/xcode/adding-unit-tests-to-your-existing-project) - Xcode test target setup
- [Hacking with Swift - XCUITest Cheat Sheet](https://www.hackingwithswift.com/articles/148/xcode-ui-testing-cheat-sheet) - Element queries, assertions, waitForExistence

### Secondary (MEDIUM confidence)
- [Swift with Majid - Swift Testing Lifecycle](https://swiftwithmajid.com/2024/10/29/introducing-swift-testing-lifecycle/) - @Suite with SwiftData, init/deinit, .serialized
- [Quality Coding - GitHub Actions CI for Xcode](https://qualitycoding.org/github-actions-ci-xcode/) - CI workflow setup, xcodebuild flags
- [Composing Accessibility Identifiers](https://betterprogramming.pub/composing-accessibility-identifiers-for-swiftui-components-10849847bd10) - Hierarchical ID naming patterns
- [Configuring UI Tests with Launch Arguments](https://www.polpiella.dev/configuring-ui-tests-with-launch-arguments) - Launch argument patterns for test configuration

### Tertiary (LOW confidence)
- [GitHub Actions runner-images Issue #11712](https://github.com/actions/runner-images/issues/11712) - macOS-15 parallel testing bugs (may be resolved by the time Phase 9 executes)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - XCTest and Swift Testing are Apple's official frameworks with excellent documentation
- Architecture: HIGH - In-memory ModelContainer, accessibility identifiers, and page object patterns are well-established
- Pitfalls: HIGH - SwiftData macro expansion limitation is verified from project history; test isolation patterns are well-documented
- CI/CD: MEDIUM - GitHub Actions macOS runners work but exact Xcode/simulator versions depend on runner image at execution time

**Research date:** 2026-02-10
**Valid until:** 2026-03-10 (30 days -- testing frameworks are stable)
