import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            BrewMethod.self,
            Grinder.self,
            CoffeeBean.self,
            BrewLog.self,
            TastingNote.self,
        ]
    }
}
