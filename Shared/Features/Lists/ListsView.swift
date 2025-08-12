import SwiftUI
import CoreData

struct ListsView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CDList.createdAt, ascending: true)], predicate: NSPredicate(format: "isSystem == NO"))
    private var lists: FetchedResults<CDList>

    @State private var newListName: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section("系统") {
                    NavigationLink { MyDayView() } label: { Label("我的一天", systemImage: "sun.max.fill") }
                    NavigationLink { PlannedView() } label: { Label("已计划", systemImage: "calendar") }
                    NavigationLink { ImportantView() } label: { Label("重要", systemImage: "star.fill") }
                    NavigationLink { CompletedView() } label: { Label("已完成", systemImage: "checkmark.circle") }
                }
                Section("清单") {
                    ForEach(lists) { list in
                        NavigationLink { TasksView(list: list) } label: { Label(list.name, systemImage: "folder") }
                            .contextMenu {
                                Button("重命名") { rename(list) }
                                Button(role: .destructive) { delete(list) } label: { Text("删除") }
                            }
                    }
                    HStack {
                        TextField("新建清单", text: $newListName)
                            .onSubmit { createList() }
                        Button("添加") { createList() }
                            .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .navigationTitle("清单")
        }
    }

    private func createList() {
        let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            _ = try ListRepository(context: context).create(name: name, icon: nil, color: nil, isSystem: false)
            newListName = ""
        } catch { print(error) }
    }
    private func rename(_ list: CDList) {
        // Simple inline rename via alert/editor could be added; for skeleton we append marker
        do { try ListRepository(context: context).rename(list: list, to: list.name + " ✏️") } catch { print(error) }
    }
    private func delete(_ list: CDList) {
        do { try ListRepository(context: context).delete(list: list) } catch { print(error) }
    }
}

struct ListsView_Previews: PreviewProvider {
    static var previews: some View {
        ListsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(SettingsStore())
    }
}


