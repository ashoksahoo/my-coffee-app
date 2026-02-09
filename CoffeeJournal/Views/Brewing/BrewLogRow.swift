import SwiftUI

struct BrewLogRow: View {
    let brew: BrewLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(brew.brewMethod?.name ?? "Unknown Method")
                    .font(AppTypography.headline)

                Text(brew.coffeeBean?.displayName ?? "No coffee selected")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondary)

                HStack(spacing: 0) {
                    Text(brew.brewRatioFormatted)
                    Text(" \u{00B7} ")
                    Text("\(brew.dose, specifier: "%.1f")g")
                    Text(" \u{00B7} ")
                    Text(brew.brewTimeFormatted)
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.subtle)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text(brew.createdAt, style: .date)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)

                if brew.rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<brew.rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(AppTypography.caption)
                        }
                    }
                    .foregroundStyle(AppColors.primary)
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
