# Phase 1: Foundation + Equipment - Research

**Researched:** 2026-02-08
**Domain:** SwiftUI + SwiftData + CloudKit foundation with Equipment CRUD (pure Swift, iOS 17+)
**Confidence:** HIGH

## Summary

This phase establishes the entire technical foundation for a pure-Swift iOS coffee journal app: Xcode project setup, SwiftData models with CloudKit sync, and equipment management (brew methods + grinders) as the first vertical slice proving the architecture end-to-end. The critical technical concern is CloudKit schema permanence -- once deployed to production, the data model follows "add-only, no-delete, no-change" rules, making careful upfront design essential.

The recommended approach is a lean SwiftUI architecture using `@Model` classes with SwiftData, `@Query` for view-level data access, and `@Observable` ViewModels only where business logic warrants separation (setup wizard, equipment statistics). CloudKit sync is virtually zero-code with SwiftData when model constraints are satisfied (all properties optional or defaulted, all relationships optional, no unique constraints). The monochrome design system should be established in this phase as a reusable set of SwiftUI components.

**Primary recommendation:** Design the SwiftData schema for ALL future phases (beans, brews, tasting) now, even though only equipment models are implemented. CloudKit schema is permanent once deployed -- getting it right in Phase 1 prevents painful migrations later.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Equipment setup flow
- Quick setup wizard on first launch (skip-able)
- If skipped: no equipment at all (empty state)
- Wizard can be re-accessed from settings anytime
- Method selection: curated common list (V60, AeroPress, Espresso, French Press, Chemex, Moka Pot, etc.)
- Grinder entry in wizard: just name and type (quick entry)
- After wizard completion: navigate to equipment library screen

#### Method parameter configuration
- **v1 approach:** Pre-configured parameters per method type (no user customization)
- **Espresso parameters:**
  - Dose (g) -- required
  - Yield (g) -- required
  - Time -- required
  - Water temperature -- required
  - Pressure profile -- optional field
- **Pour-over parameters** (V60, Chemex, etc.):
  - Dose (g) -- required
  - Water amount (g) -- required
  - Time -- required
- **Other methods** (AeroPress, French Press, Moka Pot):
  - Generic parameter set (dose, water, time, temperature)

#### Equipment organization
- Two separate screens: Methods and Grinders (not tabs, not single list)
- Equipment photos: replace default icons in list view

#### Usage statistics
- Required stats: brew count, last used date
- Equipment photos appear as equipment icons in list

### Claude's Discretion
- Method display style in list (cards vs simple list vs grid -- choose based on monochrome design constraints)
- Equipment reordering capability (manual vs auto-sorted)
- Edit/delete interaction pattern (swipe vs tap-detail vs long-press -- use iOS-standard patterns)
- Usage statistics placement (inline in list, detail only, or both)
- Additional statistics beyond brew count and last used (e.g., favorite beans, average rating)
- Empty state handling for equipment with zero brews

### Deferred Ideas (OUT OF SCOPE)
- **Parameter customization (v2):** User-configurable parameters per method -- "advanced settings" feature
- **Pour profile tracking (v2):** Pour stages, bloom time, drawdown for pour-over methods
- **Pressure profile details (v2):** Pre-infusion time, ramp patterns for espresso
</user_constraints>

## Standard Stack

**IMPORTANT:** The project switched from KMP to **pure Swift**. The earlier research files (STACK.md, ARCHITECTURE.md) reference KMP/SKIE/Koin -- those are obsolete for this project. This phase uses Apple-only frameworks.

### Core

| Library/Framework | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| SwiftUI | iOS 17+ | UI framework | Apple's declarative UI, first-class SwiftData integration via `@Query`, `@Model` |
| SwiftData | iOS 17+ | Persistence | Replaces Core Data for new projects. Zero-code CloudKit sync. `@Model` macro, `@Query` property wrapper |
| CloudKit | iOS 17+ | iCloud sync | Automatic bidirectional sync via SwiftData's ModelContainer. Private database only. No server code needed |
| Swift 5.9+ | Xcode 15+ | Language | `@Observable` macro (iOS 17+), structured concurrency, macros |
| PhotosUI | iOS 17+ | Photo picker | Native SwiftUI `PhotosPicker` for equipment photos |

### Supporting

| Library/Framework | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| Swift Charts | iOS 17+ | Data visualization | Usage statistics (future phases, but architecture should allow it) |
| SF Symbols | 5.0+ | Iconography | Default equipment icons, monochrome rendering mode |

