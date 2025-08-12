import Foundation
import CoreData

public class CDTag: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTag> {
        NSFetchRequest<CDTag>(entityName: "Tag")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var tasks: NSSet?
}

extension CDTag {
    @objc(addTasksObject)
    @NSManaged public func addToTasks(_ value: CDTask)

    @objc(removeTasksObject)
    @NSManaged public func removeFromTasks(_ value: CDTask)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)
}


