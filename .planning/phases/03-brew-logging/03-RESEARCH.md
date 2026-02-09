# Phase 3: Brew Logging - Research

**Researched:** 2026-02-09
**Domain:** SwiftUI brew log creation with equipment/bean selection, parameter entry, timer, photos, rating, and CloudKit sync
**Confidence:** HIGH

## Summary

This phase implements the core journaling loop: creating brew log entries that link user's equipment (grinder + brew method) and coffee beans to specific brewing parameters, a brew timer, photos, rating, and freeform notes. The BrewLog @Model already exists in SchemaV1 with the correct CloudKit-safe structure (all properties defaulted, optional relationships to BrewMethod, Grinder, CoffeeBean). The primary technical challenges are: (1) a multi-section form that adapts parameter fields based on the selected method's category, (2) a grind setting selector constrained to the selected grinder's range, (3) an integrated brew timer with optional step-by-step guidance, and (4) auto-calculated brew ratio.

The existing codebase provides strong precedent patterns: @Query list views with parent/child search, @Bindable detail views, EquipmentPhotoPickerView for photo handling, Form-based entry views with toolbar Save/Cancel, and the monochrome design system. The brew logging form is the most complex view in the app so far -- it combines data from three different model types (BrewMethod, Grinder, CoffeeBean) and introduces a real-time timer component. An @Observable ViewModel is warranted here to manage form state, validation, ratio calculation, and timer logic, following the same pattern used by SetupWizardViewModel.

**Primary recommendation:** Use an @Observable BrewLogViewModel to manage the full form state including timer, ratio calculation, and method-specific parameter visibility. Present brew log creation as a modal sheet with a multi-section Form. Split implementation into three plans: (1) core entry flow with equipment/bean selection and parameter entry, (2) brew timer with step-by-step guidance, (3) photos, rating, notes, and list/detail views.

## Standard Stack

### Core (Already in Project)

| Library/Framework | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All views (Form, Picker, Slider, Stepper, TimelineView) | Already used throughout app |
| SwiftData | iOS 17+ | BrewLog @Model, @Query for list views, relationships | Already configured with CloudKit |
| CloudKit | iOS 17+ | Automatic sync via ModelContainer | Already configured in CoffeeJournalApp.swift |
| PhotosUI | iOS 17+ | EquipmentPhotoPickerView (reuse existing) | Already built and tested |

### Supporting (New Usage in This Phase)

| Library/Framework | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| Foundation Timer | iOS 17+ | Timer.publish for brew timer updates | Brew timer countdown/countup |
| TimelineView | iOS 17+ | Efficient periodic UI updates for timer display | Alternative to Timer.publish for display |

### No New External Dependencies

All brew logging functionality is achievable with Apple frameworks already in the project. No new dependencies needed.

## Architecture Patterns

### Recommended Project Structure (New Files)

```
CoffeeJournal/
├── Models/
│   └── BrewLog.swift              # Extend existing model (add grinderSetting, computed ratio)
├── Views/
│   └── Brewing/
│       ├── AddBrewLogView.swift       # Modal form for creating a brew log
│       ├── BrewParametersSection.swift # Method-adaptive parameter inputs
│       ├── BrewTimerView.swift        # Integrated timer with start/stop/reset
│       ├── BrewStepGuideView.swift    # Step-by-step guidance overlay
│       ├── GrindSettingPicker.swift   # Slider/Stepper constrained to grinder range
│       ├── BrewRatioView.swift        # Auto-calculated ratio display
│       ├── BrewLogListView.swift      # Chronological list of brew logs
│       ├── BrewLogRow.swift           # List row component
│       └── BrewLogDetailView.swift    # Read/edit detail view
├── ViewModels/
│   └── BrewLogViewModel.swift     # Form state, timer, validation, ratio calc
└── Utilities/
    └── BrewStepTemplates.swift    # Step-by-step brew guidance data
```

### Pattern 1: @Observable ViewModel for Complex Form