### No External Dependencies

Per PROJECT.md constraint: "No external dependencies beyond Apple frameworks." This is achievable -- SwiftData + CloudKit + SwiftUI covers all Phase 1 needs without third-party libraries.

**Project setup:**
```
Xcode > New Project > iOS App
  Interface: SwiftUI
  Language: Swift
  Storage: SwiftData (with "Host in CloudKit" checked)
  Target: iOS 17.0+
```

## Architecture Patterns

### Recommended Project Structure

```
CoffeeJournal/
├── CoffeeJournalApp.swift          # App entry, ModelContainer setup
├── Models/
│   ├── BrewMethod.swift            # @Model for brew methods
│   ├── Grinder.swift               # @Model for grinders
│   ├── MethodCategory.swift        # Enum for method types (espresso, pour-over, etc.)
│   └── Schema/
│       ├── SchemaV1.swift          # VersionedSchema for v1
│       └── MigrationPlan.swift     # SchemaMigrationPlan
├── Views/
│   ├── Equipment/
│   │   ├── MethodListView.swift    # Methods screen (list)
│   │   ├── MethodDetailView.swift  # Method detail + edit
│   │   ├── GrinderListView.swift   # Grinders screen (list)
│   │   ├── GrinderDetailView.swift # Grinder detail + edit
│   │   └── AddMethodView.swift     # Add new method sheet
│   ├── Setup/
│   │   ├── SetupWizardView.swift   # First-launch wizard
│   │   ├── MethodSelectionView.swift # Wizard: pick methods
│   │   └── GrinderEntryView.swift  # Wizard: add grinder
│   ├── Settings/
│   │   └── SettingsView.swift      # Settings (re-access wizard)
│   └── Components/
│       ├── EquipmentRow.swift      # Reusable list row
│       ├── EmptyStateView.swift    # Empty state component
│       └── MonochromeStyle.swift   # Design system tokens
├── ViewModels/
│   └── SetupWizardViewModel.swift  # Wizard state management
├── Utilities/
│   ├── ImageCompressor.swift       # Photo compression utility
│   └── AppStorage+Keys.swift       # UserDefaults keys
└── Assets.xcassets                 # App icons, default equipment icons
```

### Pattern 1: Direct @Query in Views (Primary Pattern)

**What:** Use SwiftData's `@Query` property wrapper directly in SwiftUI views for data access. Business logic lives in the `@Model` classes themselves.

**When to use:** For list/detail screens where the view's primary job is displaying and editing SwiftData models. This is the majority of Phase 1.

**Rationale:** SwiftData's `@Query` automatically observes changes and re-renders views. Adding a ViewModel layer between `@Query` and the view adds boilerplate without benefit for simple CRUD screens. Apple's own SwiftData examples use this pattern.

**Example:**
```swift
// Source: hackingwithswift.com/quick-start/swiftdata + Apple SwiftData docs
struct MethodListView: View {
    @Query(sort: \BrewMethod.name) private var methods: [BrewMethod]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(methods) { method in
                NavigationLink(value: method) {
                    EquipmentRow(method: method)
                }
            }
            .onDelete(perform: deleteMethods)
        }
    }

    private func deleteMethods(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(methods[index])
        }
    }
}
```

**Confidence:** HIGH -- Apple's recommended pattern, documented extensively at developer.apple.com and hackingwithswift.com.

### Pattern 2: @Observable ViewModel (For Complex Logic)

**What:** Use `@Observable` class as a ViewModel when screen logic exceeds simple CRUD (multi-step flows, computed state across multiple models, validation).

**When to use:** Setup wizard (multi-step flow with state), and anywhere business logic complexity justifies separation.

**Example:**
```swift
// Source: Apple developer.apple.com/documentation/SwiftUI/Managing-model-data-in-your-app
@Observable
class SetupWizardViewModel {
    var currentStep: WizardStep = .welcome
    var selectedMethods: Set<MethodTemplate> = []
    var grinderName: String = ""
    var grinderType: GrinderType = .burr

    var canProceed: Bool {
        switch currentStep {
        case .welcome: return true
        case .methods: return !selectedMethods.isEmpty
        case .grinder: return true // grinder is optional
        case .complete: return true
        }
    }

    func saveEquipment(context: ModelContext) {
        for template in selectedMethods {
            let method = BrewMethod(from: template)
            context.insert(method)
        }
        if !grinderName.isEmpty {
            let grinder = Grinder(name: grinderName, type: grinderType)
            context.insert(grinder)
        }
    }
}
```

