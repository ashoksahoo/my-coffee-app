# Phase 7: Apple Intelligence - Research

**Researched:** 2026-02-10
**Domain:** On-device NLP, Foundation Models, pattern recognition, brew parameter suggestions
**Confidence:** MEDIUM-HIGH

## Summary

Phase 7 adds AI-powered intelligence to the coffee journal: extracting flavor descriptors from freeform tasting notes, identifying brewing patterns across history, and suggesting brew parameters for similar coffees. The implementation spans two tiers of technology: (1) the NaturalLanguage framework (available iOS 17+, works everywhere) for flavor extraction using NLTagger part-of-speech tagging and NLEmbedding word similarity matching against the existing SCA FlavorWheel vocabulary, and (2) the Foundation Models framework (iOS 26+, A17 Pro/M1+ only) for richer natural-language analysis with structured output via the `@Generable` macro. All pattern recognition and brew suggestions use straightforward SwiftData queries and statistical aggregation -- no trained ML models are needed for the brew data patterns described in the requirements.

The key architectural decision is the **dual-tier service layer**: a protocol-based `InsightsService` that has a concrete NaturalLanguage-based implementation (always available) and a Foundation Models-based implementation (conditionally available on iOS 26+). The app checks `SystemLanguageModel.default.availability` at runtime and upgrades to the richer implementation when possible, falling back gracefully to the NaturalLanguage-based extraction otherwise.

**Primary recommendation:** Use NaturalLanguage framework (NLTagger + NLEmbedding) as the universal baseline for flavor extraction. Use Foundation Models as an enhancement layer behind `#if canImport(FoundationModels)` and `@available(iOS 26, *)` guards. Implement pattern recognition and brew suggestions as pure SwiftData queries with statistical aggregation -- no Core ML models needed for the requirements as stated.

## Standard Stack

### Core

| Framework | Min iOS | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| NaturalLanguage | 11+ (enhanced 17+) | Flavor descriptor extraction from freeform text | Apple's built-in NLP. Free, on-device, zero app size increase. NLTagger for part-of-speech tagging, NLEmbedding for word similarity. Works on all devices. |
| Foundation Models | 26+ (A17 Pro/M1+) | Enhanced natural-language analysis with structured output | Apple's on-device LLM (~3B params). `@Generable` macro for type-safe structured output. Richer flavor analysis, brew descriptions, conversational suggestions. |
| SwiftData | 17+ | Pattern queries, statistical aggregation | Already in use. All brew history queries for patterns and suggestions run as SwiftData `@Query` or `ModelContext.fetch()` calls. |
| Swift Charts | 17+ | Insights visualization in statistics dashboard | Already in use in StatisticsDashboardView. Extend with pattern insights. |

### Supporting

| Framework | Min iOS | Purpose | When to Use |
|-----------|---------|---------|-------------|
| Observation | 17+ | `@Observable` view models for insights | Already used project-wide. InsightsViewModel will follow the same pattern. |
| Combine | 13+ | Debouncing freeform text input before NLP analysis | Only if real-time flavor extraction while typing is desired. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| NaturalLanguage for flavor extraction | Core ML custom text classifier | Would require training data (labeled tasting notes), Create ML setup, bundled model file. Overkill for matching known vocabulary. NaturalLanguage's built-in NLEmbedding already maps words to the SCA FlavorWheel without any training. |
| Foundation Models for enhanced analysis | Core ML with a custom fine-tuned model | Requires training pipeline, model bundling, and maintenance. Foundation Models gives LLM capability with zero training. |
| SwiftData queries for patterns | Core ML tabular regression model | Would need training data collection period. Simple statistical aggregation (averages, modes, weighted scores) answers the requirements directly. |

## Architecture Patterns

### Recommended Project Structure

