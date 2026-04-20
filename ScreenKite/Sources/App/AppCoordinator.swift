import Foundation
import Combine
import AppKit

/// 应用协调器：连接所有服务，管理整体状态
final class AppCoordinator {

    // MARK: - Dependencies
    private let recordingEngine: RecordingEngineProtocol
    private let schedulerService: SchedulerServiceProtocol
    private let hotkeyManager: HotkeyManagerProtocol
    private let dndController: DNDModeControllerProtocol
    private let notificationService: NotificationServiceProtocol

    // MARK: - State
    private var cancellables = Set<AnyCancellable>()
    private weak var mainWindow: NSWindow?

    // MARK: - Init

    init(
        recordingEngine: RecordingEngineProtocol,
        schedulerService: SchedulerServiceProtocol,
        hotkeyManager: HotkeyManagerProtocol,
        dndController: DNDModeControllerProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.recordingEngine = recordingEngine
        self.schedulerService = schedulerService
        self.hotkeyManager = hotkeyManager
        self.dndController = dndController
        self.notificationService = notificationService
    }

    // MARK: - Lifecycle

    func start() {
        schedulerService.start()
        hotkeyManager.start()
        setupSubscriptions()
        setupNotifications()
    }

    func stop() {
        schedulerService.stop()
        hotkeyManager.stop()
        recordingEngine.shutdown()
        cancellables.removeAll()
    }

    func registerMainWindow(_ window: NSWindow) {
        self.mainWindow = window
    }

    // MARK: - Subscriptions

    private func setupSubscriptions() {
        // 快捷键事件
        hotkeyManager.hotkeyPressedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                self?.handleHotkeyAction(action)
            }
            .store(in: &cancellables)

        // 定时任务即将触发
        schedulerService.taskWillTriggerPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] task in
                self?.notificationService.scheduleRecordingReminder(
                    taskName: task.name,
                    secondsBefore: 60,
                    taskId: task.id
                )
            }
            .store(in: &cancellables)

        // 定时任务触发
        schedulerService.taskTriggeredPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] task in
                self?.notificationService.notifyTaskTriggered(taskName: task.name)
                try? self?.recordingEngine.start(with: task.recordingConfig)
            }
            .store(in: &cancellables)

        // 录制状态变化
        recordingEngine.recordingStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleRecordingStateChange(state)
            }
            .store(in: &cancellables)
    }

    private func setupNotifications() {
        // 快捷键权限缺失通知
        NotificationCenter.default.publisher(for: .hotkeyPermissionNeeded)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showHotkeyPermissionAlert()
            }
            .store(in: &cancellables)
    }

    // MARK: - Hotkey Handling

    private func handleHotkeyAction(_ action: HotkeyAction) {
        // 安全门控：非录制状态下只有 startOrResume 可用
        guard recordingEngine.isRecording || action == .startOrResume else { return }

        switch action {
        case .startOrResume:
            if !recordingEngine.isRecording {
                // 使用上次配置或默认配置
                let defaultConfig = RecordingConfig()
                try? recordingEngine.start(with: defaultConfig)
            } else if recordingEngine.isPaused {
                recordingEngine.resume()
            }

        case .pauseOrResume:
            if recordingEngine.isPaused {
                recordingEngine.resume()
            } else {
                recordingEngine.pause()
            }

        case .stop:
            Task {
                _ = await recordingEngine.stop()
            }

        case .addMarker:
            if recordingEngine.isRecording {
                recordingEngine.addMarker(label: nil)
            }
        }
    }

    // MARK: - Recording State Handling

    private func handleRecordingStateChange(_ state: RecordingState) {
        switch state {
        case .recording:
            // 更新菜单栏图标（红点）
            updateMenuBarIcon(recording: true)
            NotificationCenter.default.post(name: .recordingDidStart, object: nil)

        case .idle, .stopping:
            updateMenuBarIcon(recording: false)
            NotificationCenter.default.post(name: .recordingDidStop, object: nil)

        case .paused:
            updateMenuBarIcon(recording: true, paused: true)

        case .error(let error):
            notificationService.notifyRecordingFailed(reason: error.localizedDescription ?? "未知错误")
            updateMenuBarIcon(recording: false)

        case .preparing:
            break
        }
    }

    // MARK: - UI Updates

    private func updateMenuBarIcon(recording: Bool, paused: Bool = false) {
        // 通知 UI 更新菜单栏图标
        // 实现方式：根据当前状态更新 NSStatusItem 的图片
        NotificationCenter.default.post(
            name: NSNotification.Name("ScreenKiteRecordingStateChanged"),
            object: nil,
            userInfo: ["isRecording": recording, "isPaused": paused]
        )
    }

    // MARK: - Permission Alerts

    private func showHotkeyPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "ScreenKite 的快捷键功能需要辅助功能权限才能工作。请在 系统设置 → 隐私与安全性 → 辅助功能 中启用 ScreenKite。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            HotkeyManagerHelper.openAccessibilitySettings()
        }
    }
}
