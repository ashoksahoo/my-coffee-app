import Foundation

final class NLInsightsService: InsightsService, @unchecked Sendable {

    private let flavorExtractor = FlavorExtractor()
    private let patternAnalyzer = BrewPatternAnalyzer()
    private let suggestionEngine = BrewSuggestionEngine()

    func extractFlavors(from text: String) async -> [ExtractedFlavor] {
        // NLTagger/NLEmbedding are fast but keep off main thread per research anti-patterns
        return flavorExtractor.extract(from: text)
    }

    func analyzePatterns(brews: [BrewLog]) -> [BrewPattern] {
        patternAnalyzer.analyzePatterns(brews: brews)
    }

    func suggestParameters(for bean: CoffeeBean, method: BrewMethod, history: [BrewLog]) -> BrewSuggestion? {
        suggestionEngine.suggest(for: bean, method: method, history: history)
    }
}
