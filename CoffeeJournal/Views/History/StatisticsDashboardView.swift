import SwiftUI
import SwiftData
import Charts

struct StatisticsDashboardView: View {
    @Query(sort: \BrewLog.createdAt, order: .reverse) private var brews: [BrewLog]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if brews.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.bar",
                        title: "No Statistics Yet",
                        message: "Log some brews to see your stats"
                    )
                } else {
                    summaryCards
                    methodDistributionChart
                    ratingTrendChart
                    brewFrequencyChart
                    topBeansChart
                }
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
            StatCard(title: "Total Brews", value: "\(brews.count)", icon: "mug")
            StatCard(title: "Avg Rating", value: averageRatingFormatted, icon: "star")
            StatCard(title: "Top Method", value: topMethodName, icon: "cup.and.saucer")
            StatCard(title: "Top Bean", value: topBeanName, icon: "leaf")
        }
    }

    // MARK: - Method Distribution Chart

    private var methodDistributionChart: some View {
        let methodCounts = Dictionary(grouping: brews, by: { $0.brewMethod?.name ?? "Unknown" })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Brews by Method")
                .font(AppTypography.headline)

            Chart(methodCounts, id: \.key) { item in
                BarMark(
                    x: .value("Method", item.key),
                    y: .value("Count", item.value)
                )
                .foregroundStyle(AppColors.primary.opacity(0.8))
            }
            .frame(height: 200)
        }
    }

    // MARK: - Rating Trend Chart

    @ViewBuilder
    private var ratingTrendChart: some View {
        let ratedBrews = brews.filter { $0.rating > 0 }

        if !ratedBrews.isEmpty {
            let grouped = Dictionary(grouping: ratedBrews) { brew in
                Calendar.current.dateInterval(of: .month, for: brew.createdAt)?.start ?? brew.createdAt
            }
            let monthlyRatings = grouped.map { (month, brewsInMonth) in
                MonthlyRating(
                    month: month,
                    averageRating: Double(brewsInMonth.reduce(0) { $0 + $1.rating }) / Double(brewsInMonth.count)
                )
            }.sorted { $0.month < $1.month }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Rating Trend")
                    .font(AppTypography.headline)

                Chart(monthlyRatings) { item in
                    LineMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Rating", item.averageRating)
                    )
                    .foregroundStyle(AppColors.primary)

                    PointMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Rating", item.averageRating)
                    )
                    .foregroundStyle(AppColors.primary)
                }
                .chartYScale(domain: 0...5)
                .frame(height: 200)
            }
        }
    }

    // MARK: - Brew Frequency Chart

    private var brewFrequencyChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Brew Frequency")
                .font(AppTypography.headline)

            Chart(brews) { brew in
                BarMark(
                    x: .value("Month", brew.createdAt, unit: .month),
                    y: .value("Count", 1)
                )
                .foregroundStyle(AppColors.primary.opacity(0.8))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .frame(height: 200)
        }
    }

    // MARK: - Top Beans Chart

    @ViewBuilder
    private var topBeansChart: some View {
        let beanCounts = Dictionary(grouping: brews, by: { $0.coffeeBean?.displayName ?? "Unknown" })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        let topBeans = Array(beanCounts.prefix(5))

        if !topBeans.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Top Beans")
                    .font(AppTypography.headline)

                Chart(topBeans, id: \.key) { item in
                    BarMark(
                        x: .value("Count", item.value),
                        y: .value("Bean", item.key)
                    )
                    .foregroundStyle(AppColors.primary.opacity(0.8))
                }
                .frame(height: max(120, CGFloat(topBeans.count) * 40))
            }
        }
    }

    // MARK: - Computed Helpers

    private var averageRatingFormatted: String {
        let rated = brews.filter { $0.rating > 0 }
        guard !rated.isEmpty else { return "--" }
        let avg = Double(rated.reduce(0) { $0 + $1.rating }) / Double(rated.count)
        return String(format: "%.1f", avg)
    }

    private var topMethodName: String {
        let counts = Dictionary(grouping: brews, by: { $0.brewMethod?.name ?? "Unknown" })
            .mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "--"
    }

    private var topBeanName: String {
        let counts = Dictionary(grouping: brews, by: { $0.coffeeBean?.displayName ?? "Unknown" })
            .mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "--"
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(AppTypography.title)
                .foregroundStyle(AppColors.subtle)
            Text(value)
                .font(AppTypography.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Monthly Rating Data

private struct MonthlyRating: Identifiable {
    let id = UUID()
    let month: Date
    let averageRating: Double
}
