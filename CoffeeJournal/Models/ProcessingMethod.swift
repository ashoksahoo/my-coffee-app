import Foundation

enum ProcessingMethod: String, Codable, CaseIterable {
    case washed = "washed"
    case natural = "natural"
    case honey = "honey"
    case anaerobic = "anaerobic"
    case other = "other"

    var displayName: String {
        switch self {
        case .washed: return "Washed"
        case .natural: return "Natural"
        case .honey: return "Honey"
        case .anaerobic: return "Anaerobic"
        case .other: return "Other"
        }
    }
}
