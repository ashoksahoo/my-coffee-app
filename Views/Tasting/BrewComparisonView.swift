import SwiftUI
import SwiftData

// MARK: - Comparison Side

enum ComparisonSide {
    case left, right
}

// MARK: - Brew Comparison View

struct BrewComparisonView: View {
    @Query(sort: \BrewLog.createdAt, order: .reverse) private var allBrews: [BrewLog]
    @State private var brewA: BrewLog?
    @State private var brewB: BrewLog?
    @State private var showingPickerForSide: ComparisonSide?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                brewSelectors
                if let a = brewA, let b = brewB {
                    attributeComparison(a: a, b: b)
                    flavorComparison(a: a, b: b)
                    parametersComparison(a: a, b: b)
                }
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle("Compare Brews")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $showingPickerForSide) { side in
            NavigationStack {
                BrewPickerSheet(
                    brews: filteredBrews(excluding: side),
                    onSelect: { brew in
                        switch side {
                        case .left: brewA = brew
                        case .right: brewB = brew
                        }
                        showingPickerForSide = nil
                    }
                )
            }
        }
    }

    // MARK: - Brew Selectors

    private var brewSelectors: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            brewSelector(brew: brewA, side: .left)
            Divider()
                .frame(height: 60)
            brewSelector(brew: brewB, side: .right)
        }
    }

    private func brewSelector(brew: BrewLog?, side: ComparisonSide) -> some View {
        Button {
            showingPickerForSide = side
        } label: {
            VStack(spacing: AppSpacing.xs) {
                if let brew {
                    Text(brew.coffeeBean?.displayName ?? "Unknown Coffee")
                        .font(AppTypography.headline)
                        .lineLimit(1)
                    Text(brew.brewMethod?.name ?? "Unknown Method")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondary)
                    Text(brew.createdAt, format: .dateTime.month(.abbreviated).day())
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.subtle)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundStyle(AppColors.muted)
                    Text("Select Brew")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.sm)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .foregroundStyle(AppColors.primary)
    }

    // MARK: - Attribute Comparison

    @ViewBuilder
    private func attributeComparison(a: BrewLog, b: BrewLog) -> some View {
        let noteA = a.tastingNote
        let noteB = b.tastingNote
        let hasAnyNotes = noteA != nil || noteB != nil

        if hasAnyNotes {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Tasting Attributes")
                    .font(AppTypography.headline)

                // Attribute rows
                attributeRow(label: "Acidity", valueA: noteA?.acidity ?? 0, valueB: noteB?.acidity ?? 0)
                attributeRow(label: "Body", valueA: noteA?.body ?? 0, valueB: noteB?.body ?? 0)
                attributeRow(label: "Sweetness", valueA: noteA?.sweetness ?? 0, valueB: noteB?.sweetness ?? 0)

                // Side-by-side spider charts
                let hasRatingsA = (noteA?.acidity ?? 0) > 0 || (noteA?.body ?? 0) > 0 || (noteA?.sweetness ?? 0) > 0
                let hasRatingsB = (noteB?.acidity ?? 0) > 0 || (noteB?.body ?? 0) > 0 || (noteB?.sweetness ?? 0) > 0

                if hasRatingsA || hasRatingsB {
                    HStack(spacing: AppSpacing.sm) {
                        if let noteA, hasRatingsA {
                            SpiderChartView.fromTastingNote(noteA)
                                .frame(width: 150, height: 150)
                        } else {
                            placeholder(text: "No data")
                                .frame(width: 150, height: 150)
                        }
                        if let noteB, hasRatingsB {
                            SpiderChartView.fromTastingNote(noteB)
                                .frame(width: 150, height: 150)
                        } else {
                            placeholder(text: "No data")
                                .frame(width: 150, height: 150)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func attributeRow(label: String, valueA: Int, valueB: Int) -> some View {
        HStack {
            Text(valueA > 0 ? "\(valueA)/5" : "--")
                .font(AppTypography.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(valueB > 0 ? "\(valueB)/5" : "--")
                .font(AppTypography.body)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Flavor Comparison

    @ViewBuilder
    private func flavorComparison(a: BrewLog, b: BrewLog) -> some View {
        let tagsA = decodedFlavorTags(for: a.tastingNote)
        let tagsB = decodedFlavorTags(for: b.tastingNote)
        let hasAnyTags = !tagsA.isEmpty || !tagsB.isEmpty

        if hasAnyTags {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Flavor Notes")
                    .font(AppTypography.headline)

                let sharedIds = Set(tagsA.map(\.id)).intersection(Set(tagsB.map(\.id)))

                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        if tagsA.isEmpty {
                            Text("No flavor tags")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.muted)
                        } else {
                            FlowLayout(spacing: 6) {
                                ForEach(tagsA, id: \.id) { tag in
                                    FlavorTagChipView(
                                        name: tag.name,
                                        isSelected: sharedIds.contains(tag.id),
                                        onTap: {}
                                    )
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        if tagsB.isEmpty {
                            Text("No flavor tags")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.muted)
                        } else {
                            FlowLayout(spacing: 6) {
                                ForEach(tagsB, id: \.id) { tag in
                                    FlavorTagChipView(
                                        name: tag.name,
                                        isSelected: sharedIds.contains(tag.id),
                                        onTap: {}
                                    )
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Parameters Comparison

    private func parametersComparison(a: BrewLog, b: BrewLog) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Brew Parameters")
                .font(AppTypography.headline)

            parameterRow(label: "Dose", valueA: formatDose(a.dose), valueB: formatDose(b.dose))
            parameterRow(label: "Water", valueA: formatWater(a.waterAmount), valueB: formatWater(b.waterAmount))
            parameterRow(label: "Ratio", valueA: a.brewRatioFormatted, valueB: b.brewRatioFormatted)
            parameterRow(label: "Time", valueA: a.brewTimeFormatted, valueB: b.brewTimeFormatted)
            parameterRow(label: "Rating", valueA: formatRating(a.rating), valueB: formatRating(b.rating))
        }
    }

    private func parameterRow(label: String, valueA: String, valueB: String) -> some View {
        HStack {
            Text(valueA)
                .font(AppTypography.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(valueB)
                .font(AppTypography.body)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Helpers

    private func placeholder(text: String) -> some View {
        Text(text)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func filteredBrews(excluding side: ComparisonSide) -> [BrewLog] {
        switch side {
        case .left:
            if let brewB { return allBrews.filter { $0.id != brewB.id } }
            return allBrews
        case .right:
            if let brewA { return allBrews.filter { $0.id != brewA.id } }
            return allBrews
        }
    }

    private func decodedFlavorTags(for note: TastingNote?) -> [(id: String, name: String)] {
        guard let note, !note.flavorTags.isEmpty,
              let data = note.flavorTags.data(using: .utf8),
              let tags = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return tags.compactMap { tag in
            if tag.hasPrefix("custom:") {
                let name = String(tag.dropFirst("custom:".count))
                return (id: tag, name: name)
            } else if let node = FlavorWheel.findNode(byId: tag) {
                return (id: tag, name: node.name)
            }
            return nil
        }
    }

    private func formatDose(_ dose: Double) -> String {
        dose > 0 ? String(format: "%.1fg", dose) : "--"
    }

    private func formatWater(_ water: Double) -> String {
        water > 0 ? String(format: "%.0fg", water) : "--"
    }

    private func formatRating(_ rating: Int) -> String {
        rating > 0 ? "\(rating)/5" : "--"
    }
}

// MARK: - Identifiable Conformance for ComparisonSide

extension ComparisonSide: Identifiable {
    var id: Self { self }
}

// MARK: - Brew Picker Sheet

struct BrewPickerSheet: View {
    let brews: [BrewLog]
    let onSelect: (BrewLog) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(brews) { brew in
            Button {
                onSelect(brew)
            } label: {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(brew.coffeeBean?.displayName ?? "Unknown Coffee")
                        .font(AppTypography.body)
                    HStack {
                        Text(brew.brewMethod?.name ?? "Unknown Method")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondary)
                        Spacer()
                        Text(brew.createdAt, format: .dateTime.month(.abbreviated).day().year())
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.subtle)
                    }
                }
            }
            .foregroundStyle(AppColors.primary)
        }
        .listStyle(.plain)
        .navigationTitle("Select Brew")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}