**What:** The brew log creation form is complex enough to warrant a dedicated ViewModel. It manages: equipment/bean selection state, method-specific parameter visibility, grind setting constraints, ratio calculation, timer state, and save logic.

**When to use:** This form combines data from 3 model types, has conditional field visibility, real-time calculations, and timer state -- exceeding the threshold where @Query-in-view is sufficient.

**Example:**
```swift
// Source: Established project pattern (SetupWizardViewModel)
@Observable
class BrewLogViewModel {
    // Equipment selection
    var selectedMethod: BrewMethod?
    var selectedGrinder: Grinder?
    var selectedBean: CoffeeBean?

    // Core parameters
    var dose: Double = 0       // grams
    var waterAmount: Double = 0 // grams (or ml)
    var brewTime: Double = 0    // seconds (set by timer or manual)
    var waterTemperature: Double = 0
    var grinderSetting: Double = 0

    // Method-specific (espresso)
    var yieldAmount: Double = 0
    var pressureProfile: String = ""

    // Rating & notes
    var rating: Int = 0
    var notes: String = ""
    var photoData: Data?

    // Timer state
    var timerState: TimerState = .idle
    var timerStartDate: Date?
    var elapsedSeconds: Double = 0

    // Computed
    var brewRatio: String {
        guard dose > 0 else { return "--" }
        let divisor = selectedMethod?.category == .espresso ? yieldAmount : waterAmount
        guard divisor > 0 else { return "--" }
        let ratio = divisor / dose
        return String(format: "1:%.1f", ratio)
    }

    var canSave: Bool {
        selectedMethod != nil && dose > 0
    }

    var showsYield: Bool {
        selectedMethod?.category == .espresso
    }

    var showsWaterAmount: Bool {
        selectedMethod?.category != .espresso
    }

    var showsTemperature: Bool {
        selectedMethod?.category != .pourOver
    }

    func saveBrew(context: ModelContext) {
        let log = BrewLog()
        log.brewMethod = selectedMethod
        log.grinder = selectedGrinder
        log.coffeeBean = selectedBean
        log.dose = dose
        log.waterAmount = waterAmount
        log.brewTime = brewTime
        log.waterTemperature = waterTemperature
        log.yieldAmount = yieldAmount
        log.pressureProfile = pressureProfile
        log.grinderSetting = grinderSetting
        log.rating = rating
        log.notes = notes
        log.photoData = photoData
        context.insert(log)

        // Update equipment usage stats
        if let method = selectedMethod {
            method.brewCount += 1
            method.lastUsedDate = Date()
        }
        if let grinder = selectedGrinder {
            grinder.brewCount += 1
            grinder.lastUsedDate = Date()
        }
    }
}
```

**Confidence:** HIGH -- follows SetupWizardViewModel pattern already proven in codebase.

### Pattern 2: SwiftData Picker with Optional Relationship

**What:** Use @Query to fetch available BrewMethods/Grinders/Beans, display in a Picker or selection list, bind to ViewModel's optional selection property.

**When to use:** Equipment and bean selection in the brew log form.

**Critical detail:** The `.tag()` type MUST match the selection binding type. For optional bindings, use `.tag(Optional(item))` not `.tag(item)`.

**Example:**
```swift
// Source: hackingwithswift.com/forums/swiftui/correct-use-of-swiftdata-in-a-picker
struct MethodPickerSection: View {
    @Query(sort: \BrewMethod.name) private var methods: [BrewMethod]
    @Bindable var viewModel: BrewLogViewModel

    var body: some View {
        Section("Brew Method") {
            Picker("Method", selection: $viewModel.selectedMethod) {
                Text("Select...").tag(nil as BrewMethod?)
                ForEach(methods) { method in
                    Text(method.name).tag(Optional(method))
                }
            }
        }
    }
}
```

**Confidence:** HIGH -- Verified pattern from HackingWithSwift forums, `.tag(Optional(item))` is the documented fix for optional Picker selection with SwiftData models.

