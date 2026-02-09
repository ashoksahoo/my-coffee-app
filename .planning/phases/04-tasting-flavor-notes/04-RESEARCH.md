# Phase 4: Tasting & Flavor Notes - Research

**Researched:** 2026-02-09
**Domain:** Structured tasting profiles, SCA flavor wheel UI, flavor visualization (spider chart, word cloud), brew comparison, SwiftData/CloudKit sync
**Confidence:** HIGH

## Summary

This phase adds structured coffee tasting to the brew logging system. Users will rate brews on acidity, body, and sweetness (1-5 scale), select flavor descriptors from an interactive radial flavor wheel based on the SCA (Specialty Coffee Association) hierarchy, add custom flavor tags, view flavor profile visualizations (spider chart and word cloud), and compare tasting notes side-by-side for two brews. A TastingNote @Model already exists in SchemaV1 with CloudKit-safe defaults and an optional relationship to BrewLog.

The primary technical challenges are: (1) modeling the SCA flavor wheel as a three-tier hierarchical data structure suitable for a radial interactive UI, (2) building a custom radial wheel view using SwiftUI Path/Shape drawing and gesture handling -- there is no built-in radial flavor wheel component, (3) rendering a spider/radar chart for flavor profiles using custom SwiftUI Path drawing since Apple's Swift Charts framework does not support radar charts natively, (4) building a flow-layout tag cloud for selected flavors, and (5) designing a side-by-side brew comparison view. None of these require external dependencies -- all can be built with SwiftUI's Path, Shape, Canvas, Layout protocol, and gesture system.

The existing TastingNote model stores `flavorTags` as a single String field. This will need to store multiple structured flavor selections (category + subcategory + specific flavor from the SCA hierarchy) plus custom tags. A JSON-encoded string or comma-separated format is the CloudKit-compatible approach since CloudKit does not support array attributes or embedded model collections.

**Primary recommendation:** Build all visualization and interaction components as custom SwiftUI views using Path/Shape drawing. Store flavor wheel selections as JSON-encoded string arrays in the existing TastingNote.flavorTags field. Model the SCA flavor wheel hierarchy as a static Swift data structure (enum or struct array). Split implementation into three plans: (1) tasting note entry with attribute sliders and flavor tag selection, (2) radial flavor wheel interactive UI, (3) visualizations (spider chart + word cloud) and brew comparison view.

## Standard Stack

### Core (Already in Project)

| Library/Framework | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All views: Path, Shape, Canvas, Layout, DragGesture | Already used throughout app |
| SwiftData | iOS 17+ | TastingNote @Model, relationship to BrewLog | Already configured with CloudKit |
| CloudKit | iOS 17+ | Automatic sync via ModelContainer | Already configured in CoffeeJournalApp.swift |

### Supporting (New Usage in This Phase)

| Library/Framework | Version | Purpose | When to Use |
|-------------------|---------|---------|-------------|
| SwiftUI Path/Shape | iOS 17+ | Custom radar chart polygon drawing, radial wheel arcs | Spider chart and flavor wheel rendering |
| SwiftUI Canvas | iOS 17+ | Efficient drawing for word cloud text layout | Word cloud visualization |
| SwiftUI Layout protocol | iOS 16+ | Flow layout for flavor tag chips | Tag cloud wrapping layout |
| SwiftUI GeometryReader | iOS 17+ | Sizing the radial wheel and spider chart to available space | All custom drawn views |
| Foundation JSONEncoder/Decoder | iOS 17+ | Encoding/decoding flavor tag arrays to String | Storing structured flavor data in CloudKit-safe String field |

### No New External Dependencies

All tasting, visualization, and flavor wheel functionality is achievable with Apple frameworks already in the project. No third-party charting or layout libraries needed.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom radar chart (Path) | DDSpiderChart or TKRadarChart (third-party) | Adds dependency for a simple 3-5 axis chart; custom Path is ~80 lines and matches monochrome design system exactly |
| Custom flow layout (Layout protocol) | globulus/swiftui-flow-layout SPM package | Adds dependency for something achievable in ~40 lines with Layout protocol |
| Custom radial wheel (Path + arcs) | Third-party circular menu libraries | No existing library matches the SCA flavor wheel UX; custom is necessary |

