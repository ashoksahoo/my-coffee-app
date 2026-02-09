import Foundation
import SwiftData

@Model
final class BrewLog {
    var id: UUID = UUID()
    var dose: Double = 0
    var waterAmount: Double = 0
    var brewTime: Double = 0
    var waterTemperature: Double = 0
    var yieldAmount: Double = 0
    var pressureProfile: String = ""
    var grinderSetting: Double = 0
    var rating: Int = 0
    var notes: String = ""
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var brewMethod: BrewMethod?
    var grinder: Grinder?
    var coffeeBean: CoffeeBean?

    init() {}
}

// MARK: - Computed Properties

extension BrewLog {
    var brewRatio: Double? {
        guard dose > 0 else { return nil }
        if let method = brewMethod, method.category == .espresso {
            return yieldAmount > 0 ? yieldAmount / dose : nil
        } else {
            return waterAmount > 0 ? waterAmount / dose : nil
        }
    }

    var brewRatioFormatted: String {
        guard let ratio = brewRatio else { return "--" }
        return String(format: "1:%.1f", ratio)
    }

    var brewTimeFormatted: String {
        let totalSeconds = Int(brewTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
