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
