# Phase 2: Coffee Bean Tracking - Research

**Researched:** 2026-02-09
**Domain:** SwiftData CRUD, SwiftUI search/filter, Apple Vision OCR, freshness computation (pure Swift, iOS 17+)
**Confidence:** HIGH

## Summary

Phase 2 builds the second major feature vertical on the foundation established in Phase 1. The CoffeeBean `@Model` already exists in SchemaV1 with all required fields (roaster, origin, region, variety, processingMethod, roastLevel, roastDate, isArchived, photoData, notes). No schema changes are needed -- implementation focuses entirely on views, enums, computed properties, and the OCR feature.

The phase decomposes into three technical domains: (1) standard SwiftData CRUD following the patterns already proven in Phase 1 (AddBeanView, BeanListView, BeanDetailView), (2) freshness tracking and visual indicators computed from roastDate, and (3) camera-based bag label scanning using Apple's VisionKit/Vision frameworks for OCR with custom text parsing to extract coffee-specific fields. The search/filter requirement uses SwiftUI's `.searchable()` modifier combined with SwiftData's `#Predicate` macro for database-level filtering.

The most technically complex requirement is BEAN-05 (bag label OCR). The recommended approach is a two-phase flow: (a) use `DataScannerViewController` (iOS 16+, VisionKit) for live camera text scanning with a SwiftUI wrapper, then (b) apply custom regex/heuristic parsing to extract structured fields (roaster, origin, variety, roast date) from the raw recognized text. Coffee bag labels have no standardized format, so the parsing must be heuristic and allow user correction.

**Primary recommendation:** Follow Phase 1's established patterns exactly (direct @Query, @Bindable detail views, EquipmentPhotoPickerView reuse, monochrome design tokens). The only new technical territory is the OCR scanner, which should be isolated in its own view component with a clear boundary between "text recognition" and "field extraction."

## Standard Stack

### Core (Same as Phase 1 -- No New Dependencies)

| Library/Framework | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| SwiftUI | iOS 17+ | UI framework | @Query, @Bindable, .searchable(), NavigationStack -- all proven in Phase 1 |
| SwiftData | iOS 17+ | Persistence | CoffeeBean @Model already defined. @Query with #Predicate for search filtering |
| CloudKit | iOS 17+ | iCloud sync | Already configured in CoffeeJournalApp.swift. CoffeeBean syncs automatically |
| PhotosUI | iOS 17+ | Photo picker | Reuse EquipmentPhotoPickerView from Phase 1 for bag photos |

### New for Phase 2

| Library/Framework | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| VisionKit | iOS 16+ | Live camera text scanning | DataScannerViewController provides complete camera UI with text recognition. Apple's recommended approach for live scanning |
| Vision | iOS 13+ | Static image OCR | VNRecognizeTextRequest for processing captured photos. Fallback if DataScannerViewController unavailable |

### No External Dependencies

Per PROJECT.md constraint: "No external dependencies beyond Apple frameworks." VisionKit and Vision are both first-party Apple frameworks bundled with iOS.

**Capabilities check (required for DataScannerViewController):**
- `DataScannerViewController.isSupported` -- device has camera with Neural Engine (iPhone XS/XR and later)
- `DataScannerViewController.isAvailable` -- user has granted camera permission
- Info.plist: `NSCameraUsageDescription` key required

## Architecture Patterns

### Recommended Project Structure (Additions to Phase 1)

```
CoffeeJournal/
├── Models/
│   ├── CoffeeBean.swift          # Already exists -- add computed properties (freshness, daysSinceRoast)
│   ├── RoastLevel.swift           # NEW: enum for roast levels
│   └── ProcessingMethod.swift     # NEW: enum for processing methods
├── Views/
│   ├── Beans/                     # NEW: entire folder
│   │   ├── BeanListView.swift     # List with search, active/archived filter
│   │   ├── AddBeanView.swift      # Add new bean form (sheet)
│   │   ├── BeanDetailView.swift   # Detail/edit view (@Bindable pattern)
│   │   ├── BeanRow.swift          # List row component
│   │   └── FreshnessIndicator.swift  # Reusable freshness badge
│   ├── Scanner/                   # NEW: OCR scanning
│   │   ├── BagScannerView.swift   # Camera scanner wrapper (UIViewControllerRepresentable)
│   │   └── ScanResultReviewView.swift  # Review/edit extracted fields before saving
│   └── Components/
│       └── (existing MonochromeStyle.swift, etc.)
├── Utilities/
│   ├── BagLabelParser.swift       # NEW: text-to-fields extraction logic
│   └── FreshnessCalculator.swift  # NEW: days-since-roast and freshness level computation
└── MainTabView.swift              # MODIFY: add Beans tab
```

