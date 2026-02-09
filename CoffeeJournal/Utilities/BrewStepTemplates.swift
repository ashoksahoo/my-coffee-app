import Foundation

// MARK: - Brew Step

struct BrewStep: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let durationSeconds: Int       // 0 = untimed / manual advance
    let waterPercentage: Double?   // nil = N/A
}

// MARK: - Brew Step Template

struct BrewStepTemplate {
    static func steps(for category: MethodCategory) -> [BrewStep] {
        switch category {
        case .pourOver:
            return [
                BrewStep(name: "Bloom", description: "Pour 2x dose weight, let CO2 escape", durationSeconds: 30, waterPercentage: 0.13),
                BrewStep(name: "First Pour", description: "Slow spiral to 60% total water", durationSeconds: 30, waterPercentage: 0.47),
                BrewStep(name: "Second Pour", description: "Pour remaining water in slow spiral", durationSeconds: 30, waterPercentage: 0.40),
                BrewStep(name: "Drawdown", description: "Wait for water to drain", durationSeconds: 90, waterPercentage: nil),
            ]
        case .espresso:
            return [
                BrewStep(name: "Pre-infusion", description: "Low pressure water contact", durationSeconds: 5, waterPercentage: nil),
                BrewStep(name: "Extraction", description: "Full pressure extraction", durationSeconds: 25, waterPercentage: nil),
            ]
        case .immersion:
            return [
                BrewStep(name: "Add Water", description: "Pour all water over grounds", durationSeconds: 10, waterPercentage: 1.0),
                BrewStep(name: "Steep", description: "Wait for extraction", durationSeconds: 240, waterPercentage: nil),
                BrewStep(name: "Plunge/Filter", description: "Separate grounds from brew", durationSeconds: 30, waterPercentage: nil),
            ]
        case .other:
            return [
                BrewStep(name: "Brew", description: "Follow your method's process", durationSeconds: 0, waterPercentage: nil),
            ]
        }
    }
}
