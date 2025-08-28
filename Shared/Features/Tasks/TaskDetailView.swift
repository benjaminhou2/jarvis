import SwiftUI
import CoreData

struct TaskDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: TaskDetailViewModel

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CDList.createdAt, ascending: true)], predicate: NSPredicate(format: "isSystem == NO"))
    private var userLists: FetchedResults<CDList>

    init(task: CDTask) {
        _viewModel = StateObject(wrappedValue: TaskDetailViewModel(task: task, context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        layout
            .alert("错误", isPresented: $viewModel.isShowingErrorAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .navigationTitle("任务详情")
    }
}


