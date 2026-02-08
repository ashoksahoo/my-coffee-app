# Coffee Journal

A minimal, monochrome iOS app for tracking coffee brewing from grind to cup.

## What This Is

A personal coffee journal that captures the full brewing process — equipment, beans, parameters, and tasting notes. Local-first with iCloud sync across iOS devices. Built for personal use first, then polished for App Store release.

## Why This Exists

**Core value:** Remember and improve your coffee brewing by tracking what works.

Every coffee enthusiast faces the same challenge: you dial in a perfect cup, but next week with new beans, you can't remember what worked. This journal captures the details that matter — grinder settings, brew parameters, tasting notes — so you can learn from every cup and recreate the great ones.

**Personal motivation:** Weekly new coffee arrivals mean constantly dialing in new beans. Without tracking, every bag starts from scratch. With this journal, patterns emerge: preferred ratios, grind settings that work, flavor profiles you gravitate toward.

## Who This Is For

**Primary:** You (personal use, multiple iOS devices)

**Future:** Coffee enthusiasts who want a minimal, distraction-free brew journal without subscription services or online accounts. Users who value privacy (data stays in their iCloud) and appreciate monochrome, e-ink-friendly design.

## What Done Looks Like

**v1 (Personal use):**
- Log a brew from equipment selection through tasting notes
- View past brews and search by coffee, method, or date
- Sync seamlessly across iPhone and iPad
- Apple Intelligence surfaces insights from brewing patterns

**v2 (Enhanced tracking):**
- Bean inventory management (track what's on hand, what's running low)
- More sophisticated insights and recommendations

**v3 (Public release):**
- Bluetooth scale integration for live brew tracking
- App Store polish (onboarding, help, refined UX)
- Public launch

## Requirements

### Validated

(None yet — this is a greenfield project)

### Active

**Equipment Management:**
- [ ] User can add grinders to their equipment list
- [ ] User can add brew equipment (V60, Aeropress, espresso machine, etc.)
- [ ] User can edit equipment details (name, notes)
- [ ] Equipment persists across devices via iCloud

**Coffee Tracking:**
- [ ] User can add new coffee with roaster, origin, roast date, variety
- [ ] User can view list of coffees they've logged
- [ ] User can search coffees by roaster or origin
- [ ] Coffee data syncs via iCloud

**Brew Logging:**
- [ ] User can create new brew log entry
- [ ] User can select grinder and set grind setting for the brew
- [ ] User can select brew method from their equipment
- [ ] User can select coffee from their collection
- [ ] User can input brew parameters (dose, water, time, temperature)
- [ ] Parameters adapt based on brew method selected
- [ ] User can add photos to brew log
- [ ] User can rate structured attributes (acidity, body, sweetness on 1-5 scale)
- [ ] User can select flavor tags from SCA flavor wheel
- [ ] User can add custom flavor tags
- [ ] User can write freeform tasting notes
- [ ] Brew logs sync across devices via iCloud

**Viewing & Search:**
- [ ] User can view chronological list of brew logs
- [ ] User can filter brews by coffee, method, or date
- [ ] User can view individual brew log with all details
- [ ] User can see photos in brew log detail view

**Apple Intelligence Integration:**
- [ ] System extracts flavor notes from freeform text
- [ ] System identifies brewing patterns (preferred settings by coffee origin)
- [ ] System suggests brew parameters based on similar coffees
- [ ] All ML runs on-device (no cloud processing)

**Sync & Data:**
- [ ] All data stored locally with Core Data
- [ ] iCloud sync via CloudKit
- [ ] Conflict resolution for simultaneous edits across devices
- [ ] Works offline, syncs when connected

### Out of Scope (v1)

- **Bean inventory tracking** — deferred to v2 (focus v1 on logging, not inventory management)
- **Bluetooth scale integration** — deferred to v3 (requires hardware, adds complexity)
- **Sharing/social features** — explicitly excluded (personal journal, not social network)
- **Subscription/monetization** — not relevant for v1 personal use
- **Android support** — iOS-only for v1-v3, cross-platform later if needed
- **Web app** — mobile-first, no web interface planned
- **Export/backup beyond iCloud** — iCloud is sufficient for v1

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| **Pure Swift + SwiftUI** | Native iOS development simplifies v1. SwiftUI for UI, SwiftData for persistence, CloudKit for sync. Can add cross-platform later if needed. Better learning curve than KMP for Swift beginners. | ✓ Adopted — Swift-only for v1 |
| **CloudKit for sync** | Native Apple solution, no backend to maintain, respects user privacy. Users own their data in their iCloud. | ✓ Adopted — iCloud-only, no custom backend |
| **Monochrome design** | Black and white only, e-ink friendly. Timeless aesthetic, reduces visual noise, focuses on content. | ✓ Adopted — no color anywhere in the app |
| **Apple Intelligence for insights** | On-device ML, no cloud processing, privacy-first. Leverage Apple's models rather than building custom ML. | ✓ Adopted — system-level AI, no custom models |
| **Structured + freeform tasting notes** | Hybrid approach: structured fields (acidity, body, sweetness) give ML patterns to analyze, flavor tags build vocabulary, freeform notes capture nuance. Best of both worlds. | ✓ Adopted — 1-5 scales + flavor wheel + notes |
| **Personal use first, App Store later** | Build for yourself removes pressure to polish prematurely. Ship when it's genuinely useful, not when it's marketable. v1 = working app, v3 = public release. | ✓ Adopted — pragmatic scope for v1 |

## Constraints

**Platform:**
- iOS 17+ only (requires latest CloudKit and Apple Intelligence APIs)
- iPhone and iPad supported
- No macOS Catalyst port in v1

**Technical:**
- No backend infrastructure (CloudKit only)
- No external dependencies beyond Apple frameworks
- Must work offline (sync when connected)
- Must handle iCloud sync conflicts gracefully

**Design:**
- Monochrome only (black on white, white on black)
- No color anywhere
- E-ink display friendly (high contrast, no gradients)

**Personal:**
- Learning Swift from scratch (native iOS development)
- Weekly new coffee arrivals (frequent new coffee entries)
- iPhone + iPad sync required

## Open Questions

- **Brew parameters by method:** Should we pre-populate recommended parameters per brew method, or let users define their own? (e.g., espresso defaults to 18g dose, 36g yield)
- **Flavor wheel implementation:** Full SCA wheel with all tiers, or simplified top-level categories?
- **Photo storage:** CloudKit asset storage limits? Need compression strategy?
- **Apple Intelligence availability:** What iOS 17+ features are actually available for on-device inference?

## Non-Goals

- **Social features** — Not building a community, not building sharing/following
- **Recipe database** — Not a brew guide, not suggesting recipes (beyond personal patterns)
- **Roaster database** — Not cataloging roasters, user types their own
- **Cupping scores** — Not professional cupping, just personal tasting notes
- **Commercial features** — No ads, no subscriptions, no in-app purchases in v1

---

*Last updated: 2026-02-07 after initialization*
