# Stack Research

**Domain:** iOS Coffee Journal App (Kotlin Multiplatform + SwiftUI)
**Researched:** 2026-02-07
**Confidence:** MEDIUM-HIGH (versions verified via GitHub releases; some integration patterns based on community consensus)

---

## Critical Architecture Decision: Data Layer Strategy

Before detailing the stack, the most consequential decision in this project must be addressed: **where the data layer lives**.

The project context states "Core Data for local storage" with "CloudKit for iCloud sync." However, Kotlin Multiplatform introduces a fundamental tension:

**Option A: SwiftData + CloudKit (iOS-native data layer)**
- SwiftData gives you free, zero-code iCloud sync via CloudKit.
- But SwiftData is Swift-only. KMP shared module CANNOT access it. Business logic that touches data must live in Swift, not Kotlin.
- KMP becomes limited to utility functions, pure domain logic, and models that get mapped to/from SwiftData.

**Option B: SQLDelight in KMP shared module + CKSyncEngine (custom sync)**
- Full data layer in Kotlin, shared across platforms.
- Requires writing custom CloudKit sync code in the iOS `iosMain` source set using CKSyncEngine (iOS 17+).
- More work upfront, but business logic is fully portable.

**Option C (Recommended): SwiftData + CloudKit for persistence/sync, KMP for domain logic and business rules**
- SwiftData handles persistence and iCloud sync (its strongest suit).
- KMP shared module contains: domain models, business rules, brew ratio calculations, tasting profile analysis, data validation, and formatting logic.
- Swift ViewModels bridge between SwiftData and KMP shared logic.
- Best of both worlds: free CloudKit sync AND shared business logic.

**Recommendation: Option C.** For an iOS-first app with v1 targeting personal use and v3 targeting App Store, leveraging SwiftData's built-in CloudKit sync eliminates an entire category of bugs and complexity. KMP's value is in the shared business logic layer -- brew calculations, tasting wheel algorithms, grind size recommendations -- not in reimplementing Apple's sync infrastructure.

