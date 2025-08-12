import SwiftUI

extension TaskDetailView {
    @ViewBuilder
    var layout: some View {
        VStack {
            FormContent
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var FormContent: some View {
        Form {
            Section("标题") {
                TextField("标题", text: $editedTitle)
                    .onSubmit { saveTitle() }
            }
            Section("备注") {
                TextEditor(text: $editedNotes).frame(minHeight: 80)
            }
            Section("日期与提醒") {
                DatePicker("截止日期", selection: Binding(get: { task.dueDate ?? Date() }, set: { setDueDate($0) }), displayedComponents: [.date, .hourAndMinute])
                Toggle("重要", isOn: Binding(get: { task.isImportant }, set: { setImportant($0) }))
                ReminderEditor(task: task) { newReminder in
                    try? TaskRepository(context: context).update(task) { $0.reminder = newReminder }
                }
            }
            Section("重复") { RepeatRulePicker(repeatRule: $repeatRule) }
            stepsSection
            Section("操作") {
                Button(task.isCompleted ? "标记为未完成" : "标记为完成") { try? TaskRepository(context: context).toggleCompleted(task) }
                Button(task.isImportant ? "取消重要" : "标记为重要") { try? TaskRepository(context: context).toggleImportant(task) }
                Button("删除", role: .destructive) { try? TaskRepository(context: context).delete(task) }
            }
        }
    }
}


