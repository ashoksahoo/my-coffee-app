# Coffee Journal

A minimal, monochrome iOS app for tracking coffee brewing from grind to cup.

## What This Is

A personal coffee journal that captures the full brewing process — equipment, beans, parameters, and tasting notes. Local-first with iCloud sync across iOS devices. Shipped as a working personal app (v1.0), with App Store release planned for v3.

## Why This Exists

**Core value:** Remember and improve your coffee brewing by tracking what works.

Every coffee enthusiast faces the same challenge: you dial in a perfect cup, but next week with new beans, you can't remember what worked. This journal captures the details that matter — grinder settings, brew parameters, tasting notes — so you can learn from every cup and recreate the great ones.

**Personal motivation:** Weekly new coffee arrivals mean constantly dialing in new beans. Without tracking, every bag starts from scratch. With this journal, patterns emerge: preferred ratios, grind settings that work, flavor profiles you gravitate toward.

## Who This Is For

**Primary:** You (personal use, multiple iOS devices)

**Future:** Coffee enthusiasts who want a minimal, distraction-free brew journal without subscription services or online accounts. Users who value privacy (data stays in their iCloud) and appreciate monochrome, e-ink-friendly design.

## What Done Looks Like

**v1 (Personal use) — ✅ SHIPPED 2026-02-18:**
- Log a brew from equipment selection through tasting notes
- View past brews and search by coffee, method, or date
- Sync seamlessly across iPhone and iPad
- Apple Intelligence surfaces insights from brewing patterns

**v2 (Enhanced tracking):**
- Bean inventory management (track what's on hand, what's running low)
- More sophisticated insights and recommendations
- Clone previous brew, water quality parameters

**v3 (Public release):**
- Bluetooth scale integration for live brew tracking
- App Store polish (onboarding, help, refined UX)
- Public launch

## Current State (v1.0)

**Shipped:** 2026-02-18
**Scale:** ~30,600 Swift LOC across 9 phases, 23 plans, 138 commits
**Tests:** 152 automated tests (119 unit, 23 integration, 10 UI) with GitHub Actions CI
**Architecture:** SwiftUI + SwiftData + CloudKit, iOS 17+ target

## Requirements

### Validated (v1.0)

**Equipment Management:**
- ✓ User can add brew methods to their equipment library — v1.0
- ✓ User can customize which parameters appear per brew method — v1.0
- ✓ User can add grinders with name, type, and numeric setting range — v1.0
- ✓ User can edit equipment details (name, notes, settings) — v1.0
- ✓ User can view usage statistics per equipment (brew count, last used) — v1.0
- ✓ User can add photos to equipment items — v1.0
- ✓ Equipment data syncs across devices via iCloud — v1.0

**Coffee Bean Tracking:**
- ✓ User can add coffee with roaster, origin, region, variety, processing method, roast level — v1.0
- ✓ User can set roast date and see "days since roast" displayed prominently — v1.0
- ✓ User can add photos to coffee entries — v1.0
- ✓ User can mark beans as active or archived — v1.0
- ✓ User can scan coffee bag labels with camera to auto-extract data (OCR) — v1.0
- ✓ User can see visual freshness indicator based on days since roast — v1.0
- ✓ User can search coffees by roaster or origin — v1.0
- ✓ Coffee data syncs across devices via iCloud — v1.0

**Brew Logging:**
- ✓ User can create new brew log entry with grinder, method, coffee — v1.0
- ✓ User can input dose, water amount, temperature with auto-calculated brew ratio — v1.0
- ✓ User can input method-specific parameters (yield/pressure, pour stages, steep time) — v1.0
- ✓ User can use integrated brew timer with optional step-by-step guidance — v1.0
- ✓ User can add photos, rate quality, write freeform tasting notes — v1.0
- ✓ Brew logs sync across devices via iCloud — v1.0

**Tasting & Flavor Notes:**
- ✓ User can rate acidity, body, sweetness on 1–5 scale — v1.0
- ✓ User can select flavors from interactive SCA 2016 flavor wheel — v1.0
- ✓ User can add custom flavor tags — v1.0
- ✓ User can view flavor profile spider chart visualization — v1.0
- ✓ User can compare tasting notes side-by-side for two brews — v1.0
- ✓ Tasting data syncs via iCloud — v1.0

**History & Search:**
- ✓ User can view chronological list of brew logs — v1.0
- ✓ User can filter brews by coffee, method, date range, and rating — v1.0
- ✓ User can view individual brew log detail — v1.0
- ✓ User can view statistics dashboard (methods, beans, trends, patterns) — v1.0
- ✓ User can export brew logs as PDF — v1.0
- ✓ User can export brew data as CSV — v1.0
- ✓ User can export individual brew as shareable image — v1.0