### Pattern 1: Direct @Query with #Predicate for Search (Primary Pattern)

**What:** Use SwiftUI's `.searchable()` modifier on a parent view, pass the search text to a child view that initializes `@Query` with a dynamic `#Predicate` in its `init`. This forces `@Query` reinitialization when search text changes.

**When to use:** BeanListView for searching by roaster or origin (BEAN-07).

**Why this pattern:** `@Query` does not support dynamic predicate changes after initialization. The child-view pattern is the documented workaround, filtering at the database level (efficient) rather than in-memory (wasteful).

**Example:**
```swift
// Source: createwithswift.com/performing-search-with-swiftdata-in-a-swiftui-app
// + hackingwithswift.com/quick-start/swiftdata/filtering-the-results-from-a-swiftdata-query

// Parent view owns search state
struct BeanListView: View {
    @State private var searchText = ""
    @State private var showArchived = false

    var body: some View {
        BeanListContent(searchText: searchText, showArchived: showArchived)
            .searchable(text: $searchText, prompt: "Search by roaster or origin")
    }
}

// Child view reinitializes @Query when parameters change
struct BeanListContent: View {
    let searchText: String
    let showArchived: Bool
    @Query private var beans: [CoffeeBean]

    init(searchText: String, showArchived: Bool) {
        self.searchText = searchText
        self.showArchived = showArchived

        let predicate = #Predicate<CoffeeBean> { bean in
            if showArchived {
                // Show only archived
                bean.isArchived == true
            } else {
                // Show only active
                bean.isArchived == false
            }
        }

        // Note: #Predicate with dynamic string matching requires
        // localizedStandardContains for case-insensitive search
        if searchText.isEmpty {
            _beans = Query(filter: predicate, sort: [SortDescriptor(\.createdAt, order: .reverse)])
        } else {
            let searchPredicate = #Predicate<CoffeeBean> { bean in
                (bean.roaster.localizedStandardContains(searchText) ||
                 bean.origin.localizedStandardContains(searchText)) &&
                bean.isArchived == showArchived
            }
            _beans = Query(filter: searchPredicate, sort: [SortDescriptor(\.createdAt, order: .reverse)])
        }
    }
}
```

**Confidence:** HIGH -- Pattern verified via createwithswift.com, hackingwithswift.com, and swiftyplace.com.

### Pattern 2: @Bindable Detail View (Same as Phase 1)

**What:** Use `@Bindable var bean: CoffeeBean` in the detail view for direct two-way binding to SwiftData model properties.

**When to use:** BeanDetailView for inline editing of all bean fields.

**Example:**
```swift
// Follows same pattern as GrinderDetailView from Phase 1
struct BeanDetailView: View {
    @Bindable var bean: CoffeeBean
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            photoSection
            originSection      // roaster, origin, region, variety
            processingSection  // processing method, roast level
            roastDateSection   // DatePicker + freshness indicator
            notesSection
        }
        .navigationTitle(bean.name.isEmpty ? bean.roaster : bean.name)
    }
}
```

**Confidence:** HIGH -- Pattern already proven in GrinderDetailView and MethodDetailView.

### Pattern 3: UIViewControllerRepresentable for DataScanner

**What:** Wrap `DataScannerViewController` in a `UIViewControllerRepresentable` struct to use it in SwiftUI. Pass recognized text back via a binding or closure.

**When to use:** BagScannerView for BEAN-05 (camera OCR).

**Example:**
```swift
// Source: Apple VisionKit docs + community tutorials
import VisionKit

struct BagScannerView: UIViewControllerRepresentable {
    @Binding var recognizedText: [String]
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        try? uiViewController.startScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: BagScannerView

        init(parent: BagScannerView) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didTapOn item: RecognizedItem) {
            switch item {
            case .text(let text):
                parent.recognizedText.append(text.transcript)
            default:
                break
            }
        }
    }
}
```

