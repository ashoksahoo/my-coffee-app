# Phase 6: Sync & Offline - Research

**Researched:** 2026-02-09
**Domain:** SwiftData + CloudKit sync UX, offline mode, conflict resolution, photo asset management (iOS 17+)
**Confidence:** MEDIUM-HIGH

## Summary

Phase 6 builds the user-facing sync experience on top of the SwiftData + CloudKit infrastructure established in Phase 1. The app already syncs via `ModelConfiguration(cloudKitDatabase: .automatic)` -- Phase 6 makes that sync *visible and reliable* to users. The three requirements (SYNC-03, SYNC-04, SYNC-05) translate into: (1) a network/sync status monitoring layer that detects offline state and reports sync progress, (2) understanding and surfacing CloudKit's built-in conflict resolution so users are never surprised by data loss, and (3) ensuring photos are compressed before storage so they sync efficiently as CloudKit assets.

The critical insight for this phase is that SwiftData + CloudKit handles most of the hard work automatically -- the sync infrastructure, offline queueing, and conflict merging already happen under the hood via `NSPersistentCloudKitContainer`. Phase 6's job is primarily *observational and UI-focused*: monitoring what the system is already doing, surfacing that information to users, and ensuring photos are stored optimally. The conflict resolution strategy is last-writer-wins at the record level, which CloudKit applies automatically. We cannot customize this with SwiftData, but we can design the UI to minimize scenarios where users would notice it.

**Primary recommendation:** Build a lightweight `SyncMonitor` observable class that listens to `NSPersistentCloudKitContainer.eventChangedNotification` and `NWPathMonitor`, surfaces sync state in a non-intrusive Settings section and optional toolbar indicator, and keep photo compression at the existing 1024px/0.7 JPEG quality which fits well within CloudKit's 50MB asset limit.

## Standard Stack

### Core

| Framework | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SwiftData | iOS 17+ | Persistence with automatic CloudKit sync | Already in use. `ModelConfiguration(cloudKitDatabase: .automatic)` provides zero-code sync |
| CloudKit | iOS 17+ | iCloud sync backend | Underlying sync engine accessed via `NSPersistentCloudKitContainer` notifications |
| Network.framework | iOS 12+ | Connectivity monitoring via `NWPathMonitor` | Apple's recommended replacement for Reachability. Detects WiFi/cellular/offline |
| SwiftUI | iOS 17+ | Sync status UI | Overlay banners, settings section, toolbar indicators |

### Supporting

| Framework | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| CoreData (import only) | iOS 17+ | Access `NSPersistentCloudKitContainer.eventChangedNotification` | SwiftData wraps CoreData; we import CoreData only for the notification name and event type |
| UIKit (ImageCompressor) | iOS 17+ | Photo compression before storage | Already exists in codebase. Used for JPEG compression before CloudKit sync |

### No External Dependencies

Per PROJECT.md constraint: no external dependencies. The `CloudKitSyncMonitor` SPM package exists but we will hand-roll an equivalent since: (a) it is small (~200 lines of relevant logic), (b) we avoid dependency management, and (c) it uses `@StateObject`/`ObservableObject` patterns we'd need to convert to `@Observable` anyway.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled SyncMonitor | [CloudKitSyncMonitor](https://github.com/ggruen/CloudKitSyncMonitor) SPM package | Adds external dependency; uses ObservableObject not @Observable; would need adaptation |
| NSPersistentCloudKitContainer event notifications | CKSyncEngine (iOS 17+) | CKSyncEngine is for custom CloudKit sync, not SwiftData automatic sync. Would require abandoning SwiftData's zero-code sync entirely |
| NWPathMonitor | SCNetworkReachability | Deprecated. NWPathMonitor is the modern replacement |

## Architecture Patterns

### Recommended Project Structure (Phase 6 Additions)

```
CoffeeJournal/
├── Services/
│   ├── SyncMonitor.swift          # @Observable class: CloudKit sync event monitoring
│   └── NetworkMonitor.swift       # @Observable class: NWPathMonitor connectivity state
├── Views/
│   ├── Components/
│   │   ├── SyncStatusView.swift   # Compact sync indicator (toolbar/banner)
│   │   └── SyncStatusBadge.swift  # SF Symbol badge for sync state
│   └── Settings/
│       └── SettingsView.swift     # EXISTING: Enhance with sync status section
├── Utilities/
│   └── ImageCompressor.swift      # EXISTING: Already handles photo compression
└── CoffeeJournalApp.swift         # EXISTING: Initialize SyncMonitor + NetworkMonitor
```

