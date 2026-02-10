#if canImport(FoundationModels)
import Foundation
import FoundationModels

@available(iOS 26, *)
@Generable
struct TastingAnalysis {
    @Guide(description: "Flavor descriptors found in the tasting notes")
    let descriptors: [String]

    @Guide(description: "Overall sentiment: positive, neutral, or negative")
    let sentiment: String

    @Guide(description: "One-sentence tasting profile summary")
    let summary: String
}

@available(iOS 26, *)
final class FoundationModelInsightsService: InsightsService, @unchecked Sendable {

    private let patternAnalyzer = BrewPatternAnalyzer()
    private let suggestionEngine = BrewSuggestionEngine()

    func extractFlavors(from text: String) async -> [ExtractedFlavor] {
        do {
            let session = LanguageModelSession {
                """
                You are a coffee tasting expert. Analyze tasting notes and extract flavor descriptors. \
                Use standard SCA flavor wheel terminology: fruity, floral, sweet, nutty-cocoa, spices, \
                roasted, green-vegetative, sour-fermented, other.
                """
            }

            let response = try await session.respond(
                to: "Analyze these coffee tasting notes: \(text)",
                generating: TastingAnalysis.self
            )

            // Map returned descriptors to FlavorWheel node IDs
            let vocabulary = Dictionary(
                uniqueKeysWithValues: FlavorWheel.flatDescriptors().map { ($0.name.lowercased(), $0.id) }
            )

            var results: [ExtractedFlavor] = []
            var matchedIds: Set<String> = []

            for descriptor in response.content.descriptors {
                let lowered = descriptor.lowercased()
                if let nodeId = vocabulary[lowered], !matchedIds.contains(nodeId) {
                    matchedIds.insert(nodeId)
                    results.append(ExtractedFlavor(
                        id: nodeId,
                        name: FlavorWheel.findNode(byId: nodeId)?.name ?? descriptor,
                        confidence: 0.9,
                        source: .foundationModel
                    ))
                } else {
                    // Try partial matching: check if any vocabulary key contains the descriptor
                    let partialMatch = vocabulary.first { $0.key.contains(lowered) || lowered.contains($0.key) }
                    if let match = partialMatch, !matchedIds.contains(match.value) {
                        matchedIds.insert(match.value)
                        results.append(ExtractedFlavor(
                            id: match.value,
                            name: FlavorWheel.findNode(byId: match.value)?.name ?? descriptor,
                            confidence: 0.8,
                            source: .foundationModel
                        ))
                    }
                }
            }

            return results
        } catch {
            // Fall back to NL baseline on any Foundation Models error
            return FlavorExtractor().extract(from: text)
        }
    }

    // Pattern analysis and suggestions are pure statistics -- same in both tiers
    func analyzePatterns(brews: [BrewLog]) -> [BrewPattern] {
        patternAnalyzer.analyzePatterns(brews: brews)
    }

    func suggestParameters(for bean: CoffeeBean, method: BrewMethod, history: [BrewLog]) -> BrewSuggestion? {
        suggestionEngine.suggest(for: bean, method: method, history: history)
    }
}

#endif
