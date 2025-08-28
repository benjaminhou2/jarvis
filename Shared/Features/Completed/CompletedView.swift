import SwiftUI
import CoreData

struct CompletedView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDTask.updatedAt, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == YES")
    ) private var tasks: FetchedResults<CDTask>

    private var groupedTasks: [String: [CDTask]] {
        Dictionary(grouping: tasks) { task in
            let updatedAt = task.updatedAt
            if Calendar.current.isDateInToday(updatedAt) {
                return "今天"
            } else if Calendar.current.isDateInYesterday(updatedAt) {
                return "昨天"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: updatedAt)
            }
        }
    }

    private var sortedGroupKeys: [String] {
        groupedTasks.keys.sorted {
            if $0 == "今天" { return true }
            if $1 == "今天" { return false }
            if $0 == "昨天" { return true }
            if $1 == "昨天" { return false }
            return $0 > $1
        }
    }

    var body: some View {
        List {
            ForEach(sortedGroupKeys, id: \.self) { key in
                Section(header: Text(key)) {
                    ForEach(groupedTasks[key]!) { task in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(task.title)
                                .strikethrough()
                                .foregroundColor(.secondary)
                            Spacer()
                            if let listName = task.parentList?.name {
                                Text(listName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("已完成")
    }
}


