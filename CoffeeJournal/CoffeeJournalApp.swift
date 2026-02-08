import SwiftUI
import SwiftData

@main
struct CoffeeJournalApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(
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
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
