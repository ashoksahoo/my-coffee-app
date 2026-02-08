import Foundation
import SwiftData

@Model
final class TastingNote {
    var id: UUID = UUID()
    var acidity: Int = 0
    var body: Int = 0
    var sweetness: Int = 0
    var flavorTags: String = ""
    var freeformNotes: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var brewLog: BrewLog?

    init() {}
}
