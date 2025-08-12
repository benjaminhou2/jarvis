import Foundation
import CoreData

protocol TagRepositoryProtocol {
    func fetchOrCreate(name: String) throws -> CDTag
    func setTags(for task: CDTask, names: [String]) throws
}

final class TagRepository: TagRepositoryProtocol {
    private let context: NSManagedObjectContext
    init(context: NSManagedObjectContext) { self.context = context }

    func fetchOrCreate(name: String) throws -> CDTag {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw NSError(domain: "Tag", code: 0) }
        let req = CDTag.fetchRequest(); req.predicate = NSPredicate(format: "name ==[cd] %@", trimmed); req.fetchLimit = 1
        if let tag = try context.fetch(req).first { return tag }
        let t = CDTag(context: context); t.id = UUID(); t.name = trimmed
        try context.save(); return t
    }

    func setTags(for task: CDTask, names: [String]) throws {
        let unique = Array(Set(names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })).filter { !$0.isEmpty }
        var newSet: Set<CDTag> = []
        for n in unique { let tag = try fetchOrCreate(name: n); newSet.insert(tag) }
        // replace existing
        if let existing = task.tags as? Set<CDTag> {
            for tag in existing.subtracting(newSet) { task.removeFromTags(tag) }
        }
        for tag in newSet { task.addToTags(tag) }
        task.updatedAt = Date()
        try context.save()
    }
}


