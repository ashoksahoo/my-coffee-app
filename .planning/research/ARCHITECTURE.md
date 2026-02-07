# Architecture Research

**Domain:** iOS Coffee Journal App with Kotlin Multiplatform + SwiftUI
**Researched:** 2026-02-07
**Confidence:** MEDIUM-HIGH

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                      SwiftUI Presentation Layer                     │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐       │
│  │ Equipment │  │  Beans    │  │ Brew Log  │  │ Insights  │       │
│  │  Views    │  │  Views    │  │  Views    │  │  Views    │       │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘       │
│        │              │              │              │               │
│  ┌─────┴──────────────┴──────────────┴──────────────┴─────┐        │
│  │           Swift ViewModel Wrappers (ObservableObject)   │        │
│  │           Observes KMP StateFlows via SKIE              │        │
│  └──────────────────────┬──────────────────────────────────┘        │
├─────────────────────────┼───────────────────────────────────────────┤
│                    SKIE Interop Boundary                             │
│         (Sealed classes → Swift enums, Flow → AsyncSequence,        │
│          suspend → async/await with cancellation)                   │
├─────────────────────────┼───────────────────────────────────────────┤
│                KMP Shared Module (commonMain)                       │
│  ┌──────────────────────┴──────────────────────────────────┐       │
│  │                  Shared ViewModels                       │       │
│  │           (StateFlow state, business logic)              │       │
│  └──────────────────────┬──────────────────────────────────┘       │
│  ┌──────────────────────┴──────────────────────────────────┐       │
│  │                   Use Cases / Interactors                │       │
│  │     (BrewLog operations, Bean management, Equipment)     │       │
│  └──────────────────────┬──────────────────────────────────┘       │
│  ┌──────────────────────┴──────────────────────────────────┐       │
│  │                  Domain Models & Interfaces              │       │
│  │    (BrewLog, Bean, Equipment, Repository interfaces)     │       │
│  └──────────────────────┬──────────────────────────────────┘       │
├─────────────────────────┼───────────────────────────────────────────┤
│              KMP Platform Source Sets (iosMain)                     │
│  ┌──────────────────────┴──────────────────────────────────┐       │
│  │              Repository Implementations                  │       │
│  │      (Calls through to Swift-provided adapters)          │       │
│  └──────────────────────┬──────────────────────────────────┘       │
├─────────────────────────┼───────────────────────────────────────────┤
│                  Swift Platform Layer                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐          │
│  │  Core Data   │  │   CloudKit   │  │   Foundation     │          │
│  │  Persistence │  │   Sync       │  │   Models (AI)    │          │
│  │  Manager     │  │   Manager    │  │   Service        │          │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘          │
│         │                 │                    │                    │
│  ┌──────┴─────────────────┴────────────────────┴───────────┐       │
│  │            Apple Platform Frameworks                     │       │
│  │   Core Data    CloudKit/NSPersistentCloudKitContainer   │       │
│  │   Foundation Models Framework    PhotosUI               │       │
│  └─────────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| SwiftUI Views | Render UI, capture user input, display state | SwiftUI `View` structs, monochrome design system |
| Swift ViewModel Wrappers | Bridge KMP ViewModels to SwiftUI reactivity | `ObservableObject` or `@Observable` (iOS 17+) wrapping KMP VMs |
| SKIE Interop Layer | Convert Kotlin types to idiomatic Swift | Compiler plugin -- sealed classes become Swift enums, Flows become AsyncSequence, suspend becomes async/await |
| KMP Shared ViewModels | Hold UI state as `StateFlow`, execute business logic | Kotlin classes extending `ViewModel` (AndroidX Lifecycle 2.8+) |
| Use Cases / Interactors | Encapsulate single business operations | Kotlin classes in `commonMain`, one per operation |
| Domain Models | Define data structures and repository contracts | Kotlin data classes + interfaces in `commonMain` |
| Repository Implementations (iosMain) | Adapt platform storage APIs to repository interfaces | Kotlin `actual` implementations or Koin-injected Swift adapters |
| Core Data Persistence Manager | CRUD operations against Core Data store | Swift class wrapping `NSManagedObjectContext` |
| CloudKit Sync Manager | Configure and monitor `NSPersistentCloudKitContainer` sync | Swift class managing sync state, conflict handling, notifications |
| Foundation Models Service | On-device AI for tasting notes, suggestions | Swift class wrapping `LanguageModelSession` with `@Generable` types |

## Recommended Architecture: Clean Architecture with Platform Bridges

**Recommendation:** Use Clean Architecture in the KMP shared module (domain / data / presentation layers) with Swift-native platform bridges for Core Data, CloudKit, and Foundation Models. This is the most well-documented and community-proven pattern for KMP + SwiftUI apps.

