import SwiftUI

struct EquipmentRow: View {
    let name: String
    let subtitle: String
    let iconName: String
    let photoData: Data?
    let brewCount: Int
    let lastUsedDate: Date?

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            equipmentIcon

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(name)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.primary)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                if brewCount > 0 {
                    Text("\(brewCount) brews")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.subtle)
                }

                if let lastUsedDate {
                    Text(lastUsedDate, style: .relative)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.muted)
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    @ViewBuilder
    private var equipmentIcon: some View {
        if let photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        } else {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(AppColors.subtle)
                .frame(width: 40, height: 40)
                .background(AppColors.secondaryBackground)
                .clipShape(Circle())
        }
    }
}
