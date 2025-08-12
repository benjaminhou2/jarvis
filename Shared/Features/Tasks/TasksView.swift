import SwiftUI
import CoreData

struct TasksView: View {
    @Environment(\.managedObjectContext) private var context
    let list: CDList

    @FetchRequest private var tasks: FetchedResults<CDTask>

    @State private var quickTitle: String = ""

    init(list: CDList) {
        self.list = list
        _tasks = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \CDTask.createdAt, ascending: false)],
            predicate: NSPredicate(format: "parentList == %@ AND isCompleted == NO", list)
        )
    }

    var body: some View {
        List {
            Section {
                QuickAddBar(placeholder: "添加任务到 \(list.name)") { title in
                    do { _ = try TaskRepository(context: context).create(in: list, title: title, notes: nil) } catch { print(error) }
                }
            }
            Section {
                ForEach(tasks) { task in
                    NavigationLink { TaskDetailView(task: task) } label: {
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .onTapGesture { try? TaskRepository(context: context).toggleCompleted(task) }
                            VStack(alignment: .leading) {
                                Text(task.title).font(.headline)
                                if let due = task.dueDate { Text(dateString(due)).font(.caption).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            Button(action: { try? TaskRepository(context: context).toggleImportant(task) }) {
                                Image(systemName: task.isImportant ? "star.fill" : "star")
                                    .foregroundStyle(task.isImportant ? .yellow : .secondary)
                            }
                            .buttonStyle(.plain)
                            Button(action: { try? TaskRepository(context: context).toggleMyDay(task) }) {
                                Image(systemName: task.myDay ? "sun.max.fill" : "sun.max")
                                    .foregroundStyle(task.myDay ? .orange : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    #if os(iOS)
                    .swipeActions(edge: .trailing) {
                        Button {
                            try? TaskRepository(context: context).toggleImportant(task)
                        } label: { Label(task.isImportant ? "取消重要" : "标为重要", systemImage: "star.fill") }
                        .tint(.yellow)
                        Button(role: .destructive) {
                            try? TaskRepository(context: context).delete(task)
                        } label: { Label("删除", systemImage: "trash") }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            try? TaskRepository(context: context).toggleMyDay(task)
                        } label: { Label(task.myDay ? "移出我的一天" : "加到我的一天", systemImage: "sun.max.fill") }
                        .tint(.orange)
                    }
                    #endif
                }
                .onDelete { indexSet in
                    for idx in indexSet { try? TaskRepository(context: context).delete(tasks[idx]) }
                }
            }
        }
        .navigationTitle(list.name)
        #if os(macOS)
        .onAppear { registerShortcuts() }
        .onDisappear { unregisterShortcuts() }
        #endif
    }

    private func dateString(_ date: Date) -> String { DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short) }

    #if os(macOS)
    private func registerShortcuts() {
        // Simple NSApplication key equivalents via commands can be added under App commands.
        // Here we simulate by adding local monitor if needed.
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) {
                switch event.charactersIgnoringModifiers?.lowercased() {
                case "n":
                    // Cmd+N -> focus quick add not trivial here, but we can create a placeholder task
                    do { _ = try TaskRepository(context: context).create(in: list, title: "新任务", notes: nil) } catch {}
                    return nil
                case "f":
                    // Cmd+F -> not implemented: would route to Search
                    return nil
                case "i":
                    if let first = tasks.first { try? TaskRepository(context: context).toggleImportant(first) }
                    return nil
                default: break
                }
            } else if event.keyCode == 49 { // Space
                // Space -> preview first task
                return nil
            }
            return event
        }
    }
    private func unregisterShortcuts() { /* rely on system cleanup */ }
    #endif
}

 


