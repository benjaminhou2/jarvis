import Foundation
import SwiftUI

final class SettingsStore: ObservableObject {
    @Published var iCloudSyncEnabled: Bool {
        didSet { UserDefaults.standard.set(iCloudSyncEnabled, forKey: Keys.iCloudSyncEnabled) }
    }

    @Published var defaultReminderMinutes: Int {
        didSet { UserDefaults.standard.set(defaultReminderMinutes, forKey: Keys.defaultReminderMinutes) }
    }

    @Published var defaultListID: UUID? {
        didSet { UserDefaults.standard.set(defaultListID?.uuidString, forKey: Keys.defaultListID) }
    }

    @Published var theme: Int {
        didSet { UserDefaults.standard.set(theme, forKey: Keys.theme) }
    }

    struct Keys {
        static let iCloudSyncEnabled = "iCloudSyncEnabled"
        static let defaultReminderMinutes = "defaultReminderMinutes"
        static let defaultListID = "defaultListID"
        static let theme = "theme"
    }

    init() {
        self.iCloudSyncEnabled = UserDefaults.standard.bool(forKey: Keys.iCloudSyncEnabled)
        let minutes = UserDefaults.standard.integer(forKey: Keys.defaultReminderMinutes)
        self.defaultReminderMinutes = minutes == 0 ? 15 : minutes
        if let idString = UserDefaults.standard.string(forKey: Keys.defaultListID), let id = UUID(uuidString: idString) {
            self.defaultListID = id
        } else {
            self.defaultListID = nil
        }
        let storedTheme = UserDefaults.standard.integer(forKey: Keys.theme)
        self.theme = storedTheme
    }
}


