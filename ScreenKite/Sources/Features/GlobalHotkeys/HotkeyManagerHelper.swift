import Foundation
import AppKit

/// 快捷键权限辅助工具
enum HotkeyManagerHelper {

    /// 检查辅助功能权限
    static func hasAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// 请求辅助功能权限（会触发系统弹窗）
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// 打开辅助功能设置页面
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// 检查权限并在缺失时提示用户
    static func ensureAccessibilityPermission(showPrompt: Bool = true) -> Bool {
        let hasPermission = hasAccessibilityPermission()
        if !hasPermission && showPrompt {
            requestAccessibilityPermission()
        }
        return hasPermission
    }
}