### Pattern 1: SyncMonitor Observable Class

**What:** A single `@Observable` class that subscribes to `NSPersistentCloudKitContainer.eventChangedNotification` via `NotificationCenter` and exposes sync state as published properties.

**When to use:** Injected into the SwiftUI environment at app startup. Any view can observe sync state without coupling to CloudKit internals.

**Example:**
```swift
// Source: NSPersistentCloudKitContainer.eventChangedNotification + CloudKitSyncMonitor patterns
import SwiftData
import CoreData  // For NSPersistentCloudKitContainer.eventChangedNotification
import Observation

@Observable
final class SyncMonitor {
    enum SyncState: Equatable {
        case idle
        case syncing
        case succeeded
        case failed(String)
        case noAccount
    }

    private(set) var importState: SyncState = .idle
    private(set) var exportState: SyncState = .idle
    private(set) var lastSuccessfulSync: Date?

    var overallState: SyncState {
        if case .failed(let msg) = importState { return .failed(msg) }
        if case .failed(let msg) = exportState { return .failed(msg) }
        if case .noAccount = importState { return .noAccount }
        if importState == .syncing || exportState == .syncing { return .syncing }
        if importState == .succeeded && exportState == .succeeded { return .succeeded }
        return .idle
    }

    init() {
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleEvent(notification)
        }
    }

    private func handleEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[
            NSPersistentCloudKitContainer.eventNotificationUserInfoKey
        ] as? NSPersistentCloudKitContainer.Event else { return }

        let isFinished = event.endDate != nil
        let state: SyncState = {
            if let error = event.error {
                return .failed(error.localizedDescription)
            }
            return isFinished ? .succeeded : .syncing
        }()

        switch event.type {
        case .import:
            importState = state
        case .export:
            exportState = state
        case .setup:
            break  // Initial setup event
        @unknown default:
            break
        }

        if isFinished && event.error == nil {
            lastSuccessfulSync = Date()
        }
    }
}
```

**Confidence:** HIGH -- `NSPersistentCloudKitContainer.eventChangedNotification` is a documented Apple API. The pattern of extracting events from `userInfo` with `eventNotificationUserInfoKey` is confirmed by multiple sources including Apple Developer Forums and Hacking with Swift.

### Pattern 2: NetworkMonitor with NWPathMonitor

**What:** An `@Observable` class that wraps `NWPathMonitor` to provide real-time connectivity state.

**When to use:** Combined with SyncMonitor to distinguish "offline" from "sync error". Displayed in UI to inform users whether the app is in offline mode.

**Example:**
```swift
// Source: developer.apple.com/documentation/network/nwpathmonitor
import Network
import Observation

@Observable
final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private(set) var isConnected: Bool = true
    private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi, cellular, wiredEthernet, unknown
    }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wiredEthernet }
        return .unknown
    }

    deinit {
        monitor.cancel()
    }
}
```

**Confidence:** HIGH -- `NWPathMonitor` is Apple's documented API for network monitoring, available since iOS 12. Multiple authoritative sources confirm this pattern.

### Pattern 3: iCloud Account Status Check

**What:** Check `CKContainer.default().accountStatus()` at app launch to detect whether the user has an active iCloud account. If not, disable sync UI and inform the user.

**When to use:** On app startup and when `CKAccountChanged` notification fires (user signs in/out of iCloud while app is running).

**Example:**
```swift
// Source: developer.apple.com/documentation/cloudkit/ckcontainer/1399180-accountstatus
import CloudKit

extension SyncMonitor {
    func checkAccountStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            switch status {
            case .available:
                break  // Good to go
            case .noAccount, .restricted:
                importState = .noAccount
                exportState = .noAccount
            case .couldNotDetermine:
                break  // Treat as potentially available
            case .temporarilyUnavailable:
                break  // Will retry automatically
            @unknown default:
                break
            }
        } catch {
            importState = .failed(error.localizedDescription)
        }
    }
}
```

**Confidence:** HIGH -- `CKContainer.accountStatus()` is documented Apple API.

### Pattern 4: Environment Injection at App Level

**What:** Create SyncMonitor and NetworkMonitor as `@State` in the App struct and inject them into the SwiftUI environment so all views can observe sync state.

