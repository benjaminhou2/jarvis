import SwiftUI

struct ReminderEditor: View {
    @ObservedObject var task: CDTask
    var onChange: (Date?) -> Void

    @State private var baseDate: Date = Date()
    @State private var leadMinutes: Int = 15

    let presets = [5, 15, 30, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(get: { task.reminder != nil }, set: { isOn in
                if !isOn { onChange(nil) } else { onChange(calculateReminder(base: baseDate, lead: leadMinutes)) }
            })) {
                Text("提醒")
            }
            if task.reminder != nil {
                DatePicker("提醒时间基于截止：", selection: Binding(get: { task.dueDate ?? baseDate }, set: { newDue in
                    baseDate = newDue
                    onChange(calculateReminder(base: newDue, lead: leadMinutes))
                }), displayedComponents: [.date, .hourAndMinute])
                HStack {
                    Text("提前")
                    Picker("提前", selection: $leadMinutes) {
                        ForEach(presets, id: \.self) { m in Text("\(m) 分").tag(m) }
                    }
                    .pickerStyle(.segmented)
                    Spacer()
                }
                .onChange(of: leadMinutes) { new in
                    onChange(calculateReminder(base: task.dueDate ?? baseDate, lead: new))
                }
            }
        }
        .onAppear {
            baseDate = task.dueDate ?? Date()
            if let rem = task.reminder, let due = task.dueDate {
                leadMinutes = Int((due.timeIntervalSince1970 - rem.timeIntervalSince1970) / 60)
                if !presets.contains(leadMinutes) { leadMinutes = 15 }
            }
        }
    }

    private func calculateReminder(base: Date, lead: Int) -> Date { base.addingTimeInterval(TimeInterval(-lead * 60)) }
}