**Confidence:** MEDIUM-HIGH. Based on official JetBrains documentation recommending this layering, multiple community production apps using this approach, and official Android Developer KMP ViewModel documentation.

### Why Clean Architecture for This Project

1. **Core Data is iOS-only.** Unlike Room (which has KMP support), Core Data has no Kotlin API. The repository interface must be defined in `commonMain` with the Core Data implementation provided from Swift via dependency injection. Clean Architecture's dependency inversion makes this natural.

2. **CloudKit is iOS-only.** Same reasoning -- sync logic interfaces live in shared code, but `NSPersistentCloudKitContainer` configuration is entirely Swift.

3. **Foundation Models is iOS-only.** Apple Intelligence APIs are Swift-only. The shared module defines what AI features are available; Swift implements them.

4. **Future Android potential.** If the app ever targets Android, the shared module is already platform-agnostic. Android would provide Room + Firebase implementations of the same interfaces.

## Recommended Project Structure

```
coffee-app/
├── shared/                          # KMP shared module
│   ├── build.gradle.kts             # KMP configuration, SKIE plugin
│   └── src/
│       ├── commonMain/kotlin/
│       │   └── com/app/coffee/
│       │       ├── domain/
│       │       │   ├── model/        # BrewLog, Bean, Equipment, TastingNote
│       │       │   ├── repository/   # Repository interfaces
│       │       │   └── usecase/      # Business operations
│       │       ├── presentation/
│       │       │   └── viewmodel/    # Shared ViewModels with StateFlow
│       │       └── di/
│       │           └── SharedModule.kt  # Koin common module definitions
│       ├── commonTest/kotlin/        # Shared unit tests
│       ├── iosMain/kotlin/
│       │   └── com/app/coffee/
│       │       ├── di/
│       │       │   └── PlatformModule.kt  # iOS Koin module, expect/actual
│       │       └── platform/
│       │           └── Adapters.kt   # Platform adapter interfaces
│       └── iosTest/kotlin/
├── iosApp/                           # Xcode project
│   ├── iosApp/
│   │   ├── App.swift                 # Entry point, Koin init
│   │   ├── ContentView.swift         # Root navigation
│   │   ├── UI/
│   │   │   ├── DesignSystem/         # Monochrome theme, shared components
│   │   │   ├── Equipment/            # Equipment list/detail views
│   │   │   ├── Beans/                # Bean list/add views
│   │   │   ├── BrewLog/              # Brew log entry/list/detail views
│   │   │   └── Insights/             # AI-powered insights views
│   │   ├── ViewModels/
│   │   │   └── *ViewModelWrapper.swift  # ObservableObject wrappers
│   │   ├── Persistence/
│   │   │   ├── CoffeeApp.xcdatamodeld   # Core Data model
│   │   │   ├── PersistenceController.swift  # NSPersistentCloudKitContainer
│   │   │   └── Repositories/         # Core Data repository implementations
│   │   ├── Sync/
│   │   │   ├── SyncMonitor.swift     # CloudKit sync state observation
│   │   │   └── ConflictResolver.swift  # Custom conflict handling
│   │   ├── AI/
│   │   │   ├── CoffeeAIService.swift    # Foundation Models integration
│   │   │   └── GenerableTypes.swift     # @Generable structs for guided gen
│   │   └── DI/
│   │       └── KoinBridge.swift      # Swift-side Koin initialization
│   ├── iosApp.xcodeproj
│   └── iosAppTests/
├── build.gradle.kts                  # Root build file
├── settings.gradle.kts
└── gradle/
    └── libs.versions.toml            # Version catalog
```

### Structure Rationale

