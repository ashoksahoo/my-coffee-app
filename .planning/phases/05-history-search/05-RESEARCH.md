# Phase 5: History & Search - Research

**Researched:** 2026-02-09
**Domain:** SwiftUI list filtering with SwiftData predicates, multi-criteria search, date range filtering, statistics dashboard with Swift Charts
**Confidence:** HIGH

## Summary

Phase 5 enhances the existing brew log list (BrewLogListView) with filtering, multi-criteria search, and a statistics dashboard. The current BrewLogListView is a simple chronological list with no filtering -- it uses a static `@Query(sort: \BrewLog.createdAt, order: .reverse)`. The brew detail view (BrewLogDetailView) already shows all parameters, photos, and tasting notes, satisfying HIST-04 and HIST-05 largely as-is (with minor polish opportunities).

The primary technical challenges are: (1) building a multi-criteria filter that combines coffee, method, date range, and rating constraints into a single SwiftData `#Predicate`, (2) handling optional relationship properties (BrewLog.brewMethod?, BrewLog.coffeeBean?) within predicates safely, and (3) aggregating brew data for a statistics dashboard using Swift Charts. The codebase already has an established parent/child `@Query` pattern (BeanListView/BeanListContent) for dynamic filtering that should be extended for the richer filter requirements here.

