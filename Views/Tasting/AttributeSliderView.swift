import SwiftUI

struct AttributeSliderView: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int> = 1...5

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(label)
                    .font(AppTypography.body)
                Spacer()
                Text(value == 0 ? "\u{2014}" : "\(value)")
                    .font(AppTypography.headline)
            }

            Slider(
                value: Binding(
                    get: { value == 0 ? Double(range.lowerBound) : Double(value) },
                    set: { value = Int($0.rounded()) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(AppColors.primary)

            HStack {
                Text("Low")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)
                Spacer()
                Text("High")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)
            }
        }
    }
}