**Confidence:** HIGH -- DataScannerViewController is well-documented. UIViewControllerRepresentable pattern is standard SwiftUI interop.

### Pattern 4: Enum Raw Values with Computed Accessors (Same as Phase 1)

**What:** Define domain enums (RoastLevel, ProcessingMethod) as `String`-backed enums. Store raw values in the `@Model`, provide computed accessors. Same pattern used for GrinderType and MethodCategory.

**When to use:** RoastLevel and ProcessingMethod for CoffeeBean. The CoffeeBean model already stores these as `String` -- just need the enum definitions and computed properties.

**Example:**
```swift
enum RoastLevel: String, CaseIterable {
    case light = "light"
    case mediumLight = "medium_light"
    case medium = "medium"
    case mediumDark = "medium_dark"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .mediumLight: return "Medium-Light"
        case .medium: return "Medium"
        case .mediumDark: return "Medium-Dark"
        case .dark: return "Dark"
        }
    }
}

enum ProcessingMethod: String, CaseIterable {
    case washed = "washed"
    case natural = "natural"
    case honey = "honey"
    case anaerobic = "anaerobic"
    case other = "other"

    var displayName: String {
        switch self {
        case .washed: return "Washed"
        case .natural: return "Natural"
        case .honey: return "Honey"
        case .anaerobic: return "Anaerobic"
        case .other: return "Other"
        }
    }
}
```

**Confidence:** HIGH -- Exact same pattern used throughout Phase 1.

### Anti-Patterns to Avoid

- **Storing freshness level in the model:** Freshness is computed from `roastDate` and current date. Never persist a "freshness" field -- it would be stale immediately. Always compute it.
- **Complex #Predicate with compound OR conditions:** `#Predicate` has limited support for complex expressions. Keep predicates simple. If you need complex filtering, use separate predicates or filter in-memory for small datasets.
- **Using DataScannerViewController without checking isSupported:** Not all devices support it (requires Neural Engine). Always check `DataScannerViewController.isSupported` and `isAvailable` before presenting the scanner. Provide a fallback (manual entry).
- **Auto-saving OCR results without review:** OCR on coffee bag labels is inherently imprecise. Always show extracted fields for user review/correction before creating the bean entry.
- **Using `@Attribute(.unique)` for roaster names:** CloudKit does not support unique constraints. Multiple beans from the same roaster is valid data anyway.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Camera text recognition | Custom AVCaptureSession + Vision pipeline | `DataScannerViewController` (VisionKit) | Complete camera UI with text highlighting, handles permissions, focus, exposure |
| Image OCR on static photos | Custom image processing pipeline | `VNRecognizeTextRequest` (Vision) | Apple's on-device OCR, supports .accurate and .fast modes, 10+ languages |
| Photo picker + compression | Custom camera UI | Reuse `EquipmentPhotoPickerView` + `ImageCompressor` from Phase 1 | Already built and tested |
| Search bar UI | Custom TextField with search styling | `.searchable()` SwiftUI modifier | Standard iOS search bar, automatic keyboard management, cancel button |
| Date-relative display | Custom "X days ago" formatter | `Date.formatted(.relative(presentation: .named))` or manual Calendar.dateComponents | Foundation handles locale, pluralization, edge cases |
| List filtering | In-memory array.filter() | `@Query(filter: #Predicate)` | Database-level filtering, more efficient as dataset grows |

**Key insight:** Phase 2 reuses nearly all infrastructure from Phase 1. The only genuinely new technology is VisionKit/Vision for OCR. Everything else (CRUD views, photo handling, design system, list patterns) follows established patterns.

## Common Pitfalls

### Pitfall 1: Coffee Bag Label Parsing is Heuristic, Not Deterministic

**What goes wrong:** Developer builds a rigid parser expecting labels to follow a consistent format (e.g., "Origin: Ethiopia"). Real coffee bags use wildly different layouts -- some list origin as "Ethiopia Yirgacheffe," others as "Single Origin: Sidamo, Ethiopia," others just "Guji."

**Why it happens:** Specialty coffee has no standardized label format. Each roaster designs their own. Fields may be labeled differently, ordered differently, or omitted entirely. Some bags have minimal info; others have paragraphs.