- **`shared/src/commonMain/`:** All business logic, domain models, and ViewModels live here. This code has zero platform dependencies. Repository interfaces define contracts; implementations are injected at runtime.
- **`shared/src/iosMain/`:** Minimal code. Primarily Koin module definitions that wire platform-specific implementations provided by Swift. Also houses `expect/actual` declarations for any platform primitives needed.
- **`iosApp/Persistence/`:** Core Data stack is entirely Swift. The `PersistenceController` configures `NSPersistentCloudKitContainer` and exposes repository implementations that conform to the interfaces defined in `commonMain`.
- **`iosApp/ViewModels/`:** Thin Swift wrappers that subscribe to KMP ViewModel StateFlows (via SKIE's AsyncSequence conversion) and publish changes to SwiftUI. These should be minimal -- mostly forwarding calls and observing state.
- **`iosApp/AI/`:** Foundation Models integration is completely isolated. The shared module defines an interface (e.g., `AIService`); Swift provides the implementation using `LanguageModelSession`.

## Architectural Patterns

### Pattern 1: Repository Interface in KMP, Implementation in Swift

**What:** Define repository contracts in `commonMain` as Kotlin interfaces. Implement them in Swift using Core Data. Inject via Koin.

**When to use:** For all data access. This is the fundamental pattern that makes the architecture work.

**Trade-offs:**
- PRO: Clean separation, testable, future-proof for Android
- CON: Extra boilerplate translating between Kotlin domain models and Core Data `NSManagedObject` subclasses
- CON: Type conversion overhead at the boundary (minor)

**Confidence:** HIGH. This is the officially recommended pattern per JetBrains documentation and the `expect/actual` + DI approach documented at kotlinlang.org.

**Example:**

```kotlin
// commonMain - domain/repository/BrewLogRepository.kt
interface BrewLogRepository {
    fun getAll(): Flow<List<BrewLog>>
    fun getById(id: String): Flow<BrewLog?>
    suspend fun save(brewLog: BrewLog)
    suspend fun delete(id: String)
}
```

```swift
// iosApp - Persistence/Repositories/CoreDataBrewLogRepository.swift
class CoreDataBrewLogRepository: BrewLogRepository {
    private let context: NSManagedObjectContext

    func getAll() -> SkieSwiftFlow<[BrewLog]> {
        // Fetch from Core Data, convert NSManagedObject to domain model
        // Return as Flow via a wrapper
    }

    func save(brewLog: BrewLog) async throws {
        // Convert domain model to NSManagedObject, save context
    }
}
```

### Pattern 2: KMP ViewModel + Swift ObservableObject Wrapper

**What:** Define ViewModels in KMP `commonMain` using `StateFlow` for state. Wrap them in Swift `ObservableObject` classes that subscribe to the flows using SKIE's AsyncSequence conversion.

**When to use:** For every screen. The KMP ViewModel holds state and logic; the Swift wrapper makes it reactive for SwiftUI.

**Trade-offs:**
- PRO: Business logic is shared and testable in Kotlin
- PRO: SKIE handles Flow-to-AsyncSequence conversion automatically
- CON: Two ViewModel layers (KMP + Swift wrapper) adds indirection
- CON: Lifecycle management requires care -- the Swift wrapper must cancel subscriptions

**Confidence:** HIGH. The AndroidX ViewModel KMP support (2.8.0+) is documented on developer.android.com. SKIE flow conversion is documented on skie.touchlab.co. KMP-ObservableViewModel by rickclephas provides an alternative with less boilerplate.

**Example:**

```kotlin
// commonMain - presentation/viewmodel/BrewLogListViewModel.kt
class BrewLogListViewModel(
    private val getBrewLogs: GetBrewLogsUseCase,
    private val deleteBrewLog: DeleteBrewLogUseCase
) : ViewModel() {

    private val _state = MutableStateFlow(BrewLogListState())
    val state: StateFlow<BrewLogListState> = _state.asStateFlow()

    init {
        viewModelScope.launch {
            getBrewLogs().collect { logs ->
                _state.update { it.copy(brewLogs = logs, isLoading = false) }
            }
        }
    }

    fun delete(id: String) {
        viewModelScope.launch {
            deleteBrewLog(id)
        }
    }
}

data class BrewLogListState(
    val brewLogs: List<BrewLog> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null
)

// Sealed class for one-shot events (SKIE converts to Swift enum)
sealed class BrewLogListEvent {
    data class ShowError(val message: String) : BrewLogListEvent()
    data object NavigateToDetail : BrewLogListEvent()
}
```

```swift
// iosApp - ViewModels/BrewLogListViewModelWrapper.swift
@MainActor
class BrewLogListViewModelWrapper: ObservableObject {
    private let viewModel: BrewLogListViewModel
    @Published var state: BrewLogListState

    init(viewModel: BrewLogListViewModel) {
        self.viewModel = viewModel
        self.state = viewModel.state.value

        // SKIE converts StateFlow to AsyncSequence
        Task {
            for await newState in viewModel.state {
                self.state = newState
            }
        }
    }

    func delete(id: String) {
        viewModel.delete(id: id)
    }
}
```

### Pattern 3: NSPersistentCloudKitContainer for Core Data + CloudKit Sync

**What:** Use `NSPersistentCloudKitContainer` instead of `NSPersistentContainer`. This automatically mirrors the Core Data store to a CloudKit private database. Changes sync bidirectionally with no additional code beyond configuration.

**When to use:** This is the recommended approach when you are using Core Data and want iCloud sync. It is the path of least resistance.

**Trade-offs:**
- PRO: Apple handles sync scheduling, conflict resolution (CRDT-based for to-many relationships), retry logic
- PRO: Offline-first by design -- Core Data is the local store, CloudKit syncs when available
- CON: Last-writer-wins conflict resolution for scalar fields (no field-level merge by default)
- CON: Debugging sync issues is notoriously difficult (see Apple TN3164)
- CON: Limited control over sync timing and batching
- CON: Schema changes in production are append-only (cannot remove fields)

**Confidence:** HIGH. This is Apple's official recommended approach, documented at developer.apple.com. The CRDT behavior for relationships was confirmed by Apple at WWDC 2019 session 202.

**Critical configuration:**

```swift
// PersistenceController.swift
class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentCloudKitContainer

    init() {
        container = NSPersistentCloudKitContainer(name: "CoffeeApp")

        // CRITICAL: Set merge policy. Without this, sync silently fails.
        // Default NSErrorMergePolicy will cause iCloud data to not merge.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Automatically merge remote changes into viewContext
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Pin to current query generation for consistent reads
        try? container.viewContext.setQueryGenerationFrom(.current)

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error)")
            }
        }
    }
}
```

### Pattern 4: Dependency Injection Bridge (Koin)

**What:** Use Koin for dependency injection in the KMP shared module. Swift provides platform implementations at app startup by passing them into Koin's module configuration.

**When to use:** Always. This is how Swift-implemented repositories reach KMP ViewModels.

**Trade-offs:**
- PRO: No expect/actual classes needed for repositories (use interfaces + DI instead)
- PRO: Koin is lightweight, no code generation
- CON: Koin errors are runtime, not compile-time (unlike kotlin-inject)
- CON: Requires a Swift-to-Kotlin bridge for initialization

**Confidence:** HIGH. Koin's official documentation covers KMP extensively at insert-koin.io.

**Example:**

```kotlin
// commonMain - di/SharedModule.kt
val sharedModule = module {
    // ViewModels
    viewModel { BrewLogListViewModel(get()) }
    viewModel { BeanListViewModel(get()) }

    // Use Cases
    factory { GetBrewLogsUseCase(get()) }
    factory { SaveBrewLogUseCase(get()) }
    factory { DeleteBrewLogUseCase(get()) }
}

// iosMain - di/PlatformModule.kt
fun initKoin(
    brewLogRepository: BrewLogRepository,
    beanRepository: BeanRepository,
    equipmentRepository: EquipmentRepository,
    aiService: AIService
) {
    startKoin {
        modules(
            sharedModule,
            module {
                single<BrewLogRepository> { brewLogRepository }
                single<BeanRepository> { beanRepository }
                single<EquipmentRepository> { equipmentRepository }
                single<AIService> { aiService }
            }
        )
    }
}
```

```swift
// iosApp - DI/KoinBridge.swift
@main
struct CoffeeApp: App {
    init() {
        let persistence = PersistenceController.shared
        PlatformModuleKt.doInitKoin(
            brewLogRepository: CoreDataBrewLogRepository(context: persistence.container.viewContext),
            beanRepository: CoreDataBeanRepository(context: persistence.container.viewContext),
            equipmentRepository: CoreDataEquipmentRepository(context: persistence.container.viewContext),
            aiService: FoundationModelsAIService()
        )
    }
}
```

### Pattern 5: Foundation Models Integration (Apple Intelligence)

**What:** Use Apple's Foundation Models framework for on-device AI features. Define an `AIService` interface in KMP `commonMain`. Implement in Swift using `LanguageModelSession` and `@Generable` types for structured output.

**When to use:** For tasting note suggestions, brew parameter recommendations, coffee flavor analysis. Only available on iOS 26+ with A17 Pro/M1+ chips.

**Trade-offs:**
- PRO: Fully on-device, private, no API costs, works offline
- PRO: `@Generable` macro provides type-safe structured output
- PRO: Streaming responses integrate naturally with SwiftUI
- CON: Requires iOS 26+ and specific hardware (limits deployment target)
- CON: ~3B parameter model -- capable for text tasks but not a large model
- CON: Cannot be accessed from Kotlin code, must stay in Swift layer

**Confidence:** MEDIUM. Framework was announced at WWDC 2025 and is in iOS 26 beta. API surface is well-documented but production experience is limited.

**Example:**

```kotlin
// commonMain - domain/repository/AIService.kt
interface AIService {
    suspend fun suggestTastingNotes(
        beanOrigin: String,
        roastLevel: String,
        brewMethod: String
    ): List<String>

    suspend fun analyzeFlavor(notes: String): FlavorProfile

    fun isAvailable(): Boolean
}
```

```swift
// iosApp - AI/FoundationModelsAIService.swift
import FoundationModels

@Generable
struct TastingNoteSuggestion {
    let notes: [String]
    let flavorWheel: [String]
    let bodyDescription: String
}

class FoundationModelsAIService: AIService {
    private let session = LanguageModelSession()

    func suggestTastingNotes(
        beanOrigin: String,
        roastLevel: String,
        brewMethod: String
    ) async throws -> [String] {
        let prompt = """
        Suggest tasting notes for a \(roastLevel) roast coffee
        from \(beanOrigin), brewed with \(brewMethod).
        """
        let response = try await session.respond(
            to: prompt,
            generating: TastingNoteSuggestion.self
        )
        return response.notes
    }

    func isAvailable() -> Bool {
        return SystemLanguageModel.default.isAvailable
    }
}
```

## Data Flow

### Primary Data Flow: User Creates a Brew Log

```
User taps "New Brew" in SwiftUI
    │
    ▼
SwiftUI View calls wrapper.save(brewLog)
    │
    ▼
Swift ViewModel Wrapper calls KMP ViewModel.save(brewLog)
    │
    ▼
KMP ViewModel calls SaveBrewLogUseCase.invoke(brewLog)
    │
    ▼
UseCase validates, calls BrewLogRepository.save(brewLog)
    │
    ▼
Repository interface resolves to CoreDataBrewLogRepository (via Koin)
    │
    ▼
CoreDataBrewLogRepository:
  1. Converts domain BrewLog → NSManagedObject (BrewLogEntity)
  2. Saves NSManagedObjectContext
    │
    ▼
NSPersistentCloudKitContainer automatically:
  1. Persists to local SQLite store (immediate)
  2. Mirrors change to CloudKit private database (background, when connected)
    │
    ▼
On other devices:
  CloudKit push notification triggers import
    │
    ▼
  NSPersistentCloudKitContainer merges remote changes
    │
    ▼
  Core Data sends NSManagedObjectContextDidSave notification
    │
    ▼
  Repository's Flow emits updated list (via NSFetchedResultsController)
    │
    ▼
  SKIE converts Flow update → AsyncSequence emission
    │
    ▼
  Swift ViewModel Wrapper receives new state, @Published triggers SwiftUI update
```

### State Management Flow

```
                    ┌─────────────────────────┐
                    │   KMP ViewModel          │
                    │                          │
    User Action ───►│  MutableStateFlow<State> │
                    │         │                │
                    │    Business Logic        │
                    │    (Use Cases)           │
                    │         │                │
                    │  StateFlow<State> ───────┼──► SKIE converts to AsyncSequence
                    └─────────────────────────┘              │
                                                             ▼
                                              ┌──────────────────────────┐
                                              │ Swift ObservableObject   │
                                              │                          │
                                              │ for await state in flow  │
                                              │   self.state = state     │
                                              │                          │
                                              │ @Published var state ────┼──► SwiftUI re-renders
                                              └──────────────────────────┘
```

### Sync State Flow

```
App Launch
    │
    ▼
PersistenceController inits NSPersistentCloudKitContainer
    │
    ├──► Local SQLite loads immediately (offline-first)
    │
    ├──► CloudKit sync starts in background
    │       │
    │       ├── Fetches remote changes (if any)
    │       ├── Merges into local store (merge policy: property-object-trump)
    │       └── Pushes local changes to CloudKit
    │
    └──► SyncMonitor observes NSPersistentCloudKitContainer.eventChangedNotification
            │
            ├── .setup / .import / .export events
            ├── Surfaces sync status to UI (syncing/synced/error)
            └── Logs errors for debugging (Apple TN3164)
```

### Key Data Flows

1. **CRUD Operations:** SwiftUI → Swift Wrapper → KMP ViewModel → KMP UseCase → Repository Interface → (resolved via Koin) → Core Data Implementation → SQLite + CloudKit
2. **Reactive Updates:** Core Data change notifications → NSFetchedResultsController → Kotlin Flow emission → SKIE AsyncSequence → Swift @Published → SwiftUI re-render
3. **AI Suggestions:** SwiftUI → Swift Wrapper → KMP ViewModel → AIService Interface → (resolved via Koin) → FoundationModelsAIService → On-device LLM → Structured response → KMP state update → SwiftUI
4. **Photo Capture:** SwiftUI PhotosPicker → Swift-only image processing → Core Data binary data or file reference → CloudKit CKAsset for sync

## Anti-Patterns

### Anti-Pattern 1: Putting Core Data Code in the KMP Shared Module

**What people do:** Try to access Core Data APIs from Kotlin using `cinterop` or by wrapping `NSManagedObject` in Kotlin.

**Why it's wrong:** Core Data's API surface is enormous, relies on Objective-C runtime features (KVO, faulting, context threading), and does not translate well to Kotlin. You would be fighting the framework at every turn. The interop overhead and debugging complexity would be immense.

**Do this instead:** Define repository interfaces in `commonMain`. Implement them entirely in Swift. Inject the Swift implementations into the KMP graph via Koin. The shared module never touches Core Data.

### Anti-Pattern 2: Exposing Generic Kotlin Types Across the Swift Boundary

**What people do:** Expose `Flow<Result<List<T>>>` or other deeply nested generic types in public KMP APIs that cross to Swift.

**Why it's wrong:** Kotlin compiles to Objective-C headers, which lose generic type information on protocols and interfaces. Without SKIE, Swift sees `Any?` instead of concrete types. Even with SKIE, deeply nested generics can cause confusing errors.

**Do this instead:** Keep the public API surface of your shared module simple. Use concrete types, not deeply nested generics. Expose `StateFlow<BrewLogListState>` (a single concrete generic) rather than `Flow<Result<List<BrewLog>>>`. SKIE handles single-level generics well.

### Anti-Pattern 3: Using `expect/actual` Classes Instead of Interfaces + DI

**What people do:** Define `expect class CoreDataBrewLogRepository` in `commonMain` and `actual class` in `iosMain`, trying to directly reference Core Data types.

**Why it's wrong:** `expect/actual` classes are still in Beta status. They limit you to one implementation per platform (no test doubles). They force platform code into the Kotlin compilation, adding complexity. They make testing harder because you cannot substitute mocks.

**Do this instead:** Define interfaces in `commonMain`. Use Koin or another DI framework to inject platform implementations at runtime. Reserve `expect/actual` for simple functions, properties, or objects (e.g., platform name, UUID generation).

### Anti-Pattern 4: Not Setting Core Data Merge Policy for CloudKit

**What people do:** Use `NSPersistentCloudKitContainer` without explicitly setting `mergePolicy` on the view context.

**Why it's wrong:** The default merge policy is `NSErrorMergePolicy`, which causes iCloud data to not be correctly merged into the local database. Sync appears to "work" during development but silently drops data in production when conflicts arise.

**Do this instead:** Always set `container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy` and `container.viewContext.automaticallyMergesChangesFromParent = true`.

### Anti-Pattern 5: Calling Kotlin Suspend Functions from Swift Without SKIE

**What people do:** Call Kotlin suspend functions from Swift, relying on the default Objective-C completion handler bridge, and wonder why cancellation does not work.

**Why it's wrong:** Without SKIE (or KMP-NativeCoroutines), Kotlin suspend functions exported to Swift lack cancellation support. If a SwiftUI view disappears while a suspend function is running, the Kotlin coroutine keeps executing. This causes memory leaks, wasted computation, and potentially stale state updates.

**Do this instead:** Use SKIE, which provides automatic bidirectional cancellation. When a Swift Task is cancelled, the underlying Kotlin coroutine is also cancelled, and vice versa.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| CloudKit (iCloud) | `NSPersistentCloudKitContainer` auto-sync | Requires iCloud capability + CloudKit container in entitlements. Push notifications capability needed for background sync. |
| Foundation Models (Apple Intelligence) | `LanguageModelSession` in Swift service class | iOS 26+, A17 Pro/M1+ only. Gracefully degrade on unsupported devices with `SystemLanguageModel.default.isAvailable` check. |
| PhotosUI | SwiftUI `PhotosPicker` for image selection | Photos stored as binary data in Core Data or as file references. CloudKit syncs via `CKAsset`. Large photos may cause sync delays. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| SwiftUI Views to Swift ViewModel Wrappers | Direct property access + method calls | Standard SwiftUI `@StateObject` / `@ObservedObject` pattern |
| Swift ViewModel Wrappers to KMP ViewModels | SKIE-bridged method calls + AsyncSequence observation | SKIE converts `StateFlow` to `AsyncSequence`, `suspend` to `async` |
| KMP ViewModels to Use Cases | Direct Kotlin function calls | All within `commonMain`, no interop needed |
| KMP Use Cases to Repository Interfaces | Kotlin interface method calls | Interface in `commonMain`, implementation injected by Koin |
| Repository Interfaces to Swift Implementations | Koin resolves at runtime | Swift classes implementing Kotlin interfaces, registered during `initKoin()` |
| Core Data to CloudKit | Automatic via `NSPersistentCloudKitContainer` | No manual code needed; observe `eventChangedNotification` for status |

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Personal use (1 user, 1-3 devices) | Current architecture is ideal. `NSPersistentCloudKitContainer` handles multi-device sync for a single iCloud account effortlessly. No server needed. |
| Power user (1 user, 1000+ brew logs, many photos) | Monitor Core Data fetch performance. Use `NSFetchedResultsController` with batch sizes. Consider storing photos as file references rather than binary data in Core Data to keep the SQLite store small. CloudKit has a 250MB asset limit per record. |
| Shared data (multiple users) | Current architecture does NOT support sharing between users. Would require CloudKit shared databases (CKShare) which `NSPersistentCloudKitContainer` supports but adds significant complexity. Defer this unless explicitly needed. |

### Scaling Priorities

1. **First bottleneck: Photo sync.** Large images syncing over CloudKit will be the first performance issue. Mitigate by compressing photos before storing, using thumbnails in list views, and syncing full-resolution lazily.
2. **Second bottleneck: Core Data fetch performance.** With thousands of brew logs, naive `fetchRequest` calls will slow down. Use `NSFetchedResultsController` with section-based fetching and batch sizes from the start.

## Build Order Implications

The architecture has clear dependency chains that dictate build order:

### Phase 1: Foundation (build first)

Build the KMP shared module skeleton, domain models, and the Core Data stack independently. These have no dependencies on each other and establish the two pillars of the app.

- KMP project setup with Gradle, SKIE plugin, Koin
- Domain models in `commonMain` (BrewLog, Bean, Equipment, TastingNote)
- Repository interfaces in `commonMain`
- Core Data model (`.xcdatamodeld`) matching domain models
- `PersistenceController` with `NSPersistentCloudKitContainer`
- Core Data repository implementations in Swift

**Rationale:** Everything else depends on having models and persistence. Getting the KMP-to-Swift bridge working early catches interop issues before the codebase grows.

### Phase 2: Vertical Slice (prove the architecture)

Build one complete feature end-to-end to validate the architecture before building more features.

- One KMP ViewModel (e.g., `EquipmentListViewModel`)
- Swift ViewModel wrapper with SKIE flow observation
- SwiftUI view displaying data from Core Data via KMP
- Koin wiring for the complete dependency chain
- Verify: data flows from Core Data → Repository → KMP ViewModel → SKIE → Swift Wrapper → SwiftUI

**Rationale:** This validates every boundary in the architecture. If the KMP-Swift interop, SKIE flow conversion, or Koin bridge has issues, discover them now with one simple entity before building the entire app.

### Phase 3: Core Features (build out horizontally)

With the architecture proven, build remaining features using the established patterns.

- Equipment management (CRUD)
- Bean management (CRUD)
- Brew log entry (the primary feature -- photos, parameters, tasting notes)
- Navigation and app structure

### Phase 4: Sync & Offline

CloudKit sync should be enabled early (Phase 1 uses `NSPersistentCloudKitContainer`) but sync-specific UX and conflict handling come after core features work locally.

- Sync status indicator in UI
- Conflict resolution UX (if needed beyond last-writer-wins)
- Offline state handling
- Multi-device testing

### Phase 5: Intelligence

Apple Intelligence features are additive and can be built last.

- Foundation Models service implementation
- Tasting note suggestions
- Flavor profile analysis
- Graceful degradation on unsupported devices

**Rationale:** AI features depend on having brew data to analyze. They require iOS 26+ which may not be the initial deployment target. They are differentiators, not table stakes.

## Alternative Architecture: KMP-ObservableViewModel (Simpler Wrapper)

**What:** Instead of manually writing Swift `ObservableObject` wrappers for each KMP ViewModel, use the KMP-ObservableViewModel library by rickclephas. This library makes KMP ViewModels directly usable as `ObservableObject` (or even `@Observable` on iOS 17+) with a single line of Swift code.

**Trade-off:** Less boilerplate but adds a third-party dependency. The manual wrapper approach gives more control and is easier to debug.

**Recommendation:** Start with manual wrappers to understand the architecture fully. If the boilerplate becomes burdensome after 3-4 ViewModels, evaluate switching to KMP-ObservableViewModel.

**Confidence:** MEDIUM. The library is actively maintained (latest release supports Kotlin 2.3.0) but adds another dependency to the KMP-Swift bridge.

## Key Architectural Decision: Core Data vs. Room KMP

**Decision:** Use Core Data (not Room KMP) for persistence.

**Rationale:**
- This is an iOS-only app (for now). Core Data is the native iOS persistence framework with deep CloudKit integration via `NSPersistentCloudKitContainer`.
- Room KMP exists but its CloudKit integration would require custom sync code via `CKSyncEngine`, which is significantly more work.
- Core Data's `NSPersistentCloudKitContainer` provides zero-code CloudKit sync for the common case. This dramatically reduces implementation effort.
- If Android is added later, Android would use Room as its `actual` implementation of the same repository interfaces. The shared module remains unchanged.

**Confidence:** HIGH. This is the correct choice for an iOS-first app with iCloud sync requirements.

## Key Architectural Decision: NSPersistentCloudKitContainer vs. CKSyncEngine

**Decision:** Use `NSPersistentCloudKitContainer` (not `CKSyncEngine`).

**Rationale:**
- `NSPersistentCloudKitContainer` is the recommended approach when your app already uses Core Data. It provides a fully managed sync pipeline.
- `CKSyncEngine` (iOS 17+) is for apps that want to bring their own local persistence and have more control over sync scheduling. Since we are using Core Data, this would mean maintaining two persistence systems unnecessarily.
- The trade-off is less control over sync behavior, but for a personal journal app, the automatic sync behavior is appropriate.

**Confidence:** HIGH. Apple's guidance is explicit: if you use Core Data, use `NSPersistentCloudKitContainer`. Multiple production apps confirm this works well for personal data apps.

## Sources

- [JetBrains KMP iOS Integration Methods](https://www.jetbrains.com/help/kotlin-multiplatform-dev/multiplatform-ios-integration-overview.html) - Official integration overview
- [Kotlin Expected and Actual Declarations](https://kotlinlang.org/docs/multiplatform/multiplatform-expect-actual.html) - Official expect/actual documentation
- [Android Developer: Set up ViewModel for KMP](https://developer.android.com/kotlin/multiplatform/viewmodel) - Official AndroidX ViewModel KMP docs
- [SKIE by Touchlab](https://skie.touchlab.co/) - SKIE features, Flow conversion, sealed class support
- [SKIE Flows Documentation](https://skie.touchlab.co/features/flows) - Detailed Flow-to-AsyncSequence conversion
- [KMP-ObservableViewModel](https://github.com/rickclephas/KMP-ObservableViewModel) - Library for using KMP ViewModels with SwiftUI
- [Koin KMP Documentation](https://insert-koin.io/docs/reference/koin-mp/kmp/) - Dependency injection for KMP
- [Apple: Setting Up Core Data with CloudKit](https://developer.apple.com/documentation/CoreData/setting-up-core-data-with-cloudkit) - NSPersistentCloudKitContainer setup
- [Apple TN3164: Debugging NSPersistentCloudKitContainer](https://developer.apple.com/documentation/technotes/tn3164-debugging-the-synchronization-of-nspersistentcloudkitcontainer) - Sync debugging guide
- [Apple: NSMergePolicy](https://developer.apple.com/documentation/coredata/nsmergepolicy) - Merge policy options
- [Apple: Foundation Models Framework](https://developer.apple.com/documentation/FoundationModels) - On-device AI documentation
- [Apple: Meet the Foundation Models Framework (WWDC25)](https://developer.apple.com/videos/play/wwdc2025/286/) - Framework introduction
- [Apple: LanguageModelSession](https://developer.apple.com/documentation/foundationmodels/languagemodelsession) - Session API
- [KMP Architecture Best Practices (carrion.dev)](https://carrion.dev/en/posts/kmp-architecture/) - Clean Architecture with KMP
- [Mastering Kotlin-Swift/ObjC Interop (Feb 2026)](https://medium.com/@thejohnsondev/mastering-kotlin-swift-objc-interop-9803fed95a65) - Recent interop guidance
- [KMP iOS Integration Challenges](https://medium.com/@eduardofelipi/ios-specific-integration-challenges-with-kotlin-multiplatform-75c6fa7a932e) - Common iOS interop issues
- [KMP Scalability Challenges](https://proandroiddev.com/kotlin-multiplatform-scalability-challenges-on-a-large-project-b3140e12da9d) - Large project considerations
- [KMP Pitfalls and Anti-Patterns](https://medium.com/@karelvdmmisc/my-journey-with-kotlin-multiplatform-mobile-pitfalls-anti-patterns-and-solutions-525df7058018) - Community experience
- [CloudKit: My Eight Years (fatbobman)](https://fatbobman.com/en/posts/my-eight-years-with-cloudkit) - Production CloudKit experience
- [CKSyncEngine vs NSPersistentCloudKitContainer](https://joethephish.me/blog/core-data-vs-cloudkit/) - Comparison and guidance
- [General Findings About NSPersistentCloudKitContainer](https://crunchybagel.com/nspersistentcloudkitcontainer/) - Production findings and conflict resolution details

---
*Architecture research for: iOS Coffee Journal App (KMP + SwiftUI + Core Data + CloudKit + Apple Intelligence)*
*Researched: 2026-02-07*
