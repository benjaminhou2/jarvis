import SwiftUI
import CoreData

struct StepsSection: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var task: CDTask
    @State private var newStepTitle: String = ""

    @FetchRequest private var steps: FetchedResults<CDStep>

    init(task: CDTask) {
        self.task = task
        _steps = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \CDStep.createdAt, ascending: true)],
            predicate: NSPredicate(format: "parentTask == %@", task)
        )
    }

    var body: some View {
        Section("子任务") {
            ForEach(steps) { step in
                HStack {
                    Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                        .onTapGesture { toggle(step) }
                    Text(step.title)
                }
                .contextMenu {
                    Button("删除", role: .destructive) { delete(step) }
                }
            }
            HStack {
                TextField("添加子任务", text: $newStepTitle).onSubmit(addStep)
                Button("添加") { addStep() }
                    .disabled(newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func addStep() {
        let title = newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let s = CDStep(context: context)
        s.id = UUID(); s.title = title; s.isCompleted = false; s.createdAt = Date(); s.updatedAt = Date(); s.parentTask = task
        try? context.save(); newStepTitle = ""
    }
    private func toggle(_ s: CDStep) { s.isCompleted.toggle(); s.updatedAt = Date(); try? context.save() }
    private func delete(_ s: CDStep) { context.delete(s); try? context.save() }
}

extension CDStep: Identifiable {}


