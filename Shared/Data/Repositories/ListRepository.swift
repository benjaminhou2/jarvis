import Foundation
import CoreData

protocol ListRepositoryProtocol {
    func create(name: String, icon: String?, color: String?, isSystem: Bool) throws -> CDList
    func rename(list: CDList, to name: String) throws
    func delete(list: CDList) throws
    func fetchAll() throws -> [CDList]
    func fetchUserLists() throws -> [CDList]
    func systemLists() -> [SystemList]
}

enum SystemList: CaseIterable, Identifiable {
    case myDay, planned, important, completed
    var id: String { key }
    var key: String {
        switch self {
        case .myDay: return "myday"
        case .planned: return "planned"
        case .important: return "important"
        case .completed: return "completed"
        }
    }
    var title: String {
        switch self {
        case .myDay: return "我的一天"
        case .planned: return "已计划"
        case .important: return "重要"
        case .completed: return "已完成"
        }
    }
}

final class ListRepository: ListRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func create(name: String, icon: String?, color: String?, isSystem: Bool) throws -> CDList {
        let list = CDList(context: context)
        list.id = UUID()
        list.name = name
        list.icon = icon
        list.color = color
        list.isSystem = isSystem
        list.createdAt = Date()
        list.updatedAt = Date()
        try context.save()
        return list
    }

    func rename(list: CDList, to name: String) throws {
        list.name = name
        list.updatedAt = Date()
        try context.save()
    }

    func delete(list: CDList) throws {
        context.delete(list)
        try context.save()
    }

    func fetchAll() throws -> [CDList] {
        let req = CDList.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return try context.fetch(req)
    }

    func fetchUserLists() throws -> [CDList] {
        let req = CDList.fetchRequest()
        req.predicate = NSPredicate(format: "isSystem == NO")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return try context.fetch(req)
    }

    func systemLists() -> [SystemList] { SystemList.allCases }
}


