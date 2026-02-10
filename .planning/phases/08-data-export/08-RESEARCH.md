# Phase 8: Data Export - Research

**Researched:** 2026-02-10
**Domain:** PDF generation, CSV export, SwiftUI view-to-image rendering, iOS share sheet integration
**Confidence:** HIGH

## Summary

Phase 8 adds three export capabilities to the coffee journal: (1) a collection of brew logs as a formatted PDF journal, (2) brew data as a CSV file for spreadsheet analysis, and (3) an individual brew as a shareable image. All three are achievable with Apple's built-in frameworks -- no external dependencies required.

The PDF generation approach uses `UIGraphicsPDFRenderer` with `UIPrintPageRenderer` for multi-page text layout, combined with `ImageRenderer` for rendering SwiftUI views (spider charts, photos) as images embedded into PDF pages. CSV generation is straightforward string construction with comma-separated values. Image export uses SwiftUI's `ImageRenderer` (iOS 16+) to snapshot a purpose-built "brew card" view as a `UIImage`. All three outputs are shared via SwiftUI's `ShareLink` with the `Transferable` protocol, writing to temporary files and using `FileRepresentation` for proper filenames and content types.

The main integration points are: (1) BrewLogListView toolbar gains "Export PDF" and "Export CSV" actions that operate on the current filtered brew list, (2) BrewLogDetailView gains a "Share" toolbar button that exports the individual brew as an image, and (3) a new `Services/Export/` directory houses the generation logic separate from views.

**Primary recommendation:** Use `UIGraphicsPDFRenderer` for PDF (not `ImageRenderer`-only, which lacks multi-page support), build CSV as a plain string with proper escaping, use `ImageRenderer` for the brew card image, and share everything via `ShareLink` with `FileRepresentation` for correct file naming.

## Standard Stack

### Core (Already in Project)

| Framework | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SwiftUI | iOS 17+ | `ShareLink`, `ImageRenderer`, export trigger UI | Already used throughout app |
| UIKit | iOS 17+ | `UIGraphicsPDFRenderer`, `UIPrintPageRenderer`, `NSAttributedString` for PDF layout | Ships with iOS, standard PDF generation API |
| UniformTypeIdentifiers | iOS 17+ | `UTType.pdf`, `UTType.commaSeparatedText`, custom CSV UTType | Required for `Transferable` content type declarations |
| CoreTransferable | iOS 17+ | `Transferable` protocol, `FileRepresentation` | Required for `ShareLink` file sharing |

### Supporting (No New Dependencies)

| Framework | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| SwiftUI `ImageRenderer` | iOS 16+ | Render brew card view to UIImage for image export, render chart views to embed in PDF | Brew image export (HIST-09) and PDF chart embedding |
| Foundation `FileManager` | iOS 17+ | Temporary directory for export files | All exports write to temp dir before sharing |
| PDFKit | iOS 17+ | Not needed for generation, only if we wanted to preview PDFs in-app | Optional: could add PDF preview but not required by success criteria |

### No New External Dependencies

All export functionality is achievable with Apple frameworks. No Package.swift changes needed. No new imports beyond `UniformTypeIdentifiers` (for UTType declarations).

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `UIGraphicsPDFRenderer` for PDF | `ImageRenderer.render()` to CGContext | ImageRenderer renders single views as single pages -- no built-in multi-page support. For a journal with many brews, `UIGraphicsPDFRenderer` + `UIPrintPageRenderer` handle automatic page breaks for text content |
| Custom CSV string building | `TabularData` framework or external CSV library | TabularData is macOS-focused; custom CSV is trivial for this use case (flat data, known columns). No library needed |
| `ShareLink` for sharing | `UIActivityViewController` via UIViewRepresentable | ShareLink is the SwiftUI-native approach, already targets iOS 16+. No reason to wrap UIKit |
| `FileRepresentation` | `DataRepresentation` | DataRepresentation generates random filenames with wrong extensions. FileRepresentation preserves the correct filename and extension |

## Architecture Patterns

### Recommended Project Structure (New Files)

