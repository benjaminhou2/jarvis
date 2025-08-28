import Foundation
import CoreData
import Combine

class TaskDetailViewModel: ObservableObject {
    @Published var task: CDTask

    @Published var editedTitle: String
    @Published var editedNotes: String
    @Published var repeatRule: RepeatRule

    @Published var isShowingErrorAlert: Bool = false
    @Published var errorMessage: String = ""

    private let context: NSManagedObjectContext
    private let taskRepository: TaskRepository
    private let tagRepository: TagRepository
    private var cancellables = Set<AnyCancellable>()

    init(task: CDTask, context: NSManagedObjectContext, taskRepository: TaskRepository? = nil, tagRepository: TagRepository? = nil) {
        self.task = task
        self.context = context
        self.taskRepository = taskRepository ?? TaskRepository(context: context)
        self.tagRepository = tagRepository ?? TagRepository(context: context)

        self.editedTitle = task.title
        self.editedNotes = task.notes ?? ""

        if let rrString = task.repeatRule, let rr = try? RepeatRule.decode(from: rrString) {
            self.repeatRule = rr
        } else {
            self.repeatRule = .init(kind: .none, weekdays: nil, dayOfMonth: nil, isLastDayOfMonth: nil)
        }

        // Set up subscribers to auto-save
        $editedTitle.debounce(for: .seconds(0.5), scheduler: RunLoop.main).sink { [weak self] _ in self?.saveTaskMainContent() }.store(in: &cancellables)
        $editedNotes.debounce(for: .seconds(0.5), scheduler: RunLoop.main).sink { [weak self] _ in self?.saveTaskMainContent() }.store(in: &cancellables)
        $repeatRule.debounce(for: .seconds(0.5), scheduler: RunLoop.main).sink { [weak self] _ in self?.saveTaskMainContent() }.store(in: &cancellables)
    }

    func saveTaskMainContent() {
        perform {
            try self.taskRepository.update(self.task) { t in
                t.title = self.editedTitle
                t.notes = self.editedNotes
                t.repeatRule = (try? self.repeatRule.encode())
            }
            let names = TagExtractor.extract(from: self.editedTitle + " " + self.editedNotes)
            try self.tagRepository.setTags(for: self.task, names: names)
        }
    }

    func setDueDate(_ d: Date) { perform { try self.taskRepository.update(self.task) { $0.dueDate = d } } }
    func setImportant(_ v: Bool) { perform { try self.taskRepository.update(self.task) { $0.isImportant = v } } }
    func toggleCompleted() { perform { try self.taskRepository.toggleCompleted(self.task) } }
    func deleteTask() { perform { try self.taskRepository.delete(self.task) } }

    private func perform(action: () throws -> Void) {
        do {
            try action()
        } catch {
            self.errorMessage = "操作失败: \(error.localizedDescription)"
            self.isShowingErrorAlert = true
        }
    }
}