### Pattern 3: Method-Adaptive Parameter Sections

**What:** Show/hide form sections based on the selected brew method's category. Espresso shows yield + pressure. Pour-over shows water amount only. Immersion/Other shows water amount + temperature.

**When to use:** The brew parameters section of the form.

**Example:**
```swift
// Source: Derived from existing MethodDetailView parametersForCategory pattern
@ViewBuilder
private var parametersSection: some View {
    Section("Brew Parameters") {
        // Always shown
        HStack {
            Text("Dose")
            Spacer()
            TextField("g", value: $viewModel.dose, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }

        if viewModel.showsWaterAmount {
            HStack {
                Text("Water")
                Spacer()
                TextField("g", value: $viewModel.waterAmount, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }

        if viewModel.showsYield {
            HStack {
                Text("Yield")
                Spacer()
                TextField("g", value: $viewModel.yieldAmount, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }

        if viewModel.showsTemperature {
            HStack {
                Text("Temperature")
                Spacer()
                TextField("\u{00B0}C", value: $viewModel.waterTemperature, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
    }
}
```

**Confidence:** HIGH -- uses the same category-based switching as MethodDetailView's `parametersForCategory()`.

### Pattern 4: Grind Setting Constrained to Grinder Range

**What:** When a grinder is selected, show a Slider (or Stepper) for grind setting that is constrained to the grinder's settingMin...settingMax range with the grinder's step value.

**When to use:** Grind setting selection in brew log form.

**Example:**
```swift
// Source: Derived from GrinderDetailView Stepper pattern
@ViewBuilder
private var grindSettingSection: some View {
    if let grinder = viewModel.selectedGrinder {
        Section("Grind Setting") {
            Slider(
                value: $viewModel.grinderSetting,
                in: grinder.settingMin...grinder.settingMax,
                step: grinder.settingStep
            ) {
                Text("Setting")
            } minimumValueLabel: {
                Text("\(grinder.settingMin, specifier: "%.0f")")
                    .font(AppTypography.caption)
            } maximumValueLabel: {
                Text("\(grinder.settingMax, specifier: "%.0f")")
                    .font(AppTypography.caption)
            }

            Text("Setting: \(viewModel.grinderSetting, specifier: "%.1f")")
                .font(AppTypography.headline)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
```

**Confidence:** HIGH -- Slider with in:/step: is standard SwiftUI; grinder model already stores min/max/step.

### Pattern 5: Brew Timer with State Machine

**What:** An integrated timer component that counts up from zero (or counts down from a target time). Uses Timer.publish for 1-second updates. Managed as a state machine (idle/running/paused/stopped).

**When to use:** The brew timer section of the form or as a standalone expandable component.

**Example:**
```swift
// Source: hackingwithswift.com + digitalbunker.dev timer patterns
enum TimerState {
    case idle      // Not started
    case running   // Actively counting
    case paused    // Paused mid-brew
    case stopped   // Finished, time recorded
}

// In BrewLogViewModel:
var timerState: TimerState = .idle
var timerStartDate: Date?
var pausedElapsed: TimeInterval = 0
var elapsedSeconds: TimeInterval = 0

func startTimer() {
    timerStartDate = Date()
    timerState = .running
}

func pauseTimer() {
    pausedElapsed = elapsedSeconds
    timerState = .paused
}

func resumeTimer() {
    timerStartDate = Date()
    timerState = .running
}

func stopTimer() {
    timerState = .stopped
    brewTime = elapsedSeconds
}

func resetTimer() {
    timerState = .idle
    timerStartDate = nil
    pausedElapsed = 0
    elapsedSeconds = 0
}

// Timer display in view:
struct BrewTimerView: View {
    @Bindable var viewModel: BrewLogViewModel
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text(formattedTime)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(AppColors.primary)

            HStack(spacing: AppSpacing.lg) {
                switch viewModel.timerState {
                case .idle:
                    Button("Start") { viewModel.startTimer() }
                        .monochromeButtonStyle()
                case .running:
                    Button("Pause") { viewModel.pauseTimer() }
                        .monochromeButtonStyle()
                    Button("Stop") { viewModel.stopTimer() }
                        .monochromeButtonStyle()
                case .paused:
                    Button("Resume") { viewModel.resumeTimer() }
                        .monochromeButtonStyle()
                    Button("Stop") { viewModel.stopTimer() }
                        .monochromeButtonStyle()
                case .stopped:
                    Button("Reset") { viewModel.resetTimer() }
                        .monochromeButtonStyle()
                }
            }
        }
        .onReceive(timer) { _ in
            guard viewModel.timerState == .running,
                  let start = viewModel.timerStartDate else { return }
            viewModel.elapsedSeconds = viewModel.pausedElapsed + Date().timeIntervalSince(start)
        }
    }

    private var formattedTime: String {
        let total = Int(viewModel.elapsedSeconds)
        let minutes = total / 60
        let seconds = total % 60
        let tenths = Int((viewModel.elapsedSeconds - Double(total)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}
```