## Architecture Patterns

### Recommended Project Structure (New Files)

```
CoffeeJournal/
├── Models/
│   └── TastingNote.swift             # Extend existing model (already has fields)
│   └── FlavorWheel.swift             # Static SCA flavor wheel hierarchy data
├── Views/
│   └── Tasting/
│       ├── TastingNoteEntryView.swift    # Form: acidity/body/sweetness sliders + flavor tags
│       ├── AttributeSliderView.swift     # Reusable 1-5 scale slider with label
│       ├── FlavorWheelView.swift         # Interactive radial flavor wheel
│       ├── FlavorTagChipView.swift       # Individual flavor tag chip
│       ├── FlavorTagFlowView.swift       # Flow layout of selected flavor chips
│       ├── SpiderChartView.swift         # Radar/spider chart Shape
│       ├── WordCloudView.swift           # Word cloud visualization
│       ├── FlavorProfileView.swift       # Combined visualization (spider + word cloud)
│       ├── BrewComparisonView.swift      # Side-by-side tasting comparison
│       └── BrewComparisonPickerView.swift # Picker for selecting brews to compare
├── Utilities/
│   └── FlowLayout.swift              # Layout protocol implementation for tag wrapping
└── ViewModels/
    └── TastingNoteViewModel.swift    # Manages flavor selections, encoding/decoding
```

### Pattern 1: SCA Flavor Wheel as Static Hierarchical Data

**What:** Model the SCA flavor wheel as a nested Swift data structure with three tiers: category (9 top-level), subcategory (~25 middle-tier), and specific descriptor (~85 outer-tier). Each node has a name, optional color, and children array.

**When to use:** This is the foundation for both the radial wheel UI and flavor tag storage.

**Example:**
```swift
// Source: SCA Coffee Taster's Flavor Wheel (2016 revision)
struct FlavorNode: Identifiable, Codable, Hashable {
    let id: String          // e.g. "fruity.berry.strawberry"
    let name: String        // e.g. "Strawberry"
    let children: [FlavorNode]

    var isLeaf: Bool { children.isEmpty }
}

struct FlavorWheel {
    static let categories: [FlavorNode] = [
        FlavorNode(id: "floral", name: "Floral", children: [
            FlavorNode(id: "floral.floral", name: "Floral", children: [
                FlavorNode(id: "floral.floral.jasmine", name: "Jasmine", children: []),
                FlavorNode(id: "floral.floral.rose", name: "Rose", children: []),
                FlavorNode(id: "floral.floral.chamomile", name: "Chamomile", children: []),
            ]),
            FlavorNode(id: "floral.tea-like", name: "Tea-like", children: [
                FlavorNode(id: "floral.tea-like.black-tea", name: "Black Tea", children: []),
                // ...
            ]),
        ]),
        FlavorNode(id: "fruity", name: "Fruity", children: [
            // Berry, Dried Fruit, Citrus Fruit, Other Fruit subcategories
        ]),
        // ... remaining 7 top-level categories
    ]
}
```

### Pattern 2: Custom Radar/Spider Chart via Path

**What:** Draw a radar chart using SwiftUI's Path and Shape protocol. The chart has N axes (one per tasting attribute), with concentric polygon rings for scale and a filled polygon for the data values.

**When to use:** For the flavor profile visualization showing acidity, body, sweetness (and potentially more attributes).

**Example:**
```swift
// Source: SwiftUI Path drawing (Apple developer.apple.com/tutorials/swiftui/drawing-paths-and-shapes)
struct RadarChartShape: Shape {
    let data: [Double]       // Values 0.0-1.0 for each axis
    let axisCount: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for (index, value) in data.enumerated() {
            let angle = (2 * .pi / Double(axisCount)) * Double(index) - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius * value,
                y: center.y + sin(angle) * radius * value
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct RadarChartView: View {
    let values: [Double]     // e.g. [0.6, 0.8, 0.4] for acidity, body, sweetness
    let labels: [String]     // e.g. ["Acidity", "Body", "Sweetness"]
    let gridLevels: Int = 5  // concentric rings

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                // Grid rings
                ForEach(1...gridLevels, id: \.self) { level in
                    RadarChartShape(
                        data: Array(repeating: Double(level) / Double(gridLevels), count: values.count),
                        axisCount: values.count
                    )
                    .stroke(AppColors.muted, lineWidth: 0.5)
                }
                // Axis lines
                // Data polygon
                RadarChartShape(data: values, axisCount: values.count)
                    .fill(AppColors.primary.opacity(0.15))
                RadarChartShape(data: values, axisCount: values.count)
                    .stroke(AppColors.primary, lineWidth: 2)
                // Labels at each axis endpoint
            }
            .frame(width: size, height: size)
        }
    }
}
```

