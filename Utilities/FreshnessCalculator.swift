import Foundation

enum FreshnessLevel {
    case peak       // 0-14 days
    case acceptable // 15-30 days
    case stale      // 31+ days

    var label: String {
        switch self {
        case .peak: return "Fresh"
        case .acceptable: return "OK"
        case .stale: return "Stale"
        }
    }

    var opacity: Double {
        switch self {
        case .peak: return 1.0
        case .acceptable: return 0.6
        case .stale: return 0.3
        }
    }

    var iconName: String {
        switch self {
        case .peak: return "checkmark.circle.fill"
        case .acceptable: return "minus.circle"
        case .stale: return "exclamationmark.circle"
        }
    }
}

struct FreshnessCalculator {
    static func daysSinceRoast(from roastDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: roastDate, to: Date.now)
        return max(0, components.day ?? 0)
    }

    static func freshnessLevel(daysSinceRoast days: Int) -> FreshnessLevel {
        switch days {
        case 0...14: return .peak
        case 15...30: return .acceptable
        default: return .stale
        }
    }
}
