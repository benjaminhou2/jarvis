import Foundation
import UserNotifications

final class LocalNotificationCenter {
    static let shared = LocalNotificationCenter()
    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
            case .denied:
                DispatchQueue.main.async { self.promptOpenSettings() }
            default:
                break
            }
        }
    }

    func scheduleReminder(id: String, title: String, body: String?, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let body = body { content.body = body }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(5, date.timeIntervalSinceNow), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    func cancel(id: String) { center.removePendingNotificationRequests(withIdentifiers: [id]) }
    func cancelAll() { center.removeAllPendingNotificationRequests() }

    private func promptOpenSettings() {
        #if os(iOS)
        let alert = UIAlertController(title: "通知权限已关闭", message: "前往系统设置开启 Jarvis 的通知权限。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "去设置", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
        }))
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
        #endif
    }
}