### Pattern 3: Radial Flavor Wheel via Arc Segments

**What:** Draw concentric rings of arc segments using SwiftUI Path. The inner ring shows 9 top-level categories; tapping a category reveals its subcategories in the next ring; tapping a subcategory reveals specific descriptors in the outermost ring. Each arc is drawn with Path.addArc and filled/stroked based on selection state.

**When to use:** For the interactive SCA flavor wheel (TASTE-04).

**Example:**
```swift
// Source: SwiftUI Path arc drawing (developer.apple.com/documentation/swiftui/path)
struct FlavorWheelView: View {
    @Binding var selectedFlavors: [String]
    @State private var expandedCategory: String?
    @State private var expandedSubcategory: String?

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let outerRadius = min(geo.size.width, geo.size.height) / 2
            let innerRadius = outerRadius * 0.3
            let midRadius = outerRadius * 0.6

            Canvas { context, size in
                // Draw inner ring: 9 category arcs
                drawRing(
                    context: context,
                    items: FlavorWheel.categories,
                    center: center,
                    innerRadius: innerRadius,
                    outerRadius: midRadius
                )
                // Draw outer ring: subcategories of expanded category
                if let expanded = expandedCategory {
                    // ...draw subcategory arcs from midRadius to outerRadius
                }
            }
            // Overlay tap gesture regions for each arc
        }
    }
}
```

### Pattern 4: Flow Layout for Tag Chips

**What:** Use the SwiftUI Layout protocol to create a wrapping flow layout that arranges flavor tag chips horizontally, breaking to new lines when width is exceeded.

**When to use:** For displaying selected flavor tags as tappable chips below the flavor wheel and in the tasting entry form.

**Example:**
```swift
// Source: SwiftUI Layout protocol (developer.apple.com/documentation/swiftui/composing_custom_layouts_with_swiftui)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}
```

### Pattern 5: JSON-Encoded Flavor Tags in String Field

**What:** Store flavor selections as a JSON-encoded array of flavor IDs in the existing `TastingNote.flavorTags: String` field. This is CloudKit-safe since CloudKit does not support array attributes on SwiftData models.

**When to use:** Whenever saving or loading flavor tag selections from TastingNote.

**Example:**
```swift
// Encoding selected flavors
let selectedIds = ["fruity.berry.strawberry", "sweet.honey", "custom:caramel"]
let encoded = try JSONEncoder().encode(selectedIds)
tastingNote.flavorTags = String(data: encoded, encoding: .utf8) ?? ""

// Decoding
let decoded = try JSONDecoder().decode([String].self, from: Data(tastingNote.flavorTags.utf8))
// Custom tags prefixed with "custom:" are user-created
```

### Anti-Patterns to Avoid

- **Storing flavor selections as separate SwiftData models:** CloudKit sync of many small related records is fragile and slow. Keep flavor tags as a JSON string on TastingNote.
- **Using UIKit-based charting libraries (DGCharts/ios-charts):** These require UIViewRepresentable wrappers and do not match the monochrome SwiftUI design system. Custom Path drawing is simpler and more consistent.
- **Building the flavor wheel with standard SwiftUI views (Buttons in a circle):** This creates hit-testing issues and poor performance at 85+ elements. Use Canvas or Path-based drawing with manual hit-testing via angle/radius calculation.
- **Hardcoding flavor data inline in views:** Extract flavor wheel data into a dedicated FlavorWheel data file for maintainability and testability.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Flow/wrapping layout | Manual offset calculations | SwiftUI Layout protocol (FlowLayout) | Layout protocol handles dynamic sizing, animation, RTL automatically |
| Trigonometric arc hit-testing | Complex gesture recognizers | Simple angle+radius calculation from tap point to center | atan2() and distance formula are ~5 lines and perfectly accurate |
| JSON encoding/decoding | Custom string parsing | Foundation JSONEncoder/JSONDecoder | Handles escaping, unicode, edge cases correctly |
| Slider with discrete integer steps | Custom stepper or manual state | SwiftUI Slider with `step: 1` and rounded display | Native SwiftUI component with accessibility built in |

