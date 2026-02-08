import Foundation
import SwiftData

@Model
final class BrewMethod {
    var id: UUID = UUID()
    var name: String = ""
    var categoryRawValue: String = MethodCategory.other.rawValue
    var notes: String = ""
    var brewCount: Int = 0
    var lastUsedDate: Date?
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var category: MethodCategory {
        get { MethodCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    var parameterSetDescription: String {
        switch category {
        case .espresso:
            return "Dose (g), Yield (g), Time, Water Temperature, Pressure Profile"
        case .pourOver:
            return "Dose (g), Water Amount (g), Time"
        case .immersion, .other:
            return "Dose (g), Water Amount (g), Time, Water Temperature"
        }
    }

    init(name: String, category: MethodCategory) {
        self.name = name
        self.categoryRawValue = category.rawValue
    }

    convenience init(from template: MethodTemplate) {
        self.init(name: template.name, category: template.category)
    }
}