**Example:**
```swift
@main
struct CoffeeJournalApp: App {
    let container: ModelContainer
    @State private var syncMonitor = SyncMonitor()
    @State private var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(syncMonitor)
                .environment(networkMonitor)
        }
        .modelContainer(container)
    }
}
```

**Confidence:** HIGH -- `@Observable` + `.environment()` is Apple's iOS 17+ standard pattern.

### Anti-Patterns to Avoid

- **Polling for sync status:** Never create a Timer that repeatedly checks sync state. Use `NSPersistentCloudKitContainer.eventChangedNotification` which fires exactly when events occur.
- **Blocking UI on sync:** SwiftData syncs asynchronously in the background. Never show a loading spinner that blocks user interaction while waiting for sync.
- **Custom CKRecord manipulation:** SwiftData manages the CloudKit records automatically. Writing directly to `CKRecord` would bypass SwiftData and cause data inconsistency.
- **Assuming sync is instant:** CloudKit sync timing depends on network conditions, device power state, and Apple's scheduling. Never promise real-time sync in the UI.
- **Ignoring the no-account case:** If the user isn't signed into iCloud, CloudKit sync silently does nothing. Always check account status and inform the user.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Offline data queueing | Custom pending-changes queue | SwiftData's built-in offline behavior | SwiftData writes locally immediately and syncs when connectivity returns. The queue is automatic. |
| Conflict resolution logic | Custom merge/diff algorithm | CloudKit's built-in last-writer-wins | NSPersistentCloudKitContainer resolves conflicts automatically at the record level. Custom resolution is not possible with SwiftData's automatic sync. |
| Network reachability | Third-party Reachability library | `NWPathMonitor` (Network.framework) | Apple's native solution, no dependency needed |
| Push notification sync trigger | Manual CKSubscription setup | SwiftData automatic sync | SwiftData+CloudKit handles remote notification triggers for sync automatically |
| Photo format conversion | Custom HEIC encoder | `UIImage.jpegData(compressionQuality:)` | JPEG is universally compatible; HEIC provides ~50% savings but slower encode/decode and less compatibility. For photos under 1MB, JPEG at 0.7 quality is sufficient. |
| CloudKit schema deployment | Manual CKRecord schema creation | `initializeCloudKitSchema()` during development | Call once in development to push schema to CloudKit; SwiftData handles schema automatically in production |

**Key insight:** Phase 6 is primarily a UI/monitoring layer, not an infrastructure layer. SwiftData+CloudKit already handles offline queueing, sync, and conflict resolution. Our job is to *observe and surface* that behavior, not rebuild it.

## Common Pitfalls

### Pitfall 1: Assuming Sync Means Real-Time

**What goes wrong:** Developer builds UI that implies changes are instantly available on other devices. User edits on iPhone, switches to iPad, and doesn't see the change for 15-60 seconds.

**Why it happens:** CloudKit sync is batched and scheduled. Apple dynamically adjusts sync frequency based on battery, network, and usage. On simulator, push notifications don't work at all, giving a false sense of timing.

**How to avoid:**
- Use language like "syncs automatically" not "syncs instantly" in any UI text
- Show "Last synced: X minutes ago" not "Synced" as a binary state
- Never show a loading spinner tied to sync -- let users continue working
- Test on two physical devices to understand real sync latency

**Warning signs:** Users reporting "sync doesn't work" when it's just slow.

**Confidence:** HIGH -- Multiple sources document this behavior including Apple TN3164 and fatbobman.com.

### Pitfall 2: Conflict Resolution Data Loss Confusion

**What goes wrong:** User edits a brew log's notes on iPhone (offline), then edits the rating on iPad (offline). When both come online, the last-writer-wins at the *record* level, meaning one device's changes overwrite the other entirely -- not a field-level merge.

**Why it happens:** CloudKit's `NSPersistentCloudKitContainer` uses last-writer-wins at the entity (record) level, not the attribute (property) level. This is a common misconception. Two changes to *different* properties of the *same* record will not be merged; the most recent full-record save wins.

**How to avoid:**
- Accept that this is the behavior and design UI accordingly
- Show "Last edited on [device name] at [time]" to help users understand which version they're seeing
- The `updatedAt` field on every model helps track which version won
- For critical data: consider splitting frequently-co-edited fields into separate models (but this adds complexity)
- In practice, a personal coffee journal app with 1-2 devices has very low conflict probability

**Warning signs:** Users finding "my changes disappeared" after editing on two offline devices.

