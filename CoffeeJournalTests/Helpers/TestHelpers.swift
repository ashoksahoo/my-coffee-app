import Testing
import Foundation
@testable import CoffeeJournal

// MARK: - Date Helpers

/// Creates a Date from year/month/day components using the current calendar.
func makeDate(year: Int, month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = 12 // Noon to avoid timezone edge cases
    return Calendar.current.date(from: components)!
}

/// Returns a Date that is `days` days before now.
func daysAgo(_ days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: -days, to: Date.now)!
}