**Key insight:** The radial wheel and spider chart are custom drawing tasks -- there is no shortcut. But the drawing primitives (Path.addArc, Path.addLine, Canvas) are well-documented and the math is straightforward trigonometry. The complexity is in UX design, not code.

## Common Pitfalls

### Pitfall 1: CloudKit Array Attribute Crash

**What goes wrong:** Attempting to store `[String]` or `[FlavorNode]` as a SwiftData attribute type with CloudKit enabled causes a runtime crash. CloudKit does not support Transformable array types in SwiftData.
**Why it happens:** SwiftData allows `[String]` properties locally, but CloudKit's CKRecord does not support this mapping automatically.
**How to avoid:** Store arrays as JSON-encoded String. The existing `flavorTags: String = ""` field is already correctly typed for this.
**Warning signs:** App crashes on first sync attempt, or data silently fails to sync.

### Pitfall 2: Flavor Wheel Hit-Testing on Small Arcs

**What goes wrong:** Outer-ring flavor descriptors have very thin arc segments. Tap targets become too small for reliable touch interaction, especially on iPhone SE-sized screens.
**Why it happens:** 85+ descriptors divided around 360 degrees = ~4 degrees per arc at the outermost ring.
**How to avoid:** Use a drill-down pattern: show only 9 categories initially, expand to subcategories on tap, then to specific descriptors. Never show all 85+ arcs simultaneously. Minimum tap target should be 44pt (Apple HIG).
**Warning signs:** Users cannot tap intended flavors, frequent mis-taps.

### Pitfall 3: Spider Chart with 3 Axes Looks Triangular

**What goes wrong:** A radar chart with only 3 data points (acidity, body, sweetness) looks like a triangle, which is visually unimpressive and hard to read.
**Why it happens:** Radar charts work best with 5-8 axes. Three axes produce a simple triangle that wastes the circular space.
**How to avoid:** Consider adding more tasting attributes (e.g., Aroma, Aftertaste, Balance, Uniformity, Clean Cup -- standard SCA cupping form attributes) to make the spider chart more useful. Alternatively, use a horizontal bar chart for 3 attributes and reserve the spider chart for when more attributes are available. The minimum to look good as a radar chart is 5 axes.
**Warning signs:** Users find the triangle visualization unhelpful or confusing.

### Pitfall 4: TastingNote Not Linked to BrewLog

**What goes wrong:** TastingNote has `var brewLog: BrewLog?` but BrewLog does not have an explicit inverse relationship back to TastingNote. SwiftData may infer the inverse, but CloudKit requires explicit bidirectional relationships.
**Why it happens:** The existing BrewLog model was created before tasting notes were implemented, so the inverse was not added.
**How to avoid:** Add `var tastingNote: TastingNote?` to BrewLog with `@Relationship(inverse: \TastingNote.brewLog)` annotation. This requires a schema change -- since we are on SchemaV1 and have never shipped, we can modify SchemaV1 directly. If the app were already shipped, this would require a migration stage.
**Warning signs:** Tasting notes don't sync, or become orphaned records in CloudKit.

### Pitfall 5: Word Cloud Text Overlap

**What goes wrong:** Naively placing text labels at random positions in a word cloud results in overlapping, unreadable text.
**Why it happens:** Word cloud layout is a bin-packing problem. Random placement without collision detection looks terrible.
**How to avoid:** For a coffee app, a flow-layout tag cloud (chips arranged in rows) is simpler, more readable, and more useful than a true word cloud. If a word cloud aesthetic is desired, use a spiral placement algorithm with bounding-box collision detection. Recommend starting with the simpler flow-layout approach and only building a true word cloud if the user specifically wants the scattered-text aesthetic.
**Warning signs:** Text labels overlap, small fonts are unreadable, layout looks random rather than intentional.

