import Testing
import Foundation
@testable import CoffeeJournal

@Suite("FreshnessCalculator")
struct FreshnessCalculatorTests {

    // MARK: - freshnessLevel Boundaries

    @Test("Day 0 is peak freshness")
    func dayZeroIsPeak() {
        #expect(FreshnessCalculator.freshnessLevel(daysSinceRoast: 0) == .peak)
    }

    @Test("Day 14 is still peak freshness (upper boundary)")
    func day14IsPeak() {
        #expect(FreshnessCalculator.freshnessLevel(daysSinceRoast: 14) == .peak)
    }

    @Test("Day 15 transitions to acceptable")
    func day15IsAcceptable() {
        #expect(FreshnessCalculator.freshnessLevel(daysSinceRoast: 15) == .acceptable)
    }

    @Test("Day 30 is still acceptable (upper boundary)")
    func day30IsAcceptable() {
        #expect(FreshnessCalculator.freshnessLevel(daysSinceRoast: 30) == .acceptable)
    }

    @Test("Day 31 transitions to stale")
    func day31IsStale() {
        #expect(FreshnessCalculator.freshnessLevel(daysSinceRoast: 31) == .stale)
    }

    @Test("Day 90 is stale")
    func day90IsStale() {
        #expect(FreshnessCalculator.freshnessLevel(daysSinceRoast: 90) == .stale)
    }

    // MARK: - daysSinceRoast

    @Test("Today's roast date returns 0 days")
    func todayReturnsZero() {
        let days = FreshnessCalculator.daysSinceRoast(from: Date.now)
        #expect(days == 0)
    }

    @Test("Past dates return positive days")
    func pastDateReturnsPositive() {
        let threeDaysAgo = daysAgo(3)
        let days = FreshnessCalculator.daysSinceRoast(from: threeDaysAgo)
        #expect(days >= 2 && days <= 4) // Allow for timezone/boundary variance
    }

    @Test("Future roast date clamped to 0")
    func futureDateClampedToZero() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!
        let days = FreshnessCalculator.daysSinceRoast(from: tomorrow)
        #expect(days == 0)
    }

    // MARK: - FreshnessLevel Computed Properties

    @Test("Peak label is Fresh")
    func peakLabel() {
        #expect(FreshnessLevel.peak.label == "Fresh")
    }

    @Test("Acceptable label is OK")
    func acceptableLabel() {
        #expect(FreshnessLevel.acceptable.label == "OK")
    }

    @Test("Stale label is Stale")
    func staleLabel() {
        #expect(FreshnessLevel.stale.label == "Stale")
    }

    @Test("Peak opacity is 1.0")
    func peakOpacity() {
        #expect(FreshnessLevel.peak.opacity == 1.0)
    }

    @Test("Acceptable opacity is 0.6")
    func acceptableOpacity() {
        #expect(FreshnessLevel.acceptable.opacity == 0.6)
    }

    @Test("Stale opacity is 0.3")
    func staleOpacity() {
        #expect(FreshnessLevel.stale.opacity == 0.3)
    }

    @Test("Peak icon is checkmark.circle.fill")
    func peakIcon() {
        #expect(FreshnessLevel.peak.iconName == "checkmark.circle.fill")
    }

    @Test("Acceptable icon is minus.circle")
    func acceptableIcon() {
        #expect(FreshnessLevel.acceptable.iconName == "minus.circle")
    }

    @Test("Stale icon is exclamationmark.circle")
    func staleIcon() {
        #expect(FreshnessLevel.stale.iconName == "exclamationmark.circle")
    }
}
