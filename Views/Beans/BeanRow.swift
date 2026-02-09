import SwiftUI

struct BeanRow: View {
    let bean: CoffeeBean

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            beanIcon

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(bean.displayName)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.primary)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)

                if bean.isArchived {
                    Text("Archived")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.muted)
                }
            }

            Spacer()

            FreshnessIndicatorView(roastDate: bean.roastDate)
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private var subtitle: String {
        if !bean.origin.isEmpty && !bean.variety.isEmpty {
            return "\(bean.origin) \u{00B7} \(bean.variety)"
        }
        if !bean.origin.isEmpty { return bean.origin }
        if !bean.variety.isEmpty { return bean.variety }
        return bean.roastLevelEnum.displayName
    }

    @ViewBuilder
    private var beanIcon: some View {
        if let photoData = bean.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        } else {
            Image(systemName: "leaf")
                .font(.title3)
                .foregroundStyle(AppColors.subtle)
                .frame(width: 40, height: 40)
                .background(AppColors.secondaryBackground)
                .clipShape(Circle())
        }
    }
}
