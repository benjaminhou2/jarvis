import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var syncStatus = SyncStatusManager.shared

    var body: some View {
        Form {
            Section("同步") {
                Toggle("启用 iCloud 同步（仅个人私有库）", isOn: $settings.iCloudSyncEnabled)
                Text("更改后下次启动生效。仅同一 Apple ID 个人同步，不支持协作。")
                    .font(.footnote).foregroundStyle(.secondary)
                if let dt = syncStatus.lastSyncAt {
                    Label("最近同步：\(DateFormatter.localizedString(from: dt, dateStyle: .short, timeStyle: .short))", systemImage: "icloud")
                }
                if let err = syncStatus.lastError {
                    Label("同步错误：\(err)", systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                }
            }
            Section("默认") {
                Stepper(value: $settings.defaultReminderMinutes, in: 5...120, step: 5) {
                    Text("默认提前提醒 \(settings.defaultReminderMinutes) 分钟")
                }
                Picker("主题", selection: $settings.theme) {
                    Text("跟随系统").tag(0)
                    Text("亮").tag(1)
                    Text("暗").tag(2)
                }
            }
            Section("数据") {
                Button("导出 JSON 备份") { DataBackupService.exportAll() }
                Button("导入 JSON 备份") { DataBackupService.importAll() }
            }
        }
        .navigationTitle("设置")
    }
}


