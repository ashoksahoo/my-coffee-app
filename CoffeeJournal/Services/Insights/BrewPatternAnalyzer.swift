import Foundation

struct BrewPatternAnalyzer: Sendable {

    func analyzePatterns(brews: [BrewLog]) -> [BrewPattern] {
        var patterns: [BrewPattern] = []

        let ratedBrews = brews.filter { $0.rating >= 4 }

        // MARK: - Grind preferences by origin (AI-02)

        let brewsByOrigin = Dictionary(grouping: ratedBrews) { $0.coffeeBean?.origin ?? "" }
        for (origin, originBrews) in brewsByOrigin where !origin.isEmpty && originBrews.count >= 3 {
            let validGrindBrews = originBrews.filter { $0.grinderSetting > 0 }
            guard !validGrindBrews.isEmpty else { continue }

            let totalWeight = validGrindBrews.reduce(0.0) { $0 + Double($1.rating) }
            let weightedAvg = validGrindBrews.reduce(0.0) { $0 + $1.grinderSetting * Double($1.rating) } / totalWeight

            guard weightedAvg > 0 else { continue }

            patterns.append(BrewPattern(
                title: "Grind for \(origin)",
                description: "Your best \(origin) brews use grind setting ~\(String(format: "%.0f", weightedAvg))",
                category: .grindPreference
            ))
        }

        // MARK: - Optimal ratios by method (AI-02)

        let brewsByMethod = Dictionary(grouping: ratedBrews) { $0.brewMethod?.name ?? "" }
        for (method, methodBrews) in brewsByMethod where !method.isEmpty && methodBrews.count >= 3 {
            let ratios = methodBrews.compactMap { $0.brewRatio }
            guard !ratios.isEmpty else { continue }

            let avgRatio = ratios.reduce(0.0, +) / Double(ratios.count)

            patterns.append(BrewPattern(
                title: "Best \(method) Ratio",
                description: "Your top-rated \(method) brews use 1:\(String(format: "%.1f", avgRatio))",
                category: .ratioOptimal
            ))
        }

        // MARK: - Favorite method (bonus)

        let allByMethod = Dictionary(grouping: brews) { $0.brewMethod?.name ?? "" }
        if let (method, methodBrews) = allByMethod.filter({ !$0.key.isEmpty }).max(by: { $0.value.count < $1.value.count }),
           methodBrews.count >= 5 {
            patterns.append(BrewPattern(
                title: "Favorite Method",
                description: "\(method) is your most-used brewing method with \(methodBrews.count) brews",
                category: .methodFavorite
            ))
        }

        // MARK: - Origin trend (bonus)

        let allByOrigin = Dictionary(grouping: brews) { $0.coffeeBean?.origin ?? "" }
        if let (origin, originBrews) = allByOrigin.filter({ !$0.key.isEmpty }).max(by: { $0.value.count < $1.value.count }),
           originBrews.count >= 5 {
            patterns.append(BrewPattern(
                title: "Origin Trend",
                description: "You've brewed \(origin) coffee \(originBrews.count) times -- your most explored origin",
                category: .originTrend
            ))
        }

        // Sort: grindPreference first, then ratioOptimal, then others
        return patterns.sorted { categoryOrder($0.category) < categoryOrder($1.category) }
    }

    // MARK: - Private

    private func categoryOrder(_ category: PatternCategory) -> Int {
        switch category {
        case .grindPreference: return 0
        case .ratioOptimal: return 1
        case .methodFavorite: return 2
        case .originTrend: return 3
        }
    }
}
