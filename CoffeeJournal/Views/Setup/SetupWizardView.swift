import SwiftUI
import SwiftData

struct SetupWizardView: View {
    @State private var viewModel = SetupWizardViewModel()
    @Environment(\.modelContext) private var modelContext
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressBar
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)

                // Step content
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Navigation buttons
                navigationBar
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Step \(viewModel.stepNumber) of \(viewModel.totalSteps)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.subtle)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.muted)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.primary)
                        .frame(
                            width: geometry.size.width * CGFloat(viewModel.stepNumber) / CGFloat(viewModel.totalSteps),
                            height: 4
                        )
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeStepView(onSkip: onComplete)
        case .methods:
            MethodSelectionView(selectedMethods: $viewModel.selectedMethods)
        case .grinder:
            GrinderEntryView(
                grinderName: $viewModel.grinderName,
                grinderType: $viewModel.grinderType
            )
        case .complete:
            SetupCompleteView(
                methodCount: viewModel.selectedMethods.count,
                grinderName: viewModel.grinderName
            )
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            // Back button (hidden on first step)
            if viewModel.currentStep != .welcome {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.previousStep()
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.subtle)
                }
            } else {
                Spacer()
            }

            Spacer()

            // Next / Done button
            Button {
                if viewModel.currentStep == .complete {
                    viewModel.saveEquipment(context: modelContext)
                    onComplete()
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.nextStep()
                    }
                }
            } label: {
                Text(viewModel.currentStep == .complete ? "Done" : "Next")
                    .font(AppTypography.headline)
                    .foregroundStyle(viewModel.canProceed ? AppColors.primary : AppColors.muted)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                viewModel.canProceed ? AppColors.primary : AppColors.muted,
                                lineWidth: 1.5
                            )
                    )
            }
            .disabled(!viewModel.canProceed)
            .accessibilityIdentifier(
                viewModel.currentStep == .welcome
                    ? AccessibilityID.Setup.getStartedButton
                    : AccessibilityID.Setup.continueButton
            )
        }
    }
}