**Confidence:** HIGH -- Timer.publish + onReceive is the standard SwiftUI timer pattern from hackingwithswift.com. State machine approach from digitalbunker.dev.

### Anti-Patterns to Avoid

- **Nesting NavigationStack in modal sheet form:** The AddBrewLogView will be presented in a sheet with its own NavigationStack. Do NOT nest another NavigationStack inside sub-views. Follow the established BagScannerSheet pattern.
- **Storing timer state in the model:** Timer state (running/paused) is ephemeral UI state. Only the final `brewTime` (total elapsed seconds) gets persisted to BrewLog.
- **Using TimelineView for the brew timer:** While TimelineView is more efficient for animations, Timer.publish with onReceive is simpler and gives direct control over pause/resume. The 0.1s update interval is negligible for battery. TimelineView would require more complex state management for pause/resume.
- **Modifying the BrewLog model schema:** The existing BrewLog schema has all the core fields. If additional fields are needed (like `grinderSetting`), add them with defaults -- CloudKit allows additions. But do NOT rename or remove existing fields.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Photo picking + compression | Custom camera UI | EquipmentPhotoPickerView (already exists) | Reuse existing component; handles picker, compression, error states |
| Ratio calculation display | Complex formatter | Simple String(format:) in computed property | Ratio is just division + formatting; no library needed |
| Timer formatting | Custom Date formatter pipeline | String(format: "%d:%02d.%d") | Simple integer division for mm:ss.t display |
| Empty state | Custom placeholder views | EmptyStateView (already exists) | Reuse existing component for brew log list empty state |
| Number input | Custom numeric keyboard | TextField with .keyboardType(.decimalPad) | Standard iOS pattern for decimal input |
| Star rating | Third-party rating library | Custom HStack of SF Symbol buttons | Simple enough to build (5 buttons), keeps zero-dependency constraint, monochrome compatible |
| Grind setting selector | Custom dial/wheel | SwiftUI Slider with in:/step: parameters | Standard component, grinder already provides min/max/step |

**Key insight:** The brew log form is complex in terms of state management (many fields, conditional visibility, timer), but every individual UI element is a standard SwiftUI component. The complexity lives in the ViewModel orchestration, not in custom views.

## Common Pitfalls

### Pitfall 1: Picker Tag Type Mismatch with Optional SwiftData Relationships

**What goes wrong:** Picker selection doesn't work -- tapping a method/grinder/bean does nothing, or selection resets to nil. No compiler error.
**Why it happens:** The `@State` or ViewModel property is `BrewMethod?` (optional), but `.tag(method)` provides `BrewMethod` (non-optional). The types don't match so SwiftUI silently ignores the selection.
**How to avoid:** Always use `.tag(Optional(item))` or `.tag(item as BrewMethod?)` when the selection binding is optional. Include a `.tag(nil as BrewMethod?)` option for "none selected."
**Warning signs:** Picker appears to work visually but selection state never updates.

