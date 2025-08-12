import SwiftUI

struct RepeatRulePicker: View {
    @Binding var repeatRule: RepeatRule

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("重复", selection: $repeatRule.kind) {
                Text("无").tag(RepeatKind.none)
                Text("每天").tag(RepeatKind.daily)
                Text("每周").tag(RepeatKind.weekly)
                Text("每月").tag(RepeatKind.monthly)
            }
            .pickerStyle(.segmented)

            switch repeatRule.kind {
            case .weekly:
                WeekdaySelector(selected: Binding(get: {
                    Set(repeatRule.weekdays ?? [])
                }, set: { new in
                    repeatRule.weekdays = Array(new).sorted()
                }))
            case .monthly:
                MonthlySelector(dayOfMonth: Binding(get: { repeatRule.dayOfMonth ?? 1 }, set: { repeatRule.dayOfMonth = $0; repeatRule.isLastDayOfMonth = false }), isLastDay: Binding(get: { repeatRule.isLastDayOfMonth ?? false }, set: { repeatRule.isLastDayOfMonth = $0 }))
            default:
                EmptyView()
            }
        }
    }
}

private struct WeekdaySelector: View {
    @Binding var selected: Set<Int>
    var body: some View {
        let symbols = Calendar.current.shortWeekdaySymbols // Sun...Sat
        HStack(spacing: 8) {
            ForEach(1...7, id: \.self) { idx in
                let title = symbols[idx - 1]
                Button(title) { toggle(idx) }
                    .buttonStyle(.bordered)
                    .tint(selected.contains(idx) ? .accentColor : .gray.opacity(0.3))
            }
        }
    }
    private func toggle(_ idx: Int) { if selected.contains(idx) { selected.remove(idx) } else { selected.insert(idx) } }
}

private struct MonthlySelector: View {
    @Binding var dayOfMonth: Int
    @Binding var isLastDay: Bool
    var body: some View {
        HStack {
            Toggle("每月最后一天", isOn: $isLastDay)
            Spacer()
            if !isLastDay {
                Stepper(value: $dayOfMonth, in: 1...31) { Text("每月第 \(dayOfMonth) 天") }
            }
        }
    }
}