```
CoffeeJournal/
├── Services/
│   └── Export/
│       ├── PDFExporter.swift           # UIGraphicsPDFRenderer multi-page PDF generation
│       ├── CSVExporter.swift           # CSV string generation with proper escaping
│       └── BrewImageRenderer.swift     # ImageRenderer wrapper for brew card snapshots
├── Views/
│   └── Export/
│       ├── BrewCardView.swift          # Purpose-built view for shareable brew image
│       └── ExportButton.swift          # Reusable export action button (optional)
└── (existing files modified)
    ├── Views/Brewing/BrewLogDetailView.swift   # Add share toolbar button
    ├── Views/Brewing/BrewLogListView.swift     # Add export toolbar menu
    └── Info.plist                               # Add exported UTType for CSV
```

### Pattern 1: Service-Layer Export Generation

**What:** Export logic lives in stateless service structs under `Services/Export/`, not in ViewModels or Views. Each exporter takes model data as input and returns a file URL.

**When to use:** All three export types (PDF, CSV, image).

**Why:** Separates generation logic from UI. Makes each exporter independently testable. Follows the established `Services/` pattern (Insights services).

**Example:**

```swift
// Source: Established Services/ pattern in codebase
struct PDFExporter {
    /// Generates a multi-page PDF journal from brew logs.
    /// Returns the URL of the generated PDF in the temporary directory.
    @MainActor
    static func generateJournal(brews: [BrewLog], title: String = "Coffee Journal") -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let margin: CGFloat = 50
        let contentRect = pageRect.insetBy(dx: margin, dy: margin)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { context in
            // Title page
            context.beginPage()
            drawTitlePage(title: title, brewCount: brews.count, in: contentRect)

            // Brew entries
            var yOffset: CGFloat = contentRect.minY
            context.beginPage()

            for brew in brews {
                let entryHeight = estimateEntryHeight(brew)
                if yOffset + entryHeight > contentRect.maxY {
                    context.beginPage()
                    yOffset = contentRect.minY
                }
                drawBrewEntry(brew, at: &yOffset, in: contentRect, context: context)
            }
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoffeeJournal.pdf")
        try? data.write(to: url)
        return url
    }
}
```

**Confidence:** HIGH -- `UIGraphicsPDFRenderer` and file writing to temp directory are well-documented, standard patterns.

### Pattern 2: Transferable FileRepresentation for Sharing

**What:** Create a lightweight wrapper type conforming to `Transferable` that uses `FileRepresentation` to share generated files via `ShareLink`. The file is generated on-demand when the user taps share.

**When to use:** All three export types.

**Why:** `FileRepresentation` preserves the correct filename and extension (unlike `DataRepresentation` which generates random names). `ShareLink` is the SwiftUI-native share interface.

**Example:**

```swift
import UniformTypeIdentifiers
import CoreTransferable

struct ExportedPDF: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { pdf in
            SentTransferredFile(pdf.url)
        }
    }
}

struct ExportedCSV: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { csv in
            SentTransferredFile(csv.url)
        }
    }
}

// Usage in view:
ShareLink(
    item: ExportedPDF(url: pdfURL),
    preview: SharePreview("Coffee Journal", image: Image(systemName: "doc.richtext"))
)
```

**Confidence:** HIGH -- `FileRepresentation` with `SentTransferredFile` is the documented approach for file sharing. Verified across multiple sources.

### Pattern 3: ImageRenderer for Brew Card Snapshot

**What:** Create a dedicated `BrewCardView` that lays out a single brew's key information in a visually appealing, share-friendly format. Use `ImageRenderer` to convert this SwiftUI view to a `UIImage`.

**When to use:** Individual brew image export (HIST-09).

**Why:** `ImageRenderer` (iOS 16+) renders any SwiftUI view as an image. A purpose-built card view ensures the exported image looks good standalone (not just a screenshot of the detail view).

**Example:**

```swift
// Source: Apple ImageRenderer docs, Hacking with Swift tutorial
@MainActor
struct BrewImageRenderer {
    static func render(brew: BrewLog, scale: CGFloat = 3.0) -> UIImage? {
        let cardView = BrewCardView(brew: brew)
        let renderer = ImageRenderer(content: cardView)
        renderer.scale = scale  // 3x for high-resolution sharing
        return renderer.uiImage
    }
}

// BrewCardView is a self-contained SwiftUI view designed for image export:
// - Fixed width (e.g., 400pt) for consistent rendering
// - White background for sharing on any platform
// - Key brew info: method, bean, parameters, rating, date
// - Optional spider chart if tasting note exists
// - App branding/watermark at bottom
```

