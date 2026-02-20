import SwiftUI
import SwiftData
import PostHog

// MARK: - PostHog Environment

enum PostHogEnv: String {
    case apiKey = "POSTHOG_API_KEY"
    case host = "POSTHOG_HOST"

    var value: String {
        guard let value = ProcessInfo.processInfo.environment[rawValue] else {
            fatalError("Set \(rawValue) in the Xcode scheme environment variables.")
        }
        return value
    }
}

@main
struct CoffeeJournalApp: App {
    let container: ModelContainer
    @State private var syncMonitor = SyncMonitor()
    @State private var networkMonitor = NetworkMonitor()

    init() {
        // PostHog: Initialize analytics (opt-out by default; user must explicitly enable)
        let posthogConfig = PostHogConfig(apiKey: PostHogEnv.apiKey.value, host: PostHogEnv.host.value)
        posthogConfig.captureApplicationLifecycleEvents = true
        PostHogSDK.shared.setup(posthogConfig)
        let analyticsEnabled = UserDefaults.standard.bool(forKey: AppStorageKeys.analyticsEnabled)
        if !analyticsEnabled { PostHogSDK.shared.optOut() }

        let schema = Schema(versionedSchema: SchemaV1.self)

        // Determine if running in UI test mode
        var inMemory = false
        #if DEBUG
        // Support both "UITESTING" (new convention) and "UI_TESTING" (legacy) launch arguments
        if CommandLine.arguments.contains("UITESTING") || CommandLine.arguments.contains("UI_TESTING") {
            inMemory = true
        }
        #endif

        // Use local-only storage by default
        // To enable CloudKit sync:
        // 1. Configure CloudKit container in Apple Developer Portal
        // 2. Change cloudKitDatabase to .automatic
        // 3. Ensure proper signing and entitlements
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none  // Disable CloudKit until properly configured
        )

        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: CoffeeJournalMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    @AppStorage(AppStorageKeys.appearanceMode) private var appearanceModeRaw = AppearanceMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(syncMonitor)
                .environment(networkMonitor)
                .preferredColorScheme((AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme)
        }
        .modelContainer(container)
    }
}