**Confidence:** HIGH -- `@Observable` is Apple's iOS 17+ recommended approach, replacing `ObservableObject`.

### Pattern 3: VersionedSchema from Day One

**What:** Wrap all `@Model` definitions inside a `VersionedSchema` enum from the very first release. This enables controlled migrations in future versions.

**When to use:** Always. Start with VersionedSchema even for v1 to avoid the pain of retroactively versioning an unversioned schema.

**Example:**
```swift
// Source: hackingwithswift.com/quick-start/swiftdata/how-to-create-a-complex-migration-using-versionedschema
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [BrewMethod.self, Grinder.self]
    }

    @Model
    final class BrewMethod {
        var id: UUID = UUID()
        var name: String = ""
        var category: String = ""  // Raw value of MethodCategory enum
        var notes: String = ""
        var brewCount: Int = 0
        var lastUsedDate: Date?
        @Attribute(.externalStorage) var photoData: Data?
        var createdAt: Date = Date()
        var updatedAt: Date = Date()

        init(name: String, category: MethodCategory) {
            self.name = name
            self.category = category.rawValue
        }
    }
}

enum CoffeeJournalMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }
    static var stages: [MigrationStage] {
        [] // No migrations yet for v1
    }
}
```

**Confidence:** HIGH -- Apple recommends starting with VersionedSchema. Confirmed by WWDC 2025 session "SwiftData: Dive into inheritance and schema migration."

### Anti-Patterns to Avoid

- **Putting ViewModel between @Query and every view:** Adds boilerplate without benefit for simple CRUD. Use @Query directly for list/detail screens.
- **Using @Attribute(.unique) with CloudKit:** CloudKit does not support unique constraints. Enforce uniqueness in application logic if needed.
- **Non-optional properties without defaults in @Model:** CloudKit requires all properties to be optional or have default values. A model that works locally will silently fail to sync.
- **Storing enums with associated values in @Model:** SwiftData has known crashes when deleting models with enum associated values. Store enum raw values as strings instead.
- **Modifying Codable struct properties after CloudKit deployment:** Changes to Codable type fields (adding/removing/renaming properties) break CloudKit lightweight migration. Design Codable types carefully upfront.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| iCloud sync | Custom CloudKit sync code | SwiftData ModelContainer with CloudKit capability | Zero-code sync. SwiftData handles merge, conflict, background sync automatically |
| Photo picker | Custom camera/photo library UI | SwiftUI `PhotosPicker` | Native, permission-handling built in, returns `PhotosPickerItem` |
| Image compression | Custom resize/compress pipeline | UIImage.jpegData(compressionQuality:) + downsample | Standard UIKit utility, handles HEIC/JPEG/PNG conversion |
| First-launch detection | Custom onboarding framework | `@AppStorage("hasCompletedSetup")` + conditional view | Simple boolean flag persisted in UserDefaults |
| Equipment icons | Custom icon set | SF Symbols (cup.and.saucer, gearshape, etc.) | 5000+ icons, monochrome mode built in, dynamic type support |
| Schema versioning | Manual database version tracking | SwiftData VersionedSchema + SchemaMigrationPlan | Framework handles migration lifecycle, version detection |
| List sorting/filtering | Custom sort logic | `@Query(sort:)` and `@Query(filter:)` | SwiftData sorts at the database level, more efficient |

**Key insight:** SwiftData + CloudKit + SwiftUI handles 90% of Phase 1's infrastructure automatically. The engineering effort should focus on data model design (permanent due to CloudKit) and UI/UX (setup wizard, monochrome design system), not plumbing.

## Common Pitfalls

### Pitfall 1: CloudKit Schema Permanence

**What goes wrong:** Developer iterates on the SwiftData model during development (renaming attributes, changing types) then deploys to TestFlight. Once the CloudKit schema is deployed to production, it follows "add-only, no-delete, no-change" rules. Renaming a field is interpreted as deleting the old one and adding a new one, causing data loss.

**Why it happens:** SwiftData locally supports lightweight migration (renames, type changes). Developers assume CloudKit behaves the same. The development environment is more permissive.

