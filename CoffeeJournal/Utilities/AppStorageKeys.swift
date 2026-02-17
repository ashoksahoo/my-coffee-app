import SwiftUI

enum AppStorageKeys {
    static let hasCompletedSetup = "hasCompletedSetup"
    static let methodSortOrder = "methodSortOrder"
    static let grinderSortOrder = "grinderSortOrder"
    static let appearanceMode = "appearanceMode"
}

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
