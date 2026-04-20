import Foundation

enum UserSettings {
    private static let notifiedAuthKey = "gardenpal.asked_notification_auth"

    static var hasPromptedForNotifications: Bool {
        get { UserDefaults.standard.bool(forKey: notifiedAuthKey) }
        set { UserDefaults.standard.set(newValue, forKey: notifiedAuthKey) }
    }
}
