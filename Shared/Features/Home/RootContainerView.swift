import SwiftUI
import CoreData

struct RootContainerView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        Group {
            #if os(iOS)
            TabScaffold()
            #else
            MacSplitScaffold()
            #endif
        }
        .onAppear {
            SeedManager.seedIfNeeded(context: context)
            DayRolloverManager.runIfNeeded(context: context)
        }
    }
}

#if os(iOS)
private struct TabScaffold: View {
    var body: some View {
        TabView {
            MyDayView()
                .tabItem { Label("我的一天", systemImage: "sun.max.fill") }
            PlannedView()
                .tabItem { Label("已计划", systemImage: "calendar") }
            ImportantView()
                .tabItem { Label("重要", systemImage: "star.fill") }
            ListsView()
                .tabItem { Label("清单", systemImage: "list.bullet") }
            SearchView()
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
    }
}
#else
private struct MacSplitScaffold: View {
    @Environment(\.managedObjectContext) private var context
    @State private var selection: SidebarSelection? = .system(.myDay)

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("系统") {
                    ForEach(SystemList.allCases) { sys in
                        NavigationLink(value: SidebarSelection.system(sys)) {
                            Label(sys.title, systemImage: icon(for: sys))
                        }
                    }
                }
                Section("清单") {
                    UserListsSection(selection: $selection)
                }
            }
            .navigationTitle("Jarvis")
        } content: {
            ContentArea(selection: selection)
        } detail: {
            Text("选择一个任务")
                .foregroundStyle(.secondary)
        }
    }

    private func icon(for sys: SystemList) -> String {
        switch sys { case .myDay: return "sun.max.fill"; case .planned: return "calendar"; case .important: return "star.fill"; case .completed: return "checkmark.circle" }
    }
}

private enum SidebarSelection: Hashable {
    case system(SystemList)
    case list(NSManagedObjectID)
}

private struct UserListsSection: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CDList.createdAt, ascending: true)], predicate: NSPredicate(format: "isSystem == NO"))
    private var lists: FetchedResults<CDList>
    @Binding var selection: SidebarSelection?

    var body: some View {
        ForEach(lists) { list in
            NavigationLink(value: SidebarSelection.list(list.objectID)) {
                Label(list.name, systemImage: "folder")
            }
        }
    }
}

private struct ContentArea: View {
    @Environment(\.managedObjectContext) private var context
    let selection: SidebarSelection?

    var body: some View {
        switch selection {
        case .system(let s):
            switch s {
            case .myDay: MyDayView()
            case .planned: PlannedView()
            case .important: ImportantView()
            case .completed: CompletedView()
            }
        case .list(let oid):
            if let list = try? context.existingObject(with: oid) as? CDList {
                TasksView(list: list)
            } else {
                Text("无法加载清单")
            }
        case .none:
            Text("选择一个清单")
        }
    }
}
#endif

struct RootContainerView_Previews: PreviewProvider {
    static var previews: some View {
        RootContainerView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(SettingsStore())
    }
}


