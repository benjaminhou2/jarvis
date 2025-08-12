import SwiftUI
import CoreData

struct MyDayView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest private var tasks: FetchedResults<CDTask>

    init() {
        _tasks = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \CDTask.sortIndex, ascending: true),
                NSSortDescriptor(keyPath: \CDTask.updatedAt, ascending: false)
            ],
            predicate: NSPredicate(format: "myDay == YES AND isCompleted == NO")
        )
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(tasks) { task in
                    NavigationLink { TaskDetailView(task: task) } label: {
                        HStack {
                            Image(systemName: "sun.max.fill").foregroundStyle(.orange)
                            Text(task.title)
                            Spacer()
                            if let due = task.dueDate { Text(DateFormatter.localizedString(from: due, dateStyle: .short, timeStyle: .short)).foregroundStyle(.secondary) }
                        }
                    }
                    #if os(iOS)
                    .swipeActions(edge: .trailing) {
                        Button {
                            try? TaskRepository(context: context).toggleMyDay(task)
                        } label: { Label("移出我的一天", systemImage: "minus.circle") }
                        .tint(.orange)
                    }
                    #endif
                }
            }
            .navigationTitle("我的一天")
        }
    }
}

struct MyDayView_Previews: PreviewProvider {
    static var previews: some View {
        MyDayView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(SettingsStore())
    }
}


