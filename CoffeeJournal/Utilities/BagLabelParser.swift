import Foundation

// MARK: - Parsed Result

struct ParsedBagLabel {
    var roaster: String?
    var origin: String?
    var region: String?
    var variety: String?
    var roastDate: Date?
    var roastLevel: String?
    var processingMethod: String?
}

// MARK: - Parser

struct BagLabelParser {

    // MARK: Known Values

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

    static let roastLevelKeywords: [(String, String)] = [
        ("medium-light", "medium_light"),
        ("medium light", "medium_light"),
        ("medium-dark", "medium_dark"),
        ("medium dark", "medium_dark"),
        ("espresso roast", "dark"),
        ("filter roast", "light"),
        ("omni roast", "medium"),
        ("light", "light"),
        ("medium", "medium"),
        ("dark", "dark"),
    ]

    static let processingKeywords: [(String, String)] = [
        ("wet process", "washed"),
        ("washed", "washed"),
        ("dry process", "natural"),
        ("natural", "natural"),
        ("honey process", "honey"),
        ("honey", "honey"),
        ("anaerobic", "anaerobic"),
    ]

    // MARK: Date Patterns

    private static let dateRegexPatterns = [
        "\\d{4}-\\d{2}-\\d{2}",              // ISO: YYYY-MM-DD
        "\\d{1,2}/\\d{1,2}/\\d{2,4}",        // MM/DD/YYYY or D/M/YY
        "\\d{1,2}\\.\\d{1,2}\\.\\d{2,4}",    // DD.MM.YYYY
        "\\d{1,2}-\\d{1,2}-\\d{2,4}",        // DD-MM-YYYY
    ]

    private static let spelledMonthPattern =
        "(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+\\d{1,2},?\\s+\\d{4}"

    private static let dateFormats = [
        "yyyy-MM-dd",
        "MM/dd/yyyy", "M/d/yyyy", "MM/dd/yy", "M/d/yy",
        "dd.MM.yyyy", "d.M.yyyy",
        "dd-MM-yyyy", "d-M-yyyy",
        "MMMM d, yyyy", "MMM d, yyyy",
        "MMMM dd, yyyy", "MMM dd, yyyy",
        "MMMM d yyyy", "MMM d yyyy",
    ]

    // MARK: - Parse

    static func parse(recognizedTexts: [String]) -> ParsedBagLabel {
        var result = ParsedBagLabel()
        let allText = recognizedTexts.joined(separator: "\n")
        let lowered = allText.lowercased()

        // Origin detection
        for country in knownOrigins {
            if allText.localizedCaseInsensitiveContains(country) {
                result.origin = country
                break
            }
        }

        // Variety detection
        for variety in knownVarieties {
            if allText.localizedCaseInsensitiveContains(variety) {
                result.variety = variety
                break
            }
        }

        // Roast level detection (ordered so multi-word matches are checked first)
        for (keyword, value) in roastLevelKeywords {
            if lowered.contains(keyword) {
                result.roastLevel = value
                break
            }
        }

        // Processing method detection (ordered so multi-word matches are checked first)
        for (keyword, value) in processingKeywords {
            if lowered.contains(keyword) {
                result.processingMethod = value
                break
            }
        }

        // Date extraction
        result.roastDate = extractDate(from: allText)

        // Roaster guess: first recognized text line (often the most prominent)
        if let firstLine = recognizedTexts.first, !firstLine.trimmingCharacters(in: .whitespaces).isEmpty {
            result.roaster = firstLine.trimmingCharacters(in: .whitespaces)
        }

        return result
    }

    // MARK: - Date Extraction

    private static func extractDate(from text: String) -> Date? {
        let formatters: [DateFormatter] = dateFormats.map { format in
            let df = DateFormatter()
            df.dateFormat = format
            df.locale = Locale(identifier: "en_US_POSIX")
            return df
        }

        // Try numeric date patterns
        for pattern in dateRegexPatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let dateString = String(text[match])
                if let date = tryParse(dateString: dateString, formatters: formatters) {
                    return date
                }
            }
        }

        // Try spelled-out month patterns ("January 15, 2026", "Jan 15 2026")
        if let match = text.range(of: spelledMonthPattern, options: .regularExpression) {
            let dateString = String(text[match])
            if let date = tryParse(dateString: dateString, formatters: formatters) {
                return date
            }
        }

        return nil
    }

    private static func tryParse(dateString: String, formatters: [DateFormatter]) -> Date? {
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: Date.now)!
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                // Sanity check: date within last 2 years and not in the future
                if date > twoYearsAgo && date <= Date.now {
                    return date
                }
            }
        }
        return nil
    }
}