### Pitfall 6: Comparison View State Management

**What goes wrong:** The side-by-side comparison view requires two independent brew selections. Managing two separate picker states and synchronizing their data loading gets complex.
**Why it happens:** Each "side" of the comparison needs its own BrewLog reference, and the UI must handle cases where one or both are unselected.
**How to avoid:** Use a dedicated BrewComparisonViewModel that holds `brewA: BrewLog?` and `brewB: BrewLog?`. Present brew selection as a sheet/picker that targets a specific side. Show placeholder/empty state for unselected sides.
**Warning signs:** Selection state gets confused between sides, view doesn't update when selections change.

## Code Examples

Verified patterns from official sources and existing codebase:

### Discrete Slider for Tasting Attributes (1-5 Scale)

```swift
// Source: Existing StarRatingView pattern adapted for named attributes
struct AttributeSliderView: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int> = 1...5

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(label)
                    .font(AppTypography.body)
                Spacer()
                Text("\(value)")
                    .font(AppTypography.headline)
            }
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0.rounded()) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(AppColors.primary)

            HStack {
                Text("Low")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)
                Spacer()
                Text("High")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)
            }
        }
    }
}
```

### Arc Drawing for Flavor Wheel Segment

```swift
// Source: SwiftUI Path (developer.apple.com/documentation/swiftui/path)
func arcSegmentPath(
    center: CGPoint,
    innerRadius: CGFloat,
    outerRadius: CGFloat,
    startAngle: Angle,
    endAngle: Angle
) -> Path {
    var path = Path()
    path.addArc(center: center, radius: outerRadius,
                startAngle: startAngle, endAngle: endAngle, clockwise: false)
    path.addArc(center: center, radius: innerRadius,
                startAngle: endAngle, endAngle: startAngle, clockwise: true)
    path.closeSubpath()
    return path
}
```

### Tap-to-Angle Hit Testing for Radial Wheel

```swift
// Source: Standard trigonometry for radial hit testing
func hitTest(point: CGPoint, center: CGPoint) -> (angle: Angle, radius: CGFloat) {
    let dx = point.x - center.x
    let dy = point.y - center.y
    let radius = sqrt(dx * dx + dy * dy)
    let angle = Angle(radians: atan2(dy, dx))
    return (angle, radius)
}
```

### Flavor Tag Chip

```swift
// Source: Existing monochrome design system (MonochromeStyle.swift)
struct FlavorTagChip: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(name)
            .font(AppTypography.caption)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(isSelected ? AppColors.primary : Color.clear)
            .foregroundStyle(isSelected ? AppColors.background : AppColors.primary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AppColors.primary, lineWidth: 1))
            .onTapGesture(perform: onTap)
    }
}
```

### Side-by-Side Comparison Layout

```swift
// Source: SwiftUI HStack layout pattern
struct BrewComparisonView: View {
    @State private var brewA: BrewLog?
    @State private var brewB: BrewLog?

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                // Left side
                VStack {
                    brewPickerButton(selection: $brewA, label: "Brew A")
                    if let brew = brewA {
                        comparisonCard(brew: brew)
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()

                // Right side
                VStack {
                    brewPickerButton(selection: $brewB, label: "Brew B")
                    if let brew = brewB {
                        comparisonCard(brew: brew)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle("Compare Brews")
    }
}
```

## SCA Flavor Wheel Data Structure

### Confidence: MEDIUM

The SCA Coffee Taster's Flavor Wheel (2016 revision by SCA and World Coffee Research) uses a three-tier hierarchy. Based on multiple cross-referenced sources, the structure is:

**Tier 1 - 9 Top-Level Categories:**
1. Floral
2. Fruity
3. Sour/Fermented
4. Green/Vegetative
5. Other
6. Roasted
7. Spices
8. Nutty/Cocoa
9. Sweet

