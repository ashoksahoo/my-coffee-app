import SwiftUI

struct SetupCompleteView: View {
    let methodCount: Int
    let grinderName: String

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            // Checkmark icon
            Image(systemName: "checkmark.circle")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.primary)

            // Title
            Text("You're Ready!")
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppColors.primary)
                .accessibilityIdentifier(AccessibilityID.Setup.completeTitle)

            // Summary
            VStack(spacing: AppSpacing.sm) {
                summaryRow(
                    icon: "cup.and.saucer",
                    text: "\(methodCount) brew method\(methodCount == 1 ? "" : "s") added"
                )

                if !grinderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    summaryRow(
                        icon: "gearshape",
                        text: grinderName.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                } else {
                    summaryRow(
                        icon: "gearshape",
                        text: "No grinder added"
                    )
                }
            }

            Text("You can always add more equipment later.")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.subtle)
                .padding(.top, AppSpacing.sm)

            Spacer()
        }
    }

    private func summaryRow(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppColors.subtle)
                .frame(width: 24)

            Text(text)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.primary)
        }
    }
}
