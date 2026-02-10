import SwiftUI

// MARK: - Brew Pattern Card

struct BrewPatternCard: View {
    let pattern: BrewPattern

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: categoryIcon)
                .font(AppTypography.title)
                .foregroundStyle(AppColors.subtle)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(pattern.title)
                    .font(AppTypography.headline)

                Text(pattern.description)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Category Icon

    private var categoryIcon: String {
        switch pattern.category {
        case .grindPreference:
            return "gearshape.2"
        case .ratioOptimal:
            return "scalemass"
        case .methodFavorite:
            return "cup.and.saucer"
        case .originTrend:
            return "globe"
        }
    }
}
