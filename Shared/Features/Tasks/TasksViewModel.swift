import Foundation
import CoreData
import Combine

class TasksViewModel: ObservableObject {
    @Published var tasks: [CDTask] = []
    @Published var isShowingErrorAlert: Bool = false
    @Published var errorMessage: String = ""

    private let list: CDList
    private let context: NSManagedObjectContext
    private let taskRepository: TaskRepository
    private var cancellables = Set<AnyCancellable>()
    private let fetchController: NSFetchedResultsController<CDTask>

    init(list: CDList, context: NSManagedObjectContext, taskRepository: TaskRepository? = nil) {
        self.list = list
        self.context = context
        self.taskRepository = taskRepository ?? TaskRepository(context: context)

        let fetchRequest: NSFetchRequest<CDTask> = CDTask.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDTask.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "parentList == %@ AND isCompleted == NO", list)

        fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

        // Use a custom publisher to observe Core Data changes
        CoreDataPublisher(fetchController: fetchController)
            .sink(receiveCompletion: { completion in
                // Handle completion if needed
            }, receiveValue: { [weak self] tasks in
                self?.tasks = tasks
            })
            .store(in: &cancellables)
    }

    func createTask(title: String) {
        perform {
            _ = try taskRepository.create(in: list, title: title, notes: nil)
        }
    }

    func delete(task: CDTask) {
        perform {
            try taskRepository.delete(task)
        }
    }

    func delete(at offsets: IndexSet) {
        offsets.map { tasks[$0] }.forEach(delete)
    }

    func toggleCompleted(for task: CDTask) {
        perform { try taskRepository.toggleCompleted(task) }
    }

    func toggleImportant(for task: CDTask) {
        perform { try taskRepository.toggleImportant(task) }
    }

    func toggleMyDay(for task: CDTask) {
        perform { try taskRepository.toggleMyDay(task) }
    }

    private func perform(action: () throws -> Void) {
        do {
            try action()
        } catch {
            errorMessage = "操作失败: \(error.localizedDescription)"
            isShowingErrorAlert = true
        }
    }
}

// A helper publisher to bridge NSFetchedResultsControllerDelegate
class CoreDataPublisher<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate, Publisher {
    typealias Output = [T]
    typealias Failure = Error

    private let subject: CurrentValueSubject<[T], Failure>
    private let fetchController: NSFetchedResultsController<T>

    init(fetchController: NSFetchedResultsController<T>) {
        self.fetchController = fetchController
        self.subject = .init(fetchController.fetchedObjects ?? [])
        super.init()
        fetchController.delegate = self
        do {
            try fetchController.performFetch()
            subject.send(fetchController.fetchedObjects ?? [])
        } catch {
            subject.send(completion: .failure(error))
        }
    }

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        subject.subscribe(subscriber)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        subject.send(controller.fetchedObjects as? [T] ?? [])
    }
}
