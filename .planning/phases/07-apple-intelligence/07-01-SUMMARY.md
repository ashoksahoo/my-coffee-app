---
phase: 07-apple-intelligence
plan: 01
subsystem: ai, services
tags: [NaturalLanguage, NLTagger, NLEmbedding, FoundationModels, FlavorWheel, on-device-ML]

# Dependency graph
requires:
  - phase: 04-tasting-flavor-notes
    provides: FlavorWheel vocabulary with flatDescriptors() and findNode(byId:)
  - phase: 03-brew-logging
    provides: BrewLog model with dose, waterAmount, brewTime, grinderSetting, rating, brewRatio
provides:
  - InsightsService protocol abstracting NL and Foundation Models implementations
  - FlavorExtractor with NLTagger POS tagging + NLEmbedding fuzzy matching
  - BrewPatternAnalyzer detecting grind/ratio patterns from brew history
  - BrewSuggestionEngine computing weighted-average parameter suggestions
  - FoundationModelInsightsService with @Generable structured output (iOS 26+)
  - InsightsServiceFactory for runtime service selection
affects: [07-02-insights-ui, statistics-dashboard, brew-detail, add-brew-log]

# Tech tracking
tech-stack:
  added: [NaturalLanguage framework (NLTagger, NLEmbedding), FoundationModels (conditional)]
  patterns: [dual-tier service protocol, compile-time conditional compilation, weighted-average aggregation]

key-files:
  created:
    - CoffeeJournal/Services/Insights/InsightsService.swift
    - CoffeeJournal/Services/Insights/FlavorExtractor.swift
    - CoffeeJournal/Services/Insights/NLInsightsService.swift
    - CoffeeJournal/Services/Insights/FoundationModelInsightsService.swift
    - CoffeeJournal/Services/Insights/BrewPatternAnalyzer.swift
    - CoffeeJournal/Services/Insights/BrewSuggestionEngine.swift
  modified:
    - Package.swift

key-decisions:
  - "FlavorExtractor stores both multi-word descriptors and individual word fallbacks in vocabulary map"
  - "BrewPatternAnalyzer uses rating-weighted averages for grind preference patterns"
  - "FoundationModelInsightsService falls back to FlavorExtractor on any Foundation Models error"
  - "NLInsightsService marked @unchecked Sendable since FlavorExtractor/BrewPatternAnalyzer/BrewSuggestionEngine are all Sendable structs"
  - "FoundationModelInsightsService entire file wrapped in #if canImport(FoundationModels) -- excluded when SDK not present"

patterns-established:
  - "Dual-tier service: protocol InsightsService with NL (always) and Foundation Models (iOS 26+) implementations"
  - "Compile-time gating: #if canImport(FoundationModels) wraps entire file, @available(iOS 26, *) on types"
  - "Runtime service selection: InsightsServiceFactory checks SystemLanguageModel.default.availability"
  - "FlavorWheel vocabulary matching: lowercased names -> node IDs with NLEmbedding fuzzy fallback"

# Metrics
duration: 3min
completed: 2026-02-10
---

# Phase 7 Plan 01: AI Insights Service Layer Summary

**NLTagger + NLEmbedding flavor extraction pipeline, BrewPatternAnalyzer for grind/ratio patterns, BrewSuggestionEngine for weighted-average parameter suggestions, with Foundation Models enhancement behind conditional compilation**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-10T09:34:16Z
- **Completed:** 2026-02-10T09:37:39Z
- **Tasks:** 2
- **Files modified:** 7 (6 created + 1 modified)

## Accomplishments
- InsightsService protocol with extractFlavors/analyzePatterns/suggestParameters abstraction
- FlavorExtractor extracts candidate words via NLTagger POS tagging, matches against FlavorWheel vocabulary directly (including bigrams for multi-word descriptors like "dark chocolate"), and fuzzy-matches via NLEmbedding neighbors with distance-based confidence
- BrewPatternAnalyzer detects grind-by-origin and ratio-by-method patterns from 3+ highly-rated brews, plus favorite method and origin trends
- BrewSuggestionEngine computes weighted-average parameters from same-bean (falling back to same-origin) high-rated brews with high/medium/low confidence levels
- FoundationModelInsightsService uses @Generable TastingAnalysis struct for richer extraction on iOS 26+, with automatic NL fallback on error
- All processing on-device -- zero network calls (AI-04 compliance)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create InsightsService protocol, shared types, and FlavorExtractor** - `d06e3ab` (feat)
2. **Task 2: Create NLInsightsService, FoundationModelInsightsService, BrewPatternAnalyzer, and BrewSuggestionEngine** - `87dfa1f` (feat)

## Files Created/Modified
- `CoffeeJournal/Services/Insights/InsightsService.swift` - Protocol, ExtractedFlavor/BrewPattern/BrewSuggestion types, InsightsServiceFactory
- `CoffeeJournal/Services/Insights/FlavorExtractor.swift` - NLTagger + NLEmbedding flavor extraction pipeline against FlavorWheel vocabulary
- `CoffeeJournal/Services/Insights/NLInsightsService.swift` - NaturalLanguage-based InsightsService implementation (always available)
- `CoffeeJournal/Services/Insights/FoundationModelInsightsService.swift` - Foundation Models InsightsService implementation (iOS 26+ conditional)
- `CoffeeJournal/Services/Insights/BrewPatternAnalyzer.swift` - Statistical pattern detection from brew history
- `CoffeeJournal/Services/Insights/BrewSuggestionEngine.swift` - Parameter suggestion from similar brews
- `Package.swift` - Added 6 new source files to build manifest

## Decisions Made
- FlavorExtractor stores both full multi-word descriptors ("dark chocolate") and individual words ("chocolate") in vocabulary map, with multi-word checked first via bigrams
- BrewPatternAnalyzer uses rating-weighted averages for grind preference patterns (not simple average) so 5-star brews count more than 4-star
- FoundationModelInsightsService falls back to FlavorExtractor().extract() on any error, ensuring graceful degradation
- BrewSuggestionEngine requires non-empty origin for same-origin fallback to prevent matching brews with empty origin strings
- All types marked Sendable for Swift 6 strict concurrency compliance

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- InsightsService protocol ready for Plan 02 (Insights UI views)
- InsightsServiceFactory provides single entry point for ViewModel integration
- All 6 service files compile successfully (verified via swift build)
- Foundation Models code excluded cleanly when SDK not present

## Self-Check: PASSED

All 6 service files verified present. Both task commits (d06e3ab, 87dfa1f) verified in git log.

---
*Phase: 07-apple-intelligence*
*Completed: 2026-02-10*
