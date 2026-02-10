import UIKit

struct PDFExporter {
    // MARK: - Page Constants

    private static let pageWidth: CGFloat = 612
    private static let pageHeight: CGFloat = 792
    private static let margin: CGFloat = 50
    private static let contentWidth: CGFloat = 612 - 100
    private static let contentTop: CGFloat = 50
    private static let contentBottom: CGFloat = 792 - 50

    // MARK: - Fonts

    private static let titleFont = UIFont.boldSystemFont(ofSize: 24)
    private static let sectionHeaderFont = UIFont.boldSystemFont(ofSize: 14)
    private static let bodyFont = UIFont.systemFont(ofSize: 11)
    private static let captionFont = UIFont.systemFont(ofSize: 9)

    // MARK: - Colors

    private static let primaryColor = UIColor.black
    private static let secondaryColor = UIColor.gray
    private static let separatorColor = UIColor.lightGray

    // MARK: - Public API

    @MainActor
    static func generateJournal(brews: [BrewLog], title: String = "Coffee Journal") -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let data = renderer.pdfData { context in
            // Title Page
            context.beginPage()
            drawTitlePage(title: title, brewCount: brews.count, context: context)

            // Brew Entries
            var yOffset: CGFloat = contentTop

            // Start first content page
            context.beginPage()

            for brew in brews {
                let entryHeight = estimateEntryHeight(brew: brew)

                if yOffset + entryHeight > contentBottom {
                    context.beginPage()
                    yOffset = contentTop
                }

                yOffset = drawBrewEntry(brew: brew, yOffset: yOffset, dateFormatter: dateFormatter)

                // Separator line
                if yOffset + 10 < contentBottom {
                    let separatorPath = UIBezierPath()
                    separatorPath.move(to: CGPoint(x: margin, y: yOffset + 5))
                    separatorPath.addLine(to: CGPoint(x: pageWidth - margin, y: yOffset + 5))
                    separatorColor.setStroke()
                    separatorPath.lineWidth = 0.5
                    separatorPath.stroke()
                    yOffset += 15
                }
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CoffeeJournal.pdf")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Title Page

    private static func drawTitlePage(title: String, brewCount: Int, context: UIGraphicsPDFRendererContext) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 32),
            .foregroundColor: primaryColor
        ]
        let titleSize = (title as NSString).size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: (pageWidth - titleSize.width) / 2,
            y: pageHeight / 3,
            width: titleSize.width,
            height: titleSize.height
        )
        (title as NSString).draw(in: titleRect, withAttributes: titleAttributes)

        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: secondaryColor
        ]
        let subtitleText = "\(brewCount) brew\(brewCount == 1 ? "" : "s") recorded"
        let subtitleSize = (subtitleText as NSString).size(withAttributes: subtitleAttributes)
        let subtitleRect = CGRect(
            x: (pageWidth - subtitleSize.width) / 2,
            y: titleRect.maxY + 12,
            width: subtitleSize.width,
            height: subtitleSize.height
        )
        (subtitleText as NSString).draw(in: subtitleRect, withAttributes: subtitleAttributes)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateText = "Exported \(dateFormatter.string(from: Date()))"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryColor
        ]
        let dateSize = (dateText as NSString).size(withAttributes: dateAttributes)
        let dateRect = CGRect(
            x: (pageWidth - dateSize.width) / 2,
            y: subtitleRect.maxY + 8,
            width: dateSize.width,
            height: dateSize.height
        )
        (dateText as NSString).draw(in: dateRect, withAttributes: dateAttributes)
    }

    // MARK: - Brew Entry Drawing

    private static func drawBrewEntry(brew: BrewLog, yOffset: CGFloat, dateFormatter: DateFormatter) -> CGFloat {
        var y = yOffset

        // Date header
        let dateText = dateFormatter.string(from: brew.createdAt)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionHeaderFont,
            .foregroundColor: primaryColor
        ]
        (dateText as NSString).draw(
            in: CGRect(x: margin, y: y, width: contentWidth, height: 20),
            withAttributes: dateAttributes
        )
        y += 20

        // Method + Coffee subtitle
        let methodName = brew.brewMethod?.name ?? "Unknown Method"
        let coffeeName = brew.coffeeBean?.displayName ?? ""
        let subtitle = coffeeName.isEmpty ? methodName : "\(methodName) - \(coffeeName)"
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: secondaryColor
        ]
        (subtitle as NSString).draw(
            in: CGRect(x: margin, y: y, width: contentWidth, height: 16),
            withAttributes: subtitleAttributes
        )
        y += 18

        // Parameters grid
        let paramAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: primaryColor
        ]
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryColor
        ]

        var params: [(String, String)] = []
        if brew.dose > 0 { params.append(("Dose", String(format: "%.1fg", brew.dose))) }
        if brew.waterAmount > 0 { params.append(("Water", String(format: "%.0fg", brew.waterAmount))) }
        if brew.yieldAmount > 0 { params.append(("Yield", String(format: "%.1fg", brew.yieldAmount))) }
        if brew.brewTime > 0 { params.append(("Time", brew.brewTimeFormatted)) }
        if brew.waterTemperature > 0 { params.append(("Temp", String(format: "%.0f\u{00B0}C", brew.waterTemperature))) }
        if let ratio = brew.brewRatio { params.append(("Ratio", String(format: "1:%.1f", ratio))) }

        let colWidth: CGFloat = contentWidth / 3
        for (index, param) in params.enumerated() {
            let col = CGFloat(index % 3)
            let row = CGFloat(index / 3)
            let x = margin + col * colWidth
            let paramY = y + row * 24

            (param.0 as NSString).draw(
                in: CGRect(x: x, y: paramY, width: colWidth, height: 12),
                withAttributes: labelAttributes
            )
            (param.1 as NSString).draw(
                in: CGRect(x: x, y: paramY + 10, width: colWidth, height: 14),
                withAttributes: paramAttributes
            )
        }
        let paramRows = ceil(Double(params.count) / 3.0)
        y += CGFloat(paramRows) * 24 + 4

        // Grinder info
        if let grinder = brew.grinder {
            let grinderText = brew.grinderSetting > 0
                ? "\(grinder.name) @ \(String(format: "%.1f", brew.grinderSetting))"
                : grinder.name
            (grinderText as NSString).draw(
                in: CGRect(x: margin, y: y, width: contentWidth, height: 14),
                withAttributes: [.font: bodyFont, .foregroundColor: secondaryColor]
            )
            y += 16
        }

        // Rating
        if brew.rating > 0 {
            let stars = String(repeating: "\u{2605}", count: brew.rating) + String(repeating: "\u{2606}", count: 5 - brew.rating)
            (stars as NSString).draw(
                in: CGRect(x: margin, y: y, width: contentWidth, height: 16),
                withAttributes: [.font: bodyFont, .foregroundColor: primaryColor]
            )
            y += 18
        }

        // Notes
        if !brew.notes.isEmpty {
            let truncatedNotes = brew.notes.count > 200 ? String(brew.notes.prefix(200)) + "..." : brew.notes
            let notesRect = CGRect(x: margin, y: y, width: contentWidth, height: 40)
            (truncatedNotes as NSString).draw(
                in: notesRect,
                withAttributes: [.font: bodyFont, .foregroundColor: primaryColor]
            )
            let notesSize = (truncatedNotes as NSString).boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                attributes: [.font: bodyFont],
                context: nil
            )
            y += max(notesSize.height, 14) + 4
        }

        // Tasting note attributes
        if let tasting = brew.tastingNote {
            var tastingParts: [String] = []
            if tasting.acidity > 0 { tastingParts.append("Acidity: \(tasting.acidity)") }
            if tasting.body > 0 { tastingParts.append("Body: \(tasting.body)") }
            if tasting.sweetness > 0 { tastingParts.append("Sweetness: \(tasting.sweetness)") }
            if !tastingParts.isEmpty {
                let tastingText = tastingParts.joined(separator: "  |  ")
                (tastingText as NSString).draw(
                    in: CGRect(x: margin, y: y, width: contentWidth, height: 14),
                    withAttributes: [.font: captionFont, .foregroundColor: secondaryColor]
                )
                y += 16
            }
        }

        return y
    }

    // MARK: - Height Estimation

    private static func estimateEntryHeight(brew: BrewLog) -> CGFloat {
        var height: CGFloat = 20 + 18 // date header + subtitle

        // Parameters
        var paramCount = 0
        if brew.dose > 0 { paramCount += 1 }
        if brew.waterAmount > 0 { paramCount += 1 }
        if brew.yieldAmount > 0 { paramCount += 1 }
        if brew.brewTime > 0 { paramCount += 1 }
        if brew.waterTemperature > 0 { paramCount += 1 }
        if brew.brewRatio != nil { paramCount += 1 }
        let paramRows = ceil(Double(paramCount) / 3.0)
        height += CGFloat(paramRows) * 24 + 4

        if brew.grinder != nil { height += 16 }
        if brew.rating > 0 { height += 18 }
        if !brew.notes.isEmpty { height += 44 }
        if brew.tastingNote != nil { height += 16 }
        height += 15 // separator

        return height
    }
}
