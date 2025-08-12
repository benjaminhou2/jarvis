import Foundation
import CoreData

enum DayRolloverManager {
    static let lastRunKey = "myday.lastRun"

    static func runIfNeeded(context: NSManagedObjectContext, calendar: Calendar = .current) {
        let defaults = UserDefaults.standard
        let last = defaults.object(forKey: lastRunKey) as? Date ?? .distantPast
        if !calendar.isDateInToday(last) {
            clearMyDay(context: context)
            defaults.set(Date(), forKey: lastRunKey)
        }
    }

    private static func clearMyDay(context: NSManagedObjectContext) {
        let req = CDTask.fetchRequest()
        req.predicate = NSPredicate(format: "myDay == YES")
        if let items = try? context.fetch(req) {
            for t in items { t.myDay = false; t.updatedAt = Date() }
            try? context.save()
        }
    }
}


