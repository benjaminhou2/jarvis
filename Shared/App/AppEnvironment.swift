import Foundation
import CoreData

final class AppEnvironment {
    static let shared = AppEnvironment()
    let persistence: PersistenceController
    let notifications: LocalNotificationCenter

    private init() {
        self.persistence = PersistenceController.shared
        self.notifications = LocalNotificationCenter.shared
    }
}