**How to avoid:**
- Design the full data model (equipment, beans, brews, tasting) in Phase 1, even if only equipment is implemented. This prevents future schema conflicts.
- Use generic, future-proof attribute names.
- Never rename or delete attributes after TestFlight deployment.
- Use `VersionedSchema` from day one to track all changes.
- Deploy schema to CloudKit Dashboard development environment first, inspect it before pushing to production.

**Warning signs:** "I'll just rename this field" during development. Core Data migration warnings in console.

**Confidence:** HIGH -- Verified via Apple TN3164 and fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/

### Pitfall 2: Silent Sync Failures from Model Constraints

**What goes wrong:** SwiftData model uses non-optional properties without defaults, `@Attribute(.unique)`, or non-optional relationships. The app works perfectly locally but CloudKit sync silently fails or produces duplicates.

**Why it happens:** SwiftData does not warn you at compile time that your model is incompatible with CloudKit. Everything works in the simulator where sync doesn't run anyway.

**How to avoid:**
- ALL properties must be optional or have default values
- ALL relationships must be optional
- Never use `@Attribute(.unique)` on synced models
- Test on two physical devices early in development
- Enable CloudKit debug logging: launch argument `-com.apple.CoreData.CloudKitDebug 1`

**Warning signs:** Sync works one-way (device to cloud) but not the other. Duplicate records appearing.

**Confidence:** HIGH -- Verified via Apple documentation, hackingwithswift.com, fatbobman.com, and multiple developer forums.

### Pitfall 3: CloudKit Sync Cannot Be Tested on Simulator

**What goes wrong:** Developer builds and tests CloudKit sync in iOS Simulator. Sync appears to work one direction but not the other, with 15-20 second delays.

**Why it happens:** iOS Simulator cannot receive remote push notifications (APNs), which CloudKit uses for real-time sync. The simulator must poll, causing delays and false negatives.

**How to avoid:**
- Always test CloudKit sync on two physical devices (iPhone + iPad, or two iPhones)
- Use CloudKit Dashboard (icloud.developer.apple.com) to inspect records
- Implement a debug sync status indicator early
- Enable verbose logging with `-com.apple.CoreData.CloudKitDebug 1`

**Warning signs:** "Sync works on my machine" but not on tester's device. Changes not appearing on second device for minutes.

**Confidence:** HIGH -- Verified via Apple Developer Forums and fatbobman.com troubleshooting guides.

### Pitfall 4: Enum Properties Stored Incorrectly in SwiftData

**What goes wrong:** Developer uses Swift enums directly in `@Model` properties. SwiftData stores enums as Codable binary data, making them impossible to query with `@Query(filter:)` and fragile to changes. Deleting models with enum associated values can crash.

**Why it happens:** Swift enums are Codable, so SwiftData accepts them. But the binary encoding is opaque and version-sensitive.

**How to avoid:**
- Store enum raw values (String or Int) as the actual `@Model` property
- Provide computed properties that convert to/from the enum type
- Never use enums with associated values in `@Model` directly

**Example of correct pattern:**
```swift
@Model
final class BrewMethod {
    var categoryRawValue: String = ""  // Stored property

    var category: MethodCategory {    // Computed property
        get { MethodCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
}
```

**Warning signs:** Can't filter by enum value in `@Query`. Crashes on deletion. Enum changes break existing data.

**Confidence:** HIGH -- Verified via fatbobman.com/en/posts/considerations-for-using-codable-and-enums-in-swiftdata-models/ and hackingwithswift.com.

### Pitfall 5: Photo Storage Without Compression

**What goes wrong:** Equipment photos are stored at full resolution (48MP iPhone cameras produce 8064x6048 images). Each photo is 5-15MB. With CloudKit sync, this consumes the user's personal iCloud quota rapidly.

**Why it happens:** `PhotosPicker` returns full-resolution images. Without explicit compression, SwiftData stores the raw data.