The statistics dashboard requires Swift Charts (Apple's built-in charting framework, available since iOS 16). This is a new dependency for the project but ships with the OS -- no external packages needed. The dashboard will compute aggregations (favorite methods, top beans, average ratings, trends over time) in-memory from the full brew collection, which is appropriate for a personal journal app where dataset sizes are small (hundreds to low thousands of records).

**Primary recommendation:** Extend the existing BrewLogListView with a parent/child @Query pattern for multi-criteria filtering. Use a dedicated `BrewHistoryViewModel` to manage filter state and expose the combined `#Predicate`. Build the statistics dashboard as a separate view using Swift Charts (BarMark, LineMark, SectorMark) with in-memory aggregation from `@Query` results.

## Standard Stack

### Core (Already in Project)

| Library/Framework | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All views (List, Form, Picker, DatePicker, NavigationStack) | Already used throughout app |
| SwiftData | iOS 17+ | BrewLog @Query, #Predicate for filtering, relationships | Already configured with CloudKit |
| CloudKit | iOS 17+ | Automatic sync via ModelContainer | Already configured |

### Supporting (New Usage in This Phase)

| Library/Framework | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| Swift Charts | iOS 16+ (ships with OS) | BarMark, LineMark, SectorMark for statistics dashboard | Statistics dashboard (HIST-06) |

### No New External Dependencies

All history, search, and statistics functionality is achievable with Apple frameworks. Swift Charts is the only new framework import, and it ships with iOS -- no Package.swift changes needed.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Swift Charts | SpiderChartView (existing custom) | Custom charts already in codebase for flavor profile; Swift Charts is better for bar/line/pie stats charts with built-in axes, legends, accessibility |
| #Predicate dynamic construction | In-memory Array.filter | Predicates filter at database level (faster for large datasets); in-memory filter simpler to write but loads all objects first |
| searchScopes | Custom segmented Picker | searchScopes integrates with .searchable natively; custom Picker already proven in codebase (BeanListView) and gives more layout control |

## Architecture Patterns

### Recommended Project Structure (New Files)

```
CoffeeJournal/
├── Views/
│   └── History/
│       ├── BrewHistoryView.swift         # Parent view: search bar, filter controls, sort picker
│       ├── BrewHistoryListContent.swift   # Child view: @Query with dynamic predicate
│       ├── BrewFilterSheet.swift          # Advanced search modal with multi-criteria filters
│       └── StatisticsDashboardView.swift  # Charts dashboard (favorite methods, top beans, trends)
├── ViewModels/
│   └── BrewHistoryViewModel.swift        # Filter state, predicate construction, statistics computation
└── (existing files modified)
    ├── Views/Brewing/BrewLogListView.swift   # Refactored to use BrewHistoryView or replaced
    └── Views/MainTabView.swift               # Possibly add History tab or integrate into Brews tab
```

### Pattern 1: Parent/Child @Query with Dynamic Multi-Criteria Predicate

**What:** The parent view manages filter state (search text, selected method, selected bean, date range, minimum rating). The child view reinitializes `@Query` in its `init` with a `#Predicate` built from the current filter state.

**When to use:** Whenever filter criteria need to change at runtime. This is the established codebase pattern (BeanListView/BeanListContent).

**Critical detail:** SwiftData `#Predicate` cannot compare model objects directly. Use `persistentModelID` for relationship filtering. Optional relationships need `flatMap` or `if let` within the predicate. Variables from outside the `#Predicate` closure must be captured as local `let` bindings.

**Example:**

```swift
// Source: Established BeanListContent pattern + fatbobman.com predicate guide
struct BrewHistoryListContent: View {
    @Query private var brews: [BrewLog]
    @Environment(\.modelContext) private var modelContext

    init(
        searchText: String,
        methodID: PersistentIdentifier?,
        beanID: PersistentIdentifier?,
        startDate: Date?,
        endDate: Date?,
        minimumRating: Int
    ) {
        // Capture all filter values as local lets
        let search = searchText
        let mID = methodID
        let bID = beanID
        let sDate = startDate
        let eDate = endDate
        let minRating = minimumRating

        _brews = Query(
            filter: #Predicate<BrewLog> { brew in
                // Text search (notes or coffee name)
                (search.isEmpty ||
                 brew.notes.localizedStandardContains(search)) &&

                // Rating filter
                brew.rating >= minRating &&

                // Date range filter
                (sDate == nil || brew.createdAt >= sDate!) &&
                (eDate == nil || brew.createdAt <= eDate!)
            },
            sort: [SortDescriptor(\BrewLog.createdAt, order: .reverse)]
        )
    }

    var body: some View {
        // ... list rendering
    }
}
```

**Relationship filtering note:** Filtering by `brewMethod` or `coffeeBean` relationship within `#Predicate` requires comparing `persistentModelID`. However, due to optional relationship chaining limitations in `#Predicate` (especially with `flatMap` and `persistentModelID`), a hybrid approach is safer: use `#Predicate` for scalar filters (date, rating, text) and apply relationship filters as in-memory post-filters on the `@Query` result. For a personal journal app with hundreds of brews, this hybrid approach has negligible performance impact.

**Confidence:** HIGH -- parent/child @Query pattern is proven in BeanListView. Scalar predicate filtering is well-documented. Hybrid approach for relationships avoids known `#Predicate` optional chaining pitfalls.

### Pattern 2: Advanced Search as Filter Sheet

**What:** A modal sheet presenting all filter criteria: method picker, bean picker, date range (two DatePickers), minimum rating slider, and a clear/apply action. Filter state managed in a ViewModel.

**When to use:** For the advanced multi-criteria search (HIST-03).

**Example:**

```swift
// Source: Derived from AddBrewLogView sheet pattern
struct BrewFilterSheet: View {
    @Binding var selectedMethodID: PersistentIdentifier?
    @Binding var selectedBeanID: PersistentIdentifier?
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Binding var minimumRating: Int
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \BrewMethod.name) private var methods: [BrewMethod]
    @Query(filter: #Predicate<CoffeeBean> { !$0.isArchived },
           sort: \CoffeeBean.createdAt, order: .reverse) private var beans: [CoffeeBean]

    var body: some View {
        NavigationStack {
            Form {
                Section("Brew Method") {
                    Picker("Method", selection: $selectedMethodID) {
                        Text("All Methods").tag(nil as PersistentIdentifier?)
                        ForEach(methods) { method in
                            Text(method.name).tag(Optional(method.persistentModelID))
                        }
                    }
                }

                Section("Coffee") {
                    Picker("Bean", selection: $selectedBeanID) {
                        Text("All Coffees").tag(nil as PersistentIdentifier?)
                        ForEach(beans) { bean in
                            Text(bean.displayName).tag(Optional(bean.persistentModelID))
                        }
                    }
                }

                Section("Date Range") {
                    Toggle("Filter by date", isOn: dateFilterEnabled)
                    if dateFilterEnabled.wrappedValue {
                        DatePicker("From", selection: startDateBinding, displayedComponents: .date)
                        DatePicker("To", selection: endDateBinding, displayedComponents: .date)
                    }
                }

                Section("Minimum Rating") {
                    Picker("Rating", selection: $minimumRating) {
                        Text("Any").tag(0)
                        ForEach(1...5, id: \.self) { r in
                            Text("\(r)+ stars").tag(r)
                        }
                    }
                }

                Section {
                    Button("Clear All Filters") { clearFilters() }
                        .foregroundStyle(AppColors.secondary)
                }
            }
            .navigationTitle("Filter Brews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
    }
}
```

**Confidence:** HIGH -- uses established form patterns (Picker, DatePicker, Toggle) and sheet presentation from existing codebase.

### Pattern 3: Statistics Dashboard with Swift Charts

**What:** A scrollable dashboard view computing statistics from the full brew collection: favorite methods (bar or pie chart), top beans (bar chart), average rating over time (line chart), brew frequency (bar chart by week/month).

**When to use:** Statistics dashboard (HIST-06).

**Example:**

```swift
// Source: swiftwithmajid.com/2023/01/10/mastering-charts-in-swiftui-basics/
import Charts

struct StatisticsDashboardView: View {
    @Query(sort: \BrewLog.createdAt, order: .reverse) private var brews: [BrewLog]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if brews.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.bar",
                        title: "No Statistics Yet",
                        message: "Log some brews to see your stats"
                    )
                } else {
                    summaryCards
                    methodDistributionChart
                    topBeansChart
                    ratingTrendChart
                    brewFrequencyChart
                }
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Bar chart: brews per method
    private var methodDistributionChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Brews by Method")
                .font(AppTypography.headline)

            let methodCounts = Dictionary(grouping: brews, by: { $0.brewMethod?.name ?? "Unknown" })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }

            Chart(methodCounts, id: \.key) { item in
                BarMark(
                    x: .value("Method", item.key),
                    y: .value("Count", item.value)
                )
                .foregroundStyle(AppColors.primary)
            }
            .frame(height: 200)
        }
    }

    // Line chart: average rating over time
    private var ratingTrendChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Rating Trend")
                .font(AppTypography.headline)

            let ratedBrews = brews.filter { $0.rating > 0 }
            // Group by month, compute average
            Chart(ratedBrews) { brew in
                LineMark(
                    x: .value("Date", brew.createdAt, unit: .month),
                    y: .value("Rating", brew.rating)
                )
                .foregroundStyle(AppColors.primary)
            }
            .frame(height: 200)
        }
    }
}
```

**Confidence:** HIGH -- Swift Charts API (BarMark, LineMark) is well-documented and ships with iOS 16+. Aggregation is simple in-memory computation appropriate for personal journal dataset sizes.

### Pattern 4: Hybrid Predicate + In-Memory Filter for Relationships

**What:** Use `#Predicate` for scalar fields (date range, rating, text search) that perform well at the database level. Apply relationship-based filters (method, bean) as in-memory post-filters on the `@Query` results.

**When to use:** When the `#Predicate` limitations around optional relationship `persistentModelID` comparisons cause issues or complexity.

**Example:**

```swift
struct BrewHistoryListContent: View {
    @Query private var brews: [BrewLog]
    let methodID: PersistentIdentifier?
    let beanID: PersistentIdentifier?

    init(searchText: String, methodID: PersistentIdentifier?, beanID: PersistentIdentifier?,
         startDate: Date?, endDate: Date?, minimumRating: Int) {
        self.methodID = methodID
        self.beanID = beanID

        let search = searchText
        let minRating = minimumRating
        let sDate = startDate
        let eDate = endDate

        _brews = Query(
            filter: #Predicate<BrewLog> { brew in
                (search.isEmpty || brew.notes.localizedStandardContains(search)) &&
                brew.rating >= minRating &&
                (sDate == nil || brew.createdAt >= sDate!) &&
                (eDate == nil || brew.createdAt <= eDate!)
            },
            sort: [SortDescriptor(\BrewLog.createdAt, order: .reverse)]
        )
    }

    // In-memory relationship filtering on already-fetched results
    private var filteredBrews: [BrewLog] {
        brews.filter { brew in
            if let mID = methodID {
                guard brew.brewMethod?.persistentModelID == mID else { return false }
            }
            if let bID = beanID {
                guard brew.coffeeBean?.persistentModelID == bID else { return false }
            }
            return true
        }
    }

    var body: some View {
        if filteredBrews.isEmpty {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "No Matches",
                message: "Try adjusting your filters"
            )
        } else {
            List {
                ForEach(filteredBrews) { brew in
                    NavigationLink {
                        BrewLogDetailView(brew: brew)
                    } label: {
                        BrewLogRow(brew: brew)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}
```

**Confidence:** HIGH -- hybrid approach avoids known `#Predicate` optional relationship pitfalls while maintaining database-level filtering for the most common criteria. In-memory post-filtering is negligible for typical personal journal sizes (< 10,000 records).

### Anti-Patterns to Avoid

- **Comparing model objects in #Predicate:** `#Predicate` cannot compare SwiftData `@Model` objects directly. Always use `persistentModelID` for relationship comparisons, or use in-memory post-filtering.
- **Force unwrapping in #Predicate without nil guard:** While `sDate!` works when preceded by `sDate == nil ||`, be cautious. The `#Predicate` macro translates to SQL-like expressions; ensure the nil check short-circuits before the force unwrap.
- **Fetching all brews multiple times:** The statistics dashboard and the filtered list should NOT each fetch separately. Either share a common data source or accept that two `@Query` properties on separate views is fine (SwiftData caches efficiently).
- **Using `#Index` macro:** The `#Index` macro for compound indexes requires iOS 18+. Since the app targets iOS 17+, do NOT use `#Index`. Query performance is adequate for personal journal dataset sizes without indexes.
- **Deeply nested optional chains in #Predicate:** `brew.brewMethod?.category.rawValue` or `brew.coffeeBean?.name` in a `#Predicate` can produce incorrect results or crashes. Use in-memory filtering for these instead.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bar/line/pie charts | Custom drawing (Canvas, Path) | Swift Charts (BarMark, LineMark, SectorMark) | Built-in axes, legends, accessibility, animation; ships with iOS 16+ |
| Date range input | Custom calendar component | Two SwiftUI DatePicker controls | Standard component, handles locale/calendar automatically |
| Search bar | Custom TextField with magnifying glass | .searchable() modifier | Native iOS search bar with cancel/clear, keyboard dismiss, search suggestions |
| Empty state for no results | Custom VStack placeholder | EmptyStateView (already exists) | Reuse existing component |
| List with swipe-to-delete | Custom gesture recognizer | List with .swipeActions (already exists in BrewLogListContent) | Standard SwiftUI pattern already in codebase |
| Aggregation/statistics | External analytics library | In-memory Dictionary(grouping:) + map/reduce | Standard Swift collection operations; dataset is small enough |

**Key insight:** The hard part of Phase 5 is not individual UI components (all are standard SwiftUI) but the orchestration of filter state flowing into dynamic `#Predicate` construction while avoiding SwiftData's optional relationship pitfalls. The hybrid predicate + in-memory approach sidesteps the hardest pitfalls.

## Common Pitfalls

### Pitfall 1: #Predicate Cannot Compare @Model Objects

**What goes wrong:** Compiler error or runtime crash when filtering BrewLog by its brewMethod relationship.
**Why it happens:** `#Predicate` translates expressions to SQL. It cannot serialize `@Model` objects into SQL WHERE clauses.
**How to avoid:** Use `persistentModelID` for comparisons: `brew.brewMethod?.persistentModelID == targetID`. Or use in-memory post-filtering.
**Warning signs:** Compiler error "unable to type-check this expression in reasonable time" or runtime EXC_BAD_ACCESS.

### Pitfall 2: Variable Capture in #Predicate Closure

**What goes wrong:** Predicate fails at runtime with "keypaths with multiple components" error.
**Why it happens:** `#Predicate` captures variables from surrounding scope. If you reference a property on a state object (e.g., `viewModel.searchText`), the macro interprets it as a multi-component keypath.
**How to avoid:** Always extract filter values into local `let` constants before the `#Predicate`: `let search = viewModel.searchText`.
**Warning signs:** Runtime error mentioning "keypaths" or "multiple components."

### Pitfall 3: Optional Relationship Chaining in #Predicate

**What goes wrong:** Predicate compiles but returns incorrect results (e.g., all records or no records).
**Why it happens:** Multiple optional chains (e.g., `brew.brewMethod?.name?.contains(search)`) were unreliable in early iOS 17 versions. Fixed in iOS 17.5+, but still fragile with complex chains.
**How to avoid:** Keep predicates simple (scalar comparisons). Move relationship-based filtering to in-memory post-filter. If targeting iOS 17.5+, `flatMap` with nil-coalescing (`?? false`) is the documented workaround.
**Warning signs:** Filter appears to work but returns all results, or filter returns zero results when matches exist.

### Pitfall 4: Statistics Computation on Every View Update

**What goes wrong:** Dashboard becomes sluggish as brew count grows.
**Why it happens:** Computing groupBy/average/counts in computed properties recalculates on every SwiftUI view update cycle.
**How to avoid:** Use `.task` or `.onChange(of: brews)` to compute statistics once and store in `@State` variables. Or memoize in a ViewModel. For small datasets (< 1000 brews), computed properties are acceptable.
**Warning signs:** Dashboard scroll stutters or chart animations replay on unrelated state changes.

### Pitfall 5: Forgetting to Reset Filters

**What goes wrong:** User applies filters, navigates away, comes back -- stale filters still active but not visible.
**Why it happens:** Filter state persists in parent view's @State across tab switches.
**How to avoid:** Show an active filter indicator (badge or subtitle) when any filter is non-default. Provide a "Clear All" action that is always accessible. Consider whether filters should persist or reset on tab switch.
**Warning signs:** User sees "No Matches" when they expect to see all brews, with no indication that filters are active.

### Pitfall 6: Swift Charts Import Missing from Package.swift

**What goes wrong:** CLI build (`swift build`) fails with "No such module 'Charts'".
**Why it happens:** The Package.swift is used for CLI verification. Swift Charts is a system framework available in Xcode builds but may need explicit handling for SPM builds.
**How to avoid:** Add Charts files to the Package.swift sources list. The Charts framework ships with the OS and is available to SPM when building for iOS. If CLI build issues arise, the StatisticsDashboardView can be excluded from Package.swift sources (as other view files are) since the Package.swift is for verification only, not production.
**Warning signs:** `swift build` failure mentioning Charts module.

## Code Examples

### Summary Statistics Cards

```swift
// Source: Standard SwiftUI pattern
private var summaryCards: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
        StatCard(title: "Total Brews", value: "\(brews.count)", icon: "mug")
        StatCard(
            title: "Avg Rating",
            value: averageRating,
            icon: "star"
        )
        StatCard(
            title: "Top Method",
            value: topMethodName,
            icon: "cup.and.saucer"
        )
        StatCard(
            title: "Top Bean",
            value: topBeanName,
            icon: "leaf"
        )
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(AppTypography.title)
                .foregroundStyle(AppColors.subtle)
            Text(value)
                .font(AppTypography.headline)
                .lineLimit(1)
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
```

### Brew Frequency Chart (Bar Chart by Month)

```swift
// Source: swiftwithmajid.com Swift Charts basics
import Charts

private var brewFrequencyChart: some View {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
        Text("Brew Frequency")
            .font(AppTypography.headline)

        Chart(brews) { brew in
            BarMark(
                x: .value("Month", brew.createdAt, unit: .month),
                y: .value("Count", 1)
            )
            .foregroundStyle(AppColors.primary.opacity(0.8))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .frame(height: 200)
    }
}
```

### Active Filter Indicator

```swift
// Source: Standard SwiftUI pattern
private var hasActiveFilters: Bool {
    selectedMethodID != nil || selectedBeanID != nil ||
    startDate != nil || endDate != nil || minimumRating > 0 ||
    !searchText.isEmpty
}

// In toolbar or navigation subtitle:
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button {
            showingFilterSheet = true
        } label: {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundStyle(AppColors.primary)
        }
    }
}
```

### SectorMark Pie Chart for Method Distribution

```swift
// Source: appcoda.com/swiftui-chart-ios17/ (SectorMark available iOS 17+)
import Charts

private var methodPieChart: some View {
    let methodCounts = Dictionary(grouping: brews, by: { $0.brewMethod?.name ?? "Unknown" })
        .mapValues { $0.count }
        .sorted { $0.value > $1.value }
        .prefix(5)  // Top 5 methods

    return VStack(alignment: .leading, spacing: AppSpacing.sm) {
        Text("Method Distribution")
            .font(AppTypography.headline)

        Chart(Array(methodCounts), id: \.key) { item in
            SectorMark(
                angle: .value("Count", item.value),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("Method", item.key))
        }
        .chartForegroundStyleScale(range: grayscaleRange(count: methodCounts.count))
        .frame(height: 200)
    }
}

// Monochrome-compatible grayscale palette
private func grayscaleRange(count: Int) -> [Color] {
    (0..<count).map { i in
        Color.primary.opacity(1.0 - Double(i) * 0.15)
    }
}
```

### Searchable with Filter Badge

```swift
// Source: Established BeanListView .searchable pattern
struct BrewHistoryView: View {
    @State private var searchText = ""
    @State private var selectedMethodID: PersistentIdentifier?
    @State private var selectedBeanID: PersistentIdentifier?
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var minimumRating: Int = 0
    @State private var showingFilterSheet = false

    var body: some View {
        BrewHistoryListContent(
            searchText: searchText,
            methodID: selectedMethodID,
            beanID: selectedBeanID,
            startDate: startDate,
            endDate: endDate,
            minimumRating: minimumRating
        )
        .searchable(text: $searchText, prompt: "Search brew notes")
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: hasActiveFilters
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            BrewFilterSheet(
                selectedMethodID: $selectedMethodID,
                selectedBeanID: $selectedBeanID,
                startDate: $startDate,
                endDate: $endDate,
                minimumRating: $minimumRating
            )
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| NSPredicate string format | #Predicate macro (type-safe) | iOS 17 (2023) | Compile-time safety, Swift-native syntax |
| Core Data NSCompoundPredicate | PredicateExpressions.Conjunction or conditional logic in #Predicate | iOS 17 (2023) | Less flexible but type-safe; hybrid approach recommended |
| Third-party charts (Charts by Daniel Gindi) | Swift Charts (Apple) | iOS 16 (2022) | Native, accessible, monochrome-compatible, no dependency |
| NavigationView | NavigationStack | iOS 16 (2022) | Better programmatic navigation, value-based |
| NSFetchedResultsController sections | @Query with groupBy: or in-memory grouping | iOS 17 (2023) | Simpler API; sections via Dictionary(grouping:) |

**Deprecated/outdated:**
- `NSPredicate` with string format: Use `#Predicate` macro instead (type-safe, no string parsing)
- `#Index` macro: Available only in iOS 18+; do NOT use in this iOS 17+ project
- `NavigationLink(isActive:)`: Use NavigationStack with programmatic navigation
- Third-party charting libraries: Swift Charts covers all needs for this dashboard

## Key Design Decisions (Recommendations)

### 1. History View: Enhance Existing Brews Tab (Not Add New Tab)

**Recommendation:** Refactor the existing Brews tab (BrewLogListView) to become the history/search view with filtering. Do NOT add a separate "History" tab. The Brews tab IS the history view with enhanced search and filtering.

**Rationale:** The app already has 5 tabs (Brews, Beans, Methods, Grinders, Settings). Adding a 6th creates tab bar crowding. The "Brews" tab already shows chronological brew logs -- adding search and filter makes it the history view naturally. The statistics dashboard can be accessed from a toolbar button or navigation link within this tab.

### 2. Statistics Dashboard: Toolbar Button (Not Separate Tab)

**Recommendation:** Access the statistics dashboard via a toolbar button (chart icon) in the Brews/History view. It navigates to a full-screen scrollable dashboard.

**Rationale:** Statistics are explored occasionally, not on every app launch. A toolbar button keeps it discoverable without taking permanent tab space. This mirrors the Compare button placement already in the toolbar.

### 3. Filter UX: Quick Filters + Advanced Sheet

**Recommendation:** Provide `.searchable()` for text search (always visible) and a filter icon button that opens a sheet for method/bean/date/rating filters. Show a filled icon when any filter is active.

**Rationale:** Text search is the most common filter -- it should be instantly accessible. The advanced filters (method, bean, date range, rating) are used less frequently and have too many controls for inline display. A sheet is the established pattern (AddBrewLogView, BagScannerSheet).

### 4. Monochrome Charts

**Recommendation:** Use grayscale color palettes for Swift Charts. Use `Color.primary` with varying opacity levels (1.0, 0.85, 0.7, 0.55, 0.4) rather than semantic colors.

**Rationale:** The app uses a monochrome design system (AppColors). Charts should follow the same aesthetic. Swift Charts supports `.chartForegroundStyleScale(range:)` for custom color palettes.

### 5. Relationship Filtering: Hybrid Approach

**Recommendation:** Use `#Predicate` for scalar fields (date, rating, text) and in-memory post-filtering for relationship fields (method, bean).

**Rationale:** `#Predicate` optional relationship comparisons are fragile (known iOS 17 issues with multiple optional chains, persistentModelID comparisons). In-memory filtering is reliable and fast enough for personal journal dataset sizes. This avoids the single hardest pitfall in SwiftData predicate construction.

## Open Questions

1. **Sort order control**
   - What we know: Current list sorts by `createdAt` descending (newest first). This is the most natural default.
   - What's unclear: Should users be able to sort by rating, method name, or other fields?
   - Recommendation: Add a sort picker (newest/oldest/highest rated) as a toolbar menu. Use the established parent/child pattern where the parent passes `SortDescriptor` to the child's `@Query` init.

2. **Filter persistence across sessions**
   - What we know: `@State` resets on app relaunch. Users may want filters to persist.
   - What's unclear: Should active filters be saved to `@AppStorage`?
   - Recommendation: Do NOT persist filters. Reset to "show all" on each app launch. This is the simpler approach and matches user expectations (fresh start). If needed later, `@AppStorage` can encode filter state as JSON.

3. **Statistics time range**
   - What we know: The dashboard should show trends "over time."
   - What's unclear: What time range? All time, last 30 days, last 90 days?
   - Recommendation: Default to "all time" with an option to filter by time range (segmented: 30d / 90d / 1yr / All). This gives users both an overview and the ability to focus on recent trends.

4. **BrewLogDetailView enhancements**
   - What we know: HIST-04 and HIST-05 require viewing full detail with parameters, photos, and tasting notes. The existing BrewLogDetailView already shows all of these.
   - What's unclear: Does Phase 5 need to enhance the detail view, or is it already sufficient?
   - Recommendation: The existing BrewLogDetailView satisfies HIST-04 and HIST-05. No significant changes needed. Minor polish (e.g., edit/delete actions) can be added but is not required by the success criteria.

## Sources

### Primary (HIGH confidence)
- Existing codebase: BrewLogListView.swift, BrewLogListContent -- current list with static @Query
- Existing codebase: BeanListView.swift/BeanListContent -- parent/child @Query pattern with dynamic #Predicate
- Existing codebase: BrewLogDetailView.swift -- existing detail view showing parameters, photos, tasting notes
- Existing codebase: MonochromeStyle.swift -- design system (AppColors, AppTypography, AppSpacing)
- Existing codebase: BrewComparisonView.swift -- established toolbar navigation pattern
- [Hacking with Swift: Dynamic SwiftData Query](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-dynamically-change-a-querys-sort-order-or-predicate) -- parent/child @Query pattern
- [Fat Bob Man: Dynamically Construct Complex Predicates for SwiftData](https://fatbobman.com/en/posts/how-to-dynamically-construct-complex-predicates-for-swiftdata/) -- PredicateExpressions.Conjunction, limitations
- [Fat Bob Man: Handle Optional Values in SwiftData Predicates](https://fatbobman.com/en/posts/how-to-handle-optional-values-in-swiftdata-predicates/) -- flatMap, nil-coalescing, if-let in predicates
- [UseYourLoaf: SwiftData Predicates for Parent Relationships](https://useyourloaf.com/blog/swiftdata-predicates-for-parent-relationships/) -- persistentModelID comparison pattern
- [SimplyKyra: SwiftData Filtering by Entity in Predicate](https://www.simplykyra.com/blog/swiftdata-problems-with-filtering-by-entity-in-the-predicate/) -- persistentModelID workaround
- [Swift with Majid: Mastering Charts in SwiftUI Basics](https://swiftwithmajid.com/2023/01/10/mastering-charts-in-swiftui-basics/) -- BarMark, LineMark, PointMark, foregroundStyle

### Secondary (MEDIUM confidence)
- [AppCoda: Building Pie Charts and Donut Charts with SwiftUI in iOS 17](https://www.appcoda.com/swiftui-chart-ios17/) -- SectorMark, innerRadius, angularInset
- [Hacking with Swift: SwiftData Performance Optimization](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-optimize-the-performance-of-your-swiftdata-apps) -- predicate vs in-memory filtering performance
- [Hacking with Swift: Filter SwiftData Results with Predicates](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-filter-swiftdata-results-with-predicates) -- #Predicate basics
- [UseYourLoaf: SwiftData Indexes](https://useyourloaf.com/blog/swiftdata-indexes/) -- #Index macro (iOS 18+ only, not usable in this project)
- [Apple Developer Forums: #Predicate cannot test for nil relationship](https://developer.apple.com/forums/thread/732111) -- known limitation documentation

### Tertiary (LOW confidence)
- Statistics dashboard layout (summary cards + charts grid) -- derived from common iOS dashboard patterns, no canonical source
- Monochrome chart color palette -- custom design approach; no official Apple guidance on monochrome Swift Charts styling

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all Apple frameworks, Swift Charts is well-documented
- Architecture (parent/child @Query): HIGH -- proven pattern already in codebase (BeanListView)
- Architecture (hybrid predicate + in-memory): HIGH -- verified against known SwiftData limitations from multiple sources
- Swift Charts integration: HIGH -- well-documented, many verified examples
- #Predicate relationship filtering: MEDIUM -- known issues with optional chains; hybrid approach mitigates risk
- Statistics aggregation: HIGH -- standard Swift collection operations (grouping, mapping, reducing)
- Dashboard layout: MEDIUM -- derived from common patterns, not from a canonical source

**Research date:** 2026-02-09
**Valid until:** 2026-03-09 (stable Apple frameworks, established codebase patterns)
