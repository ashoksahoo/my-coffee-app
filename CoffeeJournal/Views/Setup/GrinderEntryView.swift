import SwiftUI

struct GrinderEntryView: View {
    @Binding var grinderName: String
    @Binding var grinderType: GrinderType

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            // Header
            VStack(spacing: AppSpacing.sm) {
                Text("Add Your Grinder")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.primary)

                Text("Optional \u{2014} you can add grinders later")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.subtle)
            }

            // Form fields
            VStack(spacing: AppSpacing.lg) {
                // Grinder name
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Grinder Name")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.subtle)

                    TextField("e.g., Comandante C40", text: $grinderName)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primary)
                        .padding(.vertical, AppSpacing.sm)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(AppColors.muted),
                            alignment: .bottom
                        )
                }

                // Grinder type picker
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Grinder Type")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.subtle)

                    Picker("Grinder Type", selection: $grinderType) {
                        Text("Burr").tag(GrinderType.burr)
                        Text("Blade").tag(GrinderType.blade)
                        Text("Manual").tag(GrinderType.manual)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()
            Spacer()
        }
    }
}