**How to avoid:**
- Treat OCR as a *suggestion* system, not a *data entry* system
- Present all recognized text to the user and let them tap to assign fields
- Use heuristic matching (regex for date patterns, known country names, common roast level keywords) but always allow manual override
- Design the flow as: Scan -> Review extracted fields -> Edit/correct -> Save
- Start with simple heuristics: date patterns (MM/DD/YYYY, DD.MM.YYYY), country name matching against a known list, roast level keywords ("light", "medium", "dark")

**Warning signs:** Tests only use perfectly formatted labels. No "review" step after scanning.

**Confidence:** HIGH -- Based on analysis of specialty coffee label conventions from multiple roaster guides.

### Pitfall 2: @Query Cannot Be Dynamically Updated In-Place

**What goes wrong:** Developer tries to change the `#Predicate` of an existing `@Query` property after the view has been created. The query does not update.

**Why it happens:** `@Query` captures its configuration at view initialization time. Changing the search text state variable does not retroactively update the query's predicate.

**How to avoid:**
- Use the parent/child view pattern: parent owns search state, child receives it in `init()` and configures `@Query` there
- When the parent's search text changes, SwiftUI recreates the child view with the new text, which reinitializes `@Query`

**Warning signs:** Search bar text changes but list doesn't filter. Console shows query executing but with old predicate.

**Confidence:** HIGH -- Documented limitation, confirmed by createwithswift.com and hackingwithswift.com.

### Pitfall 3: DataScannerViewController Device Availability

**What goes wrong:** App crashes or shows blank screen when presenting DataScannerViewController on an unsupported device or simulator.

**Why it happens:** DataScannerViewController requires a device with a camera and Neural Engine (iPhone XS/XR or later, running iOS 16+). It does NOT work on the iOS Simulator.

**How to avoid:**
- Always guard with `DataScannerViewController.isSupported` before offering the scan option
- Check `DataScannerViewController.isAvailable` (true when camera permission granted) before presenting
- Provide a clear fallback: "Scan not available on this device" message with option for manual entry
- Add `NSCameraUsageDescription` to Info.plist
- Test OCR on a physical device only

**Warning signs:** Feature works in development (physical device) but crashes on testers' older devices or iPads without cameras.

**Confidence:** HIGH -- Apple documentation explicitly states device requirements.

### Pitfall 4: Freshness Indicator Not Updating Daily

**What goes wrong:** User opens the app and the freshness indicator shows yesterday's "days since roast" value. The indicator updates only when the bean is edited or the app is relaunched.

**Why it happens:** Computed properties based on `Date()` are evaluated when the view renders. If the view is cached/not redrawn, the freshness value becomes stale.

**How to avoid:**
- Compute `daysSinceRoast` as a function (not a stored property) that always uses `Calendar.current.dateComponents` against `Date.now`
- Use SwiftUI's `.onAppear` or a `TimelineView(.everyMinute)` to force periodic refresh
- Alternatively, use a lightweight `.task` modifier that checks once per view appearance

**Warning signs:** Freshness shows "14 days" even after midnight crosses to day 15.

**Confidence:** MEDIUM -- Standard date computation pattern, but the "stale cached view" issue is a known SwiftUI subtlety.

### Pitfall 5: Search Predicate with Empty String Matches Everything Incorrectly

**What goes wrong:** When search text is empty, `localizedStandardContains("")` returns `true` for all records, but combined with other predicate conditions it can produce unexpected results.

**Why it happens:** `#Predicate` closure captures variables at initialization. An empty string passed to `localizedStandardContains` matches all strings.

**How to avoid:**
- Check `searchText.isEmpty` BEFORE constructing the predicate
- Use different query configurations for empty search (show all) vs. active search (filter by text)
- The if/else pattern in the init of the child view handles this correctly

**Warning signs:** All beans disappear when user clears search field. Or archived beans appear in active list during search.

**Confidence:** HIGH -- Common pattern issue documented in SwiftData community.

## Code Examples

### Freshness Calculation and Indicator