```
CoffeeJournal/
├── Services/
│   ├── Insights/
│   │   ├── InsightsService.swift          # Protocol defining the insights API
│   │   ├── NLInsightsService.swift        # NaturalLanguage-based implementation (always available)
│   │   ├── FoundationModelInsightsService.swift  # Foundation Models implementation (iOS 26+)
│   │   ├── FlavorExtractor.swift          # NLTagger + NLEmbedding flavor matching
│   │   ├── BrewPatternAnalyzer.swift      # SwiftData queries for pattern detection
│   │   └── BrewSuggestionEngine.swift     # Parameter suggestions from similar brews
│   ├── SyncMonitor.swift                  # (existing)
│   └── NetworkMonitor.swift               # (existing)
├── ViewModels/
│   ├── InsightsViewModel.swift            # Drives insights UI in dashboard and detail views
│   └── ... (existing)
├── Views/
│   ├── Insights/
│   │   ├── FlavorInsightView.swift        # Extracted flavors display in brew detail
│   │   ├── BrewPatternCard.swift          # Pattern cards for statistics dashboard
│   │   └── BrewSuggestionBanner.swift     # Parameter suggestion in AddBrewLogView
│   └── ... (existing)
└── ... (existing)
```

### Pattern 1: Dual-Tier Service with Protocol Abstraction

**What:** Define a protocol for AI insights, with two concrete implementations selected at runtime.
**When to use:** When a feature has a baseline (NaturalLanguage) and an enhanced tier (Foundation Models) with different hardware requirements.

```swift
// InsightsService.swift
protocol InsightsService {
    /// Extract flavor descriptors from freeform tasting notes text
    func extractFlavors(from text: String) async -> [ExtractedFlavor]

    /// Analyze brewing patterns across all history
    func analyzePatterns(brews: [BrewLog]) -> [BrewPattern]

    /// Suggest brew parameters for a given coffee + method combination
    func suggestParameters(for bean: CoffeeBean, method: BrewMethod, history: [BrewLog]) -> BrewSuggestion?
}

struct ExtractedFlavor: Identifiable {
    let id: String           // FlavorWheel node ID or "extracted:<word>"
    let name: String         // Display name
    let confidence: Double   // 0.0-1.0
    let source: ExtractionSource

    enum ExtractionSource {
        case nlEmbedding    // Matched via NLEmbedding word similarity
        case nlTagger       // Matched via part-of-speech extraction
        case foundationModel // Matched via Foundation Models LLM
    }
}
```

### Pattern 2: NaturalLanguage Flavor Extraction Pipeline

**What:** Multi-step pipeline using NLTagger to extract adjectives/nouns, then NLEmbedding to match them against the FlavorWheel vocabulary.
**When to use:** Always -- this is the baseline that works on all devices.

```swift
// FlavorExtractor.swift
import NaturalLanguage

struct FlavorExtractor {
    /// All leaf node names from the SCA FlavorWheel, lowercased for embedding lookup
    private let flavorVocabulary: [String: String]  // lowercased -> FlavorNode.id

    init() {
        var vocab: [String: String] = [:]
        for node in FlavorWheel.flatDescriptors() {
            vocab[node.name.lowercased()] = node.id
        }
        self.flavorVocabulary = vocab
    }

    func extract(from text: String) -> [ExtractedFlavor] {
        var results: [ExtractedFlavor] = []

        // Step 1: Extract adjectives and nouns via NLTagger
        let candidateWords = extractCandidateWords(from: text)

        // Step 2: Direct match against FlavorWheel vocabulary
        for word in candidateWords {
            if let nodeId = flavorVocabulary[word.lowercased()] {
                results.append(ExtractedFlavor(
                    id: nodeId,
                    name: FlavorWheel.findNode(byId: nodeId)?.name ?? word,
                    confidence: 1.0,
                    source: .nlTagger
                ))
            }
        }

        // Step 3: Fuzzy match via NLEmbedding for unmatched words
        if let embedding = NLEmbedding.wordEmbedding(for: .english) {
            let matched = Set(results.map { $0.id })
            for word in candidateWords where flavorVocabulary[word.lowercased()] == nil {
                let neighbors = embedding.neighbors(for: word.lowercased(), maximumCount: 3)
                for (neighbor, distance) in neighbors {
                    if let nodeId = flavorVocabulary[neighbor], !matched.contains(nodeId) {
                        let confidence = max(0, 1.0 - distance)  // distance 0=identical, 2=no match
                        if confidence > 0.3 {  // threshold for relevance
                            results.append(ExtractedFlavor(
                                id: nodeId,
                                name: FlavorWheel.findNode(byId: nodeId)?.name ?? neighbor,
                                confidence: confidence,
                                source: .nlEmbedding
                            ))
                        }
                    }
                }
            }
        }

        return results.sorted { $0.confidence > $1.confidence }
    }

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
```

