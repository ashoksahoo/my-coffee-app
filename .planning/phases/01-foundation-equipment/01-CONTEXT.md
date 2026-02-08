# Phase 1: Foundation + Equipment - Context

**Gathered:** 2026-02-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Equipment management for coffee brewing — users manage brew methods (V60, AeroPress, Espresso, etc.) and grinders with method-specific brew parameters. Establishes SwiftUI + SwiftData + CloudKit foundation.

This phase delivers equipment CRUD only. Bean tracking, brew logging, and tasting notes are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Equipment setup flow
- Quick setup wizard on first launch (skip-able)
- If skipped: no equipment at all (empty state)
- Wizard can be re-accessed from settings anytime
- Method selection: curated common list (V60, AeroPress, Espresso, French Press, Chemex, Moka Pot, etc.)
- Grinder entry in wizard: just name and type (quick entry)
- After wizard completion: navigate to equipment library screen

### Method parameter configuration
- **v1 approach:** Pre-configured parameters per method type (no user customization)
- **Espresso parameters:**
  - Dose (g) — required
  - Yield (g) — required
  - Time — required
  - Water temperature — required
  - Pressure profile — optional field
- **Pour-over parameters** (V60, Chemex, etc.):
  - Dose (g) — required
  - Water amount (g) — required
  - Time — required
- **Other methods** (AeroPress, French Press, Moka Pot):
  - Generic parameter set (dose, water, time, temperature)

### Equipment organization
- Two separate screens: Methods and Grinders (not tabs, not single list)
- Equipment photos: replace default icons in list view

### Usage statistics
- Required stats: brew count, last used date
- Equipment photos appear as equipment icons in list

### Claude's Discretion
- Method display style in list (cards vs simple list vs grid — choose based on monochrome design constraints)
- Equipment reordering capability (manual vs auto-sorted)
- Edit/delete interaction pattern (swipe vs tap-detail vs long-press — use iOS-standard patterns)
- Usage statistics placement (inline in list, detail only, or both)
- Additional statistics beyond brew count and last used (e.g., favorite beans, average rating)
- Empty state handling for equipment with zero brews

</decisions>

<specifics>
## Specific Ideas

- Monochrome design constraint: all UI must work in black and white only (no color)
- SwiftData for persistence (iOS 17+), CloudKit for zero-code iCloud sync
- CloudKit schema permanence: data model must be designed carefully in this phase (can't change schema after deployment)

</specifics>

<deferred>
## Deferred Ideas

- **Parameter customization (v2):** User-configurable parameters per method — "advanced settings" feature
- **Pour profile tracking (v2):** Pour stages, bloom time, drawdown for pour-over methods
- **Pressure profile details (v2):** Pre-infusion time, ramp patterns for espresso

</deferred>

---

*Phase: 01-foundation-equipment*
*Context gathered: 2026-02-08*
