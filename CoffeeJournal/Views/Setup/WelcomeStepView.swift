import SwiftUI

struct WelcomeStepView: View {
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            // Icon
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.primary)

            // Title
            Text("Coffee Journal")
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppColors.primary)
                .accessibilityIdentifier(AccessibilityID.Setup.welcomeTitle)

            // Subtitle
            Text("Track your brews, remember what works, and make every cup better than the last.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.subtle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()

            // Skip button
            Button {
                onSkip()
            } label: {
                Text("Skip Setup")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.subtle)
            }
            .accessibilityIdentifier(AccessibilityID.Setup.skipButton)
            .padding(.bottom, AppSpacing.md)
        }
    }
}
