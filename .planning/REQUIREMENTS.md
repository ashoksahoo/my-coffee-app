# Requirements

## v1 Requirements

### Equipment Management

- [ ] **EQ-01**: User can add brew methods to their equipment library (V60, AeroPress, Espresso, etc.)
- [ ] **EQ-02**: User can customize which parameters appear per brew method (espresso shows yield/pressure, pour-over shows pour stages)
- [ ] **EQ-03**: User can add grinders with name, type (burr/blade), and numeric setting range
- [ ] **EQ-04**: User can edit equipment details (name, notes, settings)
- [ ] **EQ-05**: User can view usage statistics per equipment (brew count, last used date, favorite beans)
- [ ] **EQ-06**: User can add photos to equipment items
- [ ] **EQ-07**: Equipment data syncs across devices via iCloud

### Coffee Bean Tracking

- [ ] **BEAN-01**: User can add coffee with roaster, origin country, region, variety, processing method, roast level
- [ ] **BEAN-02**: User can set roast date and see "days since roast" displayed prominently
- [ ] **BEAN-03**: User can add photos to coffee entries (bag photos)
- [ ] **BEAN-04**: User can mark beans as active or archived
- [ ] **BEAN-05**: User can scan coffee bag labels with camera to auto-extract roaster, origin, variety, roast date (OCR)
- [ ] **BEAN-06**: User can see visual freshness indicator (green/yellow/red) based on days since roast date
- [ ] **BEAN-07**: User can search coffees by roaster or origin
- [ ] **BEAN-08**: Coffee data syncs across devices via iCloud

### Brew Logging

- [ ] **BREW-01**: User can create new brew log entry
- [ ] **BREW-02**: User can select grinder and set grind setting for the brew
- [ ] **BREW-03**: User can select brew method from their equipment
- [ ] **BREW-04**: User can select coffee from their collection
- [ ] **BREW-05**: User can input dose (coffee weight in grams, 0.1g precision)
- [ ] **BREW-06**: User can input water amount (grams or mL)
- [ ] **BREW-07**: User can see auto-calculated brew ratio (e.g., "1:16.2")
- [ ] **BREW-08**: User can input or use integrated timer for brew time
- [ ] **BREW-09**: User can input water temperature (°C or °F with user preference)
- [ ] **BREW-10**: User can input method-specific parameters (yield/pressure for espresso, pour stages for pour-over, steep time for immersion)
- [ ] **BREW-11**: User can start integrated brew timer with optional step-by-step guidance per method
- [ ] **BREW-12**: User can add photos to brew log entry
- [ ] **BREW-13**: User can rate overall brew quality (1-5 or 1-10 scale)
- [ ] **BREW-14**: User can write freeform tasting notes
- [ ] **BREW-15**: Brew logs sync across devices via iCloud

### Tasting & Flavor Notes

- [ ] **TASTE-01**: User can rate structured tasting attributes (acidity, body, sweetness on 1-5 scale)
- [ ] **TASTE-02**: User can select flavor tags from SCA flavor wheel hierarchy
- [ ] **TASTE-03**: User can add custom flavor tags not in the wheel
- [ ] **TASTE-04**: User can interact with radial flavor wheel UI to select flavors
- [ ] **TASTE-05**: User can view flavor profile visualization for a brew (spider chart, word cloud)
- [ ] **TASTE-06**: User can compare tasting notes side-by-side for two brews
- [ ] **TASTE-07**: Tasting data syncs across devices via iCloud

### History & Search

- [ ] **HIST-01**: User can view chronological list of all brew logs
- [ ] **HIST-02**: User can filter brews by coffee, method, or date range
- [ ] **HIST-03**: User can use advanced search with multi-criteria (coffee + method + date + rating)
- [ ] **HIST-04**: User can view individual brew log detail with all parameters, photos, and tasting notes
- [ ] **HIST-05**: User can see photos in brew log detail view
- [ ] **HIST-06**: User can view statistics dashboard (favorite methods, beans, average ratings, trends over time)
- [ ] **HIST-07**: User can export brew logs as PDF
- [ ] **HIST-08**: User can export brew data as CSV
- [ ] **HIST-09**: User can export individual brew as image

### Sync & Data

- [ ] **SYNC-01**: All data stored locally with SwiftData (iOS 17+)
- [ ] **SYNC-02**: iCloud sync via CloudKit with zero-code SwiftData integration
- [ ] **SYNC-03**: App works offline, syncs when connected
- [ ] **SYNC-04**: Conflict resolution handles simultaneous edits across devices gracefully
- [ ] **SYNC-05**: Photos stored as CloudKit assets with compression

### Apple Intelligence

