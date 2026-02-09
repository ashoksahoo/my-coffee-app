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

// MARK: - Computed Properties

extension CoffeeBean {
    var roastLevelEnum: RoastLevel {
        get { RoastLevel(rawValue: roastLevel) ?? .medium }
        set { roastLevel = newValue.rawValue }
    }

    var processingMethodEnum: ProcessingMethod {
        get { ProcessingMethod(rawValue: processingMethod) ?? .other }
        set { processingMethod = newValue.rawValue }
    }

    var daysSinceRoast: Int? {
        guard let roastDate else { return nil }
        return FreshnessCalculator.daysSinceRoast(from: roastDate)
    }

    var freshnessLevel: FreshnessLevel? {
        guard let days = daysSinceRoast else { return nil }
        return FreshnessCalculator.freshnessLevel(daysSinceRoast: days)
    }

    var displayName: String {
        if !name.isEmpty { return name }
        if !roaster.isEmpty && !origin.isEmpty { return "\(roaster) - \(origin)" }
        if !roaster.isEmpty { return roaster }
        if !origin.isEmpty { return origin }
        return "Unnamed Coffee"
    }
}
