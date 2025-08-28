import SwiftUI
import CoreData

struct PlannedView: View {
    @FetchRequest private var tasks: FetchedResults<CDTask>
    init() {
        _tasks = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \CDTask.dueDate, ascending: true)
            ],
            predicate: NSPredicate(format: "(dueDate != nil OR reminder != nil) AND isCompleted == NO")
        )
    }
    var body: some View {
        List {
            ForEach(tasks) { task in
                NavigationLink { TaskDetailView(task: task) } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text(task.title)
                        Spacer()
                        if let due = task.dueDate { Text(DateFormatter.localizedString(from: due, dateStyle: .short, timeStyle: .short)).foregroundStyle(.secondary) }
                    }
                }
            }
        }
        .refreshable { }
        .navigationTitle("已计划")
    }
}


