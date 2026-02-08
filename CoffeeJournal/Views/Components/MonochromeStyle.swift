import SwiftUI

// MARK: - Typography Scale

enum AppTypography {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title2.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let caption = Font.caption
    static let footnote = Font.footnote
}

// MARK: - Monochrome Colors

enum AppColors {
    static let primary = Color.primary
    static let secondary = Color.secondary
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let separator = Color(.separator)

    static let emphasis = Color.primary.opacity(1.0)
    static let subtle = Color.primary.opacity(0.6)
    static let muted = Color.primary.opacity(0.3)
}

// MARK: - Spacing

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Monochrome Button Style

struct MonochromeButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(AppColors.primary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.primary, lineWidth: 1)
            )
    }
}

extension View {
    func monochromeButtonStyle() -> some View {
        modifier(MonochromeButtonStyle())
    }
}
