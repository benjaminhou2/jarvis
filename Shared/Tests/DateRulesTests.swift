import XCTest
@testable import Jarvis

final class DateRulesTests: XCTestCase {
    func testMonthlyClampedEndOfMonth() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        // Jan 31 -> Feb 29 in leap year or Feb 28 otherwise
        let comps = DateComponents(year: 2023, month: 1, day: 31, hour: 12)
        let jan31 = calendar.date(from: comps)!
        let next = DateRules.addMonthsClamped(date: jan31, months: 1, targetDay: 31, calendar: calendar)!
        let d = calendar.component(.day, from: next)
        XCTAssertEqual(d, 28) // 2023 非闰年
    }

    func testWeeklyNextWeekday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let sat = calendar.date(from: DateComponents(year: 2023, month: 9, day: 2))! // Saturday
        let nextMon = DateRules.nextWeekday(from: sat, in: [2], calendar: calendar) // Monday=2
        XCTAssertNotNil(nextMon)
        XCTAssertEqual(calendar.component(.weekday, from: nextMon!), 2)
    }

    func testLeapYearFeb() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        // 2024-01-31 -> 2024-02-29 (闰年)
        let jan31 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 31))!
        let next = DateRules.addMonthsClamped(date: jan31, months: 1, targetDay: 31, calendar: calendar)!
        XCTAssertEqual(calendar.component(.day, from: next), 29)
    }
}


