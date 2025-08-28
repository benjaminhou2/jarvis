import Foundation
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        // Seed minimal demo data
        let list = CDList(context: viewContext)
        list.id = UUID()
        list.name = "示例清单"
        list.isSystem = false
        list.createdAt = Date()
        list.updatedAt = Date()

        for i in 1...5 {
            let t = CDTask(context: viewContext)
            t.id = UUID()
            t.title = "任务 \(i)"
            t.isCompleted = false
            t.isImportant = (i % 2 == 0)
            t.createdAt = Date()
            t.updatedAt = Date()
            t.parentList = list
        }
        do { try viewContext.save() } catch { print("Preview save error: \(error)") }
        return controller
    }()

    init(inMemory: Bool = false) {
        // Decide cloud or local at launch; can recreate stack on toggle if needed.
        let useCloud = UserDefaults.standard.bool(forKey: SettingsStore.Keys.iCloudSyncEnabled)
        if useCloud {
            #if canImport(CloudKit)
            let c = NSPersistentCloudKitContainer(name: "Model")
            container = c
            if let desc = container.persistentStoreDescriptions.first {
                desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                desc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
            #else
            container = NSPersistentContainer(name: "Model")
            #endif
        } else {
            container = NSPersistentContainer(name: "Model")
        }

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.undoManager = UndoManager()
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        #if canImport(CloudKit)
        NotificationCenter.default.addObserver(forName: NSPersistentCloudKitContainer.eventChangedNotification, object: container, queue: .main) { notif in
            if let event = notif.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
                SyncStatusManager.shared.ingest(event: event)
            }
        }
        #endif
    }
}


