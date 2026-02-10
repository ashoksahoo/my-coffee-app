import Foundation

struct CSVExporter {
    // MARK: - Public API

    static func generateCSV(brews: [BrewLog]) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var csv = "Date,Method,Coffee,Dose (g),Water (g),Yield (g),Temperature (C),Brew Time,Ratio,Grinder,Grind Setting,Rating,Notes,Acidity,Body,Sweetness,Flavors\n"

        for brew in brews {
            var fields: [String] = []

            fields.append(escapeCSVField(dateFormatter.string(from: brew.createdAt)))
            fields.append(escapeCSVField(brew.brewMethod?.name ?? ""))
            fields.append(escapeCSVField(brew.coffeeBean?.displayName ?? ""))
            fields.append(brew.dose > 0 ? String(format: "%.1f", brew.dose) : "")
            fields.append(brew.waterAmount > 0 ? String(format: "%.0f", brew.waterAmount) : "")
            fields.append(brew.yieldAmount > 0 ? String(format: "%.1f", brew.yieldAmount) : "")
            fields.append(brew.waterTemperature > 0 ? String(format: "%.0f", brew.waterTemperature) : "")
            fields.append(brew.brewTime > 0 ? brew.brewTimeFormatted : "")
            fields.append(brew.brewRatioFormatted != "--" ? brew.brewRatioFormatted : "")
            fields.append(escapeCSVField(brew.grinder?.name ?? ""))
            fields.append(brew.grinderSetting > 0 ? String(format: "%.1f", brew.grinderSetting) : "")
            fields.append(brew.rating > 0 ? "\(brew.rating)" : "")

            // Notes: replace newlines with spaces
            let cleanNotes = brew.notes.replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
            fields.append(escapeCSVField(cleanNotes))

            // Tasting note attributes
            if let tasting = brew.tastingNote {
                fields.append(tasting.acidity > 0 ? "\(tasting.acidity)" : "")
                fields.append(tasting.body > 0 ? "\(tasting.body)" : "")
                fields.append(tasting.sweetness > 0 ? "\(tasting.sweetness)" : "")

                // Flavor tags
                let flavors = resolveFlavorTags(tasting.flavorTags)
                fields.append(escapeCSVField(flavors))
            } else {
                fields.append("")
                fields.append("")
                fields.append("")
                fields.append("")
            }

            csv += fields.joined(separator: ",") + "\n"
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CoffeeJournal.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - CSV Field Escaping

    static func escapeCSVField(_ field: String) -> String {
        guard !field.isEmpty else { return "" }

        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")

        if needsQuoting {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }

        return field
    }

    // MARK: - Flavor Tag Resolution

    private static func resolveFlavorTags(_ tagsJSON: String) -> String {
        guard !tagsJSON.isEmpty else { return "" }

        guard let data = tagsJSON.data(using: .utf8),
              let tags = try? JSONDecoder().decode([String].self, from: data) else {
            return ""
        }

        let resolved: [String] = tags.compactMap { tag in
            if tag.hasPrefix("custom:") {
                return String(tag.dropFirst("custom:".count))
            } else {
                return FlavorWheel.findNode(byId: tag)?.name
            }
        }

        return resolved.joined(separator: "; ")
    }
}