```swift
// Source: Standard Foundation date calculation patterns

enum FreshnessLevel {
    case peak       // 0-14 days: optimal extraction window
    case acceptable // 15-30 days: still good, losing aromatics
    case stale      // 31+ days: noticeably degraded

    var label: String {
        switch self {
        case .peak: return "Fresh"
        case .acceptable: return "OK"
        case .stale: return "Stale"
        }
    }

    /// Monochrome-safe opacity levels (no color -- per design constraint)
    var opacity: Double {
        switch self {
        case .peak: return 1.0       // Full contrast
        case .acceptable: return 0.6 // Subtle
        case .stale: return 0.3      // Muted
        }
    }
}

struct FreshnessCalculator {
    static func daysSinceRoast(from roastDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: roastDate, to: Date.now)
        return max(0, components.day ?? 0)
    }

    static func freshnessLevel(daysSinceRoast days: Int) -> FreshnessLevel {
        switch days {
        case 0...14: return .peak
        case 15...30: return .acceptable
        default: return .stale
        }
    }
}
```

**IMPORTANT NOTE on BEAN-06 (green/yellow/red indicator):** The requirement says "visual freshness indicator (green/yellow/red)" but the project has a locked monochrome design constraint (black/white/gray only, no color anywhere). The planner must reconcile this: use opacity/weight/iconography to convey freshness levels instead of color. Options include:
- Filled circle vs. half-filled vs. empty circle
- Bold "FRESH" vs. normal "OK" vs. light "STALE"
- Progress bar at different fill levels
- Different SF Symbols (checkmark.circle.fill, minus.circle, xmark.circle)

### Freshness Indicator View (Monochrome)

```swift
struct FreshnessIndicatorView: View {
    let roastDate: Date?

    var body: some View {
        if let roastDate {
            let days = FreshnessCalculator.daysSinceRoast(from: roastDate)
            let level = FreshnessCalculator.freshnessLevel(daysSinceRoast: days)

            HStack(spacing: AppSpacing.xs) {
                Image(systemName: iconName(for: level))
                    .font(AppTypography.caption)
                Text("\(days)d")
                    .font(AppTypography.caption)
                    .fontWeight(level == .peak ? .bold : .regular)
            }
            .foregroundStyle(AppColors.primary.opacity(level.opacity))
        }
    }

    private func iconName(for level: FreshnessLevel) -> String {
        switch level {
        case .peak: return "checkmark.circle.fill"
        case .acceptable: return "minus.circle"
        case .stale: return "exclamationmark.circle"
        }
    }
}
```

### Coffee Bean Model Enhancements (Computed Properties)

```swift
// Additions to existing CoffeeBean.swift -- computed properties only, no schema change

extension CoffeeBean {
    var roastLevelEnum: RoastLevel {
        get { RoastLevel(rawValue: roastLevel) ?? .medium }
        set { roastLevel = newValue.rawValue }
    }

    var processingMethodEnum: ProcessingMethod {
        get { ProcessingMethod(rawValue: processingMethod) ?? .other }
        set { processingMethod = newValue.rawValue }
    }

    var daysSinceRoast: Int? {
        guard let roastDate else { return nil }
        return FreshnessCalculator.daysSinceRoast(from: roastDate)
    }

    var freshnessLevel: FreshnessLevel? {
        guard let days = daysSinceRoast else { return nil }
        return FreshnessCalculator.freshnessLevel(daysSinceRoast: days)
    }

    /// Display name: prefer bean name, fallback to "Roaster - Origin"
    var displayName: String {
        if !name.isEmpty { return name }
        if !roaster.isEmpty && !origin.isEmpty { return "\(roaster) - \(origin)" }
        if !roaster.isEmpty { return roaster }
        if !origin.isEmpty { return origin }
        return "Unnamed Coffee"
    }
}
```

### Bag Label Parser (Heuristic Text Extraction)

