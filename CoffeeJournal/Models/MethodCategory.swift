import Foundation

enum MethodCategory: String, Codable, CaseIterable {
    case espresso = "espresso"
    case pourOver = "pour_over"
    case immersion = "immersion"
    case other = "other"
}
