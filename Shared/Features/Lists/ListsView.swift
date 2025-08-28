import SwiftUI
import CoreData

struct ListsView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CDList.createdAt, ascending: true)], predicate: NSPredicate(format: "isSystem == NO"))
    private var lists: FetchedResults<CDList>

    @State private var newListName: String = ""
    @State private var listToRename: CDList?
    @State private var newListNameForAlert: String = ""
    @State private var isShowingRenameAlert: Bool = false
    @State private var isShowingErrorAlert: Bool = false
    @State private var errorMessage: String = ""

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
                                Button("重命名") { presentRenameAlert(for: list) }
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
            .alert("重命名清单", isPresented: $isShowingRenameAlert) {
                TextField("新名称", text: $newListNameForAlert)
                Button("保存") {
                    renameList()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("为清单“\(listToRename?.name ?? "")”输入一个新名称。")
            }
            .alert("错误", isPresented: $isShowingErrorAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .toolbar {
                #if os(iOS)
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if let undoManager = context.undoManager {
                        Button(action: { undoManager.undo() }) {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .disabled(!undoManager.canUndo)

                        Button(action: { undoManager.redo() }) {
                            Image(systemName: "arrow.uturn.forward")
                        }
                        .disabled(!undoManager.canRedo)
                    }
                }
                #endif
            }
        }
    }

    private func createList() {
        let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            _ = try ListRepository(context: context).create(name: name, icon: nil, color: nil, isSystem: false)
            newListName = ""
        } catch {
            showError("创建清单失败: \(error.localizedDescription)")
        }
    }

    private func presentRenameAlert(for list: CDList) {
        listToRename = list
        newListNameForAlert = list.name
        isShowingRenameAlert = true
    }

    private func renameList() {
        guard let list = listToRename else { return }
        let newName = newListNameForAlert.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else { return }
        do {
            try ListRepository(context: context).rename(list: list, to: newName)
        } catch {
            showError("重命名清单失败: \(error.localizedDescription)")
        }
    }

    private func delete(_ list: CDList) {
        do {
            try ListRepository(context: context).delete(list: list)
        } catch {
            showError("删除清单失败: \(error.localizedDescription)")
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        isShowingErrorAlert = true
    }
}

struct ListsView_Previews: PreviewProvider {
    static var previews: some View {
        ListsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(SettingsStore())
    }
}


