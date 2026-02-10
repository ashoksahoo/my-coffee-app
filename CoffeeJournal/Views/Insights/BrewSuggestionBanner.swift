import SwiftUI

// MARK: - Brew Suggestion Banner

struct BrewSuggestionBanner: View {
    let suggestion: BrewSuggestion
    let onApply: () -> Void

    @State private var isDismissed: Bool = false

    var body: some View {
        if !isDismissed {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Header
                HStack {
                    Label("Suggestion", systemImage: "lightbulb")
                        .font(AppTypography.headline)

                    Spacer()

                    confidenceBadge

                    Button {
                        isDismissed = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.subtle)
                    }
                    .buttonStyle(.plain)
                }

                // Basis
                Text("Based on \(suggestion.basedOnCount) similar brew\(suggestion.basedOnCount == 1 ? "" : "s")")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondary)

                // Suggested parameters
                VStack(spacing: AppSpacing.xs) {
                    parameterRow(label: "Dose", value: String(format: "%.1fg", suggestion.dose))

                    if let water = suggestion.waterAmount {
                        parameterRow(label: "Water", value: String(format: "%.0fg", water))
                    }

                    if let yield = suggestion.yieldAmount {
                        parameterRow(label: "Yield", value: String(format: "%.1fg", yield))
                    }

                    if suggestion.waterTemperature > 0 {
                        parameterRow(label: "Temperature", value: String(format: "%.0f\u{00B0}C", suggestion.waterTemperature))
                    }

                    if let grind = suggestion.grinderSetting {
                        parameterRow(label: "Grinder Setting", value: String(format: "%.1f", grind))
                    }

                    if suggestion.brewTime > 0 {
                        let minutes = Int(suggestion.brewTime) / 60
                        let seconds = Int(suggestion.brewTime) % 60
                        parameterRow(label: "Time", value: String(format: "%d:%02d", minutes, seconds))
                    }
                }

                // Apply button
                Button {
                    onApply()
                } label: {
                    Text("Apply Suggestions")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                }
                .monochromeButtonStyle()
            }
            .padding(AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.muted, lineWidth: 1)
            )
        }
    }

    // MARK: - Confidence Badge

    private var confidenceBadge: some View {
        let (text, opacity): (String, Double) = {
            switch suggestion.confidence {
            case .high:
                return ("High confidence", 1.0)
            case .medium:
                return ("Moderate", 0.7)
            case .low:
                return ("Rough estimate", 0.5)
            }
        }()

        return Text(text)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.primary.opacity(opacity))
    }

    // MARK: - Parameter Row

    private func parameterRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondary)
            Spacer()
            Text(value)
                .font(AppTypography.caption)
        }
    }
}
