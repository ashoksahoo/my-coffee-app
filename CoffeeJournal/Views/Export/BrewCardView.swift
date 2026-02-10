import SwiftUI

struct BrewCardView: View {
    let brew: BrewLog

    private let cardWidth: CGFloat = 400

    private let parameterColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            headerSection
            divider
            parametersGrid
            grinderSection
            tastingSection
            footerSection
        }
        .padding(AppSpacing.lg)
        .frame(width: cardWidth)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .top) {
                Text(brew.brewMethod?.name ?? "Brew")
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(Color.black)
                Spacer()
                if brew.rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...brew.rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(Color.black)
                        }
                    }
                }
            }
            if let coffee = brew.coffeeBean {
                Text(coffee.displayName)
                    .font(.subheadline)
                    .foregroundStyle(Color.gray)
            }
        }
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 1)
    }

    // MARK: - Parameters Grid

    private var parametersGrid: some View {
        LazyVGrid(columns: parameterColumns, alignment: .leading, spacing: AppSpacing.md) {
            parameterItem(value: "\(String(format: "%.1f", brew.dose))g", label: "Dose")
            parameterItem(value: brew.brewRatioFormatted, label: "Ratio")
            parameterItem(value: brew.brewTimeFormatted, label: "Time")
            if brew.waterTemperature > 0 {
                parameterItem(
                    value: "\(String(format: "%.0f", brew.waterTemperature))\u{00B0}C",
                    label: "Temp"
                )
            }
        }
    }

    private func parameterItem(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(Color.black)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.gray)
        }
    }

    // MARK: - Grinder

    @ViewBuilder
    private var grinderSection: some View {
        if let grinder = brew.grinder {
            let grindText = brew.grinderSetting > 0
                ? "\(grinder.name) -- Setting \(String(format: "%.1f", brew.grinderSetting))"
                : grinder.name
            Text(grindText)
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.8))
        }
    }

    // MARK: - Tasting Attributes

    @ViewBuilder
    private var tastingSection: some View {
        if let note = brew.tastingNote,
           (note.acidity > 0 || note.body > 0 || note.sweetness > 0) {
            SpiderChartView.fromTastingNote(note)
                .frame(height: 150)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text(brew.createdAt, format: .dateTime.month().day().year())
                .font(.caption)
                .foregroundStyle(Color.gray)
            Spacer()
            Text("Coffee Journal")
                .font(.caption)
                .foregroundStyle(Color.gray.opacity(0.6))
        }
    }
}
