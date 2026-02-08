import Foundation
import SwiftData

@Model
final class CoffeeBean {
    var id: UUID = UUID()
    var name: String = ""
    var roaster: String = ""
    var origin: String = ""
    var region: String = ""
    var variety: String = ""
    var processingMethod: String = ""
    var roastLevel: String = ""
    var roastDate: Date?
    var notes: String = ""
    var isArchived: Bool = false
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init() {}
}