### Pitfall 2: Timer Drift from Accumulated Increments

**What goes wrong:** Timer shows wrong elapsed time after pause/resume cycles. Time accumulates small errors, showing 4:02 when actual elapsed time is 4:00.
**Why it happens:** Using `elapsedSeconds += 1` on each timer fire (integer accumulation) instead of calculating from `Date()`. Timer fires are not perfectly periodic.
**How to avoid:** Always calculate elapsed time from a reference `Date()`: `elapsed = pausedElapsed + Date().timeIntervalSince(startDate)`. Never increment a counter.
**Warning signs:** Timer gradually drifts from actual wall clock time, especially after pause/resume.

### Pitfall 3: Form Keyboard Obscuring Input Fields

**What goes wrong:** When the user taps a decimal input field at the bottom of the form, the keyboard covers it. The user can't see what they're typing.
**Why it happens:** SwiftUI Form inside a sheet doesn't always auto-scroll to the focused field, especially with many sections.
**How to avoid:** Use `.scrollDismissesKeyboard(.interactively)` on the Form. Consider a toolbar button to dismiss the keyboard. Test all fields in the form with a physical keyboard present.
**Warning signs:** Users have to manually scroll while keyboard is up.

### Pitfall 4: Forgetting to Update Equipment Usage Stats

**What goes wrong:** After saving a brew, the equipment's brewCount and lastUsedDate are not updated. The statistics shown on equipment detail views remain at zero.
**Why it happens:** Saving the BrewLog only creates the log record with relationship pointers. The related BrewMethod and Grinder objects need their stats explicitly updated.
**How to avoid:** In the ViewModel's `saveBrew()`, after inserting the BrewLog, also update `method.brewCount += 1; method.lastUsedDate = Date()` and same for grinder. This is transactional -- all in the same save context.
**Warning signs:** Equipment "Usage Statistics" sections always show "Use this method in a brew to see stats here."

### Pitfall 5: Lost Form State When Sheet Dismisses

**What goes wrong:** User is mid-entry in a brew log, accidentally swipes down to dismiss the sheet. All form state is lost.
**Why it happens:** The ViewModel is created fresh each time the sheet presents.
**How to avoid:** Consider using `.interactiveDismissDisabled(hasUnsavedChanges)` on the sheet to prevent accidental dismissal when the form has data. This is the same pattern Apple uses in system apps.
**Warning signs:** User complaints about lost data entry.

### Pitfall 6: Grinder Setting Not Clamped to Range on Grinder Change

**What goes wrong:** User selects Grinder A (range 0-40), sets grind to 35, then switches to Grinder B (range 1-10). The grinderSetting value (35) is now out of range for the new grinder.
**Why it happens:** Changing the grinder selection does not reset or clamp the grinder setting value.
**How to avoid:** In the ViewModel, use a `didSet` observer on `selectedGrinder` or an `onChange` in the view to reset grinderSetting to the new grinder's midpoint or minimum.
**Warning signs:** Slider appears at the extreme end or displays incorrectly after switching grinders.

## Code Examples

### BrewLog Model Extension (Adding grinderSetting)

The existing BrewLog model needs a `grinderSetting` field. Since CloudKit allows adding new fields with defaults, this is a safe schema addition.

```swift
// Source: Existing BrewLog.swift + CloudKit add-only rule
@Model
final class BrewLog {
    var id: UUID = UUID()
    var dose: Double = 0
    var waterAmount: Double = 0
    var brewTime: Double = 0           // Total seconds
    var waterTemperature: Double = 0
    var yieldAmount: Double = 0        // Espresso yield
    var pressureProfile: String = ""   // Espresso pressure notes
    var grinderSetting: Double = 0     // NEW: grind setting used
    var rating: Int = 0                // 1-5 overall quality
    var notes: String = ""             // Freeform tasting notes
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var brewMethod: BrewMethod?
    var grinder: Grinder?
    var coffeeBean: CoffeeBean?

    // Computed: brew ratio
    var brewRatio: Double? {
        guard dose > 0 else { return nil }
        if let method = brewMethod, method.category == .espresso {
            return yieldAmount > 0 ? yieldAmount / dose : nil
        } else {
            return waterAmount > 0 ? waterAmount / dose : nil
        }
    }

    var brewRatioFormatted: String {
        guard let ratio = brewRatio else { return "--" }
        return String(format: "1:%.1f", ratio)
    }

    init() {}
}
```

