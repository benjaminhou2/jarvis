import Foundation
import CoreData

public class CDList: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDList> {
        NSFetchRequest<CDList>(entityName: "List")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var icon: String?
    @NSManaged public var color: String?
    @NSManaged public var isSystem: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var tasks: NSSet?
}

// MARK: Generated accessors for tasks
extension CDList {
    @objc(addTasksObject)
    @NSManaged public func addToTasks(_ value: CDTask)

    @objc(removeTasksObject)
    @NSManaged public func removeFromTasks(_ value: CDTask)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)
}


