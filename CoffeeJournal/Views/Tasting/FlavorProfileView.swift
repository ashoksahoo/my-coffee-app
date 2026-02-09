import SwiftUI

struct FlavorProfileView: View {
    let brewLog: BrewLog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if let note = brewLog.tastingNote {
                    spiderChartSection(note: note)
                    flavorTagsSection(note: note)
                    freeformNotesSection(note: note)
                } else {
                    emptyState
                }
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle("Flavor Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Spider Chart Section

    @ViewBuilder
    private func spiderChartSection(note: TastingNote) -> some View {
        let hasRatings = note.acidity > 0 || note.body > 0 || note.sweetness > 0
        if hasRatings {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Tasting Attributes")
                    .font(AppTypography.headline)

                SpiderChartView.fromTastingNote(note)
                    .frame(width: 250, height: 250)
                    .frame(maxWidth: .infinity)

                HStack(spacing: AppSpacing.lg) {
                    attributeLabel("Acidity", value: note.acidity)
                    attributeLabel("Body", value: note.body)
                    attributeLabel("Sweetness", value: note.sweetness)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func attributeLabel(_ name: String, value: Int) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(name)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondary)
            Text(value > 0 ? "\(value)/5" : "--")
                .font(AppTypography.body)
        }
    }

    // MARK: - Flavor Tags Section

    @ViewBuilder
    private func flavorTagsSection(note: TastingNote) -> some View {
        let displayTags = decodedFlavorTags(for: note)
        if !displayTags.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Flavor Notes")
                    .font(AppTypography.headline)

                FlavorTagFlowView(
                    tags: displayTags.map { (id: $0.id, name: $0.name, isCustom: $0.id.hasPrefix("custom:")) },
                    onToggle: { _ in },
                    onRemoveCustom: { _ in }
                )
            }
        }
    }

    // MARK: - Freeform Notes Section

    @ViewBuilder
    private func freeformNotesSection(note: TastingNote) -> some View {
        if !note.freeformNotes.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Notes")
                    .font(AppTypography.headline)

                Text(note.freeformNotes)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondary)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "chart.bar")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.muted)
            Text("No tasting notes yet")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Helpers

    private func decodedFlavorTags(for note: TastingNote) -> [(id: String, name: String)] {
        guard !note.flavorTags.isEmpty,
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
}
