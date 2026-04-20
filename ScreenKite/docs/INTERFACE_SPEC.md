# ScreenKite v1.0 接口规格说明书

> **版本**: v1.0  
> **日期**: 2026-03-24  
> **状态**: 已批准（待研发实现）

---

## 1. 概述

本文档定义 ScreenKite v1.0 三个新功能模块的对外接口规范，供开发团队实现参考。

---

## 2. RecordingEngine 现有接口（扩展前）

```swift
// Sources/Core/RecordingEngine.swift
// 录制引擎核心接口（现有）

protocol RecordingEngineProtocol {
    /// 当前是否为录制状态
    var isRecording: Bool { get }

    /// 当前是否为暂停状态
    var isPaused: Bool { get }

    /// 当前录制持续时间（秒）
    var recordingDuration: TimeInterval { get }

    /// 录制配置
    var currentConfig: RecordingConfig? { get }

    /// 录制状态变更发布
    var recordingStatePublisher: AnyPublisher<RecordingState, Never> { get }

    /// 时间轴标记变更发布
    var markersPublisher: AnyPublisher<[RecordingMarker], Never> { get }

    /// 开始录制
    /// - Parameter config: 录制配置
    /// - Throws: RecordingError
    func start(with config: RecordingConfig) throws

    /// 暂停录制
    func pause()

    /// 恢复录制
    func resume()

    /// 停止录制
    /// - Returns: 录制文件本地路径
    func stop() async -> URL?

    /// 添加时间轴标记
    /// - Parameter label: 标记名称（可选）
    func addMarker(label: String?)

    /// 销毁录制引擎，释放资源
    func shutdown()
}

// MARK: - Supporting Types

enum RecordingState {
    case idle
    case preparing
    case recording
    case paused
    case stopping
    case error(RecordingError)
}

struct RecordingConfig {
    var captureType: CaptureType
    var targetWindow: NSWindow?
    var captureRect: CGRect?
    var includeSystemAudio: Bool
    var includeMicrophone: Bool
    var frameRate: Int
    var outputFormat: OutputFormat
    var outputDirectory: URL
}

enum CaptureType {
    case fullScreen
    case specifiedWindow
    case specifiedRegion
}

enum OutputFormat {
    case mp4(H264)
    case mov(ProRes)
    case gif
}

struct RecordingMarker: Identifiable {
    let id: UUID
    let timestamp: TimeInterval   // 距录制开始的时间（秒）
    let label: String?
    let createdAt: Date
}

// 已知错误类型（需在 RecordingEngine 中定义）
enum RecordingError: Error {
    case permissionDenied
    case hardwareNotSupported
    case resourceBusy
    case configurationInvalid(String)
    case unknown(underlying: Error?)
}
```

---

## 3. SchedulerService 接口规格

### 3.1 协议定义

```swift
// Sources/Core/SchedulerService.swift

/// 调度服务协议
protocol SchedulerServiceProtocol: AnyObject {
    /// 定时任务触发事件发布
    /// 发出内容：即将触发的任务（触发前 60 秒发出）
    var taskWillTriggerPublisher: AnyPublisher<ScheduledTask, Never> { get }

    /// 定时任务执行事件发布
    var taskTriggeredPublisher: AnyPublisher<ScheduledTask, Never> { get }

    /// 任务列表变更发布
    var tasksDidChangePublisher: AnyPublisher<[ScheduledTask], Never> { get }

    /// 创建定时任务
    /// - Parameter task: 任务模型
    /// - Returns: 发布结果（成功返回任务，失败返回错误）
    func schedule(_ task: ScheduledTask) -> AnyPublisher<ScheduledTask, SchedulerError>

    /// 取消定时任务
    /// - Parameter taskId: 任务 ID
    /// - Returns: 发布结果
    func cancel(_ taskId: UUID) -> AnyPublisher<Void, SchedulerError>

    /// 更新定时任务
    /// - Parameter task: 更新后的任务模型
    /// - Returns: 发布结果
    func updateTask(_ task: ScheduledTask) -> AnyPublisher<ScheduledTask, SchedulerError>

    /// 获取所有任务
    /// - Returns: 当前所有定时任务列表
    func listAllTasks() -> AnyPublisher<[ScheduledTask], Never>

    /// 根据 ID 获取单个任务
    /// - Parameter taskId: 任务 ID
    /// - Returns: 任务（如不存在则发出 nil）
    func getTask(_ taskId: UUID) -> AnyPublisher<ScheduledTask?, Never>

    /// 启用/禁用任务
    /// - Parameters:
    ///   - taskId: 任务 ID
    ///   - enabled: 是否启用
    func setTaskEnabled(_ taskId: UUID, enabled: Bool) -> AnyPublisher<Void, SchedulerError>

    /// 触发指定任务（立即执行，跳过定时器）
    /// - Parameter taskId: 任务 ID
    func triggerNow(_ taskId: UUID) -> AnyPublisher<ScheduledTask, SchedulerError>

    /// 启动调度服务（App 启动时调用）
    func start()

    /// 停止调度服务（App 退出时调用）
    func stop()
}
```

