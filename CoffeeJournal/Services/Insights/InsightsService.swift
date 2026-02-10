import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Extraction Source

enum ExtractionSource: Sendable {
    case nlTagger
    case nlEmbedding
    case foundationModel
}

// MARK: - Extracted Flavor

struct ExtractedFlavor: Identifiable, Hashable, Sendable {
    let id: String          // FlavorWheel node ID or "extracted:<word>" for unmatched
    let name: String        // Display name
    let confidence: Double  // 0.0 to 1.0
    let source: ExtractionSource

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ExtractedFlavor, rhs: ExtractedFlavor) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Pattern Category

enum PatternCategory: Sendable {
    case grindPreference
    case ratioOptimal
    case methodFavorite
    case originTrend
}

// MARK: - Brew Pattern

struct BrewPattern: Identifiable, Sendable {
    let id: UUID
    let title: String       // e.g., "Grind for Ethiopia"
    let description: String // e.g., "Your best Ethiopian brews use grind setting ~15"
    let category: PatternCategory

    init(title: String, description: String, category: PatternCategory) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.category = category
    }
}

// MARK: - Suggestion Confidence

enum SuggestionConfidence: Sendable {
    case high   // 5+ brews
    case medium // 2-4 brews
    case low    // 1 brew
}

// MARK: - Brew Suggestion

struct BrewSuggestion: Sendable {
    let dose: Double
    let waterAmount: Double?
    let yieldAmount: Double?
    let waterTemperature: Double
    let grinderSetting: Double?
    let brewTime: Double
    let confidence: SuggestionConfidence
    let basedOnCount: Int
}

// MARK: - InsightsService Protocol

protocol InsightsService: Sendable {
    func extractFlavors(from text: String) async -> [ExtractedFlavor]
    func analyzePatterns(brews: [BrewLog]) -> [BrewPattern]
    func suggestParameters(for bean: CoffeeBean, method: BrewMethod, history: [BrewLog]) -> BrewSuggestion?
}

// MARK: - InsightsService Factory

struct InsightsServiceFactory {
    static func makeService() -> any InsightsService {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let availability = SystemLanguageModel.default.availability
            if case .available = availability {
                return FoundationModelInsightsService()
            }
        }
        #endif
        return NLInsightsService()
    }
}
