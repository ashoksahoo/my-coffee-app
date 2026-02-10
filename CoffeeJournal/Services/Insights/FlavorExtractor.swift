import Foundation
import NaturalLanguage

struct FlavorExtractor: Sendable {

    /// Lowercased name -> FlavorNode.id mapping for direct vocabulary match
    private let flavorVocabulary: [String: String]

    init() {
        var vocab: [String: String] = [:]
        for node in FlavorWheel.flatDescriptors() {
            let lowered = node.name.lowercased()
            vocab[lowered] = node.id

            // Multi-word handling: for descriptors with spaces (e.g., "Dark Chocolate"),
            // also store individual words as fallback lookups
            let words = lowered.split(separator: " ")
            if words.count > 1 {
                for word in words {
                    let wordStr = String(word)
                    // Only add individual word if not already mapped to a more specific descriptor
                    if vocab[wordStr] == nil {
                        vocab[wordStr] = node.id
                    }
                }
            }
        }
        self.flavorVocabulary = vocab
    }

    // MARK: - Public API

    func extract(from text: String) -> [ExtractedFlavor] {
        var results: [ExtractedFlavor] = []
        var matchedIds: Set<String> = []

        // Step 1: Extract candidate words (adjectives and nouns) via NLTagger
        let candidates = extractCandidateWords(from: text)

        // Step 2: Check bigrams -- combine consecutive candidates to match multi-word descriptors
        for i in 0..<candidates.count {
            if i + 1 < candidates.count {
                let bigram = "\(candidates[i]) \(candidates[i + 1])".lowercased()
                if let nodeId = flavorVocabulary[bigram], !matchedIds.contains(nodeId) {
                    matchedIds.insert(nodeId)
                    results.append(ExtractedFlavor(
                        id: nodeId,
                        name: FlavorWheel.findNode(byId: nodeId)?.name ?? bigram,
                        confidence: 1.0,
                        source: .nlTagger
                    ))
                }
            }
        }

        // Step 3: Direct match -- for each candidate word, check flavorVocabulary
        for word in candidates {
            let lowered = word.lowercased()
            if let nodeId = flavorVocabulary[lowered], !matchedIds.contains(nodeId) {
                matchedIds.insert(nodeId)
                results.append(ExtractedFlavor(
                    id: nodeId,
                    name: FlavorWheel.findNode(byId: nodeId)?.name ?? word,
                    confidence: 1.0,
                    source: .nlTagger
                ))
            }
        }

        // Step 4: Fuzzy match via NLEmbedding for unmatched words
        if let embedding = NLEmbedding.wordEmbedding(for: .english) {
            for word in candidates {
                let lowered = word.lowercased()
                // Skip words already matched directly
                if flavorVocabulary[lowered] != nil { continue }

                let neighbors = embedding.neighbors(for: lowered, maximumCount: 3)
                for (neighbor, distance) in neighbors {
                    // Distance < 0.8 threshold (Pitfall 4 -- distances near 2.0 mean word not found)
                    guard distance < 0.8 else { continue }
                    guard let nodeId = flavorVocabulary[neighbor], !matchedIds.contains(nodeId) else { continue }

                    let confidence = max(0, 1.0 - distance)
                    matchedIds.insert(nodeId)
                    results.append(ExtractedFlavor(
                        id: nodeId,
                        name: FlavorWheel.findNode(byId: nodeId)?.name ?? neighbor,
                        confidence: confidence,
                        source: .nlEmbedding
                    ))
                }
            }
        }

        // Step 5: Deduplicate by id, keep highest confidence per id. Return sorted by confidence descending.
        var bestById: [String: ExtractedFlavor] = [:]
        for flavor in results {
            if let existing = bestById[flavor.id] {
                if flavor.confidence > existing.confidence {
                    bestById[flavor.id] = flavor
                }
            } else {
                bestById[flavor.id] = flavor
            }
        }

        return bestById.values.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Private

    /// Extract adjectives and nouns from text using NLTagger lexicalClass scheme
    private func extractCandidateWords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        var words: [String] = []
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { tag, range in
            if let tag = tag,
               tag == .adjective || tag == .noun {
                words.append(String(text[range]))
            }
            return true
        }
        return words
    }
}