### Pattern 3: Foundation Models Enhanced Extraction (iOS 26+)

**What:** Use Foundation Models `@Generable` for richer, context-aware flavor extraction.
**When to use:** Only on iOS 26+ devices with Apple Intelligence available.

```swift
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
@Generable
struct FlavorAnalysis {
    @Guide(description: "Flavor descriptors found in the tasting notes")
    let flavors: [FlavorDescriptor]
    @Guide(description: "Overall sentiment of the tasting experience, from -1 (negative) to 1 (positive)")
    let sentiment: Double
    @Guide(description: "A one-sentence summary of the tasting profile")
    let summary: String
}

@available(iOS 26, *)
@Generable
struct FlavorDescriptor {
    @Guide(description: "The flavor name, e.g., 'blueberry', 'chocolate', 'citrus'")
    let name: String
    @Guide(description: "How strongly this flavor was expressed, from 0.0 (subtle) to 1.0 (dominant)")
    let intensity: Double
    @Guide(description: "The SCA flavor wheel category: floral, fruity, sour-fermented, green-vegetative, other, roasted, spices, nutty-cocoa, sweet")
    let category: String
}
#endif
```

### Pattern 4: Brew Parameter Suggestion via Statistical Aggregation

**What:** Query past successful brews (rating >= 4) with the same or similar coffee origin/method and compute weighted averages.
**When to use:** When a user selects a bean+method combination in AddBrewLogView.

```swift
// BrewSuggestionEngine.swift
struct BrewSuggestion {
    let dose: Double
    let waterAmount: Double?
    let yieldAmount: Double?
    let waterTemperature: Double
    let grinderSetting: Double?
    let brewTime: Double
    let confidence: SuggestionConfidence
    let basedOnCount: Int

    enum SuggestionConfidence {
        case high    // 5+ similar brews rated 4+
        case medium  // 2-4 similar brews
        case low     // 1 similar brew
    }
}

struct BrewSuggestionEngine {
    func suggest(
        for bean: CoffeeBean,
        method: BrewMethod,
        history: [BrewLog]
    ) -> BrewSuggestion? {
        // 1. Find brews with same bean
        let sameBeanBrews = history.filter {
            $0.coffeeBean?.id == bean.id &&
            $0.brewMethod?.id == method.id &&
            $0.rating >= 4
        }

        // 2. If none, try same origin
        let sameOriginBrews = sameBeanBrews.isEmpty
            ? history.filter {
                $0.coffeeBean?.origin == bean.origin &&
                $0.brewMethod?.id == method.id &&
                $0.rating >= 4
            }
            : sameBeanBrews

        guard !sameOriginBrews.isEmpty else { return nil }

        // 3. Compute weighted averages (weight by rating)
        let totalWeight = sameOriginBrews.reduce(0.0) { $0 + Double($1.rating) }
        let weightedDose = sameOriginBrews.reduce(0.0) { $0 + $1.dose * Double($1.rating) } / totalWeight
        // ... (similar for other parameters)

        let count = sameOriginBrews.count
        return BrewSuggestion(
            dose: weightedDose,
            // ... other computed parameters
            confidence: count >= 5 ? .high : count >= 2 ? .medium : .low,
            basedOnCount: count
        )
    }
}
```

### Pattern 5: Availability-Gated Service Selection

**What:** Select the appropriate InsightsService implementation at app launch based on device capabilities.
**When to use:** At the app's environment setup or in the InsightsViewModel initializer.

```swift
// Factory pattern for service selection
struct InsightsServiceFactory {
    static func makeService() -> InsightsService {
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
```

### Anti-Patterns to Avoid