### 3.2 数据模型

```swift
// Sources/Core/Models/ScheduledTask.swift

/// 定时任务模型
struct ScheduledTask: Codable, Identifiable, Equatable {
    let id: UUID

    /// 任务名称（用户可见）
    var name: String

    /// 触发类型
    var triggerType: TriggerType

    /// 计划触发时间（仅一次性任务使用）
    var scheduledDate: Date

    /// 重复天数（仅 weekly 类型使用，1=周一 ... 7=周日）
    var repeatDays: [Int]?

    /// 录制配置
    var recordingConfig: RecordingConfig

    /// 录制最大时长（秒），nil=无限制
    var durationLimit: TimeInterval?

    /// 是否启用
    var isEnabled: Bool

    /// 创建时间
    let createdAt: Date

    /// 上次触发时间
    var lastTriggeredAt: Date?

    /// 备注（可选）
    var note: String?

    /// 计算下次触发时间
    /// - Parameter fromDate: 基准时间（默认为当前时间）
    /// - Returns: 下次触发时间（若已过期且无重复则返回 nil）
    func nextTriggerDate(fromDate: Date) -> Date?
}

/// 触发类型
enum TriggerType: String, Codable, CaseIterable {
    /// 一次性触发
    case once = "once"
    /// 每日重复
    case daily = "daily"
    /// 每周重复
    case weekly = "weekly"

    var displayName: String {
        switch self {
        case .once: return "仅一次"
        case .daily: return "每日"
        case .weekly: return "每周"
        }
    }
}

/// 调度错误类型
enum SchedulerError: Error, LocalizedError {
    case taskNotFound(UUID)
    case taskExpired        // 一次性任务已过期
    case storageFailed(underlying: Error)
    case invalidConfiguration(String)
    case alreadyScheduled(UUID)
    case recordingEngineUnavailable

    var errorDescription: String? {
        switch self {
        case .taskNotFound(let id):
            return "未找到定时任务: \(id.uuidString)"
        case .taskExpired:
            return "该任务已过期（一次性任务）"
        case .storageFailed(let err):
            return "存储失败: \(err.localizedDescription)"
        case .invalidConfiguration(let msg):
            return "配置无效: \(msg)"
        case .alreadyScheduled(let id):
            return "任务已存在: \(id.uuidString)"
        case .recordingEngineUnavailable:
            return "录制引擎不可用"
        }
    }
}
```

### 3.3 实现要求

```swift
// Sources/Core/SchedulerServiceImpl.swift

/// SchedulerService 推荐实现
final class SchedulerServiceImpl: SchedulerServiceProtocol {

    // 注入依赖
    private let recordingEngine: RecordingEngineProtocol
    private let notificationService: NotificationServiceProtocol
    private let storage: SchedulerStorageProtocol

    // 内部状态
    private var activeTimers: [UUID: DispatchSourceTimer] = [:]
    private let queue = DispatchQueue(label: "com.screenkite.scheduler", qos: .userInitiated)

    // MARK: - 实现要点

    /// start() 必须完成以下操作：
    /// 1. 从 storage 加载所有任务
    /// 2. 遍历任务，为每个未过期的任务注册 DispatchSourceTimer
    /// 3. 计算下次触发时间，若 < 当前时间，则计算下一次（如周期性任务）
    /// 4. 60 秒前注册提醒 Timer，触发时发送 notificationService.reminder()
    /// 5. 在主 Timer 触发时，调用 recordingEngine.start()

    /// schedule(_ task:) 必须完成以下操作：
    /// 1. 验证任务配置（时间不能在过去）
    /// 2. 持久化到 storage
    /// 3. 注册 DispatchSourceTimer（相对延迟 = targetTime - now - 60s）
    /// 4. 若相对延迟 < 0，立即触发
    /// 5. 发布 tasksDidChangePublisher

    /// stop() 必须完成以下操作：
    /// 1. 取消所有 activeTimers
    /// 2. 停止 storage
}
```

