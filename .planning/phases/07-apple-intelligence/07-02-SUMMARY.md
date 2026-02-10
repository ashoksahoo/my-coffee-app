---
phase: 07-apple-intelligence
plan: 02
subsystem: ui, viewmodel
tags: [InsightsViewModel, FlavorInsightView, BrewPatternCard, BrewSuggestionBanner, FlowLayout, monochrome]

# Dependency graph
requires:
  - phase: 07-apple-intelligence
    plan: 01
    provides: InsightsService protocol, InsightsServiceFactory, ExtractedFlavor/BrewPattern/BrewSuggestion types
  - phase: 04-tasting-flavor-notes
    provides: FlowLayout, FlavorTagChipView, TastingNoteEntryView, FlavorProfileView
  - phase: 05-history-search
    provides: StatisticsDashboardView with charts and StatCard
  - phase: 03-brew-logging
    provides: BrewLogDetailView, AddBrewLogView, BrewLogViewModel
provides:
  - InsightsViewModel driving flavor extraction, pattern analysis, and brew suggestion display
  - FlavorInsightView displaying AI-extracted flavors as confidence-weighted monochrome chips
  - BrewPatternCard displaying pattern insights matching StatCard style
  - BrewSuggestionBanner showing parameter suggestions with apply action
  - BrewLogDetailView wired with flavor extraction on appear
  - StatisticsDashboardView wired with pattern analysis insights section
  - AddBrewLogView wired with suggestion banner on bean+method selection
affects: [08-polish-launch]

# Tech tracking
tech-stack:
  added: []
  patterns: [insights-viewmodel-service-bridge, suggestion-apply-pattern, graceful-empty-state-degradation]

key-files:
  created:
    - CoffeeJournal/ViewModels/InsightsViewModel.swift
    - CoffeeJournal/Views/Insights/FlavorInsightView.swift
    - CoffeeJournal/Views/Insights/BrewPatternCard.swift
    - CoffeeJournal/Views/Insights/BrewSuggestionBanner.swift
  modified:
    - CoffeeJournal/Views/Brewing/BrewLogDetailView.swift
    - CoffeeJournal/Views/History/StatisticsDashboardView.swift
    - CoffeeJournal/Views/Brewing/AddBrewLogView.swift
    - Package.swift

key-decisions:
  - "FlavorInsightView returns EmptyView when no flavors extracted -- zero visual footprint graceful degradation"
  - "BrewSuggestionBanner uses local @State isDismissed for dismiss without removing suggestion data"
  - "AddBrewLogView resets showSuggestion=true on bean/method change so dismissed banner reappears for new combinations"
  - "InsightsViewModel.extractFlavors guards against empty text to prevent unnecessary NL processing"

patterns-established:
  - "Insights bridge: InsightsViewModel wraps InsightsServiceFactory.makeService() as single entry point for all insight features"
  - "Suggestion apply: applySuggestion maps BrewSuggestion fields to BrewLogViewModel fields including manual time entry"
  - "Graceful degradation: all insight views handle empty state (EmptyView, conditional rendering) -- no UI shown when no data"

# Metrics
duration: 3min
completed: 2026-02-10
---

# Phase 7 Plan 02: AI Insights UI Summary

**InsightsViewModel + FlavorInsightView/BrewPatternCard/BrewSuggestionBanner wired into brew detail, statistics dashboard, and add brew form with monochrome confidence-weighted display and graceful empty-state degradation**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-10T09:40:28Z
- **Completed:** 2026-02-10T09:43:35Z
- **Tasks:** 2
- **Files modified:** 8 (4 created + 4 modified)

## Accomplishments
- InsightsViewModel drives all three insight features (flavor extraction, pattern analysis, brew suggestions) via InsightsServiceFactory
- FlavorInsightView displays AI-extracted flavors as confidence-weighted monochrome capsule chips using FlowLayout, with high/medium/low confidence visual encoding
- BrewPatternCard displays pattern insights (grind preferences, optimal ratios, method favorites, origin trends) matching existing StatCard monochrome style
- BrewSuggestionBanner shows parameter suggestions with basis count, confidence badge, apply action, and dismiss button
- BrewLogDetailView triggers flavor extraction from freeform tasting notes on view appear
- StatisticsDashboardView shows "Brewing Insights" section with pattern cards after existing charts
- AddBrewLogView shows suggestion banner when bean+method selected, with apply filling all form fields

## Task Commits

Each task was committed atomically:

1. **Task 1: Create InsightsViewModel and insight view components** - `9a6729c` (feat)
2. **Task 2: Wire insight views into BrewLogDetailView, StatisticsDashboardView, and AddBrewLogView** - `a4c63cf` (feat)

## Files Created/Modified
- `CoffeeJournal/ViewModels/InsightsViewModel.swift` - @Observable ViewModel bridging InsightsService to UI with flavor/pattern/suggestion state
- `CoffeeJournal/Views/Insights/FlavorInsightView.swift` - Extracted flavors display with confidence-weighted monochrome capsule chips
- `CoffeeJournal/Views/Insights/BrewPatternCard.swift` - Pattern insight card with category icon matching StatCard style
- `CoffeeJournal/Views/Insights/BrewSuggestionBanner.swift` - Suggestion banner with parameter display, confidence badge, apply and dismiss actions
- `CoffeeJournal/Views/Brewing/BrewLogDetailView.swift` - Added InsightsViewModel, FlavorInsightView in tasting notes section, .task for extraction
- `CoffeeJournal/Views/History/StatisticsDashboardView.swift` - Added InsightsViewModel, insightsSection with BrewPatternCard after charts, .onAppear for analysis
- `CoffeeJournal/Views/Brewing/AddBrewLogView.swift` - Added InsightsViewModel, suggestion section, applySuggestion, onChange triggers, allBrews query
- `Package.swift` - Added 4 new source files to build manifest

## Decisions Made
- FlavorInsightView returns EmptyView when no flavors extracted -- zero visual footprint for graceful degradation
- BrewSuggestionBanner uses local @State isDismissed rather than removing suggestion data from ViewModel
- AddBrewLogView resets showSuggestion=true on bean/method change so dismissed banner reappears for new combinations
- InsightsViewModel guards against empty text in extractFlavors to prevent unnecessary NL processing
- Suggestion apply maps all BrewSuggestion fields to BrewLogViewModel including manual time entry (minutes/seconds)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All Apple Intelligence features (AI-01 through AI-05) now surfaced to users through the insights UI
- Phase 7 complete -- all 2 plans executed (service layer + UI layer)
- Ready for Phase 8 (polish and launch)
- All processing on-device with graceful degradation on unsupported hardware

## Self-Check: PASSED

All 4 created files verified present. Both task commits (9a6729c, a4c63cf) verified in git log.

---
*Phase: 07-apple-intelligence*
*Completed: 2026-02-10*
