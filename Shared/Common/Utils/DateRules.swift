import Foundation

enum RepeatKind: String, Codable { case none, daily, weekly, monthly, custom }

struct RepeatRule: Codable, Equatable {
    var kind: RepeatKind
    // For weekly: weekday set (1...7, 1=Sun per Calendar)
    var weekdays: [Int]? // custom weekly
    // For monthly: day-of-month or last-day
    var dayOfMonth: Int? // 1...31
    var isLastDayOfMonth: Bool?
    // future extensions: interval/endDate/count

    static func decode(from json: String) throws -> RepeatRule {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(RepeatRule.self, from: data)
    }
    func encode() throws -> String {
        let data = try JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

enum DateRules {
    static func nextOccurrence(afterCompleting dueDate: Date, rule: RepeatRule, calendar: Calendar = Calendar.current) -> Date? {
        switch rule.kind {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: dueDate)
        case .weekly:
            guard let weekdays = rule.weekdays, !weekdays.isEmpty else {
                // default: same weekday next week
                return calendar.date(byAdding: .weekOfYear, value: 1, to: dueDate)
            }
            return nextWeekday(from: dueDate, in: Set(weekdays), calendar: calendar)
        case .monthly:
            if rule.isLastDayOfMonth == true {
                return nextMonthEnd(from: dueDate, calendar: calendar)
            }
            let day = rule.dayOfMonth ?? calendar.component(.day, from: dueDate)
            return addMonthsClamped(date: dueDate, months: 1, targetDay: day, calendar: calendar)
        case .custom:
            // Extend as needed
            return nil
        }
    }

    static func nextWeekday(from date: Date, in weekdays: Set<Int>, calendar: Calendar) -> Date? {
        for offset in 1...14 { // search next 2 weeks
            guard let d = calendar.date(byAdding: .day, value: offset, to: date) else { continue }
            let w = calendar.component(.weekday, from: d)
            if weekdays.contains(w) { return d }
        }
        return nil
    }

    static func nextMonthEnd(from date: Date, calendar: Calendar) -> Date? {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) else { return nil }
        let range = calendar.range(of: .day, in: .month, for: nextMonth)!
        let last = range.count
        var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: nextMonth)
        comps.day = last
        return calendar.date(from: comps)
    }

    static func addMonthsClamped(date: Date, months: Int, targetDay: Int, calendar: Calendar) -> Date? {
        guard let nm = calendar.date(byAdding: .month, value: months, to: date) else { return nil }
        let range = calendar.range(of: .day, in: .month, for: nm)!
        let clampedDay = min(max(targetDay, 1), range.count)
        var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: nm)
        comps.day = clampedDay
        return calendar.date(from: comps)
    }
}


