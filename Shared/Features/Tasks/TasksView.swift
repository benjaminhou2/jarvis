import SwiftUI
import CoreData

struct TasksView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: TasksViewModel
    @FocusState private var isQuickAddBarFocused: Bool

    let list: CDList

    init(list: CDList) {
        self.list = list
        _viewModel = StateObject(wrappedValue: TasksViewModel(list: list, context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        List {
            Section {
                QuickAddBar(placeholder: "添加任务到 \(list.name)", onCommit: viewModel.createTask, focus: $isQuickAddBarFocused)
            }
            Section {
                ForEach(viewModel.tasks) { task in
                    NavigationLink { TaskDetailView(task: task) } label: {
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .onTapGesture { viewModel.toggleCompleted(for: task) }
                            VStack(alignment: .leading) {
                                Text(task.title).font(.headline)
                                if let due = task.dueDate { Text(dateString(due)).font(.caption).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            Button(action: { viewModel.toggleImportant(for: task) }) {
                                Image(systemName: task.isImportant ? "star.fill" : "star")
                                    .foregroundStyle(task.isImportant ? .yellow : .secondary)
                            }
                            .buttonStyle(.plain)
                            Button(action: { viewModel.toggleMyDay(for: task) }) {
                                Image(systemName: task.myDay ? "sun.max.fill" : "sun.max")
                                    .foregroundStyle(task.myDay ? .orange : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    #if os(iOS)
                    .swipeActions(edge: .trailing) {
                        Button {
                            viewModel.toggleImportant(for: task)
                        } label: { Label(task.isImportant ? "取消重要" : "标为重要", systemImage: "star.fill") }
                        .tint(.yellow)
                        Button(role: .destructive) {
                            viewModel.delete(task: task)
                        } label: { Label("删除", systemImage: "trash") }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.toggleMyDay(for: task)
                        } label: { Label(task.myDay ? "移出我的一天" : "加到我的一天", systemImage: "sun.max.fill") }
                        .tint(.orange)
                    }
                    #endif
                }
                .onDelete { indexSet in
                    viewModel.delete(at: indexSet)
                }
            }
        }
        .refreshable {
            // The ViewModel's CoreDataPublisher will automatically handle updates.
        }
        .alert("错误", isPresented: $viewModel.isShowingErrorAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
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
        .navigationTitle(list.name)
        .onReceive(NotificationCenter.default.publisher(for: .didRequestAddNewTask)) { _ in
            isQuickAddBarFocused = true
        }
    }

    private func dateString(_ date: Date) -> String { DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short) }
}

 


