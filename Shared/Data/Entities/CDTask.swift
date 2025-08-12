import Foundation
import CoreData

public class CDTask: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTask> {
        NSFetchRequest<CDTask>(entityName: "Task")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var notes: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var reminder: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isImportant: Bool
    @NSManaged public var repeatRule: String?
    @NSManaged public var myDay: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var parentList: CDList
    @NSManaged public var steps: NSSet?
    @NSManaged public var tags: NSSet?
}

// MARK: Generated accessors for steps
extension CDTask {
    @objc(addStepsObject)
    @NSManaged public func addToSteps(_ value: CDStep)

    @objc(removeStepsObject)
    @NSManaged public func removeFromSteps(_ value: CDStep)

    @objc(addSteps:)
    @NSManaged public func addToSteps(_ values: NSSet)

    @objc(removeSteps:)
    @NSManaged public func removeFromSteps(_ values: NSSet)
}

// MARK: Generated accessors for tags
extension CDTask {
    @objc(addTagsObject)
    @NSManaged public func addToTags(_ value: CDTag)

    @objc(removeTagsObject)
    @NSManaged public func removeFromTags(_ value: CDTag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)
}