**Tier 2 - Subcategories (representative examples):**
- Floral: Floral, Tea-like
- Fruity: Berry, Dried Fruit, Citrus Fruit, Other Fruit
- Sour/Fermented: Sour, Alcohol/Fermented
- Green/Vegetative: Olive Oil, Raw, Green/Vegetative
- Other: Papery/Musty, Chemical
- Roasted: Pipe Tobacco, Cereal, Burnt
- Spices: Pungent, Brown Spice
- Nutty/Cocoa: Nutty, Cocoa
- Sweet: Brown Sugar, Vanilla, Vanillin, Overall Sweet

**Tier 3 - Specific Descriptors (86 total on outer ring):**
Examples include: Jasmine, Rose, Chamomile, Black Tea, Strawberry, Raspberry, Blueberry, Blackberry, Raisin, Prune, Coconut, Cherry, Pomegranate, Pineapple, Grape, Apple, Peach, Pear, Grapefruit, Orange, Lemon, Lime, Sour, Acetic Acid, Butyric Acid, Isovaleric Acid, Citric Acid, Malic Acid, Winey, Whiskey, Fermented, Overripe, Olive Oil, Raw, Under-ripe, Peapod, Fresh, Dark Green, Vegetative, Hay-like, Herb-like, Stale, Cardboard, Papery, Woody, Musty/Dusty, Musty/Earthy, Animalic, Meaty/Brothy, Phenolic, Bitter, Salty, Medicinal, Petroleum, Skunky, Rubber, Pipe Tobacco, Grain, Malt, Smoky, Ashy, Acrid, Brown Roast, Burnt, Pungent, Pepper, Brown Spice, Anise, Nutmeg, Cinnamon, Clove, Peanuts, Hazelnut, Almond, Cocoa, Dark Chocolate, Chocolate, Molasses, Maple Syrup, Brown Sugar, Honey, Caramelized, Vanilla, Vanillin, Overall Sweet, Sweet Aromatics.

**Note:** The exact complete list of 110 WCR Sensory Lexicon attributes is available from the World Coffee Research Sensory Lexicon (worldcoffeeresearch.org/resources/sensory-lexicon). The wheel image itself is copyrighted by SCA. For implementation, we will create a representative flavor hierarchy based on publicly documented categories. The data structure supports extension -- users can also add custom tags not in the predefined wheel.

**Open-source reference data:** The GitHub Gist by robertcedwards (gist.github.com/robertcedwards/8574379) provides a JSON-structured flavor wheel, though it follows the older SCAA format. The fschlz/coffee-flavor-api repository provides a REST API with the 2016 SCA wheel data in JSON format. These can be used as implementation references.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UIKit Core Graphics for charts | SwiftUI Path + Shape + Canvas | iOS 15+ (2021) | Pure SwiftUI, no UIViewRepresentable needed |
| UICollectionView flow layout for tags | SwiftUI Layout protocol | iOS 16+ (2022) | Native SwiftUI solution for wrapping layouts |
| Manual CloudKit record management | SwiftData + CloudKit automatic sync | iOS 17+ (2023) | Declarative sync via ModelContainer configuration |
| Apple Charts for all visualizations | Apple Charts (bar/line/area) + custom Path (radar/radial) | 2024-2025 | Swift Charts still does not support radar charts; custom Path required |
| Old SCAA Flavor Wheel (pre-2016) | SCA/WCR Flavor Wheel (2016 revision) | 2016 | 110 attributes vs older 49-attribute format; hierarchical clustering methodology |

**Deprecated/outdated:**
- DDSpiderChart: Last meaningful update was 2020; uses UIKit internally. Not recommended for a SwiftUI-first app.
- Old SCAA flavor wheel data (pre-2016): The robertcedwards gist uses the older format. Use the 2016 SCA/WCR hierarchy for the data model.

## Open Questions

1. **Spider Chart Axis Count**
   - What we know: The requirements specify acidity, body, and sweetness (3 axes). A 3-axis radar chart looks like a triangle and is not visually compelling.
   - What's unclear: Whether to add more SCA cupping attributes (Aroma, Aftertaste, Balance, Uniformity, Clean Cup) to make the spider chart more useful.
   - Recommendation: Start with 3 axes as required. The RadarChartShape supports any number of axes, so additional attributes can be added later. Alternatively, use a horizontal bar chart for 3 attributes (simpler, equally readable) and add a spider chart when 5+ attributes are available.

