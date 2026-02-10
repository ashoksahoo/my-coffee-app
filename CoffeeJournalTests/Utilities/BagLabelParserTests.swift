import Testing
import Foundation
@testable import CoffeeJournal

@Suite("BagLabelParser")
struct BagLabelParserTests {

    // MARK: - Origin Detection

    @Test("Detects Ethiopia from bag text")
    func originDetection() {
        let result = BagLabelParser.parse(recognizedTexts: ["Blue Bottle", "Ethiopia Yirgacheffe"])
        #expect(result.origin == "Ethiopia")
    }

    @Test("Detects Colombia origin")
    func colombiaOrigin() {
        let result = BagLabelParser.parse(recognizedTexts: ["Huila Colombia Single Origin"])
        #expect(result.origin == "Colombia")
    }

    // MARK: - Roast Level Detection

    @Test("Multi-word roast level takes priority over single-word")
    func multiWordRoastLevel() {
        let result = BagLabelParser.parse(recognizedTexts: ["Medium Light Roast"])
        #expect(result.roastLevel == "medium_light")
    }

    @Test("Single-word roast level detected")
    func singleWordRoastLevel() {
        let result = BagLabelParser.parse(recognizedTexts: ["Dark Roast"])
        #expect(result.roastLevel == "dark")
    }

    @Test("Medium dark roast detected")
    func mediumDarkRoastLevel() {
        let result = BagLabelParser.parse(recognizedTexts: ["Medium Dark Roast Profile"])
        #expect(result.roastLevel == "medium_dark")
    }

    // MARK: - Variety Detection

    @Test("Detects Gesha variety")
    func geshaVariety() {
        let result = BagLabelParser.parse(recognizedTexts: ["Gesha Lot 42"])
        #expect(result.variety == "Gesha")
    }

    @Test("Detects Bourbon variety")
    func bourbonVariety() {
        let result = BagLabelParser.parse(recognizedTexts: ["Red Bourbon Process"])
        #expect(result.variety == "Bourbon")
    }

    // MARK: - Processing Method

    @Test("Detects natural process")
    func naturalProcess() {
        let result = BagLabelParser.parse(recognizedTexts: ["Natural Process"])
        #expect(result.processingMethod == "natural")
    }

    @Test("Detects washed process")
    func washedProcess() {
        let result = BagLabelParser.parse(recognizedTexts: ["Washed Ethiopian"])
        #expect(result.processingMethod == "washed")
    }

    @Test("Detects honey process")
    func honeyProcess() {
        let result = BagLabelParser.parse(recognizedTexts: ["Honey Process Costa Rica"])
        #expect(result.processingMethod == "honey")
    }

    // MARK: - Roaster From First Line

    @Test("First line becomes roaster")
    func roasterFromFirstLine() {
        let result = BagLabelParser.parse(recognizedTexts: ["Counter Culture", "Ethiopia"])
        #expect(result.roaster == "Counter Culture")
    }

    @Test("First line trimmed for roaster")
    func roasterTrimmed() {
        let result = BagLabelParser.parse(recognizedTexts: ["  Blue Bottle  ", "Kenya"])
        #expect(result.roaster == "Blue Bottle")
    }

    // MARK: - Date Parsing

    @Test("Parses ISO date format within 2-year window")
    func isoDateParsing() {
        // Use a date that's definitely within the 2-year window
        let calendar = Calendar.current
        let recentDate = calendar.date(byAdding: .month, value: -1, to: Date.now)!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: recentDate)

        let result = BagLabelParser.parse(recognizedTexts: ["Roasted \(dateStr)"])
        #expect(result.roastDate != nil)
    }

    // MARK: - Edge Cases

    @Test("Empty input returns all nil fields")
    func emptyInput() {
        let result = BagLabelParser.parse(recognizedTexts: [])
        #expect(result.origin == nil)
        #expect(result.variety == nil)
        #expect(result.roastLevel == nil)
        #expect(result.processingMethod == nil)
        #expect(result.roastDate == nil)
        #expect(result.roaster == nil)
    }

    @Test("Random text with no matches returns nil fields")
    func noMatchInput() {
        let result = BagLabelParser.parse(recognizedTexts: ["Some Random Text 12345"])
        #expect(result.origin == nil)
        #expect(result.variety == nil)
    }
}
