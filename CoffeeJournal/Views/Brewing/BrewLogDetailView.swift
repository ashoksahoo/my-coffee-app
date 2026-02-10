import SwiftUI
import SwiftData

struct BrewLogDetailView: View {
    let brew: BrewLog
    @State private var showTastingEntry = false
    @State private var insightsViewModel = InsightsViewModel()
    @State private var renderedImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                photoSection
                equipmentSection
                parametersSection
                ratingSection
                tastingNotesSection
                notesSection
                metadataSection
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle("Brew Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let uiImage = renderedImage {
                    ShareLink(
                        item: Image(uiImage: uiImage),
                        preview: SharePreview(
                            brew.brewMethod?.name ?? "Brew",
                            image: Image(uiImage: uiImage)
                        )
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(AppColors.primary)
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .task {
            renderedImage = BrewImageRenderer.render(brew: brew)
            var textParts: [String] = []
            if let freeform = brew.tastingNote?.freeformNotes, !freeform.isEmpty {
                textParts.append(freeform)
            }
            if !brew.notes.isEmpty {
                textParts.append(brew.notes)
            }
            let combinedText = textParts.joined(separator: " ")
            if !combinedText.isEmpty {
                await insightsViewModel.extractFlavors(from: combinedText)
            }
        }
        .sheet(isPresented: $showTastingEntry) {
            NavigationStack {
                TastingNoteEntryView(brewLog: brew)
            }
        }
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
                    ? "\(grinder.name) (Setting: \(String(format: "%.1f", brew.grinderSetting)))"
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

            parameterRow(label: "Dose", value: "\(String(format: "%.1f", brew.dose))g")

            if brew.waterAmount > 0 {
                parameterRow(label: "Water", value: "\(String(format: "%.0f", brew.waterAmount))g")
            }

            if brew.yieldAmount > 0 {
                parameterRow(label: "Yield", value: "\(String(format: "%.1f", brew.yieldAmount))g")
            }

            if brew.waterTemperature > 0 {
                parameterRow(label: "Temperature", value: "\(String(format: "%.0f", brew.waterTemperature))\u{00B0}C")
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

    // MARK: - Tasting Notes

    private var tastingNotesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Tasting Notes")
                .font(AppTypography.title)

            if let note = brew.tastingNote {
                if note.acidity > 0 {
                    parameterRow(label: "Acidity", value: "\(note.acidity)/5")
                }
                if note.body > 0 {
                    parameterRow(label: "Body", value: "\(note.body)/5")
                }
                if note.sweetness > 0 {
                    parameterRow(label: "Sweetness", value: "\(note.sweetness)/5")
                }

                // Display flavor tags
                if !note.flavorTags.isEmpty,
                   let data = note.flavorTags.data(using: .utf8),
                   let tags = try? JSONDecoder().decode([String].self, from: data) {
                    let displayTags: [(id: String, name: String, isCustom: Bool)] = tags.compactMap { tag in
                        if tag.hasPrefix("custom:") {
                            let name = String(tag.dropFirst("custom:".count))
                            return (id: tag, name: name, isCustom: true)
                        } else if let node = FlavorWheel.findNode(byId: tag) {
                            return (id: tag, name: node.name, isCustom: false)
                        }
                        return nil
                    }

                    if !displayTags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(displayTags, id: \.id) { tag in
                                FlavorTagChipView(
                                    name: tag.name,
                                    isSelected: true,
                                    onTap: {}
                                )
                            }
                        }
                    }
                }

                if !note.freeformNotes.isEmpty {
                    Text(note.freeformNotes)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.secondary)
                }

                // AI-extracted flavors from freeform notes
                FlavorInsightView(
                    flavors: insightsViewModel.extractedFlavors,
                    isLoading: insightsViewModel.isExtractingFlavors
                )

                if hasFlavorProfileData(note) {
                    NavigationLink {
                        FlavorProfileView(brewLog: brew)
                    } label: {
                        Label("View Flavor Profile", systemImage: "chart.bar")
                            .font(AppTypography.body)
                    }
                    .foregroundStyle(AppColors.primary)
                    .padding(.top, AppSpacing.xs)
                }

                Button {
                    showTastingEntry = true
                } label: {
                    Label("Edit Tasting Notes", systemImage: "pencil")
                        .font(AppTypography.body)
                }
                .foregroundStyle(AppColors.primary)
                .padding(.top, AppSpacing.xs)
            } else {
                Button {
                    showTastingEntry = true
                } label: {
                    Label("Add Tasting Notes", systemImage: "plus.circle")
                        .font(AppTypography.body)
                }
                .foregroundStyle(AppColors.primary)
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

    private func hasFlavorProfileData(_ note: TastingNote) -> Bool {
        let hasRatings = note.acidity > 0 || note.body > 0 || note.sweetness > 0
        let hasTags = !note.flavorTags.isEmpty
        return hasRatings || hasTags
    }
}
