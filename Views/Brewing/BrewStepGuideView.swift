import SwiftUI

struct BrewStepGuideView: View {
    @Bindable var viewModel: BrewLogViewModel

    var body: some View {
        if viewModel.guidanceEnabled, let step = viewModel.currentStep {
            VStack(spacing: AppSpacing.sm) {
                // Step progress
                Text("Step \(viewModel.currentStepIndex + 1) of \(viewModel.currentSteps.count)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)

                // Current step name
                Text(step.name)
                    .font(AppTypography.headline)

                // Current step description
                Text(step.description)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondary)
                    .multilineTextAlignment(.center)

                // Step duration indicator
                if step.durationSeconds > 0 {
                    let remaining = max(0, Double(step.durationSeconds) - viewModel.stepElapsedSeconds)
                    let progress = min(1.0, viewModel.stepElapsedSeconds / Double(step.durationSeconds))

                    ProgressView(value: progress)
                        .tint(AppColors.primary)

                    Text("\(Int(remaining))s remaining")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.subtle)
                }

                // Water amount hint
                if let waterPct = step.waterPercentage, viewModel.waterAmount > 0 {
                    Text("\(Int(waterPct * viewModel.waterAmount))g water")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.secondary)
                }

                // Manual advance button
                Button("Next Step") { viewModel.advanceStep() }
                    .monochromeButtonStyle()
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
