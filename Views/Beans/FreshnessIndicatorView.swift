import SwiftUI

struct FreshnessIndicatorView: View {
    let roastDate: Date?

    var body: some View {
        if let roastDate {
            let days = FreshnessCalculator.daysSinceRoast(from: roastDate)
            let level = FreshnessCalculator.freshnessLevel(daysSinceRoast: days)

            HStack(spacing: AppSpacing.xs) {
                Image(systemName: level.iconName)
                    .font(AppTypography.caption)
                Text("\(days)d")
                    .font(AppTypography.caption)
                    .fontWeight(level == .peak ? .bold : .regular)
            }
            .foregroundStyle(AppColors.primary.opacity(level.opacity))
        }
    }
}