**How to avoid:**
- Compress to JPEG at 0.7 quality before storing
- Downscale to max 1024px for equipment thumbnails (equipment photos don't need high res)
- Use `@Attribute(.externalStorage)` for photo data (confirmed to work with CloudKit sync)
- Handle potential `quotaExceeded` errors gracefully

**Warning signs:** App's iCloud storage usage growing rapidly. `quotaExceeded` errors in CloudKit logs.

**Confidence:** MEDIUM-HIGH -- `.externalStorage` + CloudKit confirmed working by Apple Developer Forums. Compression strategy is standard practice.

## Code Examples

### SwiftData Model with CloudKit Compliance

```swift
// Source: Apple SwiftData docs + fatbobman.com CloudKit rules
import SwiftData

enum MethodCategory: String, Codable, CaseIterable {
    case espresso = "espresso"
    case pourOver = "pour_over"
    case immersion = "immersion"
    case other = "other"
}

enum GrinderType: String, Codable, CaseIterable {
    case burr = "burr"
    case blade = "blade"
    case manual = "manual"
}

@Model
final class BrewMethod {
    // All properties have defaults (CloudKit requirement)
    var id: UUID = UUID()
    var name: String = ""
    var categoryRawValue: String = MethodCategory.other.rawValue
    var notes: String = ""
    var brewCount: Int = 0
    var lastUsedDate: Date?
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Computed property for type-safe enum access
    var category: MethodCategory {
        get { MethodCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    // Pre-configured parameters (stored as method category, not customizable in v1)
    var parameterSetDescription: String {
        switch category {
        case .espresso:
            return "Dose, Yield, Time, Temperature, Pressure"
        case .pourOver:
            return "Dose, Water, Time"
        case .immersion, .other:
            return "Dose, Water, Time, Temperature"
        }
    }

    init(name: String, category: MethodCategory) {
        self.name = name
        self.categoryRawValue = category.rawValue
    }
}

@Model
final class Grinder {
    var id: UUID = UUID()
    var name: String = ""
    var typeRawValue: String = GrinderType.burr.rawValue
    var settingMin: Double = 0
    var settingMax: Double = 40
    var settingStep: Double = 1
    var notes: String = ""
    var brewCount: Int = 0
    var lastUsedDate: Date?
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var grinderType: GrinderType {
        get { GrinderType(rawValue: typeRawValue) ?? .burr }
        set { typeRawValue = newValue.rawValue }
    }

    init(name: String, type: GrinderType) {
        self.name = name
        self.typeRawValue = type.rawValue
    }
}
```

### ModelContainer Setup with CloudKit

```swift
// Source: hackingwithswift.com + Apple SwiftData documentation
import SwiftUI
import SwiftData

@main
struct CoffeeJournalApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic  // Enables CloudKit sync
        )
        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: CoffeeJournalMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

### Setup Wizard Pattern

```swift
// Source: riveralabs.com/blog/swiftui-onboarding + Apple docs
struct ContentView: View {
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false

    var body: some View {
        if hasCompletedSetup {
            MainTabView()
        } else {
            SetupWizardView(onComplete: {
                hasCompletedSetup = true
            })
        }
    }
}

struct SetupWizardView: View {
    @State private var viewModel = SetupWizardViewModel()
    @Environment(\.modelContext) private var modelContext
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeStepView(onSkip: onComplete)
                case .methods:
                    MethodSelectionView(selected: $viewModel.selectedMethods)
                case .grinder:
                    GrinderEntryView(
                        name: $viewModel.grinderName,
                        type: $viewModel.grinderType
                    )
                case .complete:
                    SetupCompleteView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") {
                        if viewModel.currentStep == .complete {
                            viewModel.saveEquipment(context: modelContext)
                            onComplete()
                        } else {
                            viewModel.nextStep()
                        }
                    }
                    .disabled(!viewModel.canProceed)
                }
            }
        }
    }
}
```

### Image Compression Utility

```swift
// Source: Standard UIKit pattern
import UIKit

struct ImageCompressor {
    static func compress(
        imageData: Data,
        maxDimension: CGFloat = 1024,
        quality: CGFloat = 0.7
    ) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }

        let scale = min(
            maxDimension / image.size.width,
            maxDimension / image.size.height,
            1.0  // Don't upscale
        )

        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized.jpegData(compressionQuality: quality)
    }
}
```

### Monochrome Design System Foundation

```swift
// Source: Apple HIG + monochrome constraint from PROJECT.md
import SwiftUI

// MARK: - Typography Scale
enum AppTypography {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title2.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let caption = Font.caption
    static let footnote = Font.footnote
}

// MARK: - Monochrome Colors
enum AppColors {
    static let primary = Color.primary           // Black in light, white in dark
    static let secondary = Color.secondary       // Gray
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let separator = Color(.separator)

    // Use opacity for emphasis levels (not color)
    static let emphasis = Color.primary.opacity(1.0)
    static let subtle = Color.primary.opacity(0.6)
    static let muted = Color.primary.opacity(0.3)
}

