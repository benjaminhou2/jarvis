import Foundation
import CoreData

struct BackupList: Codable { var id: UUID; var name: String; var icon: String?; var color: String?; var isSystem: Bool; var createdAt: Date; var updatedAt: Date }
struct BackupStep: Codable { var id: UUID; var title: String; var isCompleted: Bool; var createdAt: Date; var updatedAt: Date; var parentTaskId: UUID }
struct BackupTask: Codable { var id: UUID; var title: String; var notes: String?; var dueDate: Date?; var reminder: Date?; var isCompleted: Bool; var isImportant: Bool; var repeatRule: String?; var myDay: Bool; var createdAt: Date; var updatedAt: Date; var parentListId: UUID; var tagNames: [String]? }
struct BackupTag: Codable { var id: UUID; var name: String }

struct BackupEnvelope: Codable {
    var version: Int
    var lists: [BackupList]
    var tasks: [BackupTask]
    var steps: [BackupStep]
    var tags: [BackupTag]
}

enum BackupError: Error, LocalizedError {
    case empty
    case invalidSchema
    case validationFailed(String)
    case io(String)
    case versionUnsupported

    var errorDescription: String? {
        switch self {
        case .empty: return "空文件"
        case .invalidSchema: return "无效的 JSON 结构"
        case .validationFailed(let r): return "校验失败：\(r)"
        case .io(let r): return "读写失败：\(r)"
        case .versionUnsupported: return "备份版本不支持"
        }
    }
}

enum DataBackupService {
    private static var encoder: JSONEncoder { let e = JSONEncoder(); e.outputFormatting = [.prettyPrinted, .sortedKeys]; e.dateEncodingStrategy = .iso8601; return e }
    private static var decoder: JSONDecoder { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d }

    static func exportAll(date: Date = Date()) {
        let context = PersistenceController.shared.container.viewContext
        let lists = (try? context.fetch(CDList.fetchRequest())) ?? []
        let tasks = (try? context.fetch(CDTask.fetchRequest())) ?? []
        let steps = (try? context.fetch(CDStep.fetchRequest())) ?? []
        let tags = (try? context.fetch(CDTag.fetchRequest())) ?? []

        let envelope = BackupEnvelope(
            version: 1,
            lists: lists.map { .init(id: $0.id, name: $0.name, icon: $0.icon, color: $0.color, isSystem: $0.isSystem, createdAt: $0.createdAt, updatedAt: $0.updatedAt) },
            tasks: tasks.map { task in
                let names = ((task.tags as? Set<CDTag>) ?? []).map { $0.name }
                return .init(id: task.id, title: task.title, notes: task.notes, dueDate: task.dueDate, reminder: task.reminder, isCompleted: task.isCompleted, isImportant: task.isImportant, repeatRule: task.repeatRule, myDay: task.myDay, createdAt: task.createdAt, updatedAt: task.updatedAt, parentListId: task.parentList.id, tagNames: names)
            },
            steps: steps.map { .init(id: $0.id, title: $0.title, isCompleted: $0.isCompleted, createdAt: $0.createdAt, updatedAt: $0.updatedAt, parentTaskId: $0.parentTask.id) },
            tags: tags.map { .init(id: $0.id, name: $0.name) }
        )
        do {
            let data = try encoder.encode(envelope)
            let url = documentsDirectory().appendingPathComponent("JarvisBackup-\(Int(date.timeIntervalSince1970)).json")
            try data.write(to: url)
            print("Exported: \(url)")
        } catch { print("Export error: \(error)") }
    }

    static func exportToTempURL(date: Date = Date()) -> URL? {
        let context = PersistenceController.shared.container.viewContext
        let lists = (try? context.fetch(CDList.fetchRequest())) ?? []
        let tasks = (try? context.fetch(CDTask.fetchRequest())) ?? []
        let steps = (try? context.fetch(CDStep.fetchRequest())) ?? []
        let tags = (try? context.fetch(CDTag.fetchRequest())) ?? []
        let envelope = BackupEnvelope(
            version: 1,
            lists: lists.map { .init(id: $0.id, name: $0.name, icon: $0.icon, color: $0.color, isSystem: $0.isSystem, createdAt: $0.createdAt, updatedAt: $0.updatedAt) },
            tasks: tasks.map { task in
                let names = ((task.tags as? Set<CDTag>) ?? []).map { $0.name }
                return .init(id: task.id, title: task.title, notes: task.notes, dueDate: task.dueDate, reminder: task.reminder, isCompleted: task.isCompleted, isImportant: task.isImportant, repeatRule: task.repeatRule, myDay: task.myDay, createdAt: task.createdAt, updatedAt: task.updatedAt, parentListId: task.parentList.id, tagNames: names)
            },
            steps: steps.map { .init(id: $0.id, title: $0.title, isCompleted: $0.isCompleted, createdAt: $0.createdAt, updatedAt: $0.updatedAt, parentTaskId: $0.parentTask.id) },
            tags: tags.map { .init(id: $0.id, name: $0.name) }
        )
        do {
            let data = try encoder.encode(envelope)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("JarvisBackup-\(Int(date.timeIntervalSince1970)).json")
            try data.write(to: url)
            return url
        } catch { return nil }
    }

