import SwiftUI
import SwiftData

@main
struct CoffeeJournalApp: App {
    let container: ModelContainer
    @State private var syncMonitor = SyncMonitor()
    @State private var networkMonitor = NetworkMonitor()

    init() {
        let schema = Schema(versionedSchema: SchemaV1.self)

        // Try to initialize with CloudKit first
        var config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )

        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: CoffeeJournalMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            // If CloudKit setup fails, fall back to local-only storage
            print("CloudKit initialization failed: \(error). Falling back to local storage.")
            config = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .none
            )
            do {
                container = try ModelContainer(
                    for: schema,
                    migrationPlan: CoffeeJournalMigrationPlan.self,
                    configurations: [config]
                )
            } catch {
                fatalError("Failed to create ModelContainer even with local storage: \(error)")
            }
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
