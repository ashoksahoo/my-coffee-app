import XCTest
import SwiftData
@testable import CoffeeJournal

@MainActor
final class CoffeeBeanComputedTests: XCTestCase {
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

    // MARK: - Display Name Tests

    func testDisplayNameWithName() throws {
        let context = container.mainContext

        let bean = CoffeeBean()
        bean.name = "Kenya AA"
        context.insert(bean)

        try context.save()

        XCTAssertEqual(bean.displayName, "Kenya AA")
    }

    func testDisplayNameFallbackRoasterOrigin() throws {
        let context = container.mainContext

        let bean = CoffeeBean()
        bean.name = ""
        bean.roaster = "Blue Bottle"
        bean.origin = "Ethiopia"
        context.insert(bean)

        try context.save()

        XCTAssertEqual(bean.displayName, "Blue Bottle - Ethiopia")
    }

    func testDisplayNameFallbackRoasterOnly() throws {
        let context = container.mainContext

        let bean = CoffeeBean()
        bean.name = ""
        bean.roaster = "Blue Bottle"
        bean.origin = ""
        context.insert(bean)

        try context.save()

        XCTAssertEqual(bean.displayName, "Blue Bottle")
    }

    func testDisplayNameFallbackOriginOnly() throws {
        let context = container.mainContext

        let bean = CoffeeBean()
        bean.name = ""
        bean.roaster = ""
        bean.origin = "Ethiopia"
        context.insert(bean)

        try context.save()

        XCTAssertEqual(bean.displayName, "Ethiopia")
    }

    func testDisplayNameUnnamed() throws {
        let context = container.mainContext

        let bean = CoffeeBean()
        bean.name = ""
        bean.roaster = ""
        bean.origin = ""
        context.insert(bean)

        try context.save()

        XCTAssertEqual(bean.displayName, "Unnamed Coffee")
    }

    // MARK: - Enum Accessor Tests

    func testRoastLevelEnum() throws {
        let context = container.mainContext

        let bean = CoffeeBean()
        bean.roastLevel = "light"
        context.insert(bean)

        try context.save()

        XCTAssertEqual(bean.roastLevelEnum, .light)

        bean.roastLevelEnum = .dark
        XCTAssertEqual(bean.roastLevel, "dark")
    }

    func testProcessingMethodEnum() throws {
        let context = container.mainContext

        let bean = CoffeeBean()
        bean.processingMethod = "washed"
        context.insert(bean)

        try context.save()

        XCTAssertEqual(bean.processingMethodEnum, .washed)
    }

    // MARK: - Freshness Tests

    func testFreshnessLevel() throws {
        let context = container.mainContext

        let bean = CoffeeBean()
        bean.roastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date.now)!
        context.insert(bean)

        try context.save()

        XCTAssertEqual(bean.freshnessLevel, .peak)

        bean.roastDate = Calendar.current.date(byAdding: .day, value: -20, to: Date.now)!
        XCTAssertEqual(bean.freshnessLevel, .acceptable)
    }

    func testFreshnessLevelNoDate() throws {
        let context = container.mainContext

        let bean = CoffeeBean()
        bean.roastDate = nil
        context.insert(bean)

        try context.save()

        XCTAssertNil(bean.freshnessLevel)
    }
}