### 3.4 存储接口

```swift
// Sources/Core/Storage/SchedulerStorage.swift

protocol SchedulerStorageProtocol {
    func loadAll() -> AnyPublisher<[ScheduledTask], Error>
    func save(_ task: ScheduledTask) -> AnyPublisher<Void, Error>
    func delete(_ taskId: UUID) -> AnyPublisher<Void, Error>
    func saveAll(_ tasks: [ScheduledTask]) -> AnyPublisher<Void, Error>
}

/// 推荐实现：使用 UserDefaults + JSON 编码
final class UserDefaultsSchedulerStorage: SchedulerStorageProtocol {
    private let key = "com.screenkite.scheduled_tasks.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}
```

---

## 4. HotkeyManager 接口规格

### 4.1 协议定义

```swift
// Sources/Features/GlobalHotkeys/HotkeyManager.swift

/// 快捷键管理器协议
protocol HotkeyManagerProtocol: AnyObject {
    /// 快捷键按下事件发布
    var hotkeyPressedPublisher: AnyPublisher<HotkeyAction, Never> { get }

    /// 当前注册状态变更发布
    var bindingsDidChangePublisher: AnyPublisher<Void, Never> { get }

    /// 注册快捷键绑定
    /// - Parameter binding: 快捷键绑定
    /// - Throws: HotkeyError
    func register(_ binding: HotkeyBinding) throws

    /// 注销指定操作的快捷键
    /// - Parameter action: 操作类型
    func unregister(_ action: HotkeyAction)

    /// 更新绑定
    /// - Parameters:
    ///   - action: 操作类型
    ///   - newBinding: 新绑定
    func updateBinding(_ action: HotkeyAction, newBinding: HotkeyBinding) throws

    /// 获取指定操作的当前绑定
    /// - Parameter action: 操作类型
    /// - Returns: 当前绑定（未注册则返回 nil）
    func getBinding(for action: HotkeyAction) -> HotkeyBinding?

    /// 获取所有当前绑定
    func getAllBindings() -> [HotkeyAction: HotkeyBinding]

    /// 检查快捷键是否与系统/其他应用冲突
    /// - Parameter binding: 待检查绑定
    /// - Returns: 冲突信息（无冲突则 nil）
    func checkConflict(_ binding: HotkeyBinding) -> HotkeyConflict?

    /// 启动管理器
    func start()

    /// 停止管理器
    func stop()
}

// MARK: - Types

struct HotkeyBinding: Equatable, Codable {
    /// Carbon key code（如 F9=17, F10=16, F11=15, F12=14）
    let keyCode: UInt32

    /// Carbon modifiers（如 cmdKey=256, shiftKey=512, optionKey=2048, ctrlKey=4096）
    let modifiers: UInt32

    /// 绑定的操作
    let action: HotkeyAction

    /// 用户自定义名称（可选）
    var customName: String?

    /// 人类可读的快捷键描述
    var displayString: String {
        HotkeyDisplayString(keyCode: keyCode, modifiers: modifiers)
    }
}

enum HotkeyAction: String, Codable, CaseIterable {
    case startOrResume = "startOrResume"
    case pauseOrResume = "pauseOrResume"
    case stop = "stop"
    case addMarker = "addMarker"

    var displayName: String {
        switch self {
        case .startOrResume: return "开始/恢复录制"
        case .pauseOrResume: return "暂停/恢复录制"
        case .stop: return "停止录制"
        case .addMarker: return "添加时间戳标记"
        }
    }
}

struct HotkeyConflict {
    let binding: HotkeyBinding
    let conflictType: ConflictType
    let conflictDescription: String
}

enum ConflictType {
    case systemReserved    // 系统保留快捷键
    case appConflict       // 与其他应用冲突
    case selfConflict      // 与已注册的快捷键冲突
}
```

### 4.2 Carbon Key Code 参考表