### Star Rating Component (Monochrome)

```swift
// Source: hackingwithswift.com star rating pattern, adapted for monochrome
struct StarRatingView: View {
    @Binding var rating: Int
    let maxRating: Int = 5

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundStyle(index <= rating ? AppColors.primary : AppColors.muted)
                    .onTapGesture {
                        rating = index == rating ? 0 : index  // Tap same star to clear
                    }
            }
        }
    }
}
```

### Brew Step Template Data

```swift
// Source: Common coffee brew guides (Stumptown, Hario, etc.)
struct BrewStep: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let durationSeconds: Int       // 0 means untimed (user proceeds manually)
    let waterPercentage: Double?   // Percentage of total water for this step (nil = N/A)
}

struct BrewStepTemplate {
    static func steps(for category: MethodCategory) -> [BrewStep] {
        switch category {
        case .pourOver:
            return [
                BrewStep(name: "Bloom", description: "Pour 2x dose weight of water, let CO2 escape", durationSeconds: 30, waterPercentage: 0.13),
                BrewStep(name: "First Pour", description: "Pour in slow spiral to 60% of total water", durationSeconds: 30, waterPercentage: 0.47),
                BrewStep(name: "Second Pour", description: "Pour remaining water in slow spiral", durationSeconds: 30, waterPercentage: 0.40),
                BrewStep(name: "Drawdown", description: "Wait for water to drain through", durationSeconds: 90, waterPercentage: nil),
            ]
        case .espresso:
            return [
                BrewStep(name: "Pre-infusion", description: "Low pressure water contact", durationSeconds: 5, waterPercentage: nil),
                BrewStep(name: "Extraction", description: "Full pressure extraction", durationSeconds: 25, waterPercentage: nil),
            ]
        case .immersion:
            return [
                BrewStep(name: "Add Water", description: "Pour all water over grounds", durationSeconds: 10, waterPercentage: 1.0),
                BrewStep(name: "Steep", description: "Wait for extraction", durationSeconds: 240, waterPercentage: nil),
                BrewStep(name: "Plunge/Filter", description: "Separate grounds from brew", durationSeconds: 30, waterPercentage: nil),
            ]
        case .other:
            return [
                BrewStep(name: "Brew", description: "Follow your method's process", durationSeconds: 0, waterPercentage: nil),
            ]
        }
    }
}
```

### Brew Log List View with Sorting

