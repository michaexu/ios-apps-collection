import AppKit
import Combine

/// ScreenKite 应用入口
/// 负责：权限引导 → 服务启动 → 窗口管理
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Services
    private var appCoordinator: AppCoordinator!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupServices()
        checkPermissions()
        setupMainWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appCoordinator?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 保持后台运行（菜单栏 App 模式）
        return false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: - Service Setup

    private func setupServices() {
        // 初始化核心服务
        let storage = UserDefaultsSchedulerStorage()
        let notificationService = NotificationServiceImpl()
        let recordingEngine = RecordingEngineImpl()
        let hotkeyManager = HotkeyManagerImpl(recordingEngine: recordingEngine)
        let dndController = DNDModeControllerImpl(notificationService: notificationService)
        let schedulerService = SchedulerServiceImpl(
            recordingEngine: recordingEngine,
            notificationService: notificationService,
            storage: storage
        )

        // 创建协调器
        appCoordinator = AppCoordinator(
            recordingEngine: recordingEngine,
            schedulerService: schedulerService,
            hotkeyManager: hotkeyManager,
            dndController: dndController,
            notificationService: notificationService
        )

        // 启动所有服务
        appCoordinator.start()
    }

    // MARK: - Permission Checking

    private func checkPermissions() {
        // 检查屏幕录制权限
        if !ScreenCaptureKitHelper.hasScreenRecordingPermission() {
            requestScreenRecordingPermission()
        }

        // 检查辅助功能权限（快捷键）
        if !HotkeyManagerHelper.hasAccessibilityPermission() {
            // 不阻塞启动，但提示用户
            hotkeyManagerNeedsAccessibility()
        }
    }

    private func requestScreenRecordingPermission() {
        // 触发系统权限对话框
        ScreenCaptureKitHelper.requestPermission()
        // 延迟显示成功提示（权限对话框会打开系统设置）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.showPermissionGrantedAlert()
        }
    }

    private func hotkeyManagerNeedsAccessibility() {
        // 快捷键功能缺少权限，不阻塞但提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            NotificationCenter.default.post(
                name: .hotkeyPermissionNeeded,
                object: nil
            )
        }
    }

    private func showPermissionGrantedAlert() {
        let alert = NSAlert()
        alert.messageText = "屏幕录制权限已授予"
        alert.informativeText = "ScreenKite 可以正常录制您的屏幕了。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }

    private func showPermissionDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "屏幕录制权限被拒绝"
        alert.informativeText = "ScreenKite 需要屏幕录制权限才能工作。请在 系统设置 → 隐私与安全性 → 屏幕录制 中授权 ScreenKite，然后重新启动应用。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            HotkeyManagerHelper.openAccessibilitySettings()
        }
    }

    // MARK: - Window Setup

    private var mainWindowController: NSWindowController?

    private func setupMainWindow() {
        // 创建主窗口（可选，ScreenKite 主要以菜单栏 App 模式运行）
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ScreenKite"
        window.center()
        window.isReleasedWhenClosed = false

        // 设置内容视图
        let contentView = MainContentView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        window.contentView = contentView

        // 注册到 AppCoordinator
        appCoordinator.registerMainWindow(window)

        // 显示窗口（默认不显示，作为菜单栏 App）
        // window.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let hotkeyPermissionNeeded = Notification.Name("ScreenKiteHotkeyPermissionNeeded")
    static let recordingDidStart = Notification.Name("ScreenKiteRecordingDidStart")
    static let recordingDidStop = Notification.Name("ScreenKiteRecordingDidStop")
}
