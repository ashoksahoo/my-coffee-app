import SwiftUI

struct FlavorTagChipView: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(name)
                .font(AppTypography.caption)

            if let onRemove {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(isSelected ? AppColors.primary : Color.clear)
        .foregroundStyle(isSelected ? AppColors.background : AppColors.primary)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppColors.primary, lineWidth: 1))
        .onTapGesture(perform: onTap)
    }
}