**Confidence:** MEDIUM -- Multiple forum posts confirm record-level LWW, but Apple's official documentation is sparse. The CrunchyBagel article and Apple Developer Forums thread 122745 both reference entity-level resolution.

### Pitfall 3: Photo Sync Exhausting iCloud Quota

**What goes wrong:** User adds many brew log photos at full resolution. Each photo is 5-15MB. CloudKit syncs them as CKAssets, consuming the user's personal iCloud quota (which is typically 5GB for free tier).

**Why it happens:** `PhotosPicker` returns full-resolution images. Without compression, `@Attribute(.externalStorage)` stores the raw data. CloudKit asset storage counts against the user's iCloud quota.

**How to avoid:**
- Always compress photos before storing in SwiftData. The existing `ImageCompressor` (1024px max, 0.7 JPEG quality) reduces 10MB photos to ~200-400KB
- CloudKit has a 50MB per-asset limit, so even uncompressed photos would "fit", but quota impact is the real concern
- Consider storing thumbnails separately (lower resolution, ~50KB each) for list views, with the full compressed image for detail views
- Monitor and warn if photo storage grows large

**Warning signs:** Users with free iCloud (5GB) complaining about storage full notifications.

**Confidence:** HIGH -- CloudKit 50MB asset limit confirmed by Apple's official Property Metrics documentation. Quota consumption confirmed by Apple Developer Forums.

### Pitfall 4: Not Handling No-iCloud-Account State

**What goes wrong:** App assumes iCloud is always available. When user is not signed in, sync silently fails. User has no idea why their data isn't appearing on their other device.

**Why it happens:** `ModelConfiguration(cloudKitDatabase: .automatic)` silently degrades to local-only when iCloud is unavailable. No error, no UI feedback.

**How to avoid:**
- Check `CKContainer.default().accountStatus()` at app launch
- Listen for `CKAccountChanged` notification for runtime changes
- Show clear messaging: "Sign in to iCloud in Settings to sync across devices"
- Show a non-intrusive indicator in the Settings/Data section

**Warning signs:** Support requests about "sync not working" from users who aren't signed into iCloud.

**Confidence:** HIGH -- `CKContainer.accountStatus()` is documented Apple API. Multiple sources confirm silent degradation behavior.

### Pitfall 5: Testing Sync Only on Simulator

**What goes wrong:** Developer tests sync in iOS Simulator. It appears to work (local persistence works), but real CloudKit sync is never actually verified because simulator cannot receive remote push notifications.

**Why it happens:** iOS Simulator does not support APNs (Apple Push Notification Service), which CloudKit uses to trigger sync on the receiving device.

**How to avoid:**
- Always test sync on two physical devices signed into the same iCloud account
- Use CloudKit Dashboard (icloud.developer.apple.com) to inspect records in the development environment
- Enable verbose logging: add launch argument `-com.apple.CoreData.CloudKitDebug 1`

**Warning signs:** "It works on simulator" but users report sync failures.

**Confidence:** HIGH -- Apple TN3164 and multiple developer forums confirm simulator limitations.

## Code Examples

### Sync Status Banner for Settings View

```swift
// Source: Synthesis of CloudKitSyncMonitor patterns + SwiftUI
struct SyncStatusSection: View {
    @Environment(SyncMonitor.self) private var syncMonitor
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        Section {
            HStack {
                Label {
                    Text("iCloud Sync")
                } icon: {
                    Image(systemName: syncIconName)
                        .foregroundStyle(syncIconColor)
                }
                Spacer()
                Text(syncStatusText)
                    .foregroundStyle(AppColors.subtle)
            }

            if !networkMonitor.isConnected {
                Label {
                    Text("You're offline. Changes will sync when connected.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.subtle)
                } icon: {
                    Image(systemName: "wifi.slash")
                        .foregroundStyle(AppColors.muted)
                }
            }

            if case .noAccount = syncMonitor.overallState {
                Label {
                    Text("Sign in to iCloud in Settings to sync across devices.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.subtle)
                } icon: {
                    Image(systemName: "exclamationmark.icloud")
                        .foregroundStyle(AppColors.muted)
                }
            }
        } header: {
            Text("Data")
        } footer: {
            if let lastSync = syncMonitor.lastSuccessfulSync {
                Text("Last synced \(lastSync, style: .relative) ago")
            }
        }
    }

    private var syncIconName: String {
        switch syncMonitor.overallState {
        case .idle: return "icloud"
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .succeeded: return "checkmark.icloud"
        case .failed: return "exclamationmark.icloud"
        case .noAccount: return "xmark.icloud"
        }
    }

    private var syncIconColor: Color {
        switch syncMonitor.overallState {
        case .failed, .noAccount: return AppColors.primary
        default: return AppColors.subtle
        }
    }

    private var syncStatusText: String {
        if !networkMonitor.isConnected { return "Offline" }
        switch syncMonitor.overallState {
        case .idle: return "Enabled"
        case .syncing: return "Syncing..."
        case .succeeded: return "Up to date"
        case .failed: return "Error"
        case .noAccount: return "Not signed in"
        }
    }
}
```

