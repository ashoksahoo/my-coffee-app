import Foundation
import SwiftData

// MARK: - Insights ViewModel

@Observable
class InsightsViewModel {

    // MARK: - Service

    private let service: any InsightsService

    init() {
        self.service = InsightsServiceFactory.makeService()
    }

    // MARK: - Flavor Extraction State

    var extractedFlavors: [ExtractedFlavor] = []
    var isExtractingFlavors: Bool = false

    func extractFlavors(from text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            extractedFlavors = []
            return
        }
        isExtractingFlavors = true
        let results = await service.extractFlavors(from: trimmed)
        extractedFlavors = results
        isExtractingFlavors = false
    }

    // MARK: - Pattern Analysis State

    var patterns: [BrewPattern] = []

    func analyzePatterns(brews: [BrewLog]) {
        patterns = service.analyzePatterns(brews: brews)
    }

    // MARK: - Suggestion State

    var currentSuggestion: BrewSuggestion? = nil

    func fetchSuggestion(for bean: CoffeeBean?, method: BrewMethod?, history: [BrewLog]) {
        guard let bean = bean, let method = method else {
            currentSuggestion = nil
            return
        }
        currentSuggestion = service.suggestParameters(for: bean, method: method, history: history)
    }
}