**Confidence:** HIGH -- `ImageRenderer` is well-documented for iOS 16+. The `scale` property handles retina rendering. `@MainActor` requirement is well-known.

### Pattern 4: On-Demand Export with Loading State

**What:** Export generation (especially PDF for many brews) may take noticeable time. Use a `@State` property to track export progress and generate the file when the user requests it, then present `ShareLink` or the share sheet.

**When to use:** PDF and CSV export from the brew list (which may contain many entries).

**Why:** `ShareLink` requires the item to exist at tap time. For large exports, pre-generating wastes resources. A two-step flow (tap button -> generate -> present share) gives better UX.

**Example:**

```swift
// Two-step export: generate then share
@State private var exportedPDFURL: URL?
@State private var isExporting = false
@State private var showShareSheet = false

Button {
    isExporting = true
    Task { @MainActor in
        exportedPDFURL = PDFExporter.generateJournal(brews: filteredBrews)
        isExporting = false
        if exportedPDFURL != nil {
            showShareSheet = true
        }
    }
} label: {
    if isExporting {
        ProgressView()
    } else {
        Label("Export PDF", systemImage: "doc.richtext")
    }
}
.sheet(isPresented: $showShareSheet) {
    if let url = exportedPDFURL {
        ShareLink(item: ExportedPDF(url: url),
                  preview: SharePreview("Coffee Journal"))
    }
}
```

**Alternative approach:** Use ShareLink directly with a computed item, but generate the file in the Transferable's FileRepresentation closure. This is simpler but gives no loading indicator.

**Confidence:** MEDIUM -- the two-step approach is a UI pattern choice. Both approaches work; the on-demand pattern is better UX for large datasets.

### Anti-Patterns to Avoid

- **Rendering entire ScrollView with ImageRenderer for PDF:** ImageRenderer renders a single view frame. A long ScrollView will either be clipped or render at enormous height. Use `UIGraphicsPDFRenderer` with manual page breaks for multi-page documents.
- **Using `DataRepresentation` for file sharing:** `DataRepresentation` generates random filenames (e.g., `6A4F2B.txt` instead of `CoffeeJournal.csv`). Always use `FileRepresentation` for files users will save.
- **Forgetting `@MainActor` on ImageRenderer code:** `ImageRenderer` must run on the main thread. Missing this causes runtime crashes or undefined behavior.
- **Putting export logic in views:** Export generation is computation-heavy and testable -- keep it in `Services/Export/` structs, not inline in views.
- **CSV without escaping:** Fields containing commas, quotes, or newlines must be properly escaped. Always quote fields that may contain special characters.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PDF page layout with text overflow | Manual character-by-character pagination | `UIPrintPageRenderer` + `UISimpleTextPrintFormatter` | Automatic multi-page text layout with proper line/word breaks |
| PDF rendering | Custom Core Graphics drawing from scratch | `UIGraphicsPDFRenderer` | Manages PDF context lifecycle, metadata, page creation |
| SwiftUI view to image | Custom CALayer rendering or screenshot APIs | `ImageRenderer` (iOS 16+) | Apple's official API, handles scale, supports PDF context rendering |
| Share sheet | UIViewRepresentable wrapping UIActivityViewController | `ShareLink` + `Transferable` | SwiftUI-native, handles iPad popover automatically, no UIKit bridge |
| CSV parsing/generation library | Full RFC 4180 parser | Simple string builder with escaping | Personal journal data has predictable fields -- no need for a full CSV library |
| File temporary storage | Custom temp directory management | `FileManager.default.temporaryDirectory` | System-managed, auto-cleaned |

**Key insight:** The "hard" parts of this phase (multi-page PDF layout, view-to-image conversion, share sheet integration) all have first-party Apple solutions. The risk is in the details (page break calculation, filename preservation, CSV escaping) rather than framework selection.

## Common Pitfalls

### Pitfall 1: ImageRenderer Scale Defaults to 1x

