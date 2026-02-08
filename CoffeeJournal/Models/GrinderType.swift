import Foundation

enum GrinderType: String, Codable, CaseIterable {
    case burr = "burr"
    case blade = "blade"
    case manual = "manual"

    var displayName: String {
        switch self {
        case .burr: return "Burr Grinder"
        case .blade: return "Blade Grinder"
        case .manual: return "Manual Grinder"
        }
    }

    var iconName: String {
        switch self {
        case .burr: return "gearshape.2.fill"
        case .blade: return "bolt.fill"
        case .manual: return "hand.draw.fill"
        }
    }
}
