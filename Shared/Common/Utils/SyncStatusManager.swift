import Foundation
#if canImport(CloudKit)
import CoreData
import CloudKit
#endif

final class SyncStatusManager: ObservableObject {
    static let shared = SyncStatusManager()
    @Published var lastSyncAt: Date?
    @Published var lastError: String?

    #if canImport(CloudKit)
    func ingest(event: NSPersistentCloudKitContainer.Event) {
        switch event.type {
        case .setup, .import, .export:
            if let e = event.error { lastError = e.localizedDescription }
            else { lastSyncAt = Date() }
        @unknown default:
            break
        }
    }
    #endif
}