```swift
// Source: Custom heuristic approach based on coffee label conventions

struct ParsedBagLabel {
    var roaster: String?
    var origin: String?
    var variety: String?
    var roastDate: Date?
    var roastLevel: String?
    var region: String?
    var processingMethod: String?
}

struct BagLabelParser {
    // Common coffee-producing countries for origin detection
    static let knownOrigins = [
        "Ethiopia", "Colombia", "Brazil", "Kenya", "Guatemala",
        "Costa Rica", "Honduras", "Peru", "Rwanda", "Burundi",
        "Indonesia", "Sumatra", "Java", "Papua New Guinea",
        "Mexico", "El Salvador", "Nicaragua", "Panama",
        "Tanzania", "Uganda", "DR Congo", "Malawi",
        "India", "Yemen", "Vietnam"
    ]

    static let knownVarieties = [
        "Bourbon", "Typica", "Caturra", "Catuai", "SL28", "SL34",
        "Gesha", "Geisha", "Pacamara", "Maragogype", "Heirloom",
        "Castillo", "Colombia", "Catimor", "Pink Bourbon"
    ]

    static let roastLevelKeywords = [
        "light": "light", "medium-light": "medium_light",
        "medium light": "medium_light", "medium": "medium",
        "medium-dark": "medium_dark", "medium dark": "medium_dark",
        "dark": "dark", "espresso roast": "dark",
        "filter roast": "light", "omni roast": "medium"
    ]

    static let processingKeywords = [
        "washed": "washed", "wet process": "washed",
        "natural": "natural", "dry process": "natural",
        "honey": "honey", "honey process": "honey",
        "anaerobic": "anaerobic"
    ]

    // Date patterns common on coffee bags
    static let datePatterns = [
        "\\d{1,2}/\\d{1,2}/\\d{2,4}",     // MM/DD/YYYY or D/M/YY
        "\\d{1,2}\\.\\d{1,2}\\.\\d{2,4}",  // DD.MM.YYYY
        "\\d{1,2}-\\d{1,2}-\\d{2,4}",      // DD-MM-YYYY
        "\\d{4}-\\d{2}-\\d{2}",            // ISO: YYYY-MM-DD
        // "Roasted: January 15, 2026" etc.
    ]

    static func parse(recognizedTexts: [String]) -> ParsedBagLabel {
        var result = ParsedBagLabel()
        let allText = recognizedTexts.joined(separator: "\n")
        let lowered = allText.lowercased()

        // Extract origin (match known country names)
        for country in knownOrigins {
            if allText.localizedCaseInsensitiveContains(country) {
                result.origin = country
                break
            }
        }

        // Extract variety
        for variety in knownVarieties {
            if allText.localizedCaseInsensitiveContains(variety) {
                result.variety = variety
                break
            }
        }

        // Extract roast level
        for (keyword, value) in roastLevelKeywords {
            if lowered.contains(keyword) {
                result.roastLevel = value
                break
            }
        }

        // Extract processing method
        for (keyword, value) in processingKeywords {
            if lowered.contains(keyword) {
                result.processingMethod = value
                break
            }
        }

        // Extract date (attempt common patterns)
        result.roastDate = extractDate(from: allText)

        // First line or most prominent text is often the roaster name
        // (heuristic -- user should always verify)
        if let firstLine = recognizedTexts.first, !firstLine.isEmpty {
            result.roaster = firstLine
        }

        return result
    }

    private static func extractDate(from text: String) -> Date? {
        let dateFormatters: [DateFormatter] = {
            let formats = [
                "MM/dd/yyyy", "M/d/yyyy", "MM/dd/yy",
                "dd.MM.yyyy", "d.M.yyyy",
                "dd-MM-yyyy", "yyyy-MM-dd",
                "MMMM d, yyyy", "MMM d, yyyy",
                "MMMM dd, yyyy", "MMM dd, yyyy"
            ]
            return formats.map { format in
                let df = DateFormatter()
                df.dateFormat = format
                df.locale = Locale(identifier: "en_US_POSIX")
                return df
            }
        }()

        for pattern in datePatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let dateString = String(text[range])
                for formatter in dateFormatters {
                    if let date = formatter.date(from: dateString) {
                        // Sanity check: date should be within last 2 years
                        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: Date.now)!
                        if date > twoYearsAgo && date <= Date.now {
                            return date
                        }
                    }
                }
            }
        }
        return nil
    }
}
```

### Active/Archived Segmented Filter

