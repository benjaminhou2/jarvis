import SwiftUI
import CoreData

@main
struct JarvisApp: App {
    @StateObject private var settings = SettingsStore()
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(settings)
                .onAppear {
                    LocalNotificationCenter.shared.requestAuthorizationIfNeeded()
                }
        }
        #if os(macOS)
        .commands {
            SidebarCommands()
        }
        #endif
    }
}


