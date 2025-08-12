import Foundation
import CoreData

public class CDStep: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDStep> {
        NSFetchRequest<CDStep>(entityName: "Step")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var isCompleted: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var parentTask: CDTask
}


