import XCTest
import SwiftData
@testable import CoffeeJournal

@MainActor
final class SwiftDataPersistenceTests: XCTestCase {
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

    // MARK: - Create and Fetch Tests

    func testCreateAndFetchBrewMethod() throws {
        let context = container.mainContext

        let method = BrewMethod(name: "V60", category: .pourOver)
        context.insert(method)
        try context.save()

        let descriptor = FetchDescriptor<BrewMethod>()
        let methods = try context.fetch(descriptor)

        XCTAssertEqual(methods.count, 1)
        XCTAssertEqual(methods.first?.name, "V60")
        XCTAssertEqual(methods.first?.category, .pourOver)
    }

    func testCreateAndFetchGrinder() throws {
        let context = container.mainContext

        let grinder = Grinder(name: "Comandante", type: .manual)
        context.insert(grinder)
        try context.save()

        let descriptor = FetchDescriptor<Grinder>()
        let grinders = try context.fetch(descriptor)

        XCTAssertEqual(grinders.count, 1)
        XCTAssertEqual(grinders.first?.name, "Comandante")
        XCTAssertEqual(grinders.first?.grinderType, .manual)
    }

    func testCreateAndFetchCoffeeBean() throws {
        let context = container.mainContext

        let bean = CoffeeBean()
        bean.roaster = "Counter Culture"
        bean.origin = "Colombia"
        context.insert(bean)
        try context.save()

        let descriptor = FetchDescriptor<CoffeeBean>()
        let beans = try context.fetch(descriptor)

        XCTAssertEqual(beans.count, 1)
        XCTAssertEqual(beans.first?.roaster, "Counter Culture")
        XCTAssertEqual(beans.first?.origin, "Colombia")
    }

    // MARK: - Relationship Tests

    func testCreateBrewLogWithRelationships() throws {
        let context = container.mainContext

        let method = BrewMethod(name: "V60", category: .pourOver)
        let grinder = Grinder(name: "Comandante", type: .manual)
        let bean = CoffeeBean()
        bean.name = "Ethiopia Yirgacheffe"

        context.insert(method)
        context.insert(grinder)
        context.insert(bean)

        let log = BrewLog()
        log.dose = 15
        log.waterAmount = 250
        log.brewMethod = method
        log.grinder = grinder
        log.coffeeBean = bean
        context.insert(log)

        try context.save()

        let descriptor = FetchDescriptor<BrewLog>()
        let logs = try context.fetch(descriptor)

        XCTAssertEqual(logs.count, 1)
        XCTAssertNotNil(logs.first?.brewMethod)
        XCTAssertNotNil(logs.first?.grinder)
        XCTAssertNotNil(logs.first?.coffeeBean)
        XCTAssertEqual(logs.first?.brewMethod?.name, "V60")
        XCTAssertEqual(logs.first?.grinder?.name, "Comandante")
        XCTAssertEqual(logs.first?.coffeeBean?.name, "Ethiopia Yirgacheffe")
    }

    func testBrewLogTastingNoteRelationship() throws {
        let context = container.mainContext

        let log = BrewLog()
        log.dose = 18
        context.insert(log)

        let note = TastingNote()
        note.acidity = 4
        note.body = 3
        note.sweetness = 5
        note.brewLog = log
        context.insert(note)

        try context.save()

        let descriptor = FetchDescriptor<BrewLog>()
        let logs = try context.fetch(descriptor)

        XCTAssertEqual(logs.count, 1)
        XCTAssertNotNil(logs.first?.tastingNote)
        XCTAssertEqual(logs.first?.tastingNote?.acidity, 4)
        XCTAssertEqual(logs.first?.tastingNote?.brewLog?.id, log.id)
    }

    // MARK: - Update Tests

    func testUpdateBrewMethod() throws {
        let context = container.mainContext

        let method = BrewMethod(name: "V60", category: .pourOver)
        context.insert(method)
        try context.save()

        method.name = "Chemex"
        try context.save()

        let descriptor = FetchDescriptor<BrewMethod>()
        let methods = try context.fetch(descriptor)

        XCTAssertEqual(methods.count, 1)
        XCTAssertEqual(methods.first?.name, "Chemex")
    }

    // MARK: - Delete Tests

    func testDeleteBrewMethod() throws {
        let context = container.mainContext

        let method1 = BrewMethod(name: "V60", category: .pourOver)
        let method2 = BrewMethod(name: "Aeropress", category: .immersion)
        context.insert(method1)
        context.insert(method2)
        try context.save()

        context.delete(method1)
        try context.save()

        let descriptor = FetchDescriptor<BrewMethod>()
        let methods = try context.fetch(descriptor)

        XCTAssertEqual(methods.count, 1)
        XCTAssertEqual(methods.first?.name, "Aeropress")
    }

    // MARK: - Multiple Relationships Test

    func testMultipleBrewLogsPerMethod() throws {
        let context = container.mainContext

        let method = BrewMethod(name: "V60", category: .pourOver)
        context.insert(method)

        let log1 = BrewLog()
        log1.dose = 15
        log1.brewMethod = method
        context.insert(log1)

        let log2 = BrewLog()
        log2.dose = 18
        log2.brewMethod = method
        context.insert(log2)

        let log3 = BrewLog()
        log3.dose = 20
        log3.brewMethod = method
        context.insert(log3)

        try context.save()

        let descriptor = FetchDescriptor<BrewLog>()
        let logs = try context.fetch(descriptor)

        XCTAssertEqual(logs.count, 3)
        XCTAssertTrue(logs.allSatisfy { $0.brewMethod?.name == "V60" })

        // Verify brewCount can be tracked on method
        method.brewCount = 3
        XCTAssertEqual(method.brewCount, 3)
    }
}
