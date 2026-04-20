import Foundation
import UserNotifications
import OSLog

@MainActor
final class NotificationService: ObservableObject {
    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.runinterval.pro", category: "Notifications")
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - 初始化
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - 检查授权状态
    private func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = (settings.authorizationStatus == .authorized)
                self?.logger.log("通知授权状态: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    // MARK: - 请求授权
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        center.requestAuthorization(options: options) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                self?.checkAuthorizationStatus()
                
                if let error = error {
                    self?.logger.error("通知授权请求失败: \(error.localizedDescription)")
                } else {
                    self?.logger.log("通知授权: \(granted ? "成功" : "失败")")
                }
                
                completion(granted)
            }
        }
    }
    
    // MARK: - 调度训练提醒
    func scheduleWorkoutReminder(title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REMINDER"
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "workout_reminder_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                self.logger.error("调度提醒失败: \(error.localizedDescription)")
            } else {
                self.logger.info("训练提醒已调度: \(title)")
            }
        }
    }
    
    // MARK: - 取消所有通知
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        logger.info("所有通知已取消")
    }
    
    // MARK: - 发送本地通知（立即）
    func sendImmediateNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "immediate_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        center.add(request) { error in
            if let error = error {
                self.logger.error("发送通知失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 设置通知类别
    func setupNotificationCategories() {
        let workoutCategory = UNNotificationCategory(
            identifier: "WORKOUT_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([workoutCategory])
        logger.info("通知类别已设置")
    }
}

// MARK: - 通知声音自定义
extension NotificationService {
    enum NotificationSound: String {
        case phaseChange = "phase_change.caf"
        case workoutComplete = "workout_complete.caf"
        case countdown = "countdown.caf"
        case reminder = "reminder.caf"
    }
    
    func playSound(_ sound: NotificationSound) {
        // 播放自定义声音（需要在应用包中添加相应的音频文件）
        let soundName = sound.rawValue
        logger.info("播放声音: \(soundName)")
    }
}