# Pitfalls Research

**Domain:** iOS Coffee Journal App (KMP + CloudKit + Apple Intelligence)
**Researched:** 2026-02-07
**Confidence:** MEDIUM-HIGH (verified across multiple official and community sources)

---

## Critical Pitfalls

Mistakes that cause rewrites, data loss, or architectural dead ends.

### Pitfall 1: CloudKit Schema is Permanent Once Deployed to Production

**What goes wrong:**
Developer iterates on the Core Data model during development (renaming entities, changing attribute types, deleting fields) without realizing that once the CloudKit schema is deployed to production, it follows an **"Add-Only, No-Delete, No-Change"** rule. Renaming an entity or attribute is interpreted by CloudKit as deleting the old one and adding a new one, causing data loss and sync failures. Removing attributes or changing types (e.g., String to Int) also breaks production sync. The only recovery is migrating to an entirely new CloudKit container, which means losing all existing user data in the cloud.

**Why it happens:**
Core Data locally supports lightweight migration (renames, type changes). Developers assume CloudKit behaves the same way. During development, the JIT schema inference masks this because the development environment is more permissive. The constraint only becomes apparent after deploying the schema to production via the CloudKit Dashboard.

**How to avoid:**
- Design the Core Data model carefully before any TestFlight or App Store release. Treat your first production schema deployment as nearly irreversible.
- Use generic, future-proof attribute names. For example, use `notes` instead of `brewNotes` in case the field's purpose evolves.
- Add new attributes freely, but never rename or delete existing ones. Mark deprecated attributes with a naming convention (e.g., `_deprecated_oldField`) and stop using them in code.
- Keep a version log of every schema change in a `SCHEMA_CHANGELOG.md` file.
- Test schema deployment in the CloudKit Dashboard development environment first, then consciously deploy to production.

**Warning signs:**
- "I'll just rename this field real quick" during development.
- Core Data migration warnings in the Xcode console during CloudKit sync.
- Sync works in development but breaks in TestFlight (schema mismatch).

**Phase to address:**
Phase 1 (Foundation/Data Model) -- the data model must be designed with CloudKit permanence in mind from the very first schema deployment. This is not something you can fix later.