```swift
// Source: Established BeanListView pattern in codebase
struct BrewLogListView: View {
    @State private var showingAddSheet = false

    var body: some View {
        BrewLogListContent()
            .navigationTitle("Brews")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    AddBrewLogView()
                }
            }
    }
}

struct BrewLogListContent: View {
    @Query(sort: \BrewLog.createdAt, order: .reverse) private var brews: [BrewLog]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if brews.isEmpty {
            EmptyStateView(
                systemImage: "cup.and.saucer",
                title: "No Brews Yet",
                message: "Log your first brew to start tracking"
            )
        } else {
            List {
                ForEach(brews) { brew in
                    NavigationLink {
                        BrewLogDetailView(brew: brew)
                    } label: {
                        BrewLogRow(brew: brew)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(brews[index])
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Timer + @State counter | Timer.publish + Date-based elapsed | iOS 15+ | Prevents drift; robust across pause/resume |
| ObservableObject ViewModel | @Observable ViewModel | iOS 17 | Less boilerplate, fine-grained updates |
| NavigationLink(isActive:) | NavigationStack + .sheet | iOS 16+ | Cleaner modal presentation |
| Manual Form scrolling | .scrollDismissesKeyboard(.interactively) | iOS 16+ | Better keyboard interaction |
| Custom dismiss prevention | .interactiveDismissDisabled() | iOS 15+ | Prevents accidental sheet dismissal |

**Deprecated/outdated:**
- `ObservableObject` + `@Published`: Use `@Observable` macro instead (iOS 17+)
- Timer counter accumulation: Always derive elapsed time from Date references
- `Text(Date(), style: .timer)`: This counts UP from a date, useful for display-only but not for pause/resume control

## Key Design Decisions (Recommendations)

### 1. Brew Log Entry: Modal Sheet (Not Navigation Push)

**Recommendation:** Present AddBrewLogView as a `.sheet` from the brew log list (or from a "+" button in any tab). Not as a navigation push.

**Rationale:** The brew log form is a creation flow that should feel distinct from browsing. Modal sheets provide clear "Save/Cancel" semantics and `.interactiveDismissDisabled()` for data protection. This matches the AddBeanView pattern already in the codebase.

### 2. Timer: Embedded in Form (Not Full-Screen)

**Recommendation:** The brew timer should be a collapsible section within the brew log form, not a separate full-screen view.

**Rationale:** Users need to see their brew parameters while the timer runs. A full-screen timer would hide the parameter entries. An embedded section with a prominent display (large monospaced font) provides visibility without losing context.

### 3. Step-by-Step Guidance: Optional Overlay (Not Required)

**Recommendation:** Step-by-step guidance should be an opt-in feature within the timer section. Show a "Guide me" toggle that, when enabled, displays the current step name, description, and progress. When disabled, the timer runs as a simple stopwatch.

**Rationale:** Experienced brewers don't need step guidance. New users benefit from it. Making it optional serves both. The step templates are static data derived from MethodCategory, not user-configurable in v1.

### 4. Rating: Simple Star Tap (1-5)

**Recommendation:** Overall quality rating as 5 monochrome stars (SF Symbol star/star.fill). Tap to set, tap same star to clear. No half-stars, no slider.

**Rationale:** Monochrome constraint makes color-based rating impossible. Stars with fill/outline provide clear binary visual state. 1-5 scale matches the project's structured attributes requirement. Tap interaction is fast during brew logging.

### 5. Brew Log Tab Placement

**Recommendation:** Add a "Brews" tab to MainTabView, positioned as the first tab (before Beans). Use SF Symbol "cup.and.saucer" or "mug".

**Rationale:** Brew logging is the app's core action. It should be the default landing tab. Move Beans to second position. This reflects the app's primary value: logging brews.

### 6. BrewLog Model: Add grinderSetting, Keep Schema V1

**Recommendation:** Add `grinderSetting: Double = 0` to the existing BrewLog model. This is safe under CloudKit's add-only rules (new field with default). No schema version bump needed -- SchemaV1 already includes BrewLog, and adding a defaulted property is a lightweight migration that SwiftData handles automatically.

**Rationale:** The grinder setting is essential brew data. The current model has waterTemperature, yieldAmount, pressureProfile but lacks grind setting. This is a gap that needs filling before any brews are logged.

## Open Questions

1. **TastingNote relationship to BrewLog**
   - What we know: TastingNote @Model exists with `var brewLog: BrewLog?` relationship. It has acidity, body, sweetness (Int), flavorTags (String), freeformNotes (String).
   - What's unclear: Should Phase 3 include TastingNote creation in the brew log form, or defer it to Phase 4?
   - Recommendation: Phase 3 should include the `rating` (Int, overall quality 1-5) and `notes` (freeform String) on BrewLog itself. The structured TastingNote (acidity/body/sweetness scales, SCA flavor wheel tags) should be deferred to Phase 4 per the roadmap. The BrewLog.rating and BrewLog.notes fields already exist on the model and are sufficient for Phase 3's "rate overall quality" and "write freeform tasting notes" requirements.

2. **Brew step guidance depth**
   - What we know: The roadmap says "optional step-by-step guidance for the selected method."
   - What's unclear: How detailed should steps be? Per-method customization, or category-level defaults?
   - Recommendation: Use category-level defaults (pourOver gets bloom/pour/drawdown, espresso gets pre-infusion/extraction, immersion gets add-water/steep/plunge). This keeps the data model simple and avoids the need for user-configurable recipe steps in v1. Store templates as static Swift data, not in SwiftData.

3. **Multiple photos per brew**
   - What we know: BrewLog has `photoData: Data?` (single photo). The success criteria says "add photos" (plural).
   - What's unclear: Should we support multiple photos per brew log?
   - Recommendation: Keep single photo for v1. The existing model has `photoData: Data?` (singular), and changing this to an array would require a schema change. A single photo per brew is sufficient for personal journaling. Multiple photo support can be added in a future version by adding a new relationship to a BrewPhoto entity.

## Sources

### Primary (HIGH confidence)
- Existing codebase: BrewLog.swift, BrewMethod.swift, Grinder.swift, CoffeeBean.swift, TastingNote.swift -- model schema and relationships
- Existing codebase: AddBeanView.swift, MethodDetailView.swift, GrinderDetailView.swift -- established UI patterns for forms, Pickers, detail views
- Existing codebase: SetupWizardViewModel.swift -- @Observable ViewModel pattern
- Existing codebase: EquipmentPhotoPickerView.swift, ImageCompressor.swift -- photo handling
- [Hacking with Swift: Timer with SwiftUI](https://www.hackingwithswift.com/quick-start/swiftui/how-to-use-a-timer-with-swiftui) -- Timer.publish + onReceive pattern
- [Hacking with Swift: SwiftData Picker](https://www.hackingwithswift.com/forums/swiftui/correct-use-of-swiftdata-in-a-picker/25107) -- Optional tag pattern for SwiftData model Pickers
- [Apple: TimelineView](https://developer.apple.com/documentation/swiftui/timelineview) -- Periodic UI update schedule

### Secondary (MEDIUM confidence)
- [Ampersand Softworks: Stopwatch format styles](https://ampersandsoftworks.com/posts/building-a-stopwatch-and-timer-using-xcode16s-new-systemformatstyle/) -- SystemFormatStyle.Stopwatch approach
- [Hacking with Swift: Star rating component](https://www.hackingwithswift.com/books/ios-swiftui/adding-a-custom-star-rating-component) -- Star rating view pattern
- [Digital Bunker: iOS Timer recreation](https://digitalbunker.dev/recreating-the-ios-timer-in-swiftui/) -- Timer state machine pattern
- [CreateWithSwift: Time formatting in Text](https://www.createwithswift.com/formatting-time-in-a-text-view-in-swiftui/) -- Text date formatting options

### Tertiary (LOW confidence)
- Brew step templates (pour-over bloom/pour/drawdown, espresso pre-infusion/extraction) -- derived from general coffee knowledge (Stumptown, Hario guides), not iOS-specific. Exact timing defaults are approximations.
- SCA flavor wheel categories -- referenced for context but actual implementation deferred to Phase 4

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all Apple frameworks already in project, no new dependencies
- Architecture (ViewModel pattern): HIGH -- follows established SetupWizardViewModel pattern
- Architecture (Picker with optional models): HIGH -- verified with HackingWithSwift forum solution
- Timer implementation: HIGH -- Timer.publish + Date-based elapsed is well-documented standard pattern
- Method-adaptive parameters: HIGH -- extends existing MethodDetailView parametersForCategory pattern
- Brew step templates: MEDIUM -- step content is reasonable defaults but not from a canonical source
- Schema safety (adding grinderSetting): HIGH -- add-only with default follows CloudKit rules verified in Phase 1 research

**Research date:** 2026-02-09
**Valid until:** 2026-03-09 (stable Apple frameworks, established codebase patterns)
