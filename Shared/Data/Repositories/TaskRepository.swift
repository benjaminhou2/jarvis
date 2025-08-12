import Foundation
import CoreData

struct TaskQueryOptions: OptionSet { let rawValue: Int; static let includeCompleted = TaskQueryOptions(rawValue: 1 << 0) }

protocol TaskRepositoryProtocol {
    func create(in list: CDList, title: String, notes: String?) throws -> CDTask
    func update(_ task: CDTask, block: (CDTask) -> Void) throws
    func delete(_ task: CDTask) throws
    func toggleCompleted(_ task: CDTask) throws
    func toggleImportant(_ task: CDTask) throws
    func toggleMyDay(_ task: CDTask) throws
    func move(_ task: CDTask, to list: CDList) throws

    func fetch(by list: CDList, options: TaskQueryOptions) throws -> [CDTask]
    func search(keyword: String, tag: String?) throws -> [CDTask]

    // Smart lists
    func myDay() throws -> [CDTask]
    func planned() throws -> [CDTask]
    func important() throws -> [CDTask]
    func completed() throws -> [CDTask]
}

final class TaskRepository: TaskRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func create(in list: CDList, title: String, notes: String?) throws -> CDTask {
        let t = CDTask(context: context)
        t.id = UUID()
        t.title = title
        t.notes = notes
        t.isCompleted = false
        t.isImportant = false
        t.myDay = false
        t.sortIndex = nextSortIndex(for: list)
        t.createdAt = Date()
        t.updatedAt = Date()
        t.parentList = list
        try context.save()
        return t
    }

    func update(_ task: CDTask, block: (CDTask) -> Void) throws {
        block(task)
        task.updatedAt = Date()
        try context.save()
        rescheduleReminder(for: task)
    }

    func delete(_ task: CDTask) throws {
        context.delete(task)
        try context.save()
    }

    func toggleCompleted(_ task: CDTask) throws {
        task.isCompleted.toggle()
        task.updatedAt = Date()
        if task.isCompleted,
           let due = task.dueDate,
           let rrString = task.repeatRule,
           let rule = try? RepeatRule.decode(from: rrString),
           rule.kind != .none,
           let nextDue = DateRules.nextOccurrence(afterCompleting: due, rule: rule) {
            // 完成后生成下一条
            _ = try duplicateAsNext(from: task, nextDue: nextDue)
        }
        try context.save()
        if task.isCompleted { LocalNotificationCenter.shared.cancel(id: task.id.uuidString) } else { rescheduleReminder(for: task) }
    }

    func toggleImportant(_ task: CDTask) throws {
        task.isImportant.toggle()
        task.updatedAt = Date()
        try context.save()
    }

    func toggleMyDay(_ task: CDTask) throws {
        task.myDay.toggle()
        task.updatedAt = Date()
        try context.save()
    }

    func move(_ task: CDTask, to list: CDList) throws {
        task.parentList = list
        task.updatedAt = Date()
        try context.save()
    }

    func fetch(by list: CDList, options: TaskQueryOptions) throws -> [CDTask] {
        let req = CDTask.fetchRequest()
        var predicates: [NSPredicate] = [NSPredicate(format: "parentList == %@", list)]
        if !options.contains(.includeCompleted) {
            predicates.append(NSPredicate(format: "isCompleted == NO"))
        }
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        req.sortDescriptors = [
            NSSortDescriptor(key: "sortIndex", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        return try context.fetch(req)
    }

    func search(keyword: String, tag: String? = nil) throws -> [CDTask] {
        let req = CDTask.fetchRequest()
        let k = keyword as NSString
        var preds: [NSPredicate] = [NSPredicate(format: "title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", k, k)]
        if let tag = tag, !tag.isEmpty {
            preds.append(NSPredicate(format: "ANY tags.name ==[cd] %@", tag))
        }
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)
        // 未完成优先
        req.sortDescriptors = [
            NSSortDescriptor(key: "isCompleted", ascending: true),
            NSSortDescriptor(key: "updatedAt", ascending: false)
        ]
        return try context.fetch(req)
    }

    func myDay() throws -> [CDTask] {
        try fetchWithPredicate(NSPredicate(format: "myDay == YES AND isCompleted == NO"))
    }
    func planned() throws -> [CDTask] {
        try fetchWithPredicate(NSPredicate(format: "(dueDate != nil OR reminder != nil) AND isCompleted == NO"))
    }
    func important() throws -> [CDTask] {
        try fetchWithPredicate(NSPredicate(format: "isImportant == YES AND isCompleted == NO"))
    }
    func completed() throws -> [CDTask] {
        try fetchWithPredicate(NSPredicate(format: "isCompleted == YES"))
    }

    private func fetchWithPredicate(_ predicate: NSPredicate) throws -> [CDTask] {
        let req = CDTask.fetchRequest()
        req.predicate = predicate
        req.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        return try context.fetch(req)
    }

    private func rescheduleReminder(for task: CDTask) {
        LocalNotificationCenter.shared.cancel(id: task.id.uuidString)
        guard !task.isCompleted, let reminder = task.reminder, reminder > Date() else { return }
        LocalNotificationCenter.shared.scheduleReminder(id: task.id.uuidString, title: task.title, body: task.notes, date: reminder)
    }

    private func duplicateAsNext(from original: CDTask, nextDue: Date) throws -> CDTask {
        let t = CDTask(context: context)
        t.id = UUID()
        t.title = original.title
        t.notes = original.notes
        t.dueDate = nextDue
        // 快捷提醒：若原任务设置了提醒与提前时长，则将提醒相对 dueDate 迁移
        if let originalReminder = original.reminder, let originalDue = original.dueDate {
            let offset = originalDue.timeIntervalSince1970 - originalReminder.timeIntervalSince1970
            t.reminder = nextDue.addingTimeInterval(-offset)
        }
        t.isCompleted = false
        t.isImportant = original.isImportant
        t.repeatRule = original.repeatRule
        t.myDay = false
        t.sortIndex = nextSortIndex(for: original.parentList)
        t.createdAt = Date()
        t.updatedAt = Date()
        t.parentList = original.parentList
        try context.save()
        rescheduleReminder(for: t)
        return t
    }

    private func nextSortIndex(for list: CDList) -> Int64 {
        let req = CDTask.fetchRequest()
        req.predicate = NSPredicate(format: "parentList == %@", list)
        req.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: false)]
        req.fetchLimit = 1
        let maxIndex = (try? context.fetch(req).first?.sortIndex) ?? 0
        return maxIndex + 1
    }
}