**Confidence: HIGH** -- This is consistent with the KMP best practice of "shared core + native platform integration" documented by JetBrains and Google.

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| Kotlin | 2.3.10 | KMP shared module language | Latest stable (Feb 5, 2026). Required for KMP. | HIGH -- verified via [GitHub releases](https://github.com/JetBrains/kotlin/releases) |
| Kotlin Multiplatform | (Gradle plugin, matches Kotlin version) | Shared business logic across platforms | Stable since Nov 2023. Google-recommended for cross-platform logic sharing. Duolingo ships to 40M+ users with KMP. | HIGH |
| Swift 6 / SwiftUI | Ships with Xcode 16+ | iOS UI framework | Native, first-class Apple support. SwiftUI is the standard for new iOS apps targeting iOS 17+. | HIGH |
| SwiftData | iOS 17+ (ships with OS) | Local persistence | Replaces Core Data for new projects. Built-in CloudKit sync with zero code. Swift-native, works seamlessly with SwiftUI via `@Query` and `@Model`. | HIGH -- [Apple docs](https://developer.apple.com/documentation/swiftdata), [multiple 2025 sources](https://www.hackingwithswift.com/quick-start/swiftdata/swiftdata-vs-core-data) |
| CloudKit (via SwiftData) | iOS 17+ (ships with OS) | iCloud sync | SwiftData's `ModelContainer` auto-syncs to CloudKit private database. Zero sync code required. Handles offline, conflict resolution, and background sync. | HIGH -- [Apple documentation](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices) |
| Xcode | 16.x+ | IDE and build system | Required for iOS development. Builds both Swift and KMP framework. | HIGH |

### Kotlin Multiplatform Shared Module Libraries

| Library | Version | Purpose | Why Recommended | Confidence |
|---------|---------|---------|-----------------|------------|
| kotlinx.coroutines | 1.10.2 | Async operations in shared code | Standard for KMP async. Flow maps to Swift AsyncSequence via SKIE. | HIGH -- verified via [GitHub releases](https://github.com/Kotlin/kotlinx.coroutines/releases) |
| kotlinx.serialization | 1.9.0+ | JSON serialization for shared models | Standard KMP serialization. Compile-time safe. Used for import/export features. | HIGH -- verified via [GitHub releases](https://github.com/Kotlin/kotlinx.serialization/releases) |
| kotlinx-datetime | 0.7.1 | Date/time handling in shared code | Multiplatform date/time library. Critical for brew timestamps, freshness calculations. | MEDIUM -- version from [Maven Central](https://mvnrepository.com/artifact/org.jetbrains.kotlinx/kotlinx-datetime) |
| SKIE | 0.10.9 | Enhanced Swift interop for KMP | Transforms KMP's Objective-C exports into idiomatic Swift. Maps Kotlin Flow to Swift AsyncSequence, supports async/await with cancellation. Used by Mapbox in production. | HIGH -- verified via [GitHub releases](https://github.com/touchlab/SKIE/releases), [official site](https://skie.touchlab.co/) |
| Koin | 4.1.1 (stable) | Dependency injection in shared module | Lightweight, Kotlin-first DI. Official KMP support. No code generation (faster builds). | HIGH -- verified via [GitHub releases](https://github.com/InsertKoinIO/koin/releases) |

### iOS-Native Libraries (Swift Side)

| Library | Version | Purpose | Why Recommended | Confidence |
|---------|---------|---------|-----------------|------------|
| SwiftData | iOS 17+ | Persistence + CloudKit sync | See architecture decision above. Free iCloud sync. | HIGH |
| PhotosUI / PhotosPicker | iOS 17+ | Photo capture for brew logs | Native SwiftUI component. No third-party library needed. | HIGH |
| NaturalLanguage framework | iOS 11+ (enhanced in iOS 17) | Tasting note analysis | Built-in sentiment analysis (score -1 to +1), tokenization, NER. Free, fast, works offline, zero app size increase. | HIGH -- [Apple docs](https://developer.apple.com/documentation/naturallanguage) |
| Core ML | iOS 17+ | Custom ML models for brew recommendations | On-device inference. Can use Create ML to train custom models for flavor profiling. Privacy-preserving. | HIGH -- [Apple docs](https://developer.apple.com/documentation/coreml) |
| Charts (Swift Charts) | iOS 17+ | Brew history visualization | First-party Apple framework. Declarative API matches SwiftUI patterns. | HIGH |
| WidgetKit | iOS 17+ | Home screen widgets | For quick-glance brew stats, last brew info. Enhances daily-use value. | HIGH |

### Development Tools

| Tool | Purpose | Notes | Confidence |
|------|---------|-------|------------|
| Xcode 16+ | iOS build, signing, testing | Primary IDE for Swift/SwiftUI code | HIGH |
| Android Studio / Fleet | KMP shared module development | IntelliJ-based IDE for Kotlin code. Fleet has KMP plugin support. | HIGH |
| SKIE Gradle Plugin | Build-time Swift API enhancement | Add to KMP module's build.gradle.kts. Runs during framework compilation. | HIGH |
| Gradle 8.x | KMP build system | KMP requires Gradle. Use Kotlin DSL (build.gradle.kts). | HIGH |
| SwiftLint | Swift code style | Optional but recommended for consistency | MEDIUM |
| CloudKit Dashboard | CloudKit schema management, debugging | Web-based tool at developer.apple.com. Essential for debugging sync issues. | HIGH |

---

## SwiftData vs Core Data: Why SwiftData

The project context mentions "Core Data for local storage." **Recommendation: Use SwiftData instead.**

| Criterion | SwiftData | Core Data |
|-----------|-----------|-----------|
| CloudKit sync setup | Zero code -- just enable iCloud capability | Requires NSPersistentCloudKitContainer configuration |
| SwiftUI integration | Native (`@Model`, `@Query`, `@Environment`) | Requires wrappers, `@FetchRequest` is less ergonomic |
| Schema definition | Swift classes with `@Model` macro | .xcdatamodeld XML files |
| Migration | `VersionedSchema` + `SchemaMigrationPlan` | NSMappingModel, heavyweight migrations |
| Learning curve | Low for new projects | High, decades of legacy patterns |
| iOS 17+ target | Yes, designed for it | Yes, but feels legacy |
| Performance | Slightly slower than Core Data for large datasets | More optimized for bulk operations |
| KMP compatibility | Neither is accessible from Kotlin (both Swift-only) | Neither is accessible from Kotlin |

**Key insight:** Since neither SwiftData nor Core Data can be accessed from Kotlin code (both are Swift-only frameworks), the KMP integration story is identical for both. SwiftData wins on developer experience and CloudKit integration.

**CloudKit constraints with SwiftData:**
- Cannot use `@Attribute(.unique)` on synced properties
- All properties must have defaults or be optional
- All relationships must be optional
- Only syncs to CloudKit private database (not public or shared)
- Sync only works on physical devices, not Simulator

**Confidence: HIGH** -- Multiple 2025 sources agree. Apple's direction is clearly toward SwiftData.

---

## Apple Intelligence / ML Strategy

### The iOS 26 Problem

Apple's Foundation Models framework (announced WWDC 2025) provides on-device LLM access with structured output via `@Generable` macro. However, it requires **iOS 26+** (devices with A17 Pro or later).

Since this project targets **iOS 17+**, Foundation Models framework is NOT available.

### Recommended ML Stack for iOS 17+

| Framework | What It Does | Use Case in Coffee App | Confidence |
|-----------|-------------|----------------------|------------|
| **NaturalLanguage** | Built-in NLP: sentiment, tokenization, NER, language detection | Analyze tasting notes sentiment ("bright," "bitter," "smooth"). Classify flavor descriptors. | HIGH |
| **Core ML** | Run trained ML models on-device | Custom flavor profile predictor. Brew parameter optimizer based on past brews. | HIGH |
| **Create ML** | Train models on Mac with no code | Train tasting note classifier, brew quality predictor from user data | HIGH |
| **Vision** | Image analysis | Analyze coffee photos for color/roast level estimation | MEDIUM |

### Future-Proofing for Foundation Models (iOS 26+)

When the minimum deployment target moves to iOS 26, you can add:
- `@Generable` structured output for natural language brew descriptions
- On-device summarization of tasting note history
- Conversational brew assistant ("What should I brew with these Ethiopian beans?")

**Strategy:** Build the ML feature layer behind a protocol/interface. Start with NaturalLanguage + Core ML. Swap in Foundation Models when iOS 26 is the minimum target.

**Confidence: HIGH** for NaturalLanguage/CoreML availability on iOS 17. HIGH for Foundation Models requiring iOS 26 -- [verified via Apple Developer docs](https://developer.apple.com/documentation/FoundationModels) and [WWDC25 session](https://developer.apple.com/videos/play/wwdc2025/286/).

---

## KMP + SwiftUI Integration Pattern

### How It Works

```
+----------------------------------+
|        iOS App (Swift)           |
|                                  |
|  SwiftUI Views                   |
|       |                          |
|  Swift ViewModels                |
|       |           |              |
|  SwiftData     SharedKit.framework
|  (persistence)   (KMP shared)   |
|       |                          |
|  CloudKit (auto-sync)           |
+----------------------------------+

SharedKit.framework contains:
- Domain models (BrewParameters, TastingProfile, etc.)
- Business rules (brew ratio calculator, extraction time)
- Tasting wheel logic (flavor categorization)
- Data validation (grind size ranges, temperature bounds)
- Import/export formatting (JSON, CSV)
```

### Integration Flow

1. **KMP shared module** produces an XCFramework (`SharedKit.framework`)
2. **SKIE** transforms the Objective-C interface into idiomatic Swift
3. **Swift ViewModels** call into SharedKit for business logic
4. **Swift ViewModels** call into SwiftData for persistence
5. **SwiftUI Views** observe ViewModels via `@Observable`

### Expect/Actual for Platform Features

```kotlin
// commonMain
expect class PlatformContext

// iosMain
actual class PlatformContext {
    // iOS-specific platform capabilities
}
```

**Confidence: HIGH** -- This "shared core + native UI" pattern is the [recommended approach](https://kotlinlang.org/multiplatform/) by JetBrains and documented extensively.

---

## Framework Integration Method

### Recommended: Direct Framework Integration

For a single-developer, iOS-only KMP project, use **direct integration** (not CocoaPods or SPM).

| Method | Recommendation | Reason |
|--------|---------------|--------|
| Direct integration | **Recommended** | Simplest for local development. KMP Gradle plugin builds the framework; Xcode links it directly. No package manager overhead. |
| CocoaPods | Alternative | Works well, but adds CocoaPods dependency. Must use `.xcworkspace` instead of `.xcodeproj`. |
| SPM (via KMMBridge) | Not recommended for local dev | SPM integration with KMP requires KMMBridge and extra config. Better for distributing KMP libraries to external consumers. |

**Setup in `build.gradle.kts`:**
```kotlin
kotlin {
    listOf(iosArm64(), iosSimulatorArm64()).forEach { target ->
        target.binaries.framework {
            baseName = "SharedKit"
            isStatic = true
        }
    }
}
```

**Confidence: HIGH** -- [Touchlab recommends](https://touchlab.co/ios-framework-local-or-remote) direct linking for local development.

---

## Version Compatibility Matrix

| Component | Version | Compatible With | Notes | Confidence |
|-----------|---------|-----------------|-------|------------|
| Kotlin | 2.3.10 | Compose Multiplatform 1.10.0 | Latest stable as of Feb 2026 | HIGH |
| SKIE | 0.10.9 | Kotlin 2.0.0 - 2.3.0 | Check SKIE changelog for 2.3.10 compatibility; may need patch update | MEDIUM |
| Koin | 4.1.1 | Kotlin 2.0+ | Stable release. 4.2.0-RC1 available but not yet stable. | HIGH |
| kotlinx.coroutines | 1.10.2 | Kotlin 2.1.0+ | Stable | HIGH |
| kotlinx.serialization | 1.9.0 | Kotlin 2.2+ | Check for 2.3.x compatible version | MEDIUM |
| kotlinx-datetime | 0.7.1 | Kotlin 2.1.20+ | API changes in recent versions (Instant moved to kotlin.time) | MEDIUM |
| SQLDelight | 2.1.0 | Kotlin 2.x | Latest release May 2025. Only needed if choosing Option B data strategy. | MEDIUM |
| SwiftData | iOS 17+ | Xcode 15+ | Ships with iOS | HIGH |
| NaturalLanguage | iOS 11+ | All Xcode versions | Ships with iOS | HIGH |
| Core ML | iOS 17+ | Xcode 15+ | Enhanced in iOS 17 with async prediction | HIGH |

**Important SKIE note:** SKIE 0.10.9 was released January 2025 and lists compatibility up to Kotlin 2.3.0. Kotlin 2.3.10 (Feb 2026) may need SKIE 0.11.x or newer. **Verify before starting.** Check [skie.touchlab.co](https://skie.touchlab.co/) for the latest compatibility matrix.

---

## Alternatives Considered

| Category | Recommended | Alternative | When to Use Alternative |
|----------|-------------|-------------|-------------------------|
| Persistence | SwiftData | Core Data + NSPersistentCloudKitContainer | Only if you need iOS 16 support or complex batch operations |
| Persistence | SwiftData | SQLDelight (in KMP) + CKSyncEngine | Only if you need Android and want fully shared data layer |
| DI | Koin | kotlin-inject | If you prefer compile-time DI (more boilerplate, catches errors at compile time) |
| Swift interop | SKIE | KMP-NativeCoroutines | If SKIE has compatibility issues; KMP-NativeCoroutines is the alternative for Flow mapping |
| Networking | None (CloudKit handles sync) | Ktor Client | Only if you add a backend API later (e.g., community features in v3+) |
| Image loading | AsyncImage (SwiftUI built-in) | Kingfisher / SDWebImage | Only if you need advanced caching beyond what SwiftUI provides |
| Charting | Swift Charts | Charts (danielgindi) | Only if you need chart types not available in Swift Charts |
| ML | NaturalLanguage + Core ML | Foundation Models | Only when minimum target is iOS 26+ |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Core Data for new code | SwiftData is the successor; Apple's investment is in SwiftData. Core Data adds complexity with `.xcdatamodeld` files. | SwiftData |
| Realm | Proprietary (MongoDB), adds large binary dependency, being sunset for mobile. Does not integrate with CloudKit. | SwiftData |
| Firebase Firestore | Google-centric, adds backend dependency. CloudKit is free and Apple-native for iCloud sync. | CloudKit via SwiftData |
| Compose Multiplatform for UI | Project uses SwiftUI (correct decision for iOS-first). Compose on iOS is stable but doesn't integrate with Apple design patterns, WidgetKit, or system features. | SwiftUI |
| Alamofire / URLSession wrappers | No custom backend means no networking library needed. CloudKit sync is handled by SwiftData. | Nothing (or Ktor only if backend added later) |
| RxSwift | Obsolete for new SwiftUI projects. Swift Concurrency (async/await) and Combine are the standards. | Swift Concurrency + Combine |
| Cocoapods for KMP integration | Adds unnecessary complexity for a single-developer project. | Direct framework integration |
| Foundation Models framework (for now) | Requires iOS 26+, which is above your iOS 17+ target. | NaturalLanguage + Core ML |

---

## Stack Patterns by Variant

**If targeting iOS 17+ only (recommended for v1-v3):**
- Use SwiftData for persistence (available iOS 17+)
- Use Swift Charts for visualization (available iOS 17+)
- Use NaturalLanguage + Core ML for ML features
- Use CKSyncEngine if you need more CloudKit control than SwiftData provides

**If you later add Android (v4+):**
- KMP shared module already contains reusable business logic
- Add `androidMain` source set with Room or SQLDelight for Android persistence
- SwiftData stays for iOS; Android gets its own persistence
- Shared: domain models, business rules, calculations, validation

**If you raise minimum to iOS 26 (future):**
- Add Foundation Models framework for on-device LLM
- Use `@Generable` for structured brew recommendations
- Keep NaturalLanguage + Core ML as fallbacks for older devices

---

## Project Setup Commands

```bash
# Prerequisites
# 1. Install Xcode 16+ from App Store
# 2. Install JDK 17+ (e.g., via Homebrew: brew install openjdk@17)
# 3. Install Android Studio or IntelliJ IDEA for Kotlin development

# Create KMP project using the JetBrains wizard or manually:
# Option 1: Use https://kmp.jetbrains.com/ web wizard
# Option 2: Use Android Studio KMP template

# For the KMP shared module (build.gradle.kts dependencies):
# kotlin("multiplatform") version "2.3.10"
# kotlin("plugin.serialization") version "2.3.10"

# Shared module dependencies (commonMain):
# org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2
# org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0
# org.jetbrains.kotlinx:kotlinx-datetime:0.7.1
# io.insert-koin:koin-core:4.1.1

# SKIE (add to shared module's build.gradle.kts):
# plugins { id("co.touchlab.skie") version "0.10.9" }

# iOS app: Created as standard Xcode SwiftUI project
# Link SharedKit.framework from KMP build output
```

---

## Sources

### Verified (HIGH confidence)
- [Kotlin 2.3.10 release](https://github.com/JetBrains/kotlin/releases) -- GitHub releases page, Feb 5 2026
- [SKIE 0.10.9 release](https://github.com/touchlab/SKIE/releases) -- GitHub releases page, Jan 6 2025
- [SKIE official site](https://skie.touchlab.co/) -- Feature documentation, compatibility info
- [Koin 4.1.1 release](https://github.com/InsertKoinIO/koin/releases) -- GitHub releases page, Sep 3 2024
- [kotlinx.coroutines 1.10.2](https://github.com/Kotlin/kotlinx.coroutines/releases) -- GitHub releases page
- [Apple SwiftData documentation](https://developer.apple.com/documentation/swiftdata)
- [Apple Foundation Models documentation](https://developer.apple.com/documentation/FoundationModels) -- Confirms iOS 26+ requirement
- [Apple NaturalLanguage documentation](https://developer.apple.com/documentation/naturallanguage)
- [Apple Core ML documentation](https://developer.apple.com/documentation/coreml)
- [Apple CKSyncEngine documentation](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5) -- iOS 17+
- [Compose Multiplatform compatibility](https://kotlinlang.org/docs/multiplatform/compose-compatibility-and-versioning.html)
- [KMP iOS integration methods](https://kotlinlang.org/docs/multiplatform/multiplatform-ios-integration-overview.html)

### Verified (MEDIUM confidence)
- [SQLDelight 2.1.0](https://github.com/sqldelight/sqldelight/releases/tag/2.1.0) -- May 16 2025 (version numbering is non-sequential: 2.2.1 was Nov 2024, 2.1.0 was May 2025)
- [kotlinx-datetime 0.7.1](https://mvnrepository.com/artifact/org.jetbrains.kotlinx/kotlinx-datetime) -- Maven Central listing
- [kotlinx.serialization 1.9.0](https://github.com/Kotlin/kotlinx.serialization/releases) -- Requires Kotlin 2.2+; verify 2.3.x compat

### Community consensus (MEDIUM confidence)
- [KMP + SwiftUI architecture patterns](https://medium.com/@hiren6997/kotlin-multiplatform-in-2025-sharing-logic-without-losing-native-feel-fba81691e899)
- [SwiftData vs Core Data 2025 recommendations](https://distantjob.com/blog/core-data-vs-swiftdata/)
- [Touchlab on direct framework integration](https://touchlab.co/ios-framework-local-or-remote)
- [SwiftData CloudKit sync guide](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-sync-swiftdata-with-icloud)

---

## Open Questions (Need Phase-Specific Research)

1. **SKIE + Kotlin 2.3.10 compatibility**: SKIE 0.10.9 documents support up to Kotlin 2.3.0. Need to verify a compatible SKIE version exists for 2.3.10, or pin Kotlin to 2.3.0.
2. **SwiftData + KMP model mapping**: Best pattern for converting between SwiftData `@Model` classes and KMP shared domain models needs prototyping.
3. **CloudKit container quota**: For an app with photos, CloudKit free tier limits (1 PB shared, 10 GB per user) should be adequate but worth monitoring.
4. **Core ML model training**: What training data is needed for a coffee flavor profiling model? This is a v2/v3 concern.
5. **kotlinx.serialization version**: 1.9.0 requires Kotlin 2.2. A newer version compatible with Kotlin 2.3.x may exist (1.10.0 was seen in search results). Verify before setup.

---
*Stack research for: iOS Coffee Journal App (KMP + SwiftUI)*
*Researched: 2026-02-07*