    static func importAll() {
        // For simplicity, read the latest backup file if exists
        let urls = (try? FileManager.default.contentsOfDirectory(at: documentsDirectory(), includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        guard let latest = urls.filter({ $0.lastPathComponent.hasPrefix("JarvisBackup-") }).sorted(by: { (a, b) in
            let ad = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let bd = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return ad > bd
        }).first else { print("No backup found"); return }
        do {
            try import(from: latest)
        } catch { print("Import error: \(error)") }
    }

    static func import(from url: URL) throws {
        let data = (try? Data(contentsOf: url)) ?? Data()
        if data.isEmpty { throw BackupError.empty }
        guard let env = try? decoder.decode(BackupEnvelope.self, from: data) else {
            throw BackupError.invalidSchema
        }
        try validate(env)
        try importEnvelope(env)
    }

    static func importEnvelope(_ env: BackupEnvelope) throws {
        let context = PersistenceController.shared.container.viewContext
        // Deduplicate by id
        var listMap: [UUID: CDList] = [:]
        var taskMap: [UUID: CDTask] = [:]
        // Basic version check
        guard env.version >= 1 else { throw BackupError.versionUnsupported }

        for l in env.lists {
            if let existing = try? fetchList(id: l.id, context: context) { listMap[l.id] = existing }
            else {
                let obj = CDList(context: context)
                obj.id = l.id; obj.name = l.name; obj.icon = l.icon; obj.color = l.color; obj.isSystem = l.isSystem; obj.createdAt = l.createdAt; obj.updatedAt = l.updatedAt
                listMap[l.id] = obj
            }
        }
        for t in env.tasks {
            if let existing = try? fetchTask(id: t.id, context: context) { taskMap[t.id] = existing }
            else {
                let obj = CDTask(context: context)
                obj.id = t.id; obj.title = t.title; obj.notes = t.notes; obj.dueDate = t.dueDate; obj.reminder = t.reminder; obj.isCompleted = t.isCompleted; obj.isImportant = t.isImportant; obj.repeatRule = t.repeatRule; obj.myDay = t.myDay; obj.createdAt = t.createdAt; obj.updatedAt = t.updatedAt
                if let list = listMap[t.parentListId] { obj.parentList = list } else { obj.parentList = ensureImportBucket(context: context) }
                taskMap[t.id] = obj
            }
            // attach tags
            if let names = t.tagNames, !names.isEmpty, let taskObj = taskMap[t.id] {
                let repo = TagRepository(context: context)
                try? repo.setTags(for: taskObj, names: names)
            }
        }
        for s in env.steps {
            if (try? fetchStep(id: s.id, context: context)) != nil { continue }
            let obj = CDStep(context: context)
            obj.id = s.id; obj.title = s.title; obj.isCompleted = s.isCompleted; obj.createdAt = s.createdAt; obj.updatedAt = s.updatedAt
            if let parent = taskMap[s.parentTaskId] { obj.parentTask = parent } else { continue }
        }
        for tag in env.tags {
            if (try? fetchTag(id: tag.id, context: context)) != nil { continue }
            let obj = CDTag(context: context)
            obj.id = tag.id; obj.name = tag.name
        }
        try context.save()
    }

    private static func fetchList(id: UUID, context: NSManagedObjectContext) throws -> CDList? {
        let req = CDList.fetchRequest(); req.predicate = NSPredicate(format: "id == %@", id as CVarArg); req.fetchLimit = 1
        return try context.fetch(req).first
    }
    private static func fetchTask(id: UUID, context: NSManagedObjectContext) throws -> CDTask? {
        let req = CDTask.fetchRequest(); req.predicate = NSPredicate(format: "id == %@", id as CVarArg); req.fetchLimit = 1
        return try context.fetch(req).first
    }
    private static func fetchStep(id: UUID, context: NSManagedObjectContext) throws -> CDStep? {
        let req = CDStep.fetchRequest(); req.predicate = NSPredicate(format: "id == %@", id as CVarArg); req.fetchLimit = 1
        return try context.fetch(req).first
    }
    private static func fetchTag(id: UUID, context: NSManagedObjectContext) throws -> CDTag? {
        let req = CDTag.fetchRequest(); req.predicate = NSPredicate(format: "id == %@", id as CVarArg); req.fetchLimit = 1
        return try context.fetch(req).first
    }

    private static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private static func ensureImportBucket(context: NSManagedObjectContext) -> CDList {
        let req = CDList.fetchRequest(); req.predicate = NSPredicate(format: "name == %@ AND isSystem == NO", "Imported"); req.fetchLimit = 1
        if let l = try? context.fetch(req).first { return l }
        let l = CDList(context: context); l.id = UUID(); l.name = "Imported"; l.isSystem = false; l.createdAt = Date(); l.updatedAt = Date();
        return l
    }

    private static func validate(_ env: BackupEnvelope) throws {
        // duplicate id within the same envelope -> fail
        func hasDup<T: Hashable>(_ arr: [T]) -> Bool { Set(arr).count != arr.count }
        if hasDup(env.lists.map { $0.id }) { throw BackupError.validationFailed("重复的 List id") }
        if hasDup(env.tasks.map { $0.id }) { throw BackupError.validationFailed("重复的 Task id") }
        if hasDup(env.steps.map { $0.id }) { throw BackupError.validationFailed("重复的 Step id") }
        if env.version < 1 { throw BackupError.versionUnsupported }
    }
}


