import Foundation

enum MethodCategory: String, Codable, CaseIterable {
    case espresso = "espresso"
    case pourOver = "pour_over"
    case immersion = "immersion"
    case other = "other"

    var displayName: String {
        switch self {
        case .espresso: return "Espresso"
        case .pourOver: return "Pour Over"
        case .immersion: return "Immersion"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .espresso: return "cup.and.saucer.fill"
        case .pourOver: return "drop.fill"
        case .immersion: return "timer"
        case .other: return "mug.fill"
        }
    }
}