**Sync & Data:**
- ✓ All data stored locally with SwiftData — v1.0
- ✓ iCloud sync via CloudKit with zero-code SwiftData integration — v1.0
- ✓ App works offline, syncs when connected — v1.0
- ✓ Conflict resolution handles simultaneous edits gracefully — v1.0
- ✓ Photos stored as CloudKit assets with compression — v1.0

**Apple Intelligence:**
- ✓ System extracts flavor descriptors from freeform notes (NaturalLanguage) — v1.0
- ✓ System identifies brewing patterns (grind/ratio preferences by origin) — v1.0
- ✓ System suggests brew parameters based on similar coffees in history — v1.0
- ✓ All ML runs on-device, degrades gracefully on unsupported hardware — v1.0
- ✓ Insights in statistics dashboard and brew detail views — v1.0

**Quality:**
- ✓ 152 automated tests across unit, integration, and UI layers — v1.0
- ✓ GitHub Actions CI/CD pipeline with separate unit/UI test jobs — v1.0

### Active (v2 targets)

**Bean Inventory Management:**
- [ ] Bean inventory tracking with remaining weight
- [ ] Auto-deduct dose from bag weight per brew
- [ ] Low stock alerts
- [ ] Bean cost tracking and per-cup cost calculation

**Brew Enhancements:**
- [ ] Clone previous brew functionality
- [ ] Water quality parameters (TDS, hardness, mineral content)
- [ ] Yield / TDS / extraction % for espresso/refractometer users

**Advanced Features:**
- [ ] Widgets for iOS home screen
- [ ] Apple Watch companion app
- [ ] Brew templates and recipes library

### Out of Scope

- **Bluetooth scale integration** — deferred to v3 (requires hardware)
- **Sharing/social features** — explicitly excluded (personal journal, not social)
- **Subscription/monetization** — not planned for v1/v2
- **Android support** — iOS-only through v3
- **Web app** — mobile-first, no web interface planned
- **Roaster database** — not cataloging roasters, user types their own
- **Cupping scores** — personal tasting notes, not professional cupping

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| **Pure Swift + SwiftUI** | Native iOS simplifies v1, better learning curve | ✓ Good — clean codebase, no external deps |
| **CloudKit for sync** | Native Apple solution, no backend, privacy-first | ✓ Good — zero maintenance, users own data |
| **Monochrome design** | Timeless aesthetic, reduces visual noise, e-ink friendly | ✓ Good — distinctive, focused |
| **Apple Intelligence for insights** | On-device ML, privacy-first, leverage Apple models | ✓ Good — Foundation Models ready for iOS 26+ |
| **Structured + freeform tasting notes** | 1–5 scales + flavor wheel + notes — best of both worlds | ✓ Good — SCA wheel well received |
| **Personal use first, App Store later** | Ship when genuinely useful, not when marketable | ✓ Good — pragmatic, no premature polish |
| **All 5 models upfront (Phase 1)** | CloudKit schema is permanent once deployed | ✓ Critical — saved migrations later |
| **Swift Testing for unit tests** | Modern syntax, parallel by default, better ergonomics | ✓ Good — XCTest reserved for integration tests |
| **SwiftData @Query parent/child pattern** | Parent owns searchText, child reinitializes @Query for filtering | ✓ Good — clean search/filter pattern |
| **Flavor tags as JSON string array** | CloudKit compatibility, avoids relationship complexity | ✓ Good — simple, works with `custom:` prefix |
| **Canvas over ZStack for flavor wheel** | Performance with 85+ arc segments | ✓ Good — smooth at 120fps |
| **In-memory ModelContainer per test** | Complete test isolation, no persistent state between runs | ✓ Good — fast, reliable tests |

## Constraints

**Platform:**
- iOS 17+ (SwiftData, CloudKit); Foundation Models requires iOS 26+ with A17 Pro/M1+
- iPhone and iPad supported
- No macOS Catalyst port in v1

**Technical:**
- No backend infrastructure (CloudKit only)
- No external dependencies beyond Apple frameworks
- Must work offline (sync when connected)

**Design:**
- Monochrome only (black on white, white on black)
- No color anywhere
- E-ink display friendly (high contrast, no gradients)

## Non-Goals

- **Social features** — personal journal, not a social network
- **Recipe database** — not a brew guide, suggestions come from personal history only
- **Cupping scores** — personal tasting notes, not professional cupping format
- **Commercial features** — no ads, no subscriptions, no IAP in v1/v2

---

*Last updated: 2026-02-18 after v1.0 milestone*
