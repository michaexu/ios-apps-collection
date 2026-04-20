import Foundation
import Combine

// MARK: - NotificationService Protocol

protocol NotificationServiceProtocol: AnyObject {
    func scheduleRecordingReminder(taskName: String, secondsBefore: Int, taskId: UUID)
    func notifyRecordingStarted()
    func notifyRecordingStopped(duration: TimeInterval, fileURL: URL?)
    func notifyRecordingFailed(reason: String)
    func notifyTaskTriggered(taskName: String)
    func cancelAllPendingNotifications()
    func cancelNotifications(for taskId: UUID)
}

// MARK: - NotificationServiceImpl

final class NotificationServiceImpl: NotificationServiceProtocol {

    private var pendingNotifications: [UUID: NSUserNotification] = [:]

    func scheduleRecordingReminder(taskName: String, secondsBefore: Int, taskId: UUID) {
        let notification = NSUserNotification()
        notification.title = "录制即将开始"
        notification.informativeText = "「\(taskName)」将在 \(secondsBefore) 秒后开始录制"
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.userInfo = ["taskId": taskId.uuidString, "type": "reminder"]

        // 延迟发送
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(secondsBefore)) { [weak self] in
            self?.deliver(notification)
        }

        pendingNotifications[taskId] = notification
    }

    func notifyRecordingStarted() {
        let notification = NSUserNotification()
        notification.title = "录制已开始"
        notification.informativeText = "ScreenKite 正在录制您的屏幕"
        notification.soundName = nil
        deliver(notification)
    }

    func notifyRecordingStopped(duration: TimeInterval, fileURL: URL?) {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        let durationString = formatter.string(from: duration) ?? "\(Int(duration))s"

        let notification = NSUserNotification()
        notification.title = "录制已停止"
        notification.informativeText = "录制时长: \(durationString)"
        notification.soundName = NSUserNotificationDefaultSoundName
        if let url = fileURL {
            notification.userInfo = ["filePath": url.path]
        }
        deliver(notification)
    }

    func notifyRecordingFailed(reason: String) {
        let notification = NSUserNotification()
        notification.title = "录制失败"
        notification.informativeText = reason
        notification.soundName = NSUserNotificationDefaultSoundName
        deliver(notification)
    }

    func notifyTaskTriggered(taskName: String) {
        let notification = NSUserNotification()
        notification.title = "定时录制已触发"
        notification.informativeText = "「\(taskName)」现在开始录制"
        notification.soundName = NSUserNotificationDefaultSoundName
        deliver(notification)
    }

    func cancelAllPendingNotifications() {
        NSUserNotificationCenter.default.removeAllDeliveredNotifications()
        pendingNotifications.removeAll()
    }

    func cancelNotifications(for taskId: UUID) {
        guard let notification = pendingNotifications[taskId] else { return }
        NSUserNotificationCenter.default.removeDeliveredNotification(notification)
        pendingNotifications.removeValue(forKey: taskId)
    }

    private func deliver(_ notification: NSUserNotification) {
        NSUserNotificationCenter.default.deliver(notification)
    }
}
