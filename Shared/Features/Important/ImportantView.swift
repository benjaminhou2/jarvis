import SwiftUI
import CoreData

struct ImportantView: View {
    @FetchRequest private var tasks: FetchedResults<CDTask>
    init() {
        _tasks = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \CDTask.sortIndex, ascending: true),
                NSSortDescriptor(keyPath: \CDTask.updatedAt, ascending: false)
            ],
            predicate: NSPredicate(format: "isImportant == YES AND isCompleted == NO")
        )
    }
    var body: some View {
        List {
            ForEach(tasks) { task in
                NavigationLink { TaskDetailView(task: task) } label: {
                    HStack { Image(systemName: "star.fill").foregroundStyle(.yellow); Text(task.title); Spacer() }
                }
            }
        }
        .refreshable { }
        .navigationTitle("重要")
    }
}