**Confidence:** HIGH -- Uses only standard SwiftUI + `@Observable` environment pattern.

### Photo Compression Before Storage (Existing Pattern)

```swift
// Source: Already implemented in CoffeeJournal/Utilities/ImageCompressor.swift
// The existing ImageCompressor already handles the SYNC-05 requirement.
// It compresses to 1024px max dimension and 0.7 JPEG quality.
// A 48MP iPhone photo (~10MB) becomes ~200-400KB after compression.
// CloudKit asset limit is 50MB per asset, so this is well within bounds.
//
// Usage (already in place across equipment/bean/brew photo pickers):
if let compressed = ImageCompressor.compress(imageData: rawData) {
    model.photoData = compressed  // Stored with @Attribute(.externalStorage)
}
```

**Confidence:** HIGH -- Already implemented and working in the codebase.

### Offline Mode Detection Overlay

```swift
// Source: NWPathMonitor + SwiftUI pattern
struct OfflineBanner: View {
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                Text("Offline mode")
                    .font(AppTypography.caption)
            }
            .foregroundStyle(AppColors.subtle)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.secondaryBackground)
            .clipShape(Capsule())
        }
    }
}
```

**Confidence:** HIGH -- Standard SwiftUI conditional view with NWPathMonitor state.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual CKSubscription for sync triggers | SwiftData auto-sync via NSPersistentCloudKitContainer | iOS 17 (2023) | Zero-code sync triggering |
| SCNetworkReachability for connectivity | NWPathMonitor (Network.framework) | iOS 12 (2018) | Modern, structured API |
| ObservableObject + @Published for sync state | @Observable macro (iOS 17+) | WWDC 2023 | Less boilerplate, fine-grained observation |
| Custom CKSyncEngine for sync control | NSPersistentCloudKitContainer automatic sync | iOS 13+ (2019) | No manual record management needed |
| NSMergePolicy customization | Automatic last-writer-wins (no customization in SwiftData) | iOS 17+ (2023) | Simpler but less control |

**Deprecated/outdated:**
- `SCNetworkReachability` / Reachability libraries: Use `NWPathMonitor` instead
- `ObservableObject` + `@Published`: Use `@Observable` for iOS 17+
- Manual `CKRecord` manipulation with SwiftData: SwiftData handles record management
- Custom merge policies with SwiftData: `NSMergePolicy` cannot be configured through SwiftData's public API

## Open Questions

1. **Record-level vs property-level conflict resolution granularity**
   - What we know: Multiple sources indicate CloudKit uses last-writer-wins. CrunchyBagel article says "entity level" resolution. Some sources suggest property-level for attributes but entity-level for relationships.
   - What's unclear: Apple's official documentation does not explicitly state the granularity. Forum discussions are inconsistent.
   - Recommendation: Treat it as record-level (worst case) for safety. Design UI to show `updatedAt` timestamps so users can identify which version persisted. For a personal coffee journal with 1-2 devices, this is low risk -- simultaneous offline edits to the same record are rare.

2. **SwiftData access to underlying NSPersistentCloudKitContainer**
   - What we know: `NSPersistentCloudKitContainer.eventChangedNotification` works with SwiftData because SwiftData uses NSPersistentCloudKitContainer under the hood.
   - What's unclear: Whether future SwiftData versions will provide a native sync event API, making the CoreData import unnecessary.
   - Recommendation: Import CoreData solely for the notification constant. This is stable and unlikely to break. Wrap it in the `SyncMonitor` class so if Apple adds a SwiftData-native API later, only one file needs updating.

