import Foundation

struct BrewSuggestionEngine: Sendable {

    func suggest(for bean: CoffeeBean, method: BrewMethod, history: [BrewLog]) -> BrewSuggestion? {
        // Step 1: Find brews with same bean AND same method, rated >= 4
        let sameBeanBrews = history.filter {
            $0.coffeeBean?.id == bean.id &&
            $0.brewMethod?.id == method.id &&
            $0.rating >= 4
        }

        // Step 2: If none, fall back to same origin AND same method, rated >= 4
        let matchingBrews: [BrewLog]
        if !sameBeanBrews.isEmpty {
            matchingBrews = sameBeanBrews
        } else {
            let sameOriginBrews = history.filter {
                $0.coffeeBean?.origin == bean.origin &&
                !bean.origin.isEmpty &&
                $0.brewMethod?.id == method.id &&
                $0.rating >= 4
            }
            guard !sameOriginBrews.isEmpty else { return nil }
            matchingBrews = sameOriginBrews
        }

        // Step 3: Return nil if no matching brews
        guard !matchingBrews.isEmpty else { return nil }

        // Step 4: Compute weighted averages (weight = Double(rating))
        let totalWeight = matchingBrews.reduce(0.0) { $0 + Double($1.rating) }

        let weightedDose = matchingBrews.reduce(0.0) { $0 + $1.dose * Double($1.rating) } / totalWeight

        let waterBrews = matchingBrews.filter { $0.waterAmount > 0 }
        let weightedWater: Double? = waterBrews.isEmpty ? nil : {
            let w = waterBrews.reduce(0.0) { $0 + Double($1.rating) }
            return waterBrews.reduce(0.0) { $0 + $1.waterAmount * Double($1.rating) } / w
        }()

        let yieldBrews = matchingBrews.filter { $0.yieldAmount > 0 }
        let weightedYield: Double? = yieldBrews.isEmpty ? nil : {
            let w = yieldBrews.reduce(0.0) { $0 + Double($1.rating) }
            return yieldBrews.reduce(0.0) { $0 + $1.yieldAmount * Double($1.rating) } / w
        }()

        let weightedTemp = matchingBrews.reduce(0.0) { $0 + $1.waterTemperature * Double($1.rating) } / totalWeight

        let grindBrews = matchingBrews.filter { $0.grinderSetting > 0 }
        let weightedGrind: Double? = grindBrews.isEmpty ? nil : {
            let w = grindBrews.reduce(0.0) { $0 + Double($1.rating) }
            return grindBrews.reduce(0.0) { $0 + $1.grinderSetting * Double($1.rating) } / w
        }()

        let weightedTime = matchingBrews.reduce(0.0) { $0 + $1.brewTime * Double($1.rating) } / totalWeight

        // Step 5: Determine confidence
        let count = matchingBrews.count
        let confidence: SuggestionConfidence
        if count >= 5 {
            confidence = .high
        } else if count >= 2 {
            confidence = .medium
        } else {
            confidence = .low
        }

        // Step 6: Return BrewSuggestion
        return BrewSuggestion(
            dose: weightedDose,
            waterAmount: weightedWater,
            yieldAmount: weightedYield,
            waterTemperature: weightedTemp,
            grinderSetting: weightedGrind,
            brewTime: weightedTime,
            confidence: confidence,
            basedOnCount: count
        )
    }
}
