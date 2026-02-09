# Roadmap: Coffee Journal

## Overview

This roadmap delivers a local-first iOS coffee journal from foundation to intelligence. The journey starts with the data model and SwiftData/CloudKit setup (critical because CloudKit schema is permanent once deployed), proves the architecture with Equipment CRUD, then builds outward through beans, brew logging, tasting, history, sync UX, AI insights, and data export. Each phase delivers a complete, verifiable capability that builds on the previous.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation + Equipment** - Swift project setup, SwiftData model, CloudKit container, and Equipment CRUD as architecture proof
- [ ] **Phase 2: Coffee Bean Tracking** - Bean management with origin details, roast freshness, photos, and search
- [ ] **Phase 3: Brew Logging** - Core journaling loop: create brew entries with parameters, timer, and photos
- [ ] **Phase 4: Tasting & Flavor Notes** - Structured tasting attributes, SCA flavor wheel, visualizations, and brew comparison
- [ ] **Phase 5: History & Search** - Browse, filter, search brew logs and view statistics dashboard
- [ ] **Phase 6: Sync & Offline** - User-facing sync experience: offline mode, conflict resolution, sync status
- [ ] **Phase 7: Apple Intelligence** - On-device AI for flavor extraction, pattern recognition, and brew suggestions
- [ ] **Phase 8: Data Export** - Export brew data as PDF, CSV, and shareable images

## Phase Details

### Phase 1: Foundation + Equipment
**Goal**: Users can manage their coffee equipment while the app proves its full technical stack end-to-end
**Depends on**: Nothing (first phase)
**Requirements**: EQ-01, EQ-02, EQ-03, EQ-04, EQ-05, EQ-06, EQ-07, SYNC-01, SYNC-02
**Success Criteria** (what must be TRUE):
  1. User can add a brew method (e.g., V60, AeroPress) and see it in their equipment library
  2. User can add a grinder with name, type, and setting range, and later edit its details
  3. User can customize which brew parameters appear for each method (espresso shows yield/pressure, pour-over shows pour stages)
  4. User can see usage statistics for any piece of equipment (brew count, last used, favorite beans)
  5. Equipment data persists across app launches and syncs to another iOS device via iCloud
**Plans**: 5 plans

Plans:
- [ ] 01-01-PLAN.md -- Xcode project, SwiftData models (all entities for CloudKit permanence), VersionedSchema, design system
- [ ] 01-02-PLAN.md -- First-launch setup wizard (method selection, grinder entry, skip flow)
- [ ] 01-03-PLAN.md -- Equipment list screens (Methods + Grinders) with add, delete, empty states
- [ ] 01-04-PLAN.md -- Equipment detail/edit views with photos and pre-configured parameters
- [ ] 01-05-PLAN.md -- App navigation wiring (routing, tabs, settings, end-to-end verification)

### Phase 2: Coffee Bean Tracking
**Goal**: Users can catalog their coffee beans with full origin details and track freshness
**Depends on**: Phase 1
**Requirements**: BEAN-01, BEAN-02, BEAN-03, BEAN-04, BEAN-05, BEAN-06, BEAN-07, BEAN-08
**Success Criteria** (what must be TRUE):
  1. User can add a coffee with roaster, origin, region, variety, processing method, and roast level
  2. User can see "days since roast" and a visual freshness indicator that updates daily
  3. User can scan a coffee bag label with their camera and have roaster, origin, variety, and roast date auto-populated
  4. User can search their coffee collection by roaster or origin and archive beans no longer in use
  5. Coffee data syncs across devices via iCloud
**Plans**: 2 plans

Plans:
- [ ] 02-01-PLAN.md -- Bean enums, freshness calculator, CRUD views (list with search/archive, add, detail/edit), Beans tab wiring
- [ ] 02-02-PLAN.md -- Camera bag label OCR scanning with heuristic parsing and review flow

### Phase 3: Brew Logging
**Goal**: Users can log a complete brew from equipment selection through final parameters
**Depends on**: Phase 1, Phase 2
**Requirements**: BREW-01, BREW-02, BREW-03, BREW-04, BREW-05, BREW-06, BREW-07, BREW-08, BREW-09, BREW-10, BREW-11, BREW-12, BREW-13, BREW-14, BREW-15
**Success Criteria** (what must be TRUE):
  1. User can create a brew log selecting their grinder (with setting), brew method, and coffee from their collections
  2. User can enter dose, water amount, temperature, and brew time, and see the brew ratio auto-calculated
  3. User can enter method-specific parameters (yield/pressure for espresso, pour stages for pour-over, steep time for immersion)
  4. User can use an integrated brew timer with optional step-by-step guidance for the selected method
  5. User can add photos, rate overall quality, write freeform tasting notes, and have the brew log sync across devices
**Plans**: 3 plans

