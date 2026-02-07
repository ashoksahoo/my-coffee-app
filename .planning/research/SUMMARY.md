# Project Research Summary

**Project:** iOS Coffee Journal App
**Domain:** Specialty coffee brew tracking and journaling (iOS)
**Researched:** 2026-02-07
**Confidence:** MEDIUM-HIGH

## Executive Summary

This is a specialty coffee journal app for iOS that combines Kotlin Multiplatform for shared business logic with native SwiftUI presentation and SwiftData/CloudKit for persistence and sync. The research reveals a clear architectural strategy: leverage Apple's native infrastructure (SwiftData for persistence, CloudKit for zero-code iCloud sync, Foundation Models for on-device AI) while using KMP to encapsulate the coffee-specific business logic (brew ratios, tasting wheel algorithms, freshness calculations). This "shared core + native platform integration" approach is well-documented and proven in production.

The recommended path is to build an iOS-first MVP with table stakes features (bean tracking, brew logging, structured tasting, iCloud sync) using SwiftData + CloudKit for immediate zero-code sync, then layer on Apple Intelligence insights as an optional enhancement in v1.x once iOS 26+ adoption increases. The core risk is CloudKit schema permanence: once deployed to production, the schema follows an "add-only, no-delete, no-change" rule that makes refactoring nearly impossible. This means Phase 1 (data model design) requires extreme care and cannot be rushed.

The competitive landscape shows that no existing iOS coffee journal combines deep brew parameter tracking (Beanconqueror's strength) with beautiful, minimal design (BeanBook's aesthetic) and privacy-first on-device AI. The market gap is clear, and the technical approach is validated by multiple production apps using the same KMP + SwiftUI + CloudKit stack.

## Key Findings

### Recommended Stack

