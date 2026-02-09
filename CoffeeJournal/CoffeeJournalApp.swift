import SwiftUI
import SwiftData

@main
struct CoffeeJournalApp: App {
    let container: ModelContainer
    @State private var syncMonitor = SyncMonitor()
    @State private var networkMonitor = NetworkMonitor()

    init() {
        let schema = Schema(versionedSchema: SchemaV1.self)

        // Use local-only storage by default
        // To enable CloudKit sync:
        // 1. Configure CloudKit container in Apple Developer Portal
        // 2. Change cloudKitDatabase to .automatic
        // 3. Ensure proper signing and entitlements
        let config = ModelConfiguration(
            schema: schema,
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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(syncMonitor)
                .environment(networkMonitor)
        }
        .modelContainer(container)
    }
}
