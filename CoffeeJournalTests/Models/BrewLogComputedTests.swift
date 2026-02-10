import XCTest
import SwiftData
@testable import CoffeeJournal

@MainActor
final class BrewLogComputedTests: XCTestCase {
    var container: ModelContainer!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: BrewMethod.self, Grinder.self, CoffeeBean.self, BrewLog.self, TastingNote.self,
            configurations: config
        )
    }

    override func tearDownWithError() throws {
        container = nil
    }

    // MARK: - Brew Ratio Tests

    func testBrewRatioNonEspresso() throws {
        let context = container.mainContext

        let method = BrewMethod(name: "V60", category: .pourOver)
        context.insert(method)

        let log = BrewLog()
        log.dose = 15
        log.waterAmount = 250
        log.brewMethod = method
        context.insert(log)

        try context.save()

        XCTAssertNotNil(log.brewRatio)
        XCTAssertEqual(log.brewRatio!, 250.0 / 15.0, accuracy: 0.01)
        XCTAssertEqual(log.brewRatioFormatted, "1:16.7")
    }

    func testBrewRatioEspresso() throws {
        let context = container.mainContext

        let method = BrewMethod(name: "Espresso", category: .espresso)
        context.insert(method)

        let log = BrewLog()
        log.dose = 18
        log.yieldAmount = 36
        log.brewMethod = method
        context.insert(log)

        try context.save()

        XCTAssertNotNil(log.brewRatio)
        XCTAssertEqual(log.brewRatio!, 2.0, accuracy: 0.01)
        XCTAssertEqual(log.brewRatioFormatted, "1:2.0")
    }

    func testBrewRatioZeroDose() throws {
        let context = container.mainContext

        let log = BrewLog()
        log.dose = 0
        context.insert(log)

        try context.save()

        XCTAssertNil(log.brewRatio)
        XCTAssertEqual(log.brewRatioFormatted, "--")
    }

    func testBrewRatioNoWater() throws {
        let context = container.mainContext

        let log = BrewLog()
        log.dose = 15
        log.waterAmount = 0
        context.insert(log)

        try context.save()

        XCTAssertNil(log.brewRatio)
    }

    // MARK: - Brew Time Formatting Tests

    func testBrewTimeFormatted() throws {
        let context = container.mainContext

        let log = BrewLog()
        log.brewTime = 185 // 3 minutes 5 seconds
        context.insert(log)

        try context.save()

        XCTAssertEqual(log.brewTimeFormatted, "3:05")
    }

    func testBrewTimeFormattedZero() throws {
        let context = container.mainContext

        let log = BrewLog()
        log.brewTime = 0
        context.insert(log)

        try context.save()

        XCTAssertEqual(log.brewTimeFormatted, "0:00")
    }
}