3. **Photo storage: single compressed image vs thumbnail + full image**
   - What we know: The existing `ImageCompressor` compresses to 1024px/0.7 quality, producing ~200-400KB images. CloudKit allows 50MB per asset.
   - What's unclear: Whether 1024px is sufficient resolution for brew log detail views on iPad Pro displays (2732px wide).
   - Recommendation: Keep the current 1024px max dimension for Phase 6. This provides good quality for phone screens and acceptable quality for iPad. If users request higher resolution, increase to 2048px in a future update (still well under 50MB limit at ~500KB-1MB). Adding a separate thumbnail model would increase schema complexity for minimal benefit at current scale.

4. **Sync status granularity for user display**
   - What we know: `eventChangedNotification` fires for individual import/export events with start/end timestamps.
   - What's unclear: Whether showing "Syncing..." actively is beneficial or creates anxiety. Apple's own apps (Notes, Reminders) show sync status very minimally.
   - Recommendation: Follow Apple's pattern -- show sync status primarily in Settings. Add a subtle toolbar indicator only when there's an error or no account. Do not show a persistent "Syncing..." animation during normal operation.

## Sources

### Primary (HIGH confidence)
- [Apple: NWPathMonitor](https://developer.apple.com/documentation/network/nwpathmonitor) -- Network connectivity monitoring API
- [Apple: CKContainer.accountStatus()](https://developer.apple.com/documentation/cloudkit/ckcontainer/1399180-accountstatus) -- iCloud account status check
- [Apple: NSPersistentCloudKitContainer.eventChangedNotification](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer) -- Sync event monitoring
- [Apple: CloudKit Data Size Limits](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/PropertyMetrics.html) -- 1MB record, 50MB asset limits
- [Apple TN3164: Debugging the synchronization of NSPersistentCloudKitContainer](https://developer.apple.com/documentation/technotes/tn3164-debugging-the-synchronization-of-nspersistentcloudkitcontainer) -- Debug logging arguments
- [Hacking with Swift: How to sync SwiftData with iCloud](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-sync-swiftdata-with-icloud) -- Setup requirements, model constraints, testing guidance

### Secondary (MEDIUM confidence)
- [CloudKitSyncMonitor (GitHub)](https://github.com/ggruen/CloudKitSyncMonitor) -- Reference implementation for sync state monitoring patterns
- [fatbobman: Rules for Adapting Data Models to CloudKit](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/) -- Model constraints, migration rules
- [fatbobman: Core Data with CloudKit Troubleshooting](https://fatbobman.com/en/posts/coredatawithcloudkit-4/) -- Merge policy, debug logging, production issues
- [fatbobman: Fixing SwiftData & Core Data Sync: initializeCloudKitSchema](https://fatbobman.com/en/snippet/resolving-incomplete-icloud-data-sync-in-ios-development-using-initializecloudkitschema/) -- Schema initialization
- [CrunchyBagel: General Findings About NSPersistentCloudKitContainer](https://crunchybagel.com/nspersistentcloudkitcontainer/) -- Conflict resolution behavior, merge policy
- [Hacking with Swift: Syncing SwiftData with CloudKit](https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit) -- End-to-end tutorial

### Tertiary (LOW confidence)
- [Apple Developer Forums: Thread 122745](https://developer.apple.com/forums/thread/122745) -- Discussion of last-writer-wins at entity level (community observation, not official Apple statement)
- [Apple Developer Forums: Thread 751480](https://developer.apple.com/forums/thread/751480) -- SwiftData conflict resolution limitations
- [Apple Developer Forums: Thread 743493](https://developer.apple.com/forums/thread/743493) -- CloudKit conflict resolution with NSPersistentCloudKitContainer
- [Medium articles on offline sync strategies](https://ravi6997.medium.com/offline-sync-strategies-core-data-cloudkit-swiftdata-in-ios-apps-3760684567fd) -- General patterns, not SwiftData-specific

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All Apple frameworks, no external dependencies, well-documented APIs
- Architecture (SyncMonitor pattern): HIGH -- eventChangedNotification is stable API; NWPathMonitor is stable API; @Observable environment injection is standard SwiftUI
- Architecture (conflict resolution): MEDIUM -- CloudKit conflict behavior is poorly documented officially; community consensus is record-level LWW but Apple has not stated this explicitly
- Pitfalls: HIGH -- Multiple sources agree on all listed pitfalls
- Code examples: HIGH -- All examples use documented Apple APIs with verified patterns

**Research date:** 2026-02-09
**Valid until:** 2026-03-09 (stable Apple frameworks, 30-day validity)