**Confidence:** HIGH -- verified via [Apple Developer documentation](https://developer.apple.com/documentation/technotes/tn3164-debugging-the-synchronization-of-nspersistentcloudkitcontainer) and [fatbobman's CloudKit model rules](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/).

---

### Pitfall 2: Core Data + CloudKit Model Constraints Silently Break Sync

**What goes wrong:**
Developer creates a Core Data model using features that work perfectly locally but are incompatible with CloudKit sync. The app appears to work in development, then sync silently fails or produces corrupt data. The specific constraints are:

1. **Unique constraints are not supported.** `NSPersistentCloudKitContainer` explicitly does not support Core Data unique constraints. CloudKit cannot perform atomic uniqueness checks across distributed devices.
2. **All relationships must be optional with inverse relationships.** Non-optional relationships or missing inverse relationships cause sync failures.
3. **All attributes must be optional or have default values.** CloudKit syncs partial data; a required attribute without a default will fail when a new field arrives from a device running an older app version.
4. **Ordered relationships are unsupported.**
5. **Deny delete rules are unsupported.**
6. **The `Undefined` attribute type is unsupported.**

**Why it happens:**
Core Data documentation and tutorials focus on local persistence patterns. Developers build their model with proper constraints (unique username, required fields, ordered lists) then enable CloudKit, and the constraints are silently ignored or cause runtime failures. The Xcode console warnings are verbose and easy to miss among other CloudKit debug output.

**How to avoid:**
- Start with the CloudKit constraints in mind. Design every entity as if all attributes are optional and all relationships are optional with inverses.
- Handle uniqueness in application logic using UUID-based deduplication (sort duplicates by UUID, keep the smallest, delete others). Listen for `NSPersistentCloudKitContainerEventChangedNotification` to detect incoming remote records and deduplicate.
- Use a dual-store pattern if you need local-only entities with full Core Data features: put CloudKit-synced entities in one configuration and local-only entities (with unique constraints, required fields, etc.) in a separate configuration on the same `NSPersistentStoreCoordinator`.
- Validate your model at build time: write a unit test that loads the Core Data model and checks every entity/relationship against CloudKit rules.

**Warning signs:**
- Xcode console shows "CloudKit integration does not support..." warnings.
- Data exists on one device but not another after sync.
- Duplicate records appearing across devices.

**Phase to address:**
Phase 1 (Foundation/Data Model) -- model design is the first thing built and the hardest to change.

**Confidence:** HIGH -- verified via [Apple Developer Forums](https://developer.apple.com/forums/thread/656380) and [official documentation](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/).

---

### Pitfall 3: KMP/Swift Interop Creates a Hostile Developer Experience Without Proper Tooling

**What goes wrong:**
Without Swift/Obj-C experience, the developer assumes KMP will cleanly expose Kotlin types to SwiftUI. In reality, the default Objective-C bridge (used in KMP prior to Swift Export) produces Swift APIs riddled with underscored names, untyped generics, and no support for Swift's `async/await`, `Combine`, or `@Observable`. Kotlin `StateFlow` appears as an opaque Objective-C type in Swift. Kotlin coroutines cannot be called as `async` functions. Kotlin sealed classes lose their exhaustive switch semantics. The result is that every Kotlin API requires a manual Swift wrapper, doubling the code and introducing a maintenance burden that negates KMP's code-sharing benefits.

**Why it happens:**
KMP compiles to an Objective-C framework for iOS. Swift consuming Objective-C loses many type-safe features. The developer, having no Swift/Obj-C experience, does not know what "normal" Swift interop looks like vs. degraded KMP interop, and may not realize the API surface is broken until deep into development.

**How to avoid:**
- **Use SKIE (Swift Kotlin Interface Enhancer)** from Touchlab as a Kotlin compiler plugin. SKIE automatically bridges Kotlin Flows to Swift `AsyncSequence`, supports `async/await` for suspend functions, preserves sealed class exhaustiveness, and generates idiomatic Swift APIs. It is compatible with Kotlin 2.0.0 through 2.3.0 and Swift 5.8+.
- **Evaluate Swift Export** (experimental as of Kotlin 2.2.20). Swift Export bypasses the Objective-C bridge entirely, producing native Swift modules. However, it currently does not support suspend functions, inline functions, generic types, or functional types, and requires direct integration (not CocoaPods/SPM). It is still experimental and best used alongside SKIE for the features it does not yet cover.
- **Do not try to share ViewModels across platforms.** Keep ViewModels platform-specific (SwiftUI `@Observable` on iOS, Jetpack ViewModel on Android). Share only the business logic, data models, networking, and repository layers via KMP.
- **Build a thin Swift adapter layer early.** Even with SKIE, plan for a small Swift file per feature that wraps KMP types into SwiftUI-friendly types. This isolates interop friction.

**Warning signs:**
- SwiftUI views contain `import shared` with underscore-prefixed types like `__KotlinInt`.
- Xcode autocomplete shows Objective-C-style method signatures instead of Swift-style.
- Developer spends more time on interop wrappers than on business logic.

**Phase to address:**
Phase 0 (Project Setup) -- SKIE must be configured in the Gradle build before any KMP code is consumed from Swift. Retrofitting is possible but painful if wrapper patterns have already solidified.

**Confidence:** HIGH -- verified via [SKIE documentation](https://skie.touchlab.co/), [Kotlin Swift Export docs](https://kotlinlang.org/docs/native-swift-export.html), and multiple community sources.

---

### Pitfall 4: CloudKit Sync is Untestable on Simulator and Opaque to Debug

**What goes wrong:**
Developer builds CloudKit sync features and tries to test them in the iOS Simulator. Sync appears to work one direction (simulator to device) but not the other, or intermittently fails. The developer spends days debugging what turns out to be a platform limitation: **the iOS Simulator cannot receive remote push notifications**, which is the mechanism CloudKit uses to notify devices of changes. Sync from the simulator to a real device works (via polling), but real device changes are not pushed to the simulator. The simulator must be backgrounded and foregrounded to pick up changes via manual poll, with 15-20 second delays.

Additionally, `NSPersistentCloudKitContainer`'s sync errors are logged to the console in verbose, hard-to-parse format. There is no callback API for individual sync failures -- the developer must parse console logs or use `NSPersistentCloudKitContainerEvent` notifications, which provide limited information.

**Why it happens:**
Apple's Simulator does not support APNs (Apple Push Notification service). CloudKit relies on silent push notifications for real-time sync. This is a fundamental platform limitation, not a bug. Developers from Android/web backgrounds (where emulators support push) are caught off guard.

**How to avoid:**
- **Always test CloudKit sync on two physical devices.** Budget for having at least two test devices (e.g., an iPhone and an iPad, or two iPhones).
- **Use the CloudKit Dashboard** (developer.apple.com) to inspect records directly and verify sync state.
- **Enable verbose CloudKit logging** with the launch argument `-com.apple.CoreData.CloudKitDebug 1` (levels 1-3).
- **Listen for `NSPersistentCloudKitContainerEvent` notifications** programmatically to surface sync status in a debug UI (e.g., a hidden developer screen showing last sync time, error count, pending operations).
- **Write unit tests for your data model** that use `initializeCloudKitSchema()` to validate schema compatibility, but do not rely on unit tests for sync behavior.

**Warning signs:**
- "Sync works on my machine" (simulator) but not on TestFlight builds.
- Changes appearing on device A but not device B for minutes or hours.
- Console logs filled with CloudKit errors that are hard to correlate with specific operations.

**Phase to address:**
Phase 1 (Foundation) -- establish the two-device testing workflow and debug UI from the start. Do not defer CloudKit testing to later phases.

**Confidence:** HIGH -- verified via [Apple Developer Forums](https://developer.apple.com/forums/thread/678775), [fatbobman's troubleshooting guide](https://fatbobman.com/en/posts/coredatawithcloudkit-4/), and multiple community reports.

---

### Pitfall 5: KMP Memory Leaks When Passing iOS Objects Across the Kotlin/Swift Boundary

**What goes wrong:**
Developer passes UIImage, large data buffers, or other iOS-native objects into Kotlin shared code. Kotlin/Native's garbage collector and iOS's ARC (Automatic Reference Counting) have different lifecycles and heuristics. Objects that cross the boundary can be retained by both systems, creating retain cycles or delayed deallocation. For a coffee journal app with photo handling, this manifests as memory spikes when processing multiple images, eventually leading to iOS killing the app (jetsam).

The Kotlin/Native GC is a stop-the-world mark-and-sweep collector that runs on a separate thread based on memory pressure heuristics or a timer. It does not respond to iOS memory warnings the way ARC-managed objects do.

**Why it happens:**
The dual memory management systems (GC on Kotlin side, ARC on Swift side) do not communicate. When a Swift object is passed to Kotlin, Kotlin holds a strong reference. When a Kotlin object is returned to Swift, Swift holds a strong reference. Neither system knows when the other has released its reference. Image data is particularly dangerous because UIImage objects can be tens of megabytes.

**How to avoid:**
- **Never pass UIImage or raw image data directly into Kotlin shared code.** Process images entirely on the Swift/iOS side (resize, compress, save to disk), then pass only file URLs or lightweight metadata (dimensions, file path) to Kotlin.
- **Minimize object transfers across the boundary.** Batch operations and transfer data as primitive types or simple data classes rather than complex object graphs.
- **Use `GC.collect()` in Kotlin/Native** after processing large datasets if memory pressure is observed, but do not rely on it as a primary strategy.
- **Monitor memory usage** during development with Xcode Instruments (Allocations, Leaks). Look for objects that grow but never shrink.
- **Use weak references** on the Swift side when holding references to Kotlin objects that should be short-lived.

**Warning signs:**
- Memory usage steadily climbs when adding/viewing photos in the app.
- App crashes with no stack trace (jetsam termination).
- Xcode Instruments shows growing "Kotlin" or "objc_object" allocations that never decrease.

**Phase to address:**
Phase with photo handling -- this pitfall is specifically dangerous during photo capture/import implementation. Design the image pipeline architecture (Swift-only for image processing, KMP for metadata only) before writing any photo code.

**Confidence:** MEDIUM-HIGH -- verified via [Kotlin/Native memory management docs](https://kotlinlang.org/docs/native-memory-manager.html), [Kotlin Discussions forum](https://discuss.kotlinlang.org/t/kmp-ios-uiimage-memory-leak/25663), and [community reports on GC behavior](https://www.droidcon.com/2024/09/24/garbage-collector-in-kmp-part-2/).

---

### Pitfall 6: Apple Intelligence / Foundation Models Has Severe Device and Context Constraints

**What goes wrong:**
Developer builds features around Apple's Foundation Models framework (on-device LLM) assuming it will be available to all users and capable of handling meaningful tasks. In reality:

1. **Device restriction:** Foundation Models requires iOS 26+ on Apple Intelligence-compatible hardware (iPhone 15 Pro or newer with A17 Pro chip). The standard iPhone 15, iPhone 14, and all earlier models are excluded. This eliminates a significant portion of the user base.
2. **Context window is only 4,096 tokens total** (input + output combined). This is extremely small. A detailed coffee brew log with tasting notes, grind settings, water temperature, and historical context could easily exceed this limit. Multi-turn conversations or batch analysis of brew history are impractical.
3. **Geographic restrictions:** Not available in China mainland and some other regions.
4. **User opt-in required:** Apple Intelligence must be enabled by the user in Settings. It is not on by default in all configurations.
5. **Availability not guaranteed:** The framework is only available on iOS 26+, meaning the app must either require iOS 26 as minimum deployment target or implement the feature as optional.

**Why it happens:**
Apple's marketing emphasizes "on-device AI" broadly, but the developer documentation reveals strict hardware requirements. The 3B parameter model is impressive for on-device but has fundamental capacity limits. Developers from cloud AI backgrounds (GPT-4, Claude) expect much larger context windows and broader availability.

**How to avoid:**
- **Treat Apple Intelligence as an optional enhancement, never a core feature.** The app must be fully functional without it.
- **Design a graceful degradation path:** check for availability at runtime using the Foundation Models framework's availability APIs, and show alternative UX (manual input, simpler suggestions) when unavailable.
- **Keep prompts extremely concise.** With 4,096 total tokens, the system prompt + user input + output must all fit. For a coffee journal, limit to single-brew analysis rather than historical comparisons.
- **Handle the `.exceededContextWindowSize` error** explicitly with user-friendly messaging.
- **Track the iOS 26 adoption rate** before investing heavily. As of early 2026, adoption of iOS 26 may still be limited since it was only released in late 2025.

**Warning signs:**
- Feature works on developer's iPhone 15 Pro but crashes or is absent on tester's iPhone 14.
- "Why doesn't AI work?" support tickets from users without compatible hardware.
- Prompts that work in testing fail in production because user content is longer than test data.

**Phase to address:**
Late phase (post-MVP enhancement) -- do not build Apple Intelligence into the core experience. Implement it as an optional "smart suggestions" layer after the app is fully functional without it.

**Confidence:** HIGH -- verified via [Apple Developer documentation for Foundation Models](https://developer.apple.com/documentation/FoundationModels), [Apple TN3193 on context window management](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window), and [community analysis](https://zats.io/blog/making-the-most-of-apple-foundation-models-context-window/).

---

### Pitfall 7: Photo Storage Consumes User's Personal iCloud Quota (Not Yours)

**What goes wrong:**
Developer stores coffee photos as CKAssets in the CloudKit private database, assuming Apple provides generous storage. In reality, **private database storage comes directly from the user's personal iCloud quota** (the same 5 GB free tier they use for photos, backups, and documents). A coffee journal with hundreds of high-resolution brew photos could consume gigabytes of the user's iCloud storage, causing:

1. User's iCloud backup fails because the coffee app ate their storage.
2. `CKError.quotaExceeded` errors that silently stop sync.
3. Angry 1-star reviews: "This app used all my iCloud storage!"

**Why it happens:**
CloudKit's private database is "free" for developers (no server costs), but the cost is transferred to users via their iCloud storage plan. Developers think "cloud storage is handled" without realizing the user impact. The 5 GB free iCloud tier is already tight for most users.

**How to avoid:**
- **Compress images aggressively before storing as CKAssets.** Use JPEG at 0.5-0.7 quality. For a coffee journal, photos do not need to be full resolution.
- **Store multiple sizes:** save a thumbnail (~100KB) and a compressed full-size (~500KB-1MB) as separate CKAsset fields on the same record. Use `CKFetchRecordsOperation`'s `desiredKeys` to download only thumbnails in list views.
- **Implement a storage budget UI** that shows users how much iCloud storage the app is using and lets them manage it (delete old photos, reduce quality).
- **Handle `CKError.quotaExceeded` gracefully.** When this error occurs, inform the user their iCloud is full. Do not silently retry in a loop. Offer options: free up space, reduce photo quality, or continue without sync.
- **Consider offering a "local-only photos" mode** where photos are stored on-device only and not synced, for users with limited iCloud storage.
- **Set a maximum photo dimension** (e.g., 2048px on the longest edge) before upload. Modern iPhone cameras produce 48MP images (8064x6048) that are far too large for a coffee journal.

**Warning signs:**
- App's iCloud storage usage visible in Settings > Apple Account > iCloud shows unexpected growth.
- Users reporting that iCloud backup stopped working after using the app for a few weeks.
- `quotaExceeded` errors appearing in CloudKit logs.

**Phase to address:**
Phase with photo storage -- the image pipeline (capture > resize > compress > store) must be designed before any photo sync code is written. This is architectural, not a polish item.

**Confidence:** HIGH -- verified via [Apple CKAsset documentation](https://developer.apple.com/documentation/cloudkit/ckasset), [Apple CKError.quotaExceeded](https://developer.apple.com/documentation/cloudkit/ckerror/quotaexceeded), and [CloudKit storage model](https://www.rambo.codes/posts/2020-02-25-cloudkit-101).

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip deduplication logic for CloudKit entities | Faster MVP, less code | Duplicate records accumulate across devices, corrupt aggregations (e.g., "average brews per day" is wrong), users see duplicate entries | Never -- implement UUID-based dedup from day one |
| Store full-resolution photos without compression | Simpler image pipeline, "better quality" | Rapidly consumes user iCloud quota, causes `quotaExceeded` errors, slow sync over cellular, app blamed for iCloud full | Never -- always compress and resize before CKAsset storage |
| Use Kotlin ViewModels directly in SwiftUI without wrappers | Less boilerplate, faster prototyping | Opaque types in SwiftUI, no `@Observable` integration, SwiftUI views re-render incorrectly or not at all, debugging becomes impossible | Only during initial proof-of-concept (first 2 weeks) |
| Hardcode CloudKit schema without version tracking | Ship faster | Cannot evolve data model safely, eventual need to migrate to new container (losing all user data) | Never -- track schema versions from first deployment |
| Bypass SKIE/Swift Export, use raw Obj-C interop | No additional dependencies | Every Kotlin type needs manual Swift wrapper, coroutines unusable from Swift, sealed classes lose exhaustiveness | Never if targeting SwiftUI (the interop cost is too high) |
| Skip offline-first architecture, assume network available | Simpler data flow | App unusable on airplane, in cafes with bad WiFi, or when iCloud is down; data loss if network write fails | Never for a journal app where entries are created in the field |
| Defer Apple Intelligence availability checks | Fewer code paths during development | App crashes on unsupported devices, features silently fail for majority of users | Acceptable in dev builds only, must be resolved before TestFlight |

## Integration Gotchas

Common mistakes when connecting to external services and frameworks.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| CloudKit + Core Data | Calling `initializeCloudKitSchema()` in production code | Only call during development or after model changes. It is an expensive network operation. Gate it behind a `#if DEBUG` flag or a one-time migration check. |
| CloudKit + Core Data | Not deploying schema to production CloudKit environment before App Store release | Always manually deploy the development schema to production via the CloudKit Dashboard before every release that includes model changes. Production does not support JIT schema creation. |
| KMP + Xcode | Not configuring the Xcode Run Script Phase to rebuild shared KMP module | Ensure the Gradle `embedAndSignAppleFrameworkForXcode` task is in the Xcode build phases. Without this, Swift code references a stale version of the shared module. |
| KMP + SKIE | Adding SKIE after extensive Swift wrapper code is written | Add SKIE to the Gradle build as the very first KMP setup step. SKIE changes the generated framework API surface, so existing Swift wrappers will break. |
| CloudKit + Photos | Uploading CKAsset without checking user's iCloud availability | Check `CKContainer.default().accountStatus` before any CloudKit operation. Handle `.noAccount`, `.restricted`, and `.couldNotDetermine` states with user-facing UI. |
| Foundation Models | Assuming the model is always available when iOS 26+ is detected | Check both OS version AND `Apple Intelligence` enablement. A user on iOS 26 with Apple Intelligence disabled will not have access to Foundation Models. Use the framework's availability API. |
| Core Data + Background | Accessing managed objects across contexts/threads | Use `NSManagedObjectContext.perform {}` for all Core Data operations. Core Data managed objects are not thread-safe. CloudKit sync happens on a background queue, so merging changes to the view context must use `automaticallyMergesChangesFromParent = true`. |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Loading all CKAsset photos into memory for a grid view | UI jank, memory warnings, jetsam crash | Use thumbnail CKAssets for grid view, load full-size only on tap. Use `desiredKeys` on fetch operations to avoid downloading full assets. Implement `NSCache` or a disk cache for thumbnails. | 50+ photos (~200MB+ in memory) |
| Fetching entire brew history from Core Data without pagination | UI freeze on launch, high memory usage | Use `NSFetchedResultsController` with `fetchBatchSize` set to 20-30. Implement infinite scroll. Never call `fetchRequest.fetchLimit = 0` on a growing dataset. | 500+ brew entries |
| Running Apple Intelligence prompts on the main thread | UI freeze for 2-5 seconds during generation | Always call Foundation Models APIs from a background task. Use `Task { }` and display a loading indicator. The on-device model generation is CPU-intensive. | Any usage -- even small prompts block the main thread |
| CloudKit sync polling in foreground without throttling | Battery drain, CloudKit throttling errors (HTTP 503) | Let `NSPersistentCloudKitContainer` manage its own sync schedule. Do not implement manual polling. If you need forced refresh, throttle to once per 30 seconds minimum. | Continuous usage (app in foreground for 10+ minutes) |
| Passing image data through Kotlin shared code for processing | Memory spikes (2x-4x image size due to Kotlin/Swift copies), GC pauses | Process all images in Swift-only code. Pass only file URLs or metadata (path, dimensions, hash) across the KMP boundary. | Any photo larger than 5MB |
| Not compressing photos before CloudKit upload on cellular | Slow uploads, user data plan consumption, upload failures on poor connections | Compress to JPEG 0.5-0.7 quality, cap dimensions at 2048px. Use `NSURLSession` background upload configuration for reliability. | Photos over 3-5MB on LTE/5G |

## Security Mistakes

Domain-specific security issues beyond general practices.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing sensitive brew recipes or personal notes in CloudKit public database | Any iCloud user can read public database records. Brew recipes, tasting notes, and location data are personal. | Always use the private database for user-generated content. Public database is only for shared reference data (e.g., coffee bean database, roaster directory). |
| Not checking `CKContainer.accountStatus` before CloudKit operations | Operations fail silently or crash if no iCloud account is configured. User data is lost because local-only mode was not designed. | Check account status on every app launch. Implement a complete offline/local-only fallback path for users without iCloud. |
| Logging CloudKit record contents during debugging | Personal coffee notes, photos, and location data appear in console logs. If logs are collected (e.g., via crash reporting), user data is exposed. | Strip CloudKit record data from logs in release builds. Only log record metadata (type, ID, timestamps) in debug builds. |
| Exposing Foundation Models input/output in analytics | User's coffee descriptions and AI-generated suggestions may contain personal information. | Never send Foundation Models prompts or responses to analytics services. Process on-device, keep on-device. |

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No indication of CloudKit sync status | User adds a brew on iPhone, opens iPad, does not see it. Assumes data is lost. Panics. | Show a subtle sync indicator (e.g., a small cloud icon with checkmark/spinner/error in the toolbar). Show "Last synced: 2 minutes ago" in settings. |
| Showing raw CloudKit/Core Data errors to users | User sees "CKError 15: quotaExceeded" and has no idea what to do. | Translate every error to human-readable text: "Your iCloud storage is full. Free up space in Settings > Apple Account > iCloud to continue syncing." |
| Apple Intelligence feature present but unavailable with no explanation | User sees an "AI Suggestions" button that does nothing on their iPhone 14. | Check device compatibility. If unavailable, either hide the feature entirely or show an explanation: "Smart suggestions require iPhone 15 Pro or newer with iOS 26." Do not show a grayed-out button with no context. |
| Sync conflicts resolved silently with last-writer-wins | User carefully edits a brew on their iPhone, then opens the iPad (which has a stale version) and makes a small edit. The iPhone edits are silently overwritten. | For key user-generated content (brew notes, ratings), consider showing a conflict notification: "This brew was edited on another device. Keep this version or the other?" At minimum, log conflict resolutions so users can find "lost" edits. |
| Photos sync slowly with no progress indicator | User adds photos on iPhone, opens iPad, sees brew entry but photos show blank/loading forever. | Show placeholder with loading spinner for photos still syncing. Display "Syncing 3 photos..." when asset transfer is in progress. Cache thumbnails aggressively so at least low-res versions appear quickly. |
| Monochrome UI makes disabled/loading states invisible | With a monochrome color scheme, there is almost no visual difference between active, disabled, and loading states. | Use opacity, size, and animation (not color) to differentiate states. A spinner or shimmer effect works in monochrome. Use bold/regular weight contrast for enabled/disabled text. |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **CloudKit Sync:** Works on one device but never tested on two physical devices simultaneously -- verify sync completes in both directions with conflict scenario (edit same record on both devices while one is in airplane mode)
- [ ] **Photo upload:** Works for one photo but never tested with 20+ photos uploaded in quick succession -- verify no memory crash and all assets arrive in CloudKit
- [ ] **Offline mode:** App works without network but changes made offline were never verified to sync when network returns -- test: airplane mode, add 5 brews with photos, re-enable network, verify all 5 appear on second device
- [ ] **iCloud account handling:** App works with iCloud signed in but crashes or hangs when no iCloud account is configured -- verify app launches and is fully usable in local-only mode
- [ ] **Schema deployment:** Core Data model works in development but schema was never deployed to production CloudKit environment -- verify in CloudKit Dashboard that production schema matches development
- [ ] **Deduplication:** No duplicate records visible in normal testing but duplicates appear when two devices create the same entity simultaneously while offline -- verify dedup logic handles the "same brew created on two devices" case
- [ ] **Apple Intelligence:** AI feature works on developer's Pro device but was never tested on non-Pro or pre-iOS 26 device -- verify graceful degradation on incompatible hardware
- [ ] **Memory under load:** App runs fine with 10 brews and 10 photos but was never tested with 500 brews and 200 photos -- verify scroll performance, memory usage, and launch time at scale
- [ ] **CloudKit quota:** Sync works in testing with a few records but never tested against a user with a full iCloud account (5GB free tier, 4.9GB used) -- verify `quotaExceeded` handling shows user-friendly message
- [ ] **Background sync:** Sync works when app is in foreground but new records from other devices are not received when app is backgrounded and then foregrounded -- verify `NSPersistentCloudKitContainer` handles background fetch properly

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| CloudKit schema deployed with wrong model | HIGH | Cannot fix production schema. Must create a new CloudKit container identifier, implement data migration to copy records from old to new container, and release an app update. Users may lose data during migration if not handled carefully. |
| Duplicate records from missing dedup logic | MEDIUM | Write a one-time migration that scans all entities, identifies duplicates (by UUID sort), merges their data (keep most recent modification), and deletes extras. Run on app update. |
| Memory leaks from images crossing KMP boundary | MEDIUM | Refactor image pipeline to Swift-only. Extract image processing from shared Kotlin code. This requires changing the API boundary but not the business logic. |
| Users hit iCloud quota from uncompressed photos | MEDIUM | Release update with image compression. Write migration to re-compress existing CKAssets (download, resize, re-upload as new asset, delete old). This is slow and bandwidth-intensive for users. |
| Apple Intelligence features crash on unsupported devices | LOW | Add runtime availability checks, wrap in `if #available(iOS 26, *)` and Foundation Models availability guards. Release hotfix. |
| Sync not working because schema not deployed to production | LOW | Deploy schema via CloudKit Dashboard. Existing users re-sync automatically. No data is lost, just delayed. |
| SwiftUI views broken by raw KMP Obj-C types | MEDIUM | Add SKIE to build, rewrite Swift wrappers to use SKIE-generated types. Estimated 1-2 weeks of refactoring depending on number of views. |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| CloudKit schema permanence | Phase 0-1 (Project Setup / Data Model) | Schema reviewed against "Add-Only" rule before first TestFlight deployment. Schema changelog file exists. |
| Core Data model constraints for CloudKit | Phase 1 (Data Model) | Automated unit test validates all entities against CloudKit rules. All relationships optional with inverse. No unique constraints. |
| KMP/Swift interop friction | Phase 0 (Project Setup) | SKIE configured in `build.gradle.kts`. Sample Kotlin class consumed from SwiftUI with proper types verified. |
| CloudKit sync untestable on simulator | Phase 1 (Foundation) | Two physical test devices available. Debug sync status UI implemented. CloudKit Dashboard bookmarked. |
| Memory leaks with images across KMP boundary | Phase with Photos | Image pipeline processes entirely in Swift. Xcode Instruments memory test run with 20+ photos shows no growth. |
| Foundation Models device/context constraints | Phase with AI features (post-MVP) | Availability check exists. App tested on non-Pro iPhone with AI features hidden. Prompt fits within 4096 token budget. |
| Photo storage consumes user iCloud quota | Phase with Photos | Photos compressed to JPEG 0.5-0.7, max 2048px. Thumbnail + full-size stored separately. `quotaExceeded` error handled with user-facing message. |
| Duplicate records across devices | Phase 1 (Data Model) | Deduplication handler registered for `NSPersistentCloudKitContainerEventChangedNotification`. Test: create same entity on two offline devices, bring online, verify only one remains. |
| Sync conflict data loss (last-writer-wins) | Phase with Sync features | Conflict scenario tested (edit same record on two devices while offline). Decision documented: accept LWW for MVP or implement conflict UI. |
| Offline-first data integrity | Phase 1 (Foundation) | App fully functional in airplane mode. Offline changes verified to sync on reconnection. |

## Sources

**Official Apple Documentation (HIGH confidence):**
- [TN3164: Debugging NSPersistentCloudKitContainer](https://developer.apple.com/documentation/technotes/tn3164-debugging-the-synchronization-of-nspersistentcloudkitcontainer)
- [TN3193: Managing Foundation Model Context Window](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)
- [CKAsset Documentation](https://developer.apple.com/documentation/cloudkit/ckasset)
- [CKError.quotaExceeded](https://developer.apple.com/documentation/cloudkit/ckerror/quotaexceeded)
- [Foundation Models Framework](https://developer.apple.com/documentation/FoundationModels)
- [Kotlin/Native Memory Management](https://kotlinlang.org/docs/native-memory-manager.html)
- [Kotlin Swift Export](https://kotlinlang.org/docs/native-swift-export.html)

**Verified Community Sources (MEDIUM confidence):**
- [Rules for Adapting Data Models to CloudKit](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/) -- fatbobman, well-known Core Data expert
- [Core Data with CloudKit Troubleshooting](https://fatbobman.com/en/posts/coredatawithcloudkit-4/) -- fatbobman
- [SKIE Documentation](https://skie.touchlab.co/) -- Touchlab official
- [CloudKit 101](https://www.rambo.codes/posts/2020-02-25-cloudkit-101) -- Guilherme Rambo
- [What I Learned Writing My Own CloudKit Syncing Library](https://ryanashcraft.com/what-i-learned-writing-my-own-cloudkit-sync-library/)
- [KMP Pitfalls and Anti-Patterns](https://medium.com/@karelvdmmisc/my-journey-with-kotlin-multiplatform-mobile-pitfalls-anti-patterns-and-solutions-525df7058018)
- [Garbage Collector in KMP](https://www.droidcon.com/2024/09/24/garbage-collector-in-kmp-part-2/)
- [Managing Foundation Models Context Window](https://zats.io/blog/making-the-most-of-apple-foundation-models-context-window/)
- [KMP iOS UIImage Memory Leak Discussion](https://discuss.kotlinlang.org/t/kmp-ios-uiimage-memory-leak/25663)
- [Apple Intelligence Foundation Models Context Window](https://zats.io/blog/making-the-most-of-apple-foundation-models-context-window/)

**Apple Developer Forums (MEDIUM confidence):**
- [Unique Constraints Not Supported](https://developer.apple.com/forums/thread/656380)
- [NSPersistentCloudKitContainer Sync Issues](https://developer.apple.com/forums/thread/678775)
- [QuotaExceeded Error Handling](https://developer.apple.com/forums/thread/697318)

---
*Pitfalls research for: iOS Coffee Journal (KMP + CloudKit + Apple Intelligence)*
*Researched: 2026-02-07*