**What goes wrong:** Exported images look blurry/pixelated on retina screens.
**Why it happens:** `ImageRenderer` defaults to `scale = 1.0`, not the device's display scale.
**How to avoid:** Always set `renderer.scale = 3.0` (or use `@Environment(\.displayScale)` for screen-matching). For shareable images, 3x is a good universal choice.
**Warning signs:** Exported images appear sharp on device preview but fuzzy when shared to social media or printed.

### Pitfall 2: ShareLink CSV Creates .txt File

**What goes wrong:** CSV export creates a file with `.txt` extension instead of `.csv`.
**Why it happens:** `UTType.commaSeparatedText` has MIME type `text/csv` but its preferred filename extension may resolve to `.txt` on some iOS versions.
**How to avoid:** Use `FileRepresentation` writing to a file with explicit `.csv` extension, not `DataRepresentation`. The file URL's extension takes priority.
**Warning signs:** Exported file cannot be opened directly in Numbers or Excel on recipient device.

### Pitfall 3: PDF Generation Blocks Main Thread

**What goes wrong:** UI freezes during PDF export, especially with many brews containing photos.
**Why it happens:** `UIGraphicsPDFRenderer.pdfData()` is synchronous. Drawing photos (decoding `Data` to `UIImage`, scaling) is CPU-intensive.
**How to avoid:** Show a loading indicator. For the MVP, synchronous generation on main thread is acceptable for a personal journal (typically < 500 brews). If performance becomes an issue, move PDF data generation to a background actor and only use `@MainActor` for the `ImageRenderer` portions.
**Warning signs:** Export takes > 2 seconds for the user's typical brew count.

### Pitfall 4: Temporary Files Not Cleaned Up

**What goes wrong:** Exported files accumulate in the temp directory.
**Why it happens:** Each export creates a new file in `temporaryDirectory`. The system cleans temp eventually, but not immediately.
**How to avoid:** Use a consistent filename (e.g., `CoffeeJournal.pdf`) so each export overwrites the previous one. Or explicitly delete the previous export file before creating a new one.
**Warning signs:** Disk usage grows over time with repeated exports.

### Pitfall 5: CSV Fields with Commas or Quotes Break Parsing

**What goes wrong:** Spreadsheet apps misparse rows when notes contain commas, or field values contain double quotes.
**Why it happens:** CSV has special characters: comma (field separator), double-quote (field wrapper), newline (row separator). Unescaped values corrupt the structure.
**How to avoid:** Always wrap fields in double quotes and escape internal double quotes by doubling them (`"` -> `""`). Replace newlines in freeform text with spaces or `\n` literal.
**Warning signs:** Opening exported CSV in Numbers/Excel shows data in wrong columns or truncated rows.

### Pitfall 6: BrewCardView Renders Incorrectly Without Fixed Size

**What goes wrong:** `ImageRenderer` produces images with unexpected dimensions or truncated content.
**Why it happens:** Without a fixed frame, the view sizes to its intrinsic content size, which may be very narrow or very wide depending on text length.
**How to avoid:** Set a fixed `.frame(width: 400)` on the brew card view. The height can be flexible (determined by content), but width must be constrained. Use `.background(Color.white)` for consistent appearance.
**Warning signs:** Exported image has inconsistent dimensions across different brews, or text is truncated.

### Pitfall 7: Info.plist Missing Exported Type for CSV

**What goes wrong:** Custom UTType for CSV is not found at runtime.
**Why it happens:** When using a custom `UTType(exportedAs:)`, the type must be declared in Info.plist's `UTExportedTypeDeclarations` section.
**How to avoid:** If using the built-in `UTType.commaSeparatedText`, no Info.plist change is needed. If defining a custom type, add it to Info.plist. Recommendation: use the built-in type with `FileRepresentation` to avoid this entirely.
**Warning signs:** Runtime error about unrecognized type identifier; share sheet fails to present.

## Code Examples

Verified patterns from official sources and established codebase patterns:

### Multi-Page PDF with UIPrintPageRenderer