Plans:
- [ ] 03-01-PLAN.md -- BrewLog model update, BrewLogViewModel, AddBrewLogView form with equipment/bean selection, core parameters, ratio, rating, notes
- [ ] 03-02-PLAN.md -- Brew timer with state machine controls, step-by-step guidance per method category
- [ ] 03-03-PLAN.md -- Brew log list/detail views, photo support, Brews tab wiring as first tab

### Phase 4: Tasting & Flavor Notes
**Goal**: Users can capture structured tasting profiles and compare brews visually
**Depends on**: Phase 3
**Requirements**: TASTE-01, TASTE-02, TASTE-03, TASTE-04, TASTE-05, TASTE-06, TASTE-07
**Success Criteria** (what must be TRUE):
  1. User can rate acidity, body, and sweetness on a 1-5 scale for any brew
  2. User can select flavors from an interactive radial SCA flavor wheel and add custom flavor tags
  3. User can view a flavor profile visualization (spider chart or word cloud) for any brew
  4. User can compare tasting notes side-by-side for two different brews
  5. Tasting data syncs across devices via iCloud
**Plans**: 3 plans

Plans:
- [ ] 04-01-PLAN.md -- Data layer, tasting entry form with attribute sliders, flavor tag selection, BrewLog inverse relationship
- [ ] 04-02-PLAN.md -- Interactive radial SCA flavor wheel with drill-down and integration into entry form
- [ ] 04-03-PLAN.md -- Spider chart, flavor profile visualization, and side-by-side brew comparison view

### Phase 5: History & Search
**Goal**: Users can browse, search, and analyze their brewing history
**Depends on**: Phase 3, Phase 4
**Requirements**: HIST-01, HIST-02, HIST-03, HIST-04, HIST-05, HIST-06
**Success Criteria** (what must be TRUE):
  1. User can scroll through a chronological list of all brew logs
  2. User can filter brews by coffee, method, or date range, and combine multiple criteria in an advanced search
  3. User can tap any brew log to see its full detail: parameters, photos, and tasting notes
  4. User can view a statistics dashboard showing favorite methods, top beans, average ratings, and trends over time
**Plans**: TBD

Plans:
- [ ] 05-01: Brew history list, filtering, and advanced search
- [ ] 05-02: Brew detail view and statistics dashboard

### Phase 6: Sync & Offline
**Goal**: Users experience reliable, transparent data sync across devices with graceful offline behavior
**Depends on**: Phase 1
**Requirements**: SYNC-03, SYNC-04, SYNC-05
**Success Criteria** (what must be TRUE):
  1. App works fully offline and syncs automatically when connectivity returns
  2. When the same record is edited on two offline devices, conflicts are resolved gracefully without data loss
  3. Photos are stored as compressed CloudKit assets and sync across devices without consuming excessive iCloud quota
**Plans**: TBD

Plans:
- [ ] 06-01: Offline mode, sync status UI, conflict resolution, and photo compression

### Phase 7: Apple Intelligence
**Goal**: Users receive AI-powered insights about their brewing patterns and flavor preferences, all processed on-device
**Depends on**: Phase 3, Phase 4, Phase 5
**Requirements**: AI-01, AI-02, AI-03, AI-04, AI-05
**Success Criteria** (what must be TRUE):
  1. System extracts flavor descriptors from freeform tasting notes and surfaces them in the brew detail view
  2. System identifies brewing patterns (preferred grind settings by origin, optimal ratios) and displays them in the statistics dashboard
  3. When logging a new brew with a similar coffee, system suggests brew parameters based on past successful brews
  4. All ML processing runs on-device with no data sent to external servers, and features degrade gracefully on unsupported hardware
**Plans**: TBD

Plans:
- [ ] 07-01: NaturalLanguage flavor extraction and Foundation Models service
- [ ] 07-02: Pattern recognition, brew suggestions, and insights integration

### Phase 8: Data Export
**Goal**: Users can export their brewing data in multiple formats for sharing and archival
**Depends on**: Phase 5
**Requirements**: HIST-07, HIST-08, HIST-09
**Success Criteria** (what must be TRUE):
  1. User can export a collection of brew logs as a formatted PDF journal
  2. User can export brew data as a CSV file for spreadsheet analysis
  3. User can export an individual brew as a shareable image
**Plans**: TBD

Plans:
- [ ] 08-01: PDF and CSV export
- [ ] 08-02: Individual brew image export

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8

Note: Phase 6 (Sync & Offline) depends only on Phase 1 and can be executed in parallel with Phases 2-5 if desired, but is sequenced here after Phase 5 to allow sync testing with real data across all entity types.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation + Equipment | 0/5 | Planning complete | - |
| 2. Coffee Bean Tracking | 0/2 | Planning complete | - |
| 3. Brew Logging | 0/3 | Planning complete | - |
| 4. Tasting & Flavor Notes | 0/3 | Planning complete | - |
| 5. History & Search | 0/2 | Not started | - |
| 6. Sync & Offline | 0/1 | Not started | - |
| 7. Apple Intelligence | 0/2 | Not started | - |
| 8. Data Export | 0/2 | Not started | - |