```swift
// Sources/Features/GlobalHotkeys/KeyCodes.swift

enum KeyCode {
    static let f9: UInt32  = 17
    static let f10: UInt32 = 16
    static let f11: UInt32 = 15
    static let f12: UInt32 = 14
    static let space: UInt32 = 49
    static let escape: UInt32 = 53

    // Modifiers
    static let noModifier: UInt32 = 0
    static let commandKey: UInt32  = 256   // ⌘
    static let shiftKey: UInt32     = 512   // ⇧
    static let optionKey: UInt32    = 2048  // ⌥
    static let controlKey: UInt32    = 4096  // ⌃
}

/// 默认快捷键配置
let defaultHotkeyBindings: [HotkeyAction: HotkeyBinding] = [
    .startOrResume: HotkeyBinding(keyCode: .f9,  modifiers: .noModifier, action: .startOrResume),
    .pauseOrResume: HotkeyBinding(keyCode: .f10, modifiers: .noModifier, action: .pauseOrResume),
    .stop:          HotkeyBinding(keyCode: .f11, modifiers: .noModifier, action: .stop),
    .addMarker:     HotkeyBinding(keyCode: .f12, modifiers: .noModifier, action: .addMarker),
]
```

### 4.3 错误类型

```swift
enum HotkeyError: Error, LocalizedError {
    case permissionDenied              // 辅助功能权限未授权
    case registrationFailed(String)   // 系统注册失败
    case invalidKeyCode(UInt32)       // 无效的 key code
    case conflictDetected(HotkeyConflict)  // 检测到冲突

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "快捷键功能需要辅助功能权限，请在系统设置中授权 ScreenKite"
        case .registrationFailed(let msg):
            return "快捷键注册失败: \(msg)"
        case .invalidKeyCode(let code):
            return "不支持的快捷键 (keyCode: \(code))"
        case .conflictDetected(let conflict):
            return "快捷键冲突: \(conflict.conflictDescription)"
        }
    }
}
```

---

## 5. DNDModeController 接口规格

### 5.1 协议定义

```swift
// Sources/Features/DNDMode/DNDModeController.swift

/// 勿扰模式控制器协议
protocol DNDModeControllerProtocol: AnyObject {
    /// DND 模式是否激活
    var isDNDModeActive: Bool { get }

    /// 当前 DND 状态变更发布
    /// true = DND 开启，false = DND 关闭
    var dndStatusChangedPublisher: AnyPublisher<Bool, Never> { get }

    /// 当前录制 ID（DND 模式关联的录制任务）
    var associatedRecordingId: UUID? { get }

    /// 开启勿扰录制模式
    /// - Throws: DNDError
    /// - Precondition: 当前未在录制中
    func enableDNDMode() throws

    /// 关闭勿扰录制模式
    /// - Precondition: DND 模式必须已激活
    /// - Effect: 恢复录制前的 Focus 状态
    func disableDNDMode()

    /// 检查当前 Focus 状态
    /// - Returns: 当前 Focus 状态
    func getCurrentFocusState() -> FocusState

    /// 获取 DND 模式历史记录
    func getDNDModeHistory() -> [DNDModeRecord]
}

/// Focus 状态快照
struct FocusState: Codable, Equatable {
    /// DND 是否开启
    let isDNDEnabled: Bool

    /// Focus 名称（如"勿扰"、"会议"）
    let focusModeName: String?

    /// 状态启用时间
    let enabledAt: Date

    /// 状态来源
    let source: FocusStateSource
}

enum FocusStateSource: String, Codable {
    case system       // macOS 系统默认
    case userManual   // 用户手动设置
    case appDND      // ScreenKite DND 模式
}

/// DND 模式记录（历史）
struct DNDModeRecord: Codable, Identifiable {
    let id: UUID
    let enabledAt: Date
    let disabledAt: Date?
    let recordingId: UUID?
    let wasManuallyDisabled: Bool  // 用户主动关闭（非录制结束）
}
```

### 5.2 错误类型

```swift
enum DNDError: Error, LocalizedError {
    case alreadyActive                    // DND 模式已经激活
    case recordingNotStarted              // 尝试启用时不在录制状态
    case focusAPIUnavailable              // Focus API 不可用（macOS 版本问题）
    case permissionDenied                 // 权限不足
    case stateRestoreFailed               // 状态恢复失败

    var errorDescription: String? {
        switch self {
        case .alreadyActive:
            return "勿扰模式已在运行中"
        case .recordingNotStarted:
            return "请先开始录制后再启用勿扰模式"
        case .focusAPIUnavailable:
            return "当前 macOS 版本不支持勿扰模式控制"
        case .permissionDenied:
            return "系统权限不足，无法控制勿扰模式"
        case .stateRestoreFailed:
            return "录制结束，无法恢复原有的勿扰状态"
        }
    }
}
```

