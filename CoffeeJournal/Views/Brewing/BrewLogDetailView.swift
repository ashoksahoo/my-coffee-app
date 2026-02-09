import SwiftUI

struct BrewLogDetailView: View {
    let brew: BrewLog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                photoSection
                equipmentSection
                parametersSection
                ratingSection
                notesSection
                metadataSection
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle("Brew Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Photo

    @ViewBuilder
    private var photoSection: some View {
        if let photoData = brew.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .clipped()
        }
    }

    // MARK: - Equipment

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Equipment")
                .font(AppTypography.title)

            detailRow(label: "Brew Method", value: brew.brewMethod?.name ?? "Unknown", icon: brew.brewMethod?.category.iconName ?? "cup.and.saucer")

            if let grinder = brew.grinder {
                let grindInfo = brew.grinderSetting > 0
                    ? "\(grinder.name) (Setting: \(brew.grinderSetting, specifier: "%.1f"))"
                    : grinder.name
                detailRow(label: "Grinder", value: grindInfo, icon: "gearshape.2")
            }

            detailRow(label: "Coffee", value: brew.coffeeBean?.displayName ?? "None", icon: "leaf")
        }
    }

    // MARK: - Parameters

    private var parametersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Parameters")
                .font(AppTypography.title)

            parameterRow(label: "Dose", value: "\(brew.dose, specifier: "%.1f")g")

            if brew.waterAmount > 0 {
                parameterRow(label: "Water", value: "\(brew.waterAmount, specifier: "%.0f")g")
            }

            if brew.yieldAmount > 0 {
                parameterRow(label: "Yield", value: "\(brew.yieldAmount, specifier: "%.1f")g")
            }

            if brew.waterTemperature > 0 {
                parameterRow(label: "Temperature", value: "\(brew.waterTemperature, specifier: "%.0f")\u{00B0}C")
            }

            if !brew.pressureProfile.isEmpty {
                parameterRow(label: "Pressure", value: brew.pressureProfile)
            }

            parameterRow(label: "Brew Time", value: brew.brewTimeFormatted)

            HStack {
                Text("Ratio")
                    .foregroundStyle(AppColors.secondary)
                Spacer()
                Text(brew.brewRatioFormatted)
                    .font(AppTypography.title)
            }
        }
    }

    // MARK: - Rating

    @ViewBuilder
    private var ratingSection: some View {
        if brew.rating > 0 {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Rating")
                    .font(AppTypography.title)

                HStack(spacing: AppSpacing.sm) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= brew.rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(index <= brew.rating ? AppColors.primary : AppColors.muted)
                    }
                }
            }
        }
    }

    // MARK: - Notes

    @ViewBuilder
    private var notesSection: some View {
        if !brew.notes.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Notes")
                    .font(AppTypography.title)

                Text(brew.notes)
                    .font(AppTypography.body)
            }
        }
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        Text("Logged \(brew.createdAt, format: .dateTime.month().day().year().hour().minute())")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.subtle)
    }

    // MARK: - Helper Rows

    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.subtle)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(AppColors.secondary)
            Spacer()
            Text(value)
        }
    }

    private func parameterRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(AppColors.secondary)
            Spacer()
            Text(value)
        }
    }
}
