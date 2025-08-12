import Foundation
import CoreData

enum SeedManager {
    private static let flagKey = "didSeedV1"

    static func seedIfNeeded(context: NSManagedObjectContext) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: flagKey) { return }

        let req = CDList.fetchRequest()
        req.predicate = NSPredicate(format: "isSystem == NO")
        let existingCount = (try? context.count(for: req)) ?? 0
        guard existingCount == 0 else { defaults.set(true, forKey: flagKey); return }

        let personal = CDList(context: context)
        personal.id = UUID(); personal.name = "Personal"; personal.isSystem = false; personal.createdAt = Date(); personal.updatedAt = Date()
        let work = CDList(context: context)
        work.id = UUID(); work.name = "Work"; work.isSystem = false; work.createdAt = Date(); work.updatedAt = Date()
        do { try context.save(); defaults.set(true, forKey: flagKey) } catch { print("Seed error: \(error)") }
    }
}


