import Testing
import Foundation
@testable import CoffeeJournal

@Suite("BrewStepTemplates")
struct BrewStepTemplatesTests {

    // MARK: - Step Counts Per Category

    @Test("Pour over has 4 steps")
    func pourOverStepCount() {
        let steps = BrewStepTemplate.steps(for: .pourOver)
        #expect(steps.count == 4)
    }

    @Test("Espresso has 2 steps")
    func espressoStepCount() {
        let steps = BrewStepTemplate.steps(for: .espresso)
        #expect(steps.count == 2)
    }

    @Test("Immersion has 3 steps")
    func immersionStepCount() {
        let steps = BrewStepTemplate.steps(for: .immersion)
        #expect(steps.count == 3)
    }

    @Test("Other has 1 step")
    func otherStepCount() {
        let steps = BrewStepTemplate.steps(for: .other)
        #expect(steps.count == 1)
    }

    // MARK: - Pour Over Step Names

    @Test("Pour over steps are Bloom, First Pour, Second Pour, Drawdown")
    func pourOverStepNames() {
        let steps = BrewStepTemplate.steps(for: .pourOver)
        #expect(steps[0].name == "Bloom")
        #expect(steps[1].name == "First Pour")
        #expect(steps[2].name == "Second Pour")
        #expect(steps[3].name == "Drawdown")
    }

    // MARK: - Espresso Step Names

    @Test("Espresso steps are Pre-infusion, Extraction")
    func espressoStepNames() {
        let steps = BrewStepTemplate.steps(for: .espresso)
        #expect(steps[0].name == "Pre-infusion")
        #expect(steps[1].name == "Extraction")
    }

    // MARK: - Immersion Step Names

    @Test("Immersion steps are Add Water, Steep, Plunge/Filter")
    func immersionStepNames() {
        let steps = BrewStepTemplate.steps(for: .immersion)
        #expect(steps[0].name == "Add Water")
        #expect(steps[1].name == "Steep")
        #expect(steps[2].name == "Plunge/Filter")
    }

    // MARK: - Step Durations

    @Test("Bloom step has 30 second duration")
    func bloomDuration() {
        let steps = BrewStepTemplate.steps(for: .pourOver)
        #expect(steps[0].durationSeconds == 30)
    }

    @Test("Bloom step has ~0.13 water percentage")
    func bloomWaterPercentage() {
        let steps = BrewStepTemplate.steps(for: .pourOver)
        let percentage = steps[0].waterPercentage!
        #expect(percentage > 0.12 && percentage < 0.14)
    }

    @Test("Steep step has 240 second duration")
    func steepDuration() {
        let steps = BrewStepTemplate.steps(for: .immersion)
        #expect(steps[1].durationSeconds == 240)
    }

    @Test("Drawdown step has 90 second duration")
    func drawdownDuration() {
        let steps = BrewStepTemplate.steps(for: .pourOver)
        #expect(steps[3].durationSeconds == 90)
    }

    @Test("Other Brew step has 0 duration (untimed)")
    func otherBrewDuration() {
        let steps = BrewStepTemplate.steps(for: .other)
        #expect(steps[0].durationSeconds == 0)
    }

    // MARK: - Step Identity

    @Test("Each step has a unique ID")
    func uniqueStepIds() {
        let steps = BrewStepTemplate.steps(for: .pourOver)
        let ids = steps.map { $0.id }
        #expect(Set(ids).count == ids.count)
    }
}