---

## 6. 通知服务接口

```swift
// Sources/Core/NotificationService.swift

protocol NotificationServiceProtocol {
    /// 预约录制提醒
    /// - Parameters:
    ///   - taskName: 任务名称
    ///   - secondsBefore: 提前多少秒（默认 60）
    ///   - taskId: 关联的任务 ID
    func scheduleRecordingReminder(taskName: String, secondsBefore: Int, taskId: UUID)

    /// 录制已开始通知
    func notifyRecordingStarted()

    /// 录制已停止通知
    /// - Parameters:
    ///   - duration: 录制时长
    ///   - fileURL: 文件路径
    func notifyRecordingStopped(duration: TimeInterval, fileURL: URL?)

    /// 录制失败通知
    func notifyRecordingFailed(reason: String)

    /// 定时任务触发通知
    func notifyTaskTriggered(taskName: String)

    /// 取消所有预约通知
    func cancelAllPendingNotifications()

    /// 取消指定任务的通知
    func cancelNotifications(for taskId: UUID)
}

/// 通知类型
enum NotificationType {
    case recordingReminder
    case recordingStarted
    case recordingStopped
    case recordingFailed
    case taskTriggered
}
```

---

## 7. 模块集成规范

### 7.1 AppCoordinator 集成点

```swift
// Sources/App/AppCoordinator.swift

final class AppCoordinator {
    // 依赖注入
    private let recordingEngine: RecordingEngineProtocol
    private let schedulerService: SchedulerServiceProtocol
    private let hotkeyManager: HotkeyManagerProtocol
    private let dndController: DNDModeControllerProtocol
    private let notificationService: NotificationServiceProtocol

    init(
        recordingEngine: RecordingEngineProtocol,
        storage: SchedulerStorageProtocol,
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

    func start() {
        // 启动所有服务
        schedulerService.start()
        hotkeyManager.start()

        // 订阅快捷键事件
        setupHotkeySubscriptions()

        // 订阅定时任务事件
        setupSchedulerSubscriptions()
    }

    private func setupHotkeySubscriptions() {
        hotkeyManager.hotkeyPressedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                self?.handleHotkeyAction(action)
            }
            .store(in: &cancellables)
    }

    private func handleHotkeyAction(_ action: HotkeyAction) {
        guard recordingEngine.isRecording || action == .startOrResume else { return }

        switch action {
        case .startOrResume:
            if !recordingEngine.isRecording {
                // 使用上次配置或默认配置启动
                try? recordingEngine.start(with: lastRecordingConfig)
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
                await recordingEngine.stop()
            }

        case .addMarker:
            if recordingEngine.isRecording {
                recordingEngine.addMarker(label: nil)
            }
        }
    }

    private func setupSchedulerSubscriptions() {
        // 定时录制触发
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

        schedulerService.taskTriggeredPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] task in
                self?.notificationService.notifyTaskTriggered(taskName: task.name)
                // 自动启动录制
                try? self?.recordingEngine.start(with: task.recordingConfig)
            }
            .store(in: &cancellables)
    }
}
```

---

## 8. 依赖注入配置

```swift
// Sources/App/DIContainer.swift

/// 依赖注入容器（简单实现，可替换为专业 DI 框架如 Needle）
final class DIContainer {
    static let shared = DIContainer()

    // MARK: - Core
    lazy var recordingEngine: RecordingEngineProtocol = RecordingEngineImpl()
    lazy var schedulerStorage: SchedulerStorageProtocol = UserDefaultsSchedulerStorage()
    lazy var notificationService: NotificationServiceProtocol = NotificationServiceImpl()

    lazy var schedulerService: SchedulerServiceProtocol = SchedulerServiceImpl(
        recordingEngine: recordingEngine,
        notificationService: notificationService,
        storage: schedulerStorage
    )

    // MARK: - Features
    lazy var hotkeyManager: HotkeyManagerProtocol = HotkeyManagerImpl(
        recordingEngine: recordingEngine
    )

    lazy var dndController: DNDModeControllerProtocol = DNDModeControllerImpl(
        notificationService: notificationService
    )

    // MARK: - App Coordinator
    lazy var appCoordinator: AppCoordinator = AppCoordinator(
        recordingEngine: recordingEngine,
        storage: schedulerStorage,
        hotkeyManager: hotkeyManager,
        dndController: dndController,
        notificationService: notificationService
    )
}
```