- **Training a Core ML model for pattern recognition:** The requirements describe statistical patterns (preferred grind settings, optimal ratios) that are simple aggregations over SwiftData queries. A trained model adds complexity without value for these use cases.
- **Requiring Foundation Models for any feature to work:** Every AI feature must have a NaturalLanguage fallback. Foundation Models is an enhancement, not a dependency.
- **Running NLP analysis on the main thread:** NLTagger and NLEmbedding are fast but should still run on a background task for text longer than a few sentences, especially NLEmbedding neighbor searches.
- **Hardcoding flavor vocabulary without the FlavorWheel:** The FlavorWheel already defines the SCA vocabulary with hierarchical IDs. Flavor extraction should map to FlavorWheel node IDs, not invent a separate vocabulary.
- **Sending data to external servers:** All ML must be on-device. No network calls for AI features. This is an explicit requirement (AI-04).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Part-of-speech tagging | Custom word classification | NLTagger with `.lexicalClass` scheme | Apple's built-in model handles English and many languages, works offline, zero size |
| Word similarity matching | Levenshtein distance or custom embeddings | NLEmbedding.wordEmbedding(for: .english) | Pre-trained word vectors shipped with the OS, no model file needed |
| Sentiment analysis | Custom sentiment scorer | NLTagger with `.sentimentScore` scheme | Returns -1.0 to +1.0, built into iOS since 13 |
| Structured LLM output parsing | JSON parsing from raw LLM text | Foundation Models `@Generable` macro | Compile-time schema generation, type-safe, handles parsing automatically |
| Statistical aggregation | Custom analytics engine | SwiftData `@Query` + Swift standard library | `Dictionary(grouping:)`, `.reduce()`, weighted averages are trivial in Swift |

**Key insight:** The NaturalLanguage framework and SwiftData queries handle 90% of the requirements without any custom ML. Foundation Models adds richness (better context understanding, natural summaries) but is not required for the feature set to work.

## Common Pitfalls

### Pitfall 1: NLEmbedding Requires Lowercase Input

**What goes wrong:** `NLEmbedding.neighbors(for: "Chocolate", maximumCount: 5)` returns empty results.
**Why it happens:** OS word embeddings only contain lowercase entries. Any capitalized input silently returns no results.
**How to avoid:** Always call `.lowercased()` on input words before embedding lookup.
**Warning signs:** Flavor extraction returns zero matches despite obvious flavor words in text.

### Pitfall 2: Foundation Models 4096 Token Limit

**What goes wrong:** Long tasting notes or large context prompts get truncated or error out.
**Why it happens:** The on-device model has a combined input+output limit of 4096 tokens.
**How to avoid:** Keep prompts concise. For flavor extraction, send only the freeform notes text (not the entire brew log). For suggestions, summarize history rather than sending raw data.
**Warning signs:** `LanguageModelError` thrown during `respond()` calls with long inputs.

### Pitfall 3: Foundation Models Unavailability is Multi-Dimensional

**What goes wrong:** Checking only for iOS version and assuming Foundation Models works.
**Why it happens:** Foundation Models requires: (1) iOS 26+, (2) A17 Pro or M1+ hardware, (3) Apple Intelligence enabled in Settings, (4) sufficient storage for model download, (5) not in Game Mode. Any of these can cause unavailability.
**How to avoid:** Always check `SystemLanguageModel.default.availability` at runtime, not just OS version. Handle `.unavailable(.deviceNotEligible)`, `.unavailable(.appleIntelligenceNotEnabled)`, `.unavailable(.modelNotReady)` distinctly.
**Warning signs:** Features silently fail on devices that technically run iOS 26 but lack Apple Intelligence.

### Pitfall 4: NLEmbedding Distance Semantics