// MARK: - Reusable Components
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionLabel: String = "Get Started"

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let action {
                Button(actionLabel, action: action)
                    .buttonStyle(.bordered)
            }
        }
    }
}
```

## Design Decisions (Claude's Discretion)

Based on research, here are recommendations for the discretionary areas:

### Method Display Style: Simple List with Row Detail

**Recommendation:** Use a simple `List` with custom rows showing method name, category icon, and inline stats. Not cards (too heavy for monochrome), not grid (equipment collections are typically small, 3-10 items).

**Rationale:** Monochrome constrains visual differentiation. A simple list with typography hierarchy (bold name, caption stats) works best. Cards need shadows/borders for visual separation, which conflicts with monochrome minimalism.

### Equipment Reordering: Auto-sorted by Last Used, Manual Sort Available

**Recommendation:** Default sort by "last used" (most recently used first). Provide sort options: last used, alphabetical, brew count. No manual drag-to-reorder.

**Rationale:** Users care about recency. Sorting by last used keeps the most relevant equipment at top without manual effort. Manual reorder adds complexity with minimal value for small lists.

### Edit/Delete Pattern: Swipe Actions (iOS Standard)

**Recommendation:** Trailing swipe for delete (red), tap row to navigate to detail/edit. Use `.swipeActions` modifier.

**Rationale:** This is the standard iOS pattern. Users expect swipe-to-delete on list items. Tap navigates to detail where editing happens. Long-press context menus are discoverable but secondary.

### Usage Statistics Placement: Inline Subtitle + Detail Screen

**Recommendation:** Show brew count and last used as subtitle text in list rows. Show full statistics on the detail screen.

**Rationale:** Inline stats provide at-a-glance value without extra taps. Detail screen has room for additional stats (future: favorite beans, average rating).

### Empty State: ContentUnavailableView with Setup Action

**Recommendation:** Use SwiftUI's `ContentUnavailableView` (iOS 17+) with a clear call-to-action to add first equipment or re-run setup wizard.

**Rationale:** Apple's built-in component, works in monochrome, handles both icon + text + action button.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Core Data + NSPersistentCloudKitContainer | SwiftData ModelContainer with CloudKit | WWDC 2023 (iOS 17) | Zero-code sync, @Model macro replaces .xcdatamodeld |
| ObservableObject + @Published | @Observable macro + @State | WWDC 2023 (iOS 17) | Less boilerplate, better performance (fine-grained observation) |
| @StateObject for ViewModels | @State with @Observable | iOS 17+ | Simpler API, no need for @StateObject vs @ObservedObject distinction |
| NSFetchedResultsController | @Query property wrapper | WWDC 2023 (iOS 17) | Declarative data access, automatic updates |
| Manual CloudKit record management | SwiftData automatic sync | iOS 17+ | Developers never touch CKRecord directly |

**Deprecated/outdated patterns for this project:**
- KMP/SKIE/Koin stack (from earlier project research -- project switched to pure Swift)
- Core Data .xcdatamodeld files (use @Model macro instead)
- ObservableObject protocol (use @Observable macro for iOS 17+)
- Manual CKRecord management (SwiftData handles it)

## Future-Proofing the Schema

Because CloudKit schema is permanent, the Phase 1 data model should account for ALL future phases. Here are the entities to plan for (even if only BrewMethod and Grinder are implemented now):

### Phase 1 (Implement Now)
- `BrewMethod` -- brew methods with category, photo, stats
- `Grinder` -- grinders with type, settings range, photo, stats

### Phase 2-4 (Schema Design Now, Implementation Later)
- `CoffeeBean` -- roaster, origin, variety, processing, roast level, roast date, photo, active/archived
- `BrewLog` -- links to method + grinder + bean, dose, water, time, temp, ratio, rating, notes, photos
- `TastingNote` -- linked to BrewLog, acidity/body/sweetness scores, flavor tags, freeform text

### Schema Design Principles
1. All properties optional or with defaults
2. All relationships optional
3. Store enum raw values as String, not enum directly
4. Use UUID for all `id` fields
5. Include `createdAt` and `updatedAt` on every entity
6. Use `@Attribute(.externalStorage)` for all binary data (photos)
7. Name fields generically (use `notes` not `brewMethodNotes`)
8. Include `_reserved1: String?`, `_reserved2: String?` fields for future expansion if paranoid about schema permanence

## Open Questions

1. **@Attribute(.externalStorage) and CloudKit sync reliability**
   - What we know: Multiple sources confirm it works. Apple Developer Forums has confirmation.
   - What's unclear: Edge cases with large files (>50MB), behavior when user's iCloud is full, and whether thumbnails need to be stored separately.
   - Recommendation: Use `.externalStorage` for photos. Compress to <1MB before storing. Test on two physical devices with photo sync early.

2. **VersionedSchema + CloudKit migration behavior**
   - What we know: VersionedSchema tracks local schema versions. CloudKit has its own "add-only" constraints.
   - What's unclear: How VersionedSchema migrations interact with CloudKit schema evolution. Can you use custom migrations with CloudKit-synced models?
   - Recommendation: Start with VersionedSchema. Only use lightweight migrations (add fields). Test any migration on a CloudKit-enabled device before release.

3. **Brew parameters as pre-configured vs. stored data**
   - What we know: User decided "pre-configured parameters per method type, no user customization."
   - What's unclear: Should parameter definitions be stored in the model (for future customization) or computed from the category enum (simpler for v1)?
   - Recommendation: Store only the `categoryRawValue` in the model. Compute parameter lists from a static dictionary keyed by category. This keeps the schema simpler now and allows adding a `customParameters` field later without schema conflict.

## Sources

### Primary (HIGH confidence)
- [Apple SwiftData Documentation](https://developer.apple.com/documentation/swiftdata) -- ModelContainer, @Model, @Query
- [Apple: Syncing model data across a person's devices](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices) -- CloudKit setup requirements
- [Hacking with Swift: SwiftData + iCloud sync](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-sync-swiftdata-with-icloud) -- Setup steps, model requirements, limitations
- [fatbobman: Rules for Adapting Data Models to CloudKit](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/) -- Mandatory CloudKit model constraints
- [fatbobman: Considerations for Using Codable and Enums in SwiftData Models](https://fatbobman.com/en/posts/considerations-for-using-codable-and-enums-in-swiftdata-models/) -- Enum and Codable patterns
- [Apple: WWDC 2025 SwiftData: Dive into inheritance and schema migration](https://developer.apple.com/videos/play/wwdc2025/291/) -- VersionedSchema best practices
- [Apple: Migrating from ObservableObject to @Observable](https://developer.apple.com/documentation/SwiftUI/Migrating-from-the-observable-object-protocol-to-the-observable-macro) -- iOS 17 observation pattern

### Secondary (MEDIUM confidence)
- [Hacking with Swift: Complex migration using VersionedSchema](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-a-complex-migration-using-versionedschema) -- Migration code examples
- [AzamSharp: SwiftData Architecture Patterns and Practices](https://azamsharp.com/2025/03/28/swiftdata-architecture-patterns-and-practices.html) -- @Query vs ViewModel debate
- [firewhale.io: Some Quirks of SwiftData with CloudKit](https://firewhale.io/posts/swift-data-quirks/) -- Practical CloudKit quirks
- [Rivera Labs: SwiftUI Onboarding Flow](https://www.riveralabs.com/blog/swiftui-onboarding/) -- Setup wizard patterns
- [Apple Developer Forums: @Attribute(.externalStorage) with CloudKit](https://developer.apple.com/forums/thread/751617) -- Confirmation that externalStorage works with CloudKit

### Tertiary (LOW confidence)
- Various Medium articles on SwiftData MVVM patterns -- community opinions, not authoritative
- Monochrome design system research -- no single authoritative source; recommendation based on Apple HIG principles adapted for monochrome constraint

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Apple-only frameworks, well-documented, no third-party dependencies
- Architecture: HIGH -- @Query pattern and @Observable are Apple's recommended approaches for iOS 17+
- CloudKit constraints: HIGH -- Multiple authoritative sources agree on all rules
- Pitfalls: HIGH -- CloudKit schema permanence and model constraints verified across Apple docs and community experts
- Monochrome design: MEDIUM -- No authoritative monochrome-specific iOS design guide; recommendations synthesized from Apple HIG principles
- Photo storage: MEDIUM-HIGH -- .externalStorage + CloudKit confirmed working but edge cases not fully documented

**Research date:** 2026-02-08
**Valid until:** 2026-03-08 (stable Apple frameworks, 30-day validity)
