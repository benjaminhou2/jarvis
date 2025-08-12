import SwiftUI
import CoreData

struct CompletedView: View {
    @FetchRequest private var tasks: FetchedResults<CDTask>
    init() {
        _tasks = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \CDTask.updatedAt, ascending: false)
            ],
            predicate: NSPredicate(format: "isCompleted == YES")
        )
    }
    var body: some View {
        List {
            DisclosureGroup("已完成 \(tasks.count)") {
                ForEach(tasks) { task in
                    HStack { Image(systemName: "checkmark.circle"); Text(task.title).strikethrough() }
                }
            }
        }
        .navigationTitle("已完成")
    }
}


