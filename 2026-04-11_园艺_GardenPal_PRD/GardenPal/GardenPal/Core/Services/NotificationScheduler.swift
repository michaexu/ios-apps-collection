import Foundation
import UserNotifications

enum NotificationScheduler {
    static let morningSummaryId = "gardenpal.morning.summary"

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleMorningSummary(plantsNeedingWater: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningSummaryId])

        var content = UNMutableNotificationContent()
        content.title = "GardenPal 今日养护"
        if plantsNeedingWater > 0 {
            content.body = "今日有 \(plantsNeedingWater) 株植物需要浇水，去 App 一键完成吧。"
        } else {
            content.body = "今日暂无浇水任务，看看植物生长日志吧。"
        }
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: morningSummaryId, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            // Scheduling failures are non-fatal for local MVP
        }
    }
}