2. **Word Cloud vs. Tag Cloud**
   - What we know: Requirement TASTE-05 mentions "word cloud" as a visualization option. True word clouds (scattered text with size proportional to frequency) require a spiral bin-packing algorithm.
   - What's unclear: Whether the user wants a true scattered word cloud or a cleaner flow-layout tag cloud with varying chip sizes.
   - Recommendation: Implement a flow-layout tag cloud as the default (cleaner, more usable). The word cloud name is often used colloquially for tag clouds. If the user specifically wants scattered-text layout, it can be added as an enhancement.

3. **Flavor Wheel Interaction Model**
   - What we know: TASTE-04 requires an interactive radial flavor wheel. The SCA wheel has ~85 outer descriptors.
   - What's unclear: Whether the wheel should be a full 360-degree visualization or a drill-down picker.
   - Recommendation: Use a drill-down approach -- show all 9 categories as a full wheel, tap to expand subcategories, tap again for specific descriptors. This keeps tap targets large enough (44pt minimum) while preserving the radial aesthetic.

4. **BrewLog Inverse Relationship**
   - What we know: TastingNote has `var brewLog: BrewLog?` but BrewLog lacks an inverse `var tastingNote: TastingNote?`. CloudKit requires inverse relationships.
   - What's unclear: Whether adding the inverse to BrewLog will cause issues with existing data.
   - Recommendation: Since the app has not shipped and we are on SchemaV1, add the inverse relationship directly. No migration needed. If the app had shipped, a SchemaV2 with a migration stage would be required.

## Sources

### Primary (HIGH confidence)
- Apple SwiftUI Path/Shape documentation (developer.apple.com/tutorials/swiftui/drawing-paths-and-shapes) -- Path, Shape, Canvas APIs
- Apple SwiftUI Layout protocol documentation (developer.apple.com/documentation/swiftui/composing_custom_layouts_with_swiftui) -- Custom layout for flow/tag cloud
- Apple SwiftData syncing documentation (developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices) -- CloudKit sync requirements
- Existing codebase: TastingNote.swift, BrewLog.swift, SchemaV1.swift, MonochromeStyle.swift -- Current model and design system

### Secondary (MEDIUM confidence)
- Fat Bob Man's CloudKit sync rules (fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/) -- Verified CloudKit model constraints: all properties optional/defaulted, relationships must have inverses, no unique constraints, no deny delete rules, no ordered relationships, add-only schema migrations after production
- SCA Flavor Wheel structure (sca.coffee/research/coffee-tasters-flavor-wheel, multiple coffee blog sources) -- 9 categories, 3-tier hierarchy, 110 WCR Lexicon attributes
- Hacking with Swift SwiftData CloudKit (hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit) -- Relationship inverse requirements
- SwiftUI radar chart tutorials (jimmymandersson.medium.com, betterprogramming.pub) -- Custom Path-based radar chart implementation patterns
- Coffee flavor wheel JSON (gist.github.com/robertcedwards/8574379) -- Structured flavor data reference, older SCAA format

### Tertiary (LOW confidence)
- Word cloud layout algorithms -- No authoritative SwiftUI-specific source found. Spiral placement with collision detection is the standard algorithm (Wordle-style). Recommend flow-layout tag cloud instead.
- Exact count of SCA 2016 outer-ring descriptors (86 vs 85 vs 110) -- Sources vary. The WCR Lexicon has 110 total attributes but not all appear on the wheel's outer ring. Implementation should be data-driven so exact count does not affect architecture.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All native Apple frameworks already in the project. No new dependencies.
- Architecture: HIGH -- Custom Path/Shape drawing for charts and wheel is well-documented. Layout protocol for flow layout is straightforward. JSON string storage for CloudKit is a proven pattern.
- Data model (SCA hierarchy): MEDIUM -- The 9-category, 3-tier structure is well-established but the exact complete list of all descriptors requires referencing the official SCA/WCR resources. The data structure supports incremental addition.
- Pitfalls: HIGH -- Based on verified CloudKit constraints, Apple HIG touch targets, and practical radar chart axis-count considerations.

**Research date:** 2026-02-09
**Valid until:** 2026-03-09 (stable domain -- SCA wheel unchanged since 2016, SwiftUI APIs stable in iOS 17+)
