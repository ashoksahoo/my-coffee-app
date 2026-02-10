import SwiftUI

// MARK: - Flavor Insight View

struct FlavorInsightView: View {
    let flavors: [ExtractedFlavor]
    let isLoading: Bool

    var body: some View {
        if isLoading {
            HStack(spacing: AppSpacing.sm) {
                ProgressView()
                Text("Analyzing flavors...")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)
            }
            .padding(.vertical, AppSpacing.xs)
        } else if flavors.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("AI-Extracted Flavors", systemImage: "sparkles")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)

                FlowLayout(spacing: 8) {
                    ForEach(flavors) { flavor in
                        flavorChip(flavor)
                    }
                }
            }
        }
    }

    // MARK: - Flavor Chip

    @ViewBuilder
    private func flavorChip(_ flavor: ExtractedFlavor) -> some View {
        let opacity = max(0.5, min(1.0, flavor.confidence))

        Text(flavor.name)
            .font(AppTypography.caption)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .foregroundStyle(chipForeground(confidence: flavor.confidence))
            .background(chipBackground(confidence: flavor.confidence))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppColors.primary.opacity(opacity), lineWidth: 1)
            )
    }

    private func chipForeground(confidence: Double) -> some ShapeStyle {
        AppColors.primary.opacity(max(0.5, min(1.0, confidence)))
    }

    private func chipBackground(confidence: Double) -> some ShapeStyle {
        if confidence >= 0.8 {
            // High confidence: solid fill
            return AppColors.primary.opacity(0.15)
        } else if confidence >= 0.5 {
            // Medium confidence: lighter fill
            return AppColors.primary.opacity(0.08)
        } else {
            // Low confidence: outline only (no fill)
            return AppColors.primary.opacity(0.0)
        }
    }
}