```swift
// Source: Hacking with Swift - NSAttributedString to PDF tutorial
// Handles automatic page breaks for long text content
@MainActor
static func generateMultiPagePDF(attributedText: NSAttributedString, title: String) -> Data {
    let pageSize = CGSize(width: 612, height: 792) // US Letter
    let pageMargins = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72)

    let printableRect = CGRect(
        x: pageMargins.left,
        y: pageMargins.top,
        width: pageSize.width - pageMargins.left - pageMargins.right,
        height: pageSize.height - pageMargins.top - pageMargins.bottom
    )
    let paperRect = CGRect(origin: .zero, size: pageSize)

    let printFormatter = UISimpleTextPrintFormatter(attributedText: attributedText)
    let pageRenderer = UIPrintPageRenderer()
    pageRenderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
    pageRenderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
    pageRenderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

    let pdfData = NSMutableData()
    UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
    pageRenderer.prepare(forDrawingPages: NSMakeRange(0, pageRenderer.numberOfPages))

    let bounds = UIGraphicsGetPDFContextBounds()
    for i in 0..<pageRenderer.numberOfPages {
        UIGraphicsBeginPDFPage()
        pageRenderer.drawPage(at: i, in: bounds)
    }

    UIGraphicsEndPDFContext()
    return pdfData as Data
}
```

### CSV Generation with Proper Escaping

```swift
// Source: Standard RFC 4180 CSV escaping rules
struct CSVExporter {
    static func generateCSV(brews: [BrewLog]) -> URL? {
        var csv = "Date,Method,Coffee,Dose (g),Water (g),Yield (g),Temperature (C),Brew Time,Ratio,Grinder,Grind Setting,Rating,Notes,Acidity,Body,Sweetness,Flavors\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        for brew in brews {
            let fields: [String] = [
                dateFormatter.string(from: brew.createdAt),
                brew.brewMethod?.name ?? "",
                brew.coffeeBean?.displayName ?? "",
                String(format: "%.1f", brew.dose),
                String(format: "%.0f", brew.waterAmount),
                String(format: "%.1f", brew.yieldAmount),
                String(format: "%.0f", brew.waterTemperature),
                brew.brewTimeFormatted,
                brew.brewRatioFormatted,
                brew.grinder?.name ?? "",
                String(format: "%.1f", brew.grinderSetting),
                "\(brew.rating)",
                brew.notes,
                brew.tastingNote.map { "\($0.acidity)" } ?? "",
                brew.tastingNote.map { "\($0.body)" } ?? "",
                brew.tastingNote.map { "\($0.sweetness)" } ?? "",
                flavorTagsString(brew.tastingNote),
            ]

            csv += fields.map { escapeCSVField($0) }.joined(separator: ",") + "\n"
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoffeeJournal.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    private static func flavorTagsString(_ note: TastingNote?) -> String {
        guard let note = note, !note.flavorTags.isEmpty,
              let data = note.flavorTags.data(using: .utf8),
              let tags = try? JSONDecoder().decode([String].self, from: data) else {
            return ""
        }
        return tags.compactMap { tag in
            if tag.hasPrefix("custom:") {
                return String(tag.dropFirst("custom:".count))
            }
            return FlavorWheel.findNode(byId: tag)?.name
        }.joined(separator: "; ")
    }
}
```

### Brew Card View for Image Export

```swift
// Source: Established codebase design system (AppColors, AppTypography, AppSpacing)
struct BrewCardView: View {
    let brew: BrewLog

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(brew.brewMethod?.name ?? "Brew")
                        .font(AppTypography.title)
                    Text(brew.coffeeBean?.displayName ?? "")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.secondary)
                }
                Spacer()
                if brew.rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<brew.rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption)
                        }
                    }
                }
            }

            Divider()

            // Parameters grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                parameterItem("Dose", "\(String(format: "%.1f", brew.dose))g")
                parameterItem("Ratio", brew.brewRatioFormatted)
                parameterItem("Time", brew.brewTimeFormatted)
                if brew.waterTemperature > 0 {
                    parameterItem("Temp", "\(String(format: "%.0f", brew.waterTemperature))\u{00B0}C")
                }
            }

            // Tasting note summary (if exists)
            if let note = brew.tastingNote, note.acidity > 0 || note.body > 0 || note.sweetness > 0 {
                SpiderChartView.fromTastingNote(note)
                    .frame(height: 150)
            }

            // Date and branding
            HStack {
                Text(brew.createdAt, format: .dateTime.month().day().year())
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)
                Spacer()
                Text("Coffee Journal")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.muted)
            }
        }
        .padding(AppSpacing.lg)
        .frame(width: 400)
        .background(Color.white)
    }

    private func parameterItem(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppTypography.headline)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondary)
        }
    }
}
```