**Core Decision: SwiftData + CloudKit for persistence/sync, KMP for business logic.** This hybrid approach gives free iCloud sync (SwiftData's built-in CloudKit integration) while keeping coffee-specific calculations, validation, and domain logic portable in Kotlin. The KMP shared module produces an XCFramework that Swift ViewModels call into for business rules, while SwiftData handles all persistence and sync.

**Core technologies:**
- **Kotlin 2.3.10 + KMP:** Shared business logic (brew calculations, tasting algorithms, data validation) across potential future platforms
- **SwiftData (iOS 17+):** Native persistence with zero-code CloudKit sync via ModelContainer auto-sync to private database
- **SKIE 0.10.9:** Transforms KMP's Objective-C exports into idiomatic Swift (Flow to AsyncSequence, suspend to async/await with cancellation)
- **SwiftUI + Swift 6:** Native iOS UI with monochrome/e-ink aesthetic for calm, focused design
- **Foundation Models (iOS 26+):** On-device LLM for tasting note suggestions and brew insights (optional, degrades gracefully on older devices)
- **NaturalLanguage + Core ML:** Fallback AI for iOS 17+ (sentiment analysis, flavor classification, custom ML models)

**Critical version note:** SKIE 0.10.9 lists compatibility up to Kotlin 2.3.0; Kotlin 2.3.10 may require SKIE 0.11.x or newer. Verify compatibility before starting.

### Expected Features

**Must have (table stakes):**
- Bean entry with origin details, roast date, photos, freshness indicators
- Equipment management (brew methods, grinders with settings)
- Brew logging with method-specific parameters (espresso vs pour-over vs immersion forms)
- Structured tasting (acidity/body/sweetness sliders, SCA flavor wheel tags, freeform notes)
- Clone previous brew (reduce data entry friction from 2 minutes to 10 seconds)
- Brew history with search/filter
- iCloud sync across devices (multi-device from day one)
- Dark mode, monochrome design system

**Should have (competitive):**
- Apple Intelligence insights ("You rate washed Ethiopians 0.8 points higher than naturals")
- Bean inventory tracking with auto-deduct per brew
- Bag photo OCR for bean data entry (Apple Vision framework)
- Home Screen / Lock Screen widgets (freshness, quick-log)
- PDF journal export (aligns with physical journal aesthetic)
- Integrated brew timer with step-by-step guidance

**Defer (v2+):**
- Bluetooth scale integration (massive effort, Beanconqueror already dominates)
- Apple Watch app
- Siri / Shortcuts integration
- Year in review / monthly summaries (needs calendar year of data)
- Import from other apps (only if user demand is clear)

**Anti-features (deliberately avoid):**
- Social/community brew sharing (violates privacy-first, requires backend)
- Cloud-based AI / ChatGPT integration (sends personal data to external servers)
- Built-in roaster/bean database (maintenance nightmare, stale data, regional bias)
- Gamification (badges, streaks, leaderboards — patronizing to specialty coffee enthusiasts)

### Architecture Approach

**Clean Architecture in KMP shared module with Swift-native platform bridges.** The KMP shared module (commonMain) contains domain models, repository interfaces, use cases, and ViewModels with StateFlow state. Swift provides the platform implementations: Core Data repositories, CloudKit sync monitoring, and Foundation Models AI service. SKIE bridges the boundary, converting Kotlin Flows to Swift AsyncSequence for SwiftUI reactivity. Swift ViewModels wrap KMP ViewModels to integrate with SwiftUI's @Observable pattern.

**Major components:**
1. **SwiftUI Views** — render UI, capture input, display state
2. **Swift ViewModel Wrappers** — bridge KMP ViewModels to SwiftUI reactivity, observe StateFlows via SKIE AsyncSequence
3. **KMP Shared ViewModels** — hold UI state as StateFlow, execute business logic via use cases
4. **Use Cases / Interactors** — encapsulate single business operations (SaveBrewLogUseCase, CalculateBrewRatioUseCase)
5. **Domain Models & Repository Interfaces** — Kotlin data classes + interfaces in commonMain, platform implementations injected via Koin
6. **Core Data Persistence Manager** — Swift class wrapping NSManagedObjectContext, implements repository interfaces
7. **NSPersistentCloudKitContainer** — automatic bidirectional sync to CloudKit private database with offline-first design
8. **Foundation Models Service** — Swift class wrapping LanguageModelSession for on-device AI (iOS 26+ only, graceful degradation)

**Data flow:** User action in SwiftUI -> Swift Wrapper -> KMP ViewModel -> Use Case -> Repository Interface (resolved via Koin to Core Data impl) -> NSManagedObjectContext save -> NSPersistentCloudKitContainer auto-syncs to CloudKit -> remote devices receive push notification -> merge remote changes -> NSFetchedResultsController emits Flow update -> SKIE converts to AsyncSequence -> Swift Wrapper publishes to SwiftUI.

### Critical Pitfalls

1. **CloudKit Schema is Permanent Once Deployed** — Once the Core Data model's CloudKit schema is deployed to production, it follows "add-only, no-delete, no-change" rules. Renaming entities/attributes, changing types, or deleting fields causes data loss and sync failures. The only recovery is migrating to a new CloudKit container (losing all user data). **Prevention:** Design the data model carefully before any TestFlight/App Store release. Use generic, future-proof attribute names. Keep a schema changelog. Test schema deployment in CloudKit Dashboard development environment first.

2. **Core Data + CloudKit Model Constraints Silently Break Sync** — Unique constraints, non-optional relationships without inverses, required attributes without defaults, ordered relationships, and deny delete rules are all unsupported by NSPersistentCloudKitContainer. The app appears to work locally, then sync silently fails or produces duplicates. **Prevention:** Design every entity as if all attributes are optional and all relationships are optional with inverses. Handle uniqueness in application logic using UUID-based deduplication.

3. **KMP/Swift Interop Without SKIE is Hostile** — The default Objective-C bridge produces untyped generics, underscored names, and no async/await support. Kotlin StateFlow is opaque, suspend functions lack cancellation, sealed classes lose exhaustiveness. **Prevention:** Use SKIE from day one. It converts Flows to AsyncSequence, suspend to async/await with cancellation, and sealed classes to Swift enums. Add it to Gradle build before writing any KMP code consumed from Swift.

4. **CloudKit Sync is Untestable on Simulator** — iOS Simulator cannot receive remote push notifications (the mechanism CloudKit uses for real-time sync). Sync appears to work one direction but not the other. **Prevention:** Always test CloudKit sync on two physical devices. Use CloudKit Dashboard to inspect records. Enable verbose CloudKit logging with launch argument `-com.apple.CoreData.CloudKitDebug 1`. Implement a debug sync status UI.

5. **Photo Storage Consumes User's Personal iCloud Quota** — CloudKit private database storage comes from the user's personal iCloud quota (5 GB free tier). Hundreds of high-resolution photos could consume gigabytes, causing user's iCloud backup to fail and quotaExceeded errors. **Prevention:** Compress images aggressively before storing as CKAssets (JPEG 0.5-0.7 quality, max 2048px). Store thumbnails separately. Handle quotaExceeded gracefully with user-facing message. Implement storage budget UI.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Foundation (Data Model + KMP Setup)
**Rationale:** Everything depends on having the data model and KMP-Swift bridge working. CloudKit schema permanence means the data model cannot be refactored after production deployment, so it must be designed correctly upfront. The KMP-to-Swift interop must be validated early to catch issues before the codebase grows.

**Delivers:**
- KMP project skeleton with SKIE, Koin, domain models, repository interfaces
- Core Data model (.xcdatamodeld) matching domain models, validated against CloudKit constraints
- PersistenceController with NSPersistentCloudKitContainer
- Core Data repository implementations in Swift
- One complete vertical slice (Equipment CRUD end-to-end) proving the architecture

**Addresses:**
- Critical Pitfall 1 (CloudKit schema permanence) — data model designed with "add-only" rule in mind
- Critical Pitfall 2 (model constraints) — all relationships optional with inverses, no unique constraints
- Critical Pitfall 3 (KMP interop) — SKIE configured before any Swift code consumes KMP

**Avoids:**
- Rushing data model and needing schema migration later
- Discovering KMP interop issues after building many features
- Building features before persistence layer is stable

### Phase 2: Core Journal Loop (Beans + Brews + Tasting)
**Rationale:** The daily journaling loop (log a brew, add tasting notes) is the product's core value. This phase builds horizontally using the patterns validated in Phase 1. Features are interdependent: every brew references a bean, every brew has tasting notes. Build them together as a cohesive feature set.

**Delivers:**
- Bean management (CRUD with origin details, roast date, photos, freshness indicator)
- Brew log entry with method-specific parameter forms (espresso vs pour-over)
- Structured tasting (sliders, SCA flavor wheel tags, freeform notes)
- Clone previous brew (reduces data entry to 10 seconds)
- Brew history with search/filter
- Basic statistics (total brews, beans tried, top-rated)

**Uses:**
- Established repository pattern from Phase 1
- SKIE for ViewModel reactivity
- PhotosUI for image capture

**Implements:**
- KMP ViewModels for BeanList, BeanDetail, BrewLogEntry, BrewHistory
- Swift ViewModel wrappers with AsyncSequence observation
- Method-specific brew parameter logic in KMP (espresso yield calculations, pour-over ratio validation)

**Avoids:**
- Critical Pitfall 4 (sync untestable) — two-device testing workflow established during this phase
- Critical Pitfall 5 (photo quota) — image compression pipeline designed before photo sync

### Phase 3: Sync & Offline
**Rationale:** CloudKit sync should be enabled early (NSPersistentCloudKitContainer is used from Phase 1) but sync-specific UX and conflict handling come after core features work locally. This phase focuses on the user-facing sync experience and multi-device edge cases.

**Delivers:**
- Sync status indicator in UI
- Offline state handling and graceful degradation
- iCloud account status checks with local-only fallback
- Conflict resolution UX (or explicit acceptance of last-writer-wins)
- Multi-device testing scenarios (same record edited on two offline devices)
- Debug sync UI (last sync time, error count, pending operations)

**Addresses:**
- Critical Pitfall 4 (sync debugging) — CloudKit Dashboard workflow, verbose logging, event notifications
- UX Pitfall (no sync indication) — users see sync status, know when data is safe

**Avoids:**
- Sync issues discovered at TestFlight release
- Data loss from conflict scenarios not considered

### Phase 4: Intelligence (Optional AI Features)
**Rationale:** Apple Intelligence features are additive and require iOS 26+ with specific hardware (iPhone 15 Pro+, A17 Pro chip). They cannot be table stakes. This phase implements AI as an optional enhancement with graceful degradation for unsupported devices. Requires brew history data to be meaningful, so comes after core features.

**Delivers:**
- Foundation Models service implementation (iOS 26+ only)
- Tasting note suggestions based on bean origin, roast level, brew method
- Brew optimization suggestions ("Your last 3 brews with this bean were under-extracted")
- Flavor profile insights ("You rate washed Ethiopians higher than naturals")
- Graceful degradation on unsupported devices (hide features or show explanation)
- Fallback to NaturalLanguage + Core ML for iOS 17-25

**Uses:**
- Foundation Models framework with @Generable types for structured output
- AIService interface defined in KMP, implemented in Swift
- On-device inference (private, no data leaves device)

**Addresses:**
- Critical Pitfall 6 (device/context constraints) — availability checks, feature hidden on incompatible devices
- 4,096 token context window limit — prompts designed to be concise

**Avoids:**
- Building AI into core features (would exclude majority of users)
- Sending personal brew data to external servers

### Phase 5: Polish & Extensions
**Rationale:** After the core journal is working with sync and optional AI, add the "nice-to-have" features that improve usability and retention but are not launch-blocking.

**Delivers:**
- Home Screen / Lock Screen widgets (freshness indicator, last brew summary)
- Bean inventory tracking with auto-deduct per brew
- PDF journal export (beautiful formatted output)
- Shareable brew card (image for social sharing without social features)
- Data export (JSON/CSV for user data ownership)
- Brew comparison / radar charts (side-by-side tasting profiles)

### Phase Ordering Rationale

- **Phase 1 first because:** Data model is nearly irreversible due to CloudKit schema permanence. KMP-Swift bridge must be validated before building features. Everything else depends on persistence working.
- **Phase 2 before sync UX because:** Core features must work locally before worrying about multi-device edge cases. No point syncing an incomplete product.
- **Phase 3 before AI because:** Sync is infrastructure; AI is optional enhancement. Multi-device testing workflow (needed for sync) also validates data integrity needed for AI insights.
- **Phase 4 is optional because:** Foundation Models requires iOS 26+ (limited adoption in early 2026). Cannot be table stakes.
- **Phase 5 is polish because:** Widgets, exports, and comparisons are value-add but not core to journaling.

### Research Flags

**Phases likely needing deeper research during planning:**
- **Phase 2 (Photo handling):** Need to prototype image compression pipeline, test CKAsset upload at scale, verify thumbnail + full-size strategy. Worth a focused research spike before implementation.
- **Phase 4 (Foundation Models integration):** Framework is new (iOS 26 beta), limited production experience. May need experimentation to find optimal prompt structure and @Generable schema. Consider research spike if iOS 26 adoption is high enough to prioritize.

**Phases with standard patterns (skip research-phase):**
- **Phase 1:** KMP + SKIE setup is well-documented. SwiftData + CloudKit setup has extensive Apple documentation and community guides.
- **Phase 2:** CRUD patterns in SwiftUI + Core Data are established. No novel integration.
- **Phase 3:** CloudKit sync monitoring has Apple documentation (TN3164). Established patterns for sync status UI.
- **Phase 5:** WidgetKit, PDF generation, data export are all documented Apple frameworks with clear examples.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Kotlin, KMP, SKIE, SwiftData, CloudKit versions verified via official releases and documentation. Integration patterns proven in production (Duolingo uses KMP, multiple apps use SwiftData + CloudKit). |
| Features | MEDIUM-HIGH | Based on analysis of 8+ competitor apps (Beanconqueror, iBrew, Filtru, BeanBook) and SCA standards. Feature prioritization is well-informed but user testing will validate assumptions. |
| Architecture | MEDIUM-HIGH | Clean Architecture + KMP is officially recommended by JetBrains. NSPersistentCloudKitContainer is Apple's standard approach. Multiple community sources confirm this pattern works at scale. |
| Pitfalls | MEDIUM-HIGH | CloudKit schema permanence and model constraints verified via official Apple documentation and community experience. KMP interop issues documented by Touchlab and community. Foundation Models constraints from Apple TN3193. |

**Overall confidence:** MEDIUM-HIGH

The technical approach is validated and proven. The main uncertainties are: (1) SKIE compatibility with Kotlin 2.3.10 (may need version adjustment), (2) iOS 26 adoption rate for Foundation Models features, (3) user testing of the monochrome design aesthetic with specialty coffee enthusiasts.

### Gaps to Address

- **SKIE + Kotlin 2.3.10 compatibility:** SKIE 0.10.9 documents support up to Kotlin 2.3.0. Need to verify a compatible SKIE version exists for 2.3.10, or pin Kotlin to 2.3.0. Resolve during Phase 1 setup.

- **SwiftData + KMP model mapping best practices:** Mapping between SwiftData @Model classes (Swift) and KMP domain models (Kotlin) needs prototyping. Likely pattern: Swift repositories perform conversion, but optimal strategy needs validation. Prototype during Phase 1 vertical slice.

- **CloudKit container quota for photos:** For an app with photos, CloudKit free tier (1 PB shared, 10 GB per user) should be adequate but worth monitoring. If users hit limits, graceful handling (quotaExceeded error with user message) is already planned. Monitor during TestFlight.

- **iOS 26 / Foundation Models adoption:** Foundation Models requires iOS 26+, which may have limited adoption in early 2026. Decision: implement as optional feature with graceful degradation, but track adoption rate before investing heavily. Re-evaluate during Phase 4 planning.

- **Monochrome design validation:** The e-ink aesthetic is a differentiator but needs user testing. Ensure disabled/loading states are visually distinct without color. Validate during design system development in Phase 2.

## Sources

### Primary (HIGH confidence)
- [Kotlin 2.3.10 release](https://github.com/JetBrains/kotlin/releases) — official GitHub releases
- [SKIE 0.10.9 release](https://github.com/touchlab/SKIE/releases) — official GitHub releases
- [SKIE official documentation](https://skie.touchlab.co/) — feature docs, Flow conversion, sealed class support
- [Apple SwiftData documentation](https://developer.apple.com/documentation/swiftdata) — persistence and CloudKit sync
- [Apple Foundation Models documentation](https://developer.apple.com/documentation/FoundationModels) — confirms iOS 26+ requirement
- [Apple TN3164: Debugging NSPersistentCloudKitContainer](https://developer.apple.com/documentation/technotes/tn3164-debugging-the-synchronization-of-nspersistentcloudkitcontainer) — sync debugging
- [Apple TN3193: Managing Foundation Model Context Window](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window) — 4,096 token limit
- [JetBrains KMP iOS Integration](https://www.jetbrains.com/help/kotlin-multiplatform-dev/multiplatform-ios-integration-overview.html) — official integration methods
- [SCA Coffee Taster's Flavor Wheel](https://sca.coffee/research/coffee-tasters-flavor-wheel) — 9 categories, ~110 descriptors

### Secondary (MEDIUM confidence)
- [Beanconqueror](https://beanconqueror.com/) and [GitHub repo](https://github.com/graphefruit/Beanconqueror) — competitor analysis (open-source, feature set)
- [iBrew Coffee](https://ibrew.coffee/), [Filtru](https://getfiltru.com/), [BeanBook](https://beanbook.app/) — competitor feature comparison
- [fatbobman's CloudKit model rules](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/) — community expert on Core Data + CloudKit
- [Touchlab: iOS framework local or remote](https://touchlab.co/ios-framework-local-or-remote) — KMP integration recommendations
- [KMP + SwiftUI architecture patterns](https://carrion.dev/en/posts/kmp-architecture/) — Clean Architecture with KMP
- [KMP pitfalls and anti-patterns](https://medium.com/@karelvdmmisc/my-journey-with-kotlin-multiplatform-mobile-pitfalls-anti-patterns-and-solutions-525df7058018) — community experience

### Tertiary (LOW confidence)
- Various blog posts and Medium articles on KMP interop, CloudKit debugging, and coffee app UX patterns

---
*Research completed: 2026-02-07*
*Ready for roadmap: yes*