- [ ] **AI-01**: System extracts flavor descriptors from freeform tasting notes using NaturalLanguage framework
- [ ] **AI-02**: System identifies brewing patterns (preferred grind settings by coffee origin, optimal ratios)
- [ ] **AI-03**: System suggests brew parameters based on similar coffees in history
- [ ] **AI-04**: All ML runs on-device using Foundation Models framework (iOS 26+ with A17 Pro/M1+ graceful degradation)
- [ ] **AI-05**: Insights available through statistics dashboard and individual brew detail views

## v2 Requirements (Deferred)

### Bean Inventory Management
- Bean inventory tracking with remaining weight
- Auto-deduct dose from bag weight per brew
- Low stock alerts
- Bean cost tracking and per-cup cost calculation

### Brew Enhancements
- Clone previous brew functionality
- Water quality parameters (TDS, hardness, mineral content)
- Yield / TDS / extraction % for espresso/refractometer users

### Advanced Features
- Widgets for iOS home screen
- Apple Watch companion app
- Brew templates and recipes library
- Tasting notes templates

## Out of Scope (All Versions)

- **Social/sharing features** — No backend, no social network, no user accounts
- **Bluetooth scale integration** — Manual entry only (complex BLE integration deferred indefinitely)
- **Roaster/bean database** — User-entered data only, no preloaded databases
- **Recipe marketplace** — Not a recipe app, personal journal only
- **Gamification** — No achievements, streaks, or badges
- **Subscription/monetization** — Not relevant for personal use focus
- **Android support** — iOS-only for v1-v3
- **Web app** — Mobile-first, no web interface

## Traceability

| Requirement | Phase | Plan | Status |
|-------------|-------|------|--------|
| EQ-01 | Phase 1 | - | Pending |
| EQ-02 | Phase 1 | - | Pending |
| EQ-03 | Phase 1 | - | Pending |
| EQ-04 | Phase 1 | - | Pending |
| EQ-05 | Phase 1 | - | Pending |
| EQ-06 | Phase 1 | - | Pending |
| EQ-07 | Phase 1 | - | Pending |
| SYNC-01 | Phase 1 | - | Pending |
| SYNC-02 | Phase 1 | - | Pending |
| BEAN-01 | Phase 2 | - | Pending |
| BEAN-02 | Phase 2 | - | Pending |
| BEAN-03 | Phase 2 | - | Pending |
| BEAN-04 | Phase 2 | - | Pending |
| BEAN-05 | Phase 2 | - | Pending |
| BEAN-06 | Phase 2 | - | Pending |
| BEAN-07 | Phase 2 | - | Pending |
| BEAN-08 | Phase 2 | - | Pending |
| BREW-01 | Phase 3 | - | Pending |
| BREW-02 | Phase 3 | - | Pending |
| BREW-03 | Phase 3 | - | Pending |
| BREW-04 | Phase 3 | - | Pending |
| BREW-05 | Phase 3 | - | Pending |
| BREW-06 | Phase 3 | - | Pending |
| BREW-07 | Phase 3 | - | Pending |
| BREW-08 | Phase 3 | - | Pending |
| BREW-09 | Phase 3 | - | Pending |
| BREW-10 | Phase 3 | - | Pending |
| BREW-11 | Phase 3 | - | Pending |
| BREW-12 | Phase 3 | - | Pending |
| BREW-13 | Phase 3 | - | Pending |
| BREW-14 | Phase 3 | - | Pending |
| BREW-15 | Phase 3 | - | Pending |
| TASTE-01 | Phase 4 | - | Pending |
| TASTE-02 | Phase 4 | - | Pending |
| TASTE-03 | Phase 4 | - | Pending |
| TASTE-04 | Phase 4 | - | Pending |
| TASTE-05 | Phase 4 | - | Pending |
| TASTE-06 | Phase 4 | - | Pending |
| TASTE-07 | Phase 4 | - | Pending |
| HIST-01 | Phase 5 | - | Pending |
| HIST-02 | Phase 5 | - | Pending |
| HIST-03 | Phase 5 | - | Pending |
| HIST-04 | Phase 5 | - | Pending |
| HIST-05 | Phase 5 | - | Pending |
| HIST-06 | Phase 5 | - | Pending |
| SYNC-03 | Phase 6 | - | Pending |
| SYNC-04 | Phase 6 | - | Pending |
| SYNC-05 | Phase 6 | - | Pending |
| AI-01 | Phase 7 | - | Pending |
| AI-02 | Phase 7 | - | Pending |
| AI-03 | Phase 7 | - | Pending |
| AI-04 | Phase 7 | - | Pending |
| AI-05 | Phase 7 | - | Pending |
| HIST-07 | Phase 8 | - | Pending |
| HIST-08 | Phase 8 | - | Pending |
| HIST-09 | Phase 8 | - | Pending |

---

*Generated: 2026-02-07 during project initialization*
*Traceability updated: 2026-02-07 during roadmap creation*
