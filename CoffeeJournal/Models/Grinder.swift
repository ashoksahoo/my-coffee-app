import Foundation
import SwiftData

@Model
final class Grinder {
    var id: UUID = UUID()
    var name: String = ""
    var typeRawValue: String = GrinderType.burr.rawValue
    var settingMin: Double = 0
    var settingMax: Double = 40
    var settingStep: Double = 1
    var notes: String = ""
    var brewCount: Int = 0
    var lastUsedDate: Date?
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var grinderType: GrinderType {
        get { GrinderType(rawValue: typeRawValue) ?? .burr }
        set { typeRawValue = newValue.rawValue }
    }

    init(name: String, type: GrinderType) {
        self.name = name
        self.typeRawValue = type.rawValue
    }
}