### ImageRenderer Usage

```swift
// Source: Apple ImageRenderer docs, Hacking with Swift tutorial
@MainActor
struct BrewImageRenderer {
    static func render(brew: BrewLog, scale: CGFloat = 3.0) -> UIImage? {
        let renderer = ImageRenderer(content: BrewCardView(brew: brew))
        renderer.scale = scale
        return renderer.uiImage
    }

    static func renderToData(brew: BrewLog, scale: CGFloat = 3.0) -> Data? {
        render(brew: brew, scale: scale)?.pngData()
    }
}
```

### Transferable Wrappers

```swift
// Source: Apple Transferable docs, simanerush.com FileRepresentation pattern
import UniformTypeIdentifiers
import CoreTransferable

struct ExportedPDF: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { pdf in
            SentTransferredFile(pdf.url)
        }
    }
}

struct ExportedCSV: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { csv in
            SentTransferredFile(csv.url)
        }
    }
}

struct ExportedImage: Transferable {
    let image: Image

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.image)
    }
}
```

### Share Integration in Views

```swift
// Source: Apple ShareLink docs, established toolbar pattern in codebase

// In BrewLogDetailView -- share individual brew as image:
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        if let image = BrewImageRenderer.render(brew: brew) {
            ShareLink(
                item: Image(uiImage: image),
                preview: SharePreview(
                    brew.brewMethod?.name ?? "Brew",
                    image: Image(uiImage: image)
                )
            )
        }
    }
}

// In BrewLogListView -- export menu for filtered brews:
Menu {
    Button {
        exportPDF()
    } label: {
        Label("Export as PDF", systemImage: "doc.richtext")
    }
    Button {
        exportCSV()
    } label: {
        Label("Export as CSV", systemImage: "tablecells")
    }
} label: {
    Image(systemName: "square.and.arrow.up")
        .foregroundStyle(AppColors.primary)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UIActivityViewController (UIKit) | ShareLink + Transferable (SwiftUI) | iOS 16 (2022) | SwiftUI-native, declarative, handles iPad automatically |
| CALayer.render(in:) for screenshots | ImageRenderer | iOS 16 (2022) | SwiftUI-native, supports scale/size customization |
| UIGraphicsBeginPDFContext (C-style) | UIGraphicsPDFRenderer (block-based) | iOS 10 (2016) | Cleaner API, memory-safe, auto-cleanup |
| NSString draw(in:) for PDF text | NSAttributedString + UIPrintPageRenderer | iOS 8+ | Automatic multi-page text layout with page breaks |

**Deprecated/outdated:**
- `UIGraphicsBeginPDFContext` / `UIGraphicsEndPDFContext`: Still works but `UIGraphicsPDFRenderer` is the modern replacement with better memory management
- `UIActivityViewController` in SwiftUI: Still works via UIViewRepresentable but `ShareLink` is the SwiftUI-native approach since iOS 16
- `drawHierarchy(in:afterScreenUpdates:)`: Replaced by `ImageRenderer` for SwiftUI views; the old approach was for UIKit view snapshots

## Key Design Decisions (Recommendations)

### 1. PDF Layout: UIGraphicsPDFRenderer with Manual Entry Drawing (Not ImageRenderer for Whole Pages)

**Recommendation:** Use `UIGraphicsPDFRenderer` to create the PDF context and manually draw each brew entry using `NSAttributedString.draw(in:)` for text and `UIImage.draw(in:)` for photos. Use `ImageRenderer` only for embedding SwiftUI chart views (spider chart) as images within the PDF.

**Rationale:** `ImageRenderer` renders a single view as a single image/page. For a journal with potentially dozens or hundreds of brews, we need proper multi-page layout with automatic page breaks. `UIGraphicsPDFRenderer` gives full control over page breaks, margins, headers/footers, and content positioning. The `UIPrintPageRenderer` approach with `UISimpleTextPrintFormatter` handles automatic text pagination, but for a more structured layout (brew entries with photos and charts), manual position tracking with page-break detection is more appropriate.

### 2. Export Trigger: Menu in BrewLogListView Toolbar (Not Separate Export Screen)

**Recommendation:** Add an export `Menu` button in the BrewLogListView toolbar that offers "Export as PDF" and "Export as CSV" options. The exports operate on the currently filtered/displayed brews. For individual brew image export, add a share button to BrewLogDetailView's toolbar.

**Rationale:** Export is a secondary action, not a primary navigation destination. A toolbar menu keeps it accessible without adding UI clutter. Operating on the filtered list is intuitive -- users naturally filter first, then export what they see. This follows the existing toolbar pattern (compare button, statistics button, filter button are all in the toolbar).

### 3. CSV Format: Flat with All Fields (Not Nested/Hierarchical)

**Recommendation:** Export a flat CSV with one row per brew and all relevant fields as columns. Include tasting note attributes as additional columns (acidity, body, sweetness, flavors as semicolon-separated string). Do not create separate CSV files for different entities.

**Rationale:** Spreadsheet users expect flat data. A single file is simpler to work with than multiple related files. Flavor tags can be joined with semicolons to avoid confusion with comma separators. All brew-relevant information (including related entity names) should be denormalized into each row.

### 4. Image Export: Purpose-Built Card View (Not Screenshot of Detail View)

**Recommendation:** Create a dedicated `BrewCardView` designed specifically for image sharing. This view has a fixed width, white background, condensed layout with key parameters, optional spider chart, and subtle app branding.

**Rationale:** The existing `BrewLogDetailView` is designed for in-app reading with system backgrounds, navigation chrome, and scrollable content. A shareable image needs to be self-contained, visually polished, and sized appropriately for social media or messaging apps. A purpose-built card gives control over the exact exported appearance.

### 5. Sharing: FileRepresentation Always (Not DataRepresentation)

**Recommendation:** Use `FileRepresentation` for all exports (PDF, CSV). Use `ProxyRepresentation` for image export (through SwiftUI `Image`'s built-in `Transferable` conformance).

**Rationale:** `DataRepresentation` generates random filenames with wrong extensions. `FileRepresentation` writes to a named temp file first, preserving the correct filename and extension. Users who save the file get a sensible name like `CoffeeJournal.pdf` instead of `6A4F2B.txt`.

## Open Questions

1. **PDF visual design complexity**
   - What we know: The PDF needs to include brew parameters, tasting notes, and optionally photos/charts.
   - What's unclear: How polished should the PDF look? Simple text-based listing vs. rich layout with photos and charts embedded?
   - Recommendation: Start with a clean text-based layout using NSAttributedString with section headers, brew entries, and parameter tables. Embed photos and spider charts as optional enhancements. A "journal-style" layout with date headers and grouped entries is more useful than a plain data dump.

2. **Export scope: all brews vs. filtered brews**
   - What we know: BrewLogListView has filtering. Users may want to export a subset.
   - What's unclear: Should export always respect current filters, or offer a choice?
   - Recommendation: Export the currently displayed/filtered brews. This is the most intuitive behavior -- "what you see is what you export." If no filters are active, all brews are exported. Show the brew count in the export button label (e.g., "Export 23 brews as PDF").

3. **Photo inclusion in PDF**
   - What we know: BrewLog has optional photoData. Photos could make the PDF much larger.
   - What's unclear: Should photos be included in the PDF? At what size?
   - Recommendation: Include photos when available, scaled to fit within the content width (around 200pt height max). Skip photos if the user prefers a compact export. For the MVP, always include photos. A future enhancement could add a toggle.

4. **Export from which views?**
   - What we know: Success criteria require collection PDF, collection CSV, and individual image.
   - What's unclear: Should export also be available from StatisticsDashboardView or other views?
   - Recommendation: Phase 8 scope: PDF and CSV from BrewLogListView toolbar, image from BrewLogDetailView toolbar. Statistics export is not in the requirements and should be deferred.

## Sources

### Primary (HIGH confidence)
- Existing codebase: BrewLog.swift, CoffeeBean.swift, TastingNote.swift, BrewMethod.swift, Grinder.swift -- model structures for export data
- Existing codebase: BrewLogDetailView.swift -- current detail layout, integration point for image share
- Existing codebase: BrewLogListView.swift, BrewHistoryListContent.swift -- list view with filtering, integration point for PDF/CSV export
- Existing codebase: MonochromeStyle.swift -- design system for consistent export styling
- Existing codebase: SpiderChartView.swift -- existing radar chart view to embed in exports
- [Hacking with Swift: UIGraphicsPDFRenderer](https://www.hackingwithswift.com/example-code/uikit/how-to-render-pdfs-using-uigraphicspdfrenderer) -- PDF generation basics
- [Hacking with Swift: NSAttributedString to PDF](https://www.hackingwithswift.com/example-code/uikit/how-to-render-an-nsattributedstring-to-a-pdf) -- Multi-page PDF with UIPrintPageRenderer
- [Hacking with Swift: ImageRenderer](https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image) -- SwiftUI view to UIImage, scale, @MainActor
- [Hacking with Swift: SwiftUI view to PDF](https://www.hackingwithswift.com/quick-start/swiftui/how-to-render-a-swiftui-view-to-a-pdf) -- ImageRenderer render() to CGContext
- [Swift with Majid: ImageRenderer](https://swiftwithmajid.com/2023/04/18/imagerenderer-in-swiftui/) -- render() method, CGContext PDF, scale/proposedSize
- [Swift with Majid: Sharing Content](https://swiftwithmajid.com/2023/03/28/sharing-content-in-swiftui/) -- ShareLink, Transferable, transfer representations
- [AppCoda: ShareLink](https://www.appcoda.com/swiftui-sharelink/) -- ShareLink with images, SharePreview, Transferable
- [Apple: UIGraphicsPDFRenderer docs](https://developer.apple.com/documentation/uikit/uigraphicspdfrenderer) -- Official API reference
- [Apple: ImageRenderer docs](https://developer.apple.com/documentation/swiftui/imagerenderer) -- Official API reference
- [Sima Nerush: Sharing files in SwiftUI](https://www.simanerush.com/posts/sharing-files) -- FileRepresentation for PDFDocument, SentTransferredFile pattern

### Secondary (MEDIUM confidence)
- [Hacking with Swift Forums: Multi-page PDF](https://www.hackingwithswift.com/forums/swiftui/rendering-a-swiftui-view-to-multi-page-pdf/17892) -- Discussion on multi-page PDF challenges with ImageRenderer
- [Hacking with Swift Forums: ShareLink CSV problem](https://www.hackingwithswift.com/forums/swiftui/sharelink-problem-with-csv-file/21194) -- UTType.commaSeparatedText .txt extension issue, FileRepresentation workaround
- [Apple Forums: ShareLink exporting issues](https://developer.apple.com/forums/thread/740629) -- Custom UTType Info.plist requirements
- [CreateWithSwift: Share sheet in SwiftUI](https://www.createwithswift.com/using-the-share-sheet-to-share-content-in-a-swiftui-app/) -- ShareLink basics, Transferable ProxyRepresentation
- [juniperphoton: Transferable issues iOS 17](https://juniperphoton.substack.com/p/addressing-and-solving-transferable) -- iOS 17 sharing file pitfalls

### Tertiary (LOW confidence)
- PDF journal visual design -- no canonical "coffee journal PDF" reference; layout is a design choice
- On-demand export vs. pre-generation UX -- pattern choice, no definitive best practice for this use case

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all Apple frameworks, well-documented APIs
- PDF generation (UIGraphicsPDFRenderer): HIGH -- multiple verified sources, established API since iOS 10
- CSV generation: HIGH -- trivial string building, standard escaping rules
- Image export (ImageRenderer): HIGH -- well-documented iOS 16+ API, verified scale/MainActor requirements
- ShareLink + Transferable: HIGH -- verified FileRepresentation pattern across multiple sources
- Multi-page PDF layout: MEDIUM -- UIPrintPageRenderer works for text; custom layout with photos/charts requires manual page-break tracking (more complex, fewer examples)
- Integration points (toolbar placement, export scope): MEDIUM -- design decisions rather than technical verification

**Research date:** 2026-02-10
**Valid until:** 2026-03-10 (stable Apple frameworks, no fast-moving dependencies)
