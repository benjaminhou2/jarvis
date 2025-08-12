import SwiftUI
import CoreData

struct TaskDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var task: CDTask
    @State private var repeatRule: RepeatRule = .init(kind: .none, weekdays: nil, dayOfMonth: nil, isLastDayOfMonth: nil)
    @State private var editedTitle: String = ""
    @State private var editedNotes: String = ""

    var body: some View {
        layout
            .onAppear {
                editedTitle = task.title
                editedNotes = task.notes ?? ""
                if let rrString = task.repeatRule, let rr = try? RepeatRule.decode(from: rrString) { repeatRule = rr }
            }
            .onDisappear { saveAll() }
            .navigationTitle("任务详情")
    }

    func saveTitle() { try? TaskRepository(context: context).update(task) { $0.title = editedTitle } }
    func saveAll() {
        try? TaskRepository(context: context).update(task) { t in
            t.title = editedTitle
            t.notes = editedNotes
            t.repeatRule = (try? repeatRule.encode())
        }
        let names = TagExtractor.extract(from: editedTitle + " " + editedNotes)
        try? TagRepository(context: context).setTags(for: task, names: names)
    }
    func setDueDate(_ d: Date) { try? TaskRepository(context: context).update(task) { $0.dueDate = d } }
    func setImportant(_ v: Bool) { try? TaskRepository(context: context).update(task) { $0.isImportant = v } }
}