```swift
// Source: Standard SwiftUI Picker with .segmented style

struct BeanListView: View {
    @State private var searchText = ""
    @State private var showArchived = false
    @State private var showingAddSheet = false
    @State private var showingScanner = false

    var body: some View {
        VStack(spacing: 0) {
            // Active / Archived toggle
            Picker("Filter", selection: $showArchived) {
                Text("Active").tag(false)
                Text("Archived").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)

            BeanListContent(searchText: searchText, showArchived: showArchived)
        }
        .searchable(text: $searchText, prompt: "Search by roaster or origin")
        .navigationTitle("Beans")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add Manually", systemImage: "plus")
                    }
                    if DataScannerViewController.isSupported {
                        Button {
                            showingScanner = true
                        } label: {
                            Label("Scan Bag Label", systemImage: "camera.viewfinder")
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom AVCaptureSession + Vision pipeline for OCR | DataScannerViewController (VisionKit) | iOS 16 (WWDC 2022) | Complete camera + text recognition UI in one component |
| NSPredicate (string-based, runtime errors) | #Predicate macro (type-checked at compile time) | iOS 17 (WWDC 2023) | Compile-time safety for SwiftData queries |
| Manual NSFetchedResultsController for search | @Query + #Predicate + .searchable() | iOS 17 (WWDC 2023) | Declarative search with database-level filtering |
| VNRecognizeTextRequest only (image-based) | DataScannerViewController (live) + VNRecognizeTextRequest (static) | iOS 16+ | Live scanning is now trivial; static OCR remains for photo-based flow |

**Deprecated/outdated:**
- Custom camera capture sessions for text recognition (use DataScannerViewController instead)
- String-based NSPredicate with SwiftData (use #Predicate macro)
- In-memory filtering of @Query results (use database-level #Predicate)

## OCR Architecture: Two Approaches

The bag scanning feature (BEAN-05) should support two flows:

### Approach A: Live Camera Scanning (Primary)

Use `DataScannerViewController` for real-time text recognition from the camera feed.

**Pros:** Instant feedback, user sees text being recognized, can position camera for best results.
**Cons:** Requires iOS 16+, Neural Engine device, camera permission. Cannot process photos from library.

**Flow:** Open scanner -> Point at bag -> Tap "Capture" when text is visible -> Parse recognized text -> Show review screen with extracted fields -> User corrects/confirms -> Save bean.

### Approach B: Photo-Based OCR (Fallback)

Capture or select a photo, then run `VNRecognizeTextRequest` on the image.

**Pros:** Works with photos from library, can process images from any source, works on more devices.
**Cons:** No live preview, user doesn't know if text will be recognized until after capture.

**Flow:** Take/select photo -> Run VNRecognizeTextRequest -> Parse recognized text -> Show review screen -> User corrects/confirms -> Save bean.

**Recommendation:** Implement Approach A as the primary path with Approach B as fallback when `DataScannerViewController.isSupported` returns false. Both approaches feed into the same `BagLabelParser` and `ScanResultReviewView`.

## Design Decisions (Recommendations for Planner)

### Bean List Row Design

**Recommendation:** Show roaster name (primary), origin + variety (secondary), freshness indicator (trailing). Include bag photo thumbnail if available (same 40x40 circle pattern as EquipmentRow). For monochrome, use SF Symbols `leaf` or `cup.and.saucer` as default icon when no photo.

### Bean Display Name

**Recommendation:** Many specialty coffees don't have a "name" per se -- they're identified by "Roaster - Origin" (e.g., "Counter Culture - Hologram" or just "Ethiopia Yirgacheffe"). Use a computed `displayName` property: prefer `name` if set, fallback to `roaster - origin`, fallback to `origin`, fallback to "Unnamed Coffee".

### Freshness Thresholds

**Recommendation:** Use coffee industry standard windows:
- Peak: 0-14 days (optimal for most brew methods)
- Acceptable: 15-30 days (still drinkable, losing aromatics)
- Stale: 31+ days (noticeably degraded)

These are appropriate defaults. User-configurable thresholds are a v2 feature.

### Tab Placement

**Recommendation:** Add "Beans" as the first tab (before Methods and Grinders), since beans are the most frequently accessed entity (users add new beans weekly, check freshness daily). Tab icon: `leaf` SF Symbol.

### OCR User Experience

**Recommendation:** The scan feature should be a secondary action (not the primary "Add Bean" flow). Most beans will be added manually (faster than scanning for experienced users). Scan is a convenience for new bags. Present scan as an option in a menu alongside "Add Manually."

## Open Questions

1. **CoffeeBean model `name` field usage**
   - What we know: The model has both `name` and `roaster` fields. In specialty coffee, beans are often identified by roaster + origin rather than a distinct "name."
   - What's unclear: Should `name` be required, optional, or auto-generated from other fields?
   - Recommendation: Make `name` optional (it already has a default of ""). Use `displayName` computed property for display. Let user set a custom name if they want (e.g., "Morning Blend") but don't require it.

2. **OCR accuracy on diverse coffee labels**
   - What we know: Vision framework OCR is good for printed text. Coffee labels use varied fonts, orientations, and layouts.
   - What's unclear: How well the heuristic parser will work across different roasters' label designs.
   - Recommendation: Build the parser with known-good heuristics (country names, date patterns) and always require user confirmation. Track which fields are most often corrected to improve heuristics over time (v2 improvement).

3. **Roast date vs. "best by" date**
   - What we know: Some roasters print roast date, others print "best by" or "enjoy by" date (typically roast date + 30-90 days).
   - What's unclear: Should the parser attempt to distinguish these?
   - Recommendation: For v1, parse any date found and let the user confirm it's the roast date. Add a note in the review screen: "Is this the roast date?" The date field in the model is already named `roastDate`, which makes the intent clear.

## Sources

### Primary (HIGH confidence)
- [Apple DataScannerViewController](https://developer.apple.com/documentation/visionkit/datascannerviewcontroller) -- Live text scanning API, iOS 16+
- [Apple VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest) -- Image-based OCR API
- [Apple: Capture machine-readable codes and text with VisionKit (WWDC22)](https://developer.apple.com/videos/play/wwdc2022/10025/) -- DataScannerViewController introduction
- [createwithswift.com: Performing search with SwiftData](https://www.createwithswift.com/performing-search-with-swiftdata-in-a-swiftui-app/) -- Parent/child @Query pattern for dynamic search
- [createwithswift.com: Recognizing text with the Vision framework](https://www.createwithswift.com/recognizing-text-with-the-vision-framework/) -- VNRecognizeTextRequest code patterns
- [swiftyplace.com: Query and Filter Data with SwiftData Predicate](https://www.swiftyplace.com/blog/fetch-and-filter-in-swiftdata) -- #Predicate syntax, optional handling, compound conditions
- [hackingwithswift.com: Filtering SwiftData results with predicates](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-filter-swiftdata-results-with-predicates) -- Dynamic predicate pattern
- Phase 1 codebase (GrinderDetailView, GrinderListView, EquipmentPhotoPickerView) -- Proven patterns to replicate

### Secondary (MEDIUM confidence)
- [Crema Coffee Roasters: How to Decode a Coffee Label](https://crema-coffee.com/blogs/coffee-101/how-to-decode-a-coffee-label) -- Coffee label field conventions
- [hackingwithswift.com: Dynamically sorting and filtering @Query with SwiftUI](https://www.hackingwithswift.com/books/ios-swiftui/dynamically-sorting-and-filtering-query-with-swiftui) -- Dynamic query patterns
- [Apple Developer Forums: VisionKit](https://developer.apple.com/forums/tags/visionkit) -- Community questions and Apple engineer answers on DataScanner limitations
- Multiple Medium tutorials on DataScannerViewController UIViewControllerRepresentable wrapping -- Consistent pattern across sources

### Tertiary (LOW confidence)
- Coffee industry freshness windows (0-14 peak, 15-30 acceptable, 31+ stale) -- Generally accepted but varies by roast level and brew method. Good defaults for v1.
- BagLabelParser heuristics -- Custom approach based on label analysis. Will need real-world testing and iteration.

## Metadata

**Confidence breakdown:**
- CRUD views/patterns: HIGH -- Direct replication of Phase 1 patterns with different model
- SwiftData search/filter: HIGH -- Well-documented pattern, multiple authoritative sources agree
- Freshness computation: HIGH -- Simple date math, standard Foundation APIs
- Monochrome freshness indicator: MEDIUM -- Reconciling color-based requirement with monochrome constraint requires design judgment
- DataScannerViewController integration: HIGH -- Well-documented API, UIViewControllerRepresentable is standard pattern
- Bag label parsing heuristics: LOW -- Custom approach, no authoritative source, requires real-world validation
- OCR accuracy on coffee labels: MEDIUM -- Apple's OCR is good for printed text, but coffee labels vary widely in design

**Research date:** 2026-02-09
**Valid until:** 2026-03-09 (stable Apple frameworks, 30-day validity)