**What goes wrong:** Using NLEmbedding distance values incorrectly to filter matches.
**Why it happens:** Distance is cosine-based. Value of 0 = identical, 2.0 = word not found in embedding. Developers sometimes confuse "close distance = bad" or misinterpret the 2.0 sentinel.
**How to avoid:** Filter neighbors with `distance < 1.0` for reasonable similarity. A distance of 2.0 means the word doesn't exist in the embedding at all, not that it's maximally different.
**Warning signs:** Getting 2.0 distance for valid English words (usually means the word wasn't lowercased).

### Pitfall 5: Suggesting Parameters from Too Few Data Points

**What goes wrong:** Suggesting a grind setting of 15 based on a single brew rated 4 stars, which the user takes as authoritative.
**Why it happens:** Statistical suggestions from 1-2 data points are unreliable but presented with the same UI confidence as suggestions from 20 brews.
**How to avoid:** Display confidence levels clearly in the UI. Show "Based on N brews" alongside suggestions. Require a minimum threshold (e.g., 2+ brews) before showing suggestions. Use different visual treatment for low vs high confidence.
**Warning signs:** User confusion when suggestions don't match their expectations.

### Pitfall 6: Testing Foundation Models Requires macOS 26 + Physical Device

**What goes wrong:** Cannot test Foundation Models features in CI or on older macOS.
**Why it happens:** Simulator uses host macOS models. Xcode Previews can crash with Foundation Models. CI environments typically don't have Apple Intelligence.
**How to avoid:** Design with protocol abstraction so NaturalLanguage implementation is always testable. Test Foundation Models manually on physical devices. Use mock implementations for unit tests.
**Warning signs:** Tests pass in CI but features fail on device (or vice versa).

## Code Examples

### Flavor Extraction from Freeform Notes (NaturalLanguage)

```swift
// Source: Apple NaturalLanguage docs + NLEmbedding neighbors API
import NaturalLanguage

func extractFlavorDescriptors(from notes: String) -> [String] {
    // Step 1: Extract candidate words (nouns + adjectives)
    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = notes
    let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

    var candidates: [String] = []
    tagger.enumerateTags(
        in: notes.startIndex..<notes.endIndex,
        unit: .word,
        scheme: .lexicalClass,
        options: options
    ) { tag, range in
        if let tag, tag == .adjective || tag == .noun {
            candidates.append(String(notes[range]))
        }
        return true
    }

    // Step 2: Match against FlavorWheel vocabulary
    let vocabulary = Set(FlavorWheel.flatDescriptors().map { $0.name.lowercased() })
    var matched: [String] = []

    for word in candidates {
        let lower = word.lowercased()
        // Direct match
        if vocabulary.contains(lower) {
            matched.append(lower)
            continue
        }
        // Embedding neighbor match
        if let embedding = NLEmbedding.wordEmbedding(for: .english) {
            for (neighbor, distance) in embedding.neighbors(for: lower, maximumCount: 3) {
                if vocabulary.contains(neighbor) && distance < 0.8 {
                    matched.append(neighbor)
                    break
                }
            }
        }
    }

    return Array(Set(matched))  // deduplicate
}
```

### Sentiment Analysis of Tasting Notes

```swift
// Source: https://www.hackingwithswift.com/example-code/naturallanguage/how-to-perform-sentiment-analysis-on-a-string-using-nltagger
import NaturalLanguage

func analyzeSentiment(of text: String) -> Double {
    let tagger = NLTagger(tagSchemes: [.sentimentScore])
    tagger.string = text
    let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
    return Double(sentiment?.rawValue ?? "0") ?? 0  // -1.0 to +1.0
}
```

### Foundation Models Availability Check and Graceful Degradation

```swift
// Source: https://www.createwithswift.com/exploring-the-foundation-models-framework/
// Source: https://artemnovichkov.com/blog/getting-started-with-apple-foundation-models

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
func checkFoundationModelsAvailability() -> FoundationModelsStatus {
    let model = SystemLanguageModel.default
    switch model.availability {
    case .available:
        return .available
    case .unavailable(.deviceNotEligible):
        return .notEligible
    case .unavailable(.appleIntelligenceNotEnabled):
        return .notEnabled
    case .unavailable(.modelNotReady):
        return .downloading
    case .unavailable:
        return .unavailable
    }
}

enum FoundationModelsStatus {
    case available
    case notEligible    // Device hardware doesn't support Apple Intelligence
    case notEnabled     // User hasn't enabled Apple Intelligence in Settings
    case downloading    // Model assets are being downloaded
    case unavailable    // Other reason
}
#endif
```

### Foundation Models Structured Flavor Analysis

```swift
// Source: https://azamsharp.com/2025/06/18/the-ultimate-guide-to-the-foundation-models-framework.html
// Source: https://www.appcoda.com/generable/

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
@Generable
struct TastingAnalysis {
    @Guide(description: "Flavor descriptors identified in the tasting notes text")
    let descriptors: [String]

    @Guide(description: "Overall quality assessment: positive, neutral, or negative")
    let sentiment: String

    @Guide(description: "Brief one-sentence summary of the tasting experience")
    let summary: String
}

@available(iOS 26, *)
func analyzeWithFoundationModels(notes: String) async throws -> TastingAnalysis {
    let session = LanguageModelSession {
        """
        You are a coffee tasting expert. Analyze tasting notes and extract flavor descriptors.
        Use standard SCA flavor wheel terminology where possible: fruity, floral, sweet,
        nutty-cocoa, spices, roasted, green-vegetative, sour-fermented, other.
        """
    }

    let response = try await session.respond(
        to: "Analyze these coffee tasting notes: \(notes)",
        generating: TastingAnalysis.self
    )

    return response.content
}
#endif
```

### Brew Pattern Detection via SwiftData Queries

```swift
// Pure Swift statistical analysis -- no ML model needed
struct BrewPatternAnalyzer {

    struct BrewPattern: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let category: PatternCategory

        enum PatternCategory {
            case grindPreference
            case ratioOptimal
            case methodFavorite
            case originTrend
        }
    }

    func analyzePatterns(brews: [BrewLog]) -> [BrewPattern] {
        var patterns: [BrewPattern] = []

        // Pattern: Preferred grind settings by origin
        let brewsByOrigin = Dictionary(grouping: brews.filter { $0.rating >= 4 }) {
            $0.coffeeBean?.origin ?? "Unknown"
        }
        for (origin, originBrews) in brewsByOrigin where originBrews.count >= 3 {
            let avgGrind = originBrews.reduce(0.0) { $0 + $1.grinderSetting } / Double(originBrews.count)
            if avgGrind > 0 {
                patterns.append(BrewPattern(
                    title: "Grind for \(origin)",
                    description: "Your best \(origin) brews use grind setting ~\(String(format: "%.0f", avgGrind))",
                    category: .grindPreference
                ))
            }
        }

        // Pattern: Optimal ratio by method
        let brewsByMethod = Dictionary(grouping: brews.filter { $0.rating >= 4 }) {
            $0.brewMethod?.name ?? "Unknown"
        }
        for (method, methodBrews) in brewsByMethod where methodBrews.count >= 3 {
            let ratios = methodBrews.compactMap { $0.brewRatio }
            if !ratios.isEmpty {
                let avgRatio = ratios.reduce(0.0, +) / Double(ratios.count)
                patterns.append(BrewPattern(
                    title: "Best \(method) Ratio",
                    description: "Your top-rated \(method) brews use 1:\(String(format: "%.1f", avgRatio))",
                    category: .ratioOptimal
                ))
            }
        }

        return patterns
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Core ML custom models for NLP tasks | NaturalLanguage framework built-in NLTagger/NLEmbedding | iOS 12+ (2018), enhanced through iOS 17 | No need to train/bundle custom models for standard NLP tasks |
| Core ML for on-device LLM inference | Foundation Models framework with `@Generable` | iOS 26 (WWDC 2025, released Fall 2025) | Native Swift API for on-device LLM, type-safe structured output, no third-party LLM libraries |
| Manual JSON parsing of LLM output | `@Generable` + `@Guide` macros | iOS 26 (WWDC 2025) | Compile-time schema generation, model respects type constraints |
| No on-device text generation | SystemLanguageModel.default (~3B parameter model) | iOS 26 | On-device, private, free, ~4096 token combined limit |

**Deprecated/outdated:**
- **NSLinguisticTagger**: Replaced by NLTagger in iOS 12. Do not use.
- **Third-party NLP libraries (OpenNLP, spaCy mobile wrappers)**: NaturalLanguage framework covers all needed NLP tasks without dependencies.
- **OpenAI/Anthropic API calls for on-device features**: Violates AI-04 requirement (all processing on-device). Foundation Models provides equivalent capability.

## Integration Points with Existing Codebase

### Where AI Features Connect

| Requirement | Existing View/Component | Integration |
|-------------|------------------------|-------------|
| AI-01: Flavor extraction from freeform notes | `TastingNoteEntryView` (freeform notes TextEditor) and `BrewLogDetailView` (tasting notes section) | Extract flavors when freeform notes are saved or viewed; display extracted flavors as chips in detail view |
| AI-02: Brewing patterns | `StatisticsDashboardView` (existing stats cards and charts) | Add new "Insights" section with BrewPatternCards below existing charts |
| AI-03: Brew parameter suggestions | `AddBrewLogView` (equipment + coffee selection) | Show suggestion banner when bean+method are selected; auto-fill parameters on tap |
| AI-04: On-device ML | New `InsightsService` protocol | Protocol abstraction ensures NaturalLanguage fallback; no network calls |
| AI-05: Insights in dashboard + detail views | `StatisticsDashboardView` and `BrewLogDetailView` | Dashboard gets patterns section; detail view gets extracted flavors section |

### Existing Data Available for Analysis

| Data Point | Model | Property | Useful For |
|------------|-------|----------|------------|
| Freeform tasting notes | `TastingNote` | `freeformNotes: String` | AI-01 flavor extraction |
| Quick brew notes | `BrewLog` | `notes: String` | AI-01 additional flavor extraction |
| Selected flavor tags | `TastingNote` | `flavorTags: String` (JSON array) | Validation of AI extraction accuracy |
| Brew parameters | `BrewLog` | `dose`, `waterAmount`, `brewTime`, `grinderSetting`, `waterTemperature`, `yieldAmount` | AI-02 pattern detection, AI-03 suggestions |
| Brew rating | `BrewLog` | `rating: Int` (0-5) | Weighting for pattern quality and suggestion confidence |
| Coffee origin | `CoffeeBean` | `origin: String` | AI-02 grind preferences by origin |
| Brew method | `BrewMethod` | `name`, `category` | AI-02 optimal ratios by method, AI-03 method-specific suggestions |
| FlavorWheel vocabulary | `FlavorWheel` | `categories: [FlavorNode]` with `flatDescriptors()` | AI-01 target vocabulary for NLEmbedding matching |

## Open Questions

1. **NLEmbedding coverage of coffee vocabulary**
   - What we know: NLEmbedding.wordEmbedding(for: .english) contains general English words and finds neighbors based on semantic similarity.
   - What's unclear: How well does the OS embedding cover specialty coffee terms like "washed process", "natural process", "channeling", or compound descriptors like "dark chocolate"? Multi-word descriptors may not be found as single embedding lookups.
   - Recommendation: Test embedding coverage against FlavorWheel leaf nodes during implementation. For multi-word descriptors (e.g., "dark chocolate"), try both the compound and individual words. Consider building a fallback dictionary of common coffee-specific synonyms (e.g., "chocolatey" -> "chocolate", "citrusy" -> "citrus") if embedding coverage is insufficient. Confidence: MEDIUM -- needs validation.

2. **Foundation Models session management in a coffee app context**
   - What we know: `LanguageModelSession` maintains conversation context and has a 4096 token limit.
   - What's unclear: Should we create one session per analysis request, or maintain a session across multiple analyses? Does `prewarm()` provide meaningful latency reduction for short prompts?
   - Recommendation: Create a new session per analysis request to avoid context pollution. Call `prewarm()` when InsightsViewModel appears to reduce first-analysis latency. Confidence: MEDIUM -- needs benchmarking.

3. **Minimum brew count before showing pattern insights**
   - What we know: Statistical patterns from 1-2 data points are unreliable.
   - What's unclear: What is the right threshold? Too high (10+) means the feature is invisible to most users. Too low (1) means unreliable suggestions.
   - Recommendation: Show patterns at 3+ brews for a category, show suggestions at 2+ similar brews, but always display confidence level and "based on N brews" in the UI. Confidence: MEDIUM -- this is a UX decision.

4. **Xcode build compatibility for `#if canImport(FoundationModels)`**
   - What we know: The project currently targets iOS 17 with Xcode and Swift 5. Foundation Models requires iOS 26 SDK.
   - What's unclear: Whether `#if canImport(FoundationModels)` compiles cleanly on current Xcode (which may not have the FoundationModels SDK). The code behind the `#if` block would simply be excluded at compile time if the SDK is absent.
   - Recommendation: `#if canImport` is a compile-time check and will compile fine -- the code is simply excluded when the SDK is not available. Verify with a test build. If needed, also gate with `#if swift(>=6.2)` or an Xcode version check. Confidence: HIGH -- this is standard Swift conditional compilation.

## Sources

### Primary (HIGH confidence)
- [Apple NaturalLanguage documentation](https://developer.apple.com/documentation/NaturalLanguage) -- NLTagger, NLEmbedding APIs
- [Apple Foundation Models documentation](https://developer.apple.com/documentation/FoundationModels) -- API surface, platform requirements
- [Hacking with Swift: NLEmbedding neighbors](https://www.hackingwithswift.com/example-code/naturallanguage/how-to-find-similar-words-for-a-search-term) -- Verified code example
- [Hacking with Swift: NLTagger sentiment](https://www.hackingwithswift.com/example-code/naturallanguage/how-to-perform-sentiment-analysis-on-a-string-using-nltagger) -- Verified code example
- [createwithswift.com: Lexical classification](https://www.createwithswift.com/lexical-classification-with-the-natural-language-framework/) -- NLTagger lexicalClass code example
- [createwithswift.com: Foundation Models exploration](https://www.createwithswift.com/exploring-the-foundation-models-framework/) -- SystemLanguageModel, LanguageModelSession, @Generable API

### Secondary (MEDIUM confidence)
- [AzamSharp: Foundation Models guide](https://azamsharp.com/2025/06/18/the-ultimate-guide-to-the-foundation-models-framework.html) -- LanguageModelSession usage, @Generable/@Guide macros, 4096 token limit
- [AppCoda: @Generable and @Guide](https://www.appcoda.com/generable/) -- Structured output code examples, property order matters
- [Artem Novichkov: Foundation Models getting started](https://artemnovichkov.com/blog/getting-started-with-apple-foundation-models) -- Availability checking, Tool protocol, error handling
- [MacRumors: Apple Intelligence device compatibility](https://www.macrumors.com/guide/does-my-iphone-support-apple-intelligence/) -- A17 Pro/M1+ requirement
- [fritz.ai: Word Embeddings and Text Catalogs](https://fritz.ai/exploring-word-embeddings-and-text-catalogs-ios/) -- Custom embeddings, NLGazetteer, domain-specific usage

### Tertiary (LOW confidence)
- [WebSearch: Foundation Models simulator testing](https://developer.apple.com/forums/topics/machine-learning-and-ai/machine-learning-and-ai-foundation-models) -- Simulator requires macOS 26 host, Preview can crash. Needs validation with actual development setup.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- NaturalLanguage and Foundation Models are well-documented Apple frameworks. No third-party dependencies.
- Architecture (dual-tier service): HIGH -- Protocol abstraction with `#if canImport` and `@available` is standard Swift pattern for optional framework features.
- Flavor extraction pipeline: MEDIUM -- NLEmbedding's coverage of coffee-specific vocabulary needs validation. The algorithm is sound but the embedding quality for specialty terms is untested.
- Pattern recognition: HIGH -- Pure statistical aggregation over SwiftData queries. No novel algorithms.
- Brew suggestions: HIGH -- Weighted average of historical parameters. Standard approach.
- Foundation Models integration: MEDIUM -- API is well-documented but testing requires macOS 26 + eligible device. Token limits (4096) need prompt engineering to stay within bounds.
- Pitfalls: HIGH -- Well-documented issues (lowercase embedding, token limits, availability checks) with clear mitigations.

**Research date:** 2026-02-10
**Valid until:** 2026-03-10 (30 days -- NaturalLanguage is stable; Foundation Models API stabilized post-release)
