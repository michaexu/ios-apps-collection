import AppKit
import Combine

/// ScreenKite 主内容视图
/// 提供基础设置面板（快捷键、定时录制、DND 模式）
final class MainContentView: NSView {

    // MARK: - UI Elements
    private let titleLabel = NSTextField(labelWithString: "ScreenKite v1.0")
    private let statusLabel = NSTextField(labelWithString: "就绪")
    private let recordButton = NSButton(title: "开始录制", target: nil, action: nil)
    private let stopButton = NSButton(title: "停止录制", target: nil, action: nil)
    private let hotkeyStatusLabel = NSTextField(labelWithString: "快捷键: 未注册")
    private let permissionButton = NSButton(title: "检查权限", target: nil, action: nil)

    // MARK: - State
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        setupNotifications()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupNotifications()
    }

    // MARK: - Setup

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = NSColor(red: 26/255, green: 82/255, blue: 118/255, alpha: 1)
        titleLabel.alignment = .center

        // Status
        statusLabel.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.alignment = .center

        // Buttons
        recordButton.bezelStyle = .rounded
        recordButton.controlSize = .large
        recordButton.target = self
        recordButton.action = #selector(startRecording)

        stopButton.bezelStyle = .rounded
        stopButton.controlSize = .large
        stopButton.isEnabled = false
        stopButton.target = self
        stopButton.action = #selector(stopRecording)

        permissionButton.bezelStyle = .rounded
        permissionButton.target = self
        permissionButton.action = #selector(checkPermissions)

        // Layout
        let titleStack = NSStackView(views: [titleLabel])
        titleStack.orientation = .vertical
        titleStack.alignment = .centerX
        titleStack.spacing = 8

        let statusStack = NSStackView(views: [statusLabel])
        statusStack.orientation = .vertical
        statusStack.alignment = .centerX
        statusStack.spacing = 4

        let buttonStack = NSStackView(views: [recordButton, stopButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 16

        let hotkeyStack = NSStackView(views: [hotkeyStatusLabel])
        hotkeyStack.orientation = .vertical
        hotkeyStack.alignment = .centerX
        hotkeyStack.spacing = 4

        let mainStack = NSStackView(views: [titleStack, statusStack, buttonStack, hotkeyStack, permissionButton])
        mainStack.orientation = .vertical
        mainStack.alignment = .centerX
        mainStack.spacing = 24
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            mainStack.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -40),
        ])
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: NSNotification.Name("ScreenKiteRecordingStateChanged"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                let isRecording = notification.userInfo?["isRecording"] as? Bool ?? false
                let isPaused = notification.userInfo?["isPaused"] as? Bool ?? false
                self?.updateRecordingUI(isRecording: isRecording, isPaused: isPaused)
            }
            .store(in: &cancellables)
    }

    private func updateRecordingUI(isRecording: Bool, isPaused: Bool) {
        if isRecording {
            if isPaused {
                statusLabel.stringValue = "已暂停"
                recordButton.isEnabled = true
            } else {
                statusLabel.stringValue = "正在录制..."
                recordButton.isEnabled = false
            }
            statusLabel.textColor = NSColor.systemRed
            stopButton.isEnabled = true
        } else {
            statusLabel.stringValue = "就绪"
            statusLabel.textColor = NSColor.secondaryLabelColor
            recordButton.isEnabled = true
            stopButton.isEnabled = false
        }
    }

    // MARK: - Actions

    @objc private func startRecording() {
        NotificationCenter.default.post(
            name: NSNotification.Name("ScreenKiteStartRecording"),
            object: nil
        )
    }

    @objc private func stopRecording() {
        NotificationCenter.default.post(
            name: NSNotification.Name("ScreenKiteStopRecording"),
            object: nil
        )
    }

    @objc private func checkPermissions() {
        let hasScreen = CGPreflightScreenCaptureAccess()
        let hasAcc = HotkeyManagerHelper.hasAccessibilityPermission()

        let screenStatus = hasScreen ? "已授权" : "未授权"
        let accStatus = hasAcc ? "已授权" : "未授权"

        let alert = NSAlert()
        alert.messageText = "权限检查结果"
        alert.informativeText = "屏幕录制权限: " + screenStatus + "\n辅助功能权限: " + accStatus
        alert.alertStyle = (hasScreen && hasAcc) ? .informational : .warning
        alert.addButton(withTitle: "确定")

        if !hasScreen {
            alert.addButton(withTitle: "打开屏幕录制设置")
        }

        let response = alert.runModal()
        if response == .alertSecondButtonReturn && !hasScreen {
            _ = CGRequestScreenCaptureAccess()
        }
    }
}
