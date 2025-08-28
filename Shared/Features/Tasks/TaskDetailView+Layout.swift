import SwiftUI

extension TaskDetailView {
    @ViewBuilder
    var layout: some View {
        VStack {
            FormContent
            Spacer(minLength: 0)
        }
        .environmentObject(viewModel)
    }

    @ViewBuilder
    private var FormContent: some View {
        Form {
            Section("标题") {
                TextField("标题", text: $viewModel.editedTitle)
                    .onSubmit { viewModel.saveTaskMainContent() }
            }
            Section("所属清单") {
                Picker("清单", selection: $viewModel.task.parentList) {
                    ForEach(userLists) { list in
                        Text(list.name).tag(list as CDList)
                    }
                }
                .pickerStyle(.menu)
            }
            Section("备注") {
                TextEditor(text: $viewModel.editedNotes).frame(minHeight: 80)
            }
            Section("日期与提醒") {
                DatePicker("截止日期", selection: Binding(get: { viewModel.task.dueDate ?? Date() }, set: { viewModel.setDueDate($0) }), displayedComponents: [.date, .hourAndMinute])
                Toggle("重要", isOn: $viewModel.task.isImportant)
                ReminderEditor(task: viewModel.task) { newReminder in
                    // This still creates a repository, will be fixed in a later step if possible
                    try? TaskRepository(context: context).update(viewModel.task) { $0.reminder = newReminder }
                }
            }
            Section("重复") { RepeatRulePicker(repeatRule: $viewModel.repeatRule) }
            stepsSection
            Section("操作") {
                Button(viewModel.task.isCompleted ? "标记为未完成" : "标记为完成") { viewModel.toggleCompleted() }
                Button(viewModel.task.isImportant ? "取消重要" : "标记为重要") { viewModel.setImportant(!viewModel.task.isImportant) }
                Button("删除", role: .destructive) { viewModel.deleteTask() }
            }
        }
    }
}


