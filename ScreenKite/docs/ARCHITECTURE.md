# ScreenKite v1.0 架构设计文档

> **版本**: v1.0  
> **日期**: 2026-03-24  
> **状态**: 已批准  

---

## 1. 架构总览

### 1.1 设计原则

- **低侵入性**：不修改 ScreenKite 现有核心录制引擎，新增功能以独立 Feature Module 形式存在
- **响应式**：使用 Combine 框架实现事件驱动架构
- **线程安全**：UI 操作在主线程，数据处理在后台队列
- **可测试**：所有核心逻辑均有单元测试覆盖

### 1.2 系统架构图

```
┌─────────────────────────────────────────────────┐
│                   ScreenKite App                  │
│  ┌───────────────────────────────────────────┐   │
│  │              Presentation Layer            │   │
│  │  ┌──────────┐ ┌──────────┐ ┌───────────┐  │   │
│  │  │MainWindow│ │MenuBarUI │ │PrefsPanel│  │   │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘  │   │
│  └───────┼────────────┼────────────┼──────────┘   │
│          │            │            │               │
│  ┌───────┴────────────┴────────────┴──────────┐   │
│  │              Application Layer               │   │
│  │  ┌─────────────────────────────────────┐   │   │
│  │  │         AppCoordinator              │   │   │
│  │  │  (Combine Publishers / Subscribers) │   │   │
│  │  └──────────────────┬──────────────────┘   │   │
│  └─────────────────────┼─────────────────────┘   │
│                        │                          │
│  ┌─────────────────────┼─────────────────────┐   │
│  │          Feature Modules Layer             │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────┐ │   │
│  │  │Scheduled    │ │Global       │ │DND  │ │   │
│  │  │Recording    │ │Hotkeys      │ │Mode │ │   │
│  │  └──────┬──────┘ └──────┬──────┘ └──┬──┘ │   │
│  └─────────┼────────────────┼───────────┼─────┘   │
│            │                │           │          │
│  ┌─────────┴────────────────┴───────────┴──────┐   │
│  │              Core Services Layer            │   │
│  │  ┌──────────┐ ┌──────────┐ ┌───────────┐  │   │
│  │  │Recording │ │Scheduler │ │Notification│  │   │
│  │  │Engine    │ │Service   │ │Service    │  │   │
│  │  └──────────┘ └──────────┘ └───────────┘  │   │
│  └───────────────────────────────────────────┘   │
│                                                   │
│  ┌───────────────────────────────────────────┐   │
│  │            Platform Layer                   │   │
│  │  ScreenCaptureKit │ Metal │ Carbon │ Focus │   │
│  └───────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

---

## 2. 模块架构

### 2.1 模块划分

| 模块 | 职责 | 公开接口 |
|------|------|---------|
| `Core.RecordingEngine` | 录制核心（已有） | `start()`, `pause()`, `stop()`, `addMarker()` |
| `Core.SchedulerService` | 定时调度核心 | `schedule(Task)`, `cancel(id)`, `list()` |
| `Core.NotificationService` | 通知服务 | `schedule(type, content, at:)` |
| `Features.ScheduledRecording` | 定时录制业务 | `ScheduledRecordingCoordinator` |
| `Features.GlobalHotkeys` | 快捷键管理 | `HotkeyManager` |
| `Features.DNDMode` | 勿扰模式管理 | `DNDModeController` |

### 2.2 模块依赖关系

```
AppCoordinator
├── ScheduledRecordingCoordinator
│   ├── SchedulerService (Core)
│   ├── NotificationService (Core)
│   └── RecordingEngine (Core)
├── HotkeyManager
│   └── RecordingEngine (Core)
└── DNDModeController
    └── NotificationService (Core)
```

---

## 3. 核心服务设计

### 3.1 SchedulerService（调度服务）

```swift
// 核心接口
protocol SchedulerServiceProtocol {
    func schedule(_ task: ScheduledTask) -> AnyPublisher<ScheduledTask, SchedulerError>
    func cancel(_ taskId: UUID) -> AnyPublisher<Void, SchedulerError>
    func listAllTasks() -> AnyPublisher<[ScheduledTask], Never>
    func updateTask(_ task: ScheduledTask) -> AnyPublisher<ScheduledTask, SchedulerError>
}

// 触发事件流
let taskTriggeredPublisher: AnyPublisher<ScheduledTask, Never>
```

**实现要点**：
- 使用 `DispatchSourceTimer` 作为高精度定时器
- 定时任务存储在 `UserDefaults`（JSON 编码），确保重启后持久化
- 使用 `NSFileProtectionComplete` 加密存储录制配置
- 定时精度：±500ms（系统调度精度）

### 3.2 RecordingEngine 接口扩展

```swift
// 为支持三个新功能，RecordingEngine 需要暴露以下接口
protocol RecordingEngineProtocol {
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    var recordingDuration: TimeInterval { get }

    func start(with config: RecordingConfig) throws
    func pause()
    func resume()
    func stop() async -> URL?   // 返回录制文件路径
    func addMarker(label: String)
}
```

### 3.3 HotkeyManager（快捷键管理）

```swift
// 核心接口
final class HotkeyManager {
    struct HotkeyBinding {
        let keyCode: UInt32      // Carbon key code
        let modifiers: UInt32     // Carbon modifiers
        let action: HotkeyAction
    }

    enum HotkeyAction {
        case startOrResumeRecording
        case pauseOrResumeRecording
        case stopRecording
        case addMarker
    }

    func register(_ binding: HotkeyBinding) throws
    func unregister(_ action: HotkeyAction)
    func updateBinding(_ action: HotkeyAction, newBinding: HotkeyBinding) throws

    // 全局事件发布
    let hotkeyPressed: AnyPublisher<HotkeyAction, Never>
}
```

**实现要点**：
- 使用 Carbon Events API (`RegisterEventHotKey`) 注册全局快捷键
- 需要"辅助功能"权限（Accessibility），启动时引导用户授权
- 快捷键在非录制状态不触发任何操作（安全门控）
- 冲突检测：注册前检查 `CGSGetActiveHotKey` 是否已被占用

### 3.4 DNDModeController（勿扰模式控制）

```swift
// 核心接口
final class DNDModeController {
    struct FocusState: Codable {
        let isEnabled: Bool
        let focusModeName: String?
        let enabledDate: Date?
    }

    // 当前录制是否启用了 DND
    var isDNDModeActive: Bool { get }

    // 开启勿扰录制
    func enableDNDMode() throws

    // 关闭勿扰录制，恢复原状态
    func disableDNDMode()

    // DND 状态变化发布
    let dndStatusChanged: AnyPublisher<Bool, Never>
}
```

**实现要点**：
- 通过 `NSUserNotifications` 或 Private Framework 操作 Focus 状态
- 录制开始前保存当前 Focus 状态到 `UserDefaults`
- 录制结束后根据保存状态恢复
- 提供手动开关作为备用方案

---

## 4. 数据流设计

### 4.1 定时录制数据流

```
用户创建定时任务
    ↓
UI Layer: ScheduledRecordingViewModel
    ↓ (Combine Publisher)
SchedulerService.schedule(task)
    ↓
持久化到 UserDefaults
    ↓
注册 DispatchSourceTimer
    ↓
Timer 触发（at scheduledDate - 60s）
    ↓
NotificationService.sendReminder()
    ↓ (60秒后)
RecordingEngine.start()
    ↓
录制进行中...
    ↓
用户按 F11 或到达时长上限
    ↓
RecordingEngine.stop()
    ↓
保存文件，发送完成通知
    ↓
若为周期性任务 → 计算下次触发时间 → 更新 Timer
```

### 4.2 全局快捷键数据流

```
用户按下 F9（在任意应用窗口）
    ↓
Carbon Event Tap (CGEvent)
    ↓
HotkeyManager 捕获事件
    ↓
检查 isRecording / isPaused 状态
    ↓
若录制中 → 忽略（安全门控）
若未录制 → RecordingEngine.start()
    ↓
更新 UI 状态（菜单栏红点）
```

### 4.3 DND 录制数据流

```
用户点击"开始勿扰录制"
    ↓
DNDModeController.enableDNDMode()
    ├→ 保存当前 Focus 状态
    ├→ 开启 macOS DND (Focus API)
    └→ 发布 dndStatusChanged = true
    ↓
RecordingEngine.start()
    ↓
录制中...（DND 保护）
    ↓
用户停止录制 / 超时
    ↓
RecordingEngine.stop()
    ↓
DNDModeController.disableDNDMode()
    ├→ 读取保存的 Focus 状态
    └→ 恢复到录制前状态
```

---

## 5. 技术选型

| 组件 | 技术选型 | 理由 |
|------|---------|------|
| 项目管理 | XcodeGen + YAML | 声明式配置，版本控制友好 |
| 语言 | Swift 5.9 | 原生支持，简洁安全 |
| 响应式 | Combine | Apple 官方框架，与 SwiftUI 无缝集成 |
| 定时器 | DispatchSourceTimer | 高精度（纳秒级），低功耗 |
| 持久化 | UserDefaults (JSON) | 轻量，简单，无需迁移 |
| 通知 | UserNotifications | 系统原生通知 |
| 快捷键 | Carbon Events API | 全局热键唯一可靠方案 |
| DND 控制 | Private Framework / NSWorkspace | macOS 系统集成 |
| 测试 | XCTest + XCUITest | Apple 官方测试框架 |

---

## 6. 安全性设计

### 6.1 权限矩阵

| 功能 | 所需权限 | 引导时机 |
|------|---------|---------|
| 屏幕录制 | 屏幕录制权限 | 首次启动 |
| 定时录制 | 屏幕录制权限 + 后台运行 | 首次设置定时任务 |
| 全局快捷键 | 辅助功能权限 | 首次注册快捷键 |
| DND 模式 | 无额外权限 | 系统内置 |

### 6.2 安全门控

- 快捷键 F9/F10/F11 **仅在录制引擎已初始化后**才响应操作
- DND 录制期间关闭 DND **不影响录制进程**，仅显示警告
- 定时任务数据包含录制配置（可能含文件路径），使用 `NSFileProtection` 加密

---

## 7. 错误处理策略

| 错误场景 | 处理策略 |
|---------|---------|
| 快捷键权限未授权 | 弹出系统偏好设置引导 |
| 定时录制触发时屏幕录制权限被撤销 | 跳过本次录制，发送失败通知，保留任务 |
| DND API 调用失败 | 降级到手动 DND 提示，录制继续 |
| 录制引擎启动失败 | 发送错误通知，标记任务为失败状态 |
| 定时任务过期（错过触发时间） | 跳过本次，周期性任务计算下次触发 |

---

## 8. 性能预算

| 指标 | 预算 |
|------|------|
| 定时器内存占用 | +2MB |
| 快捷键注册内存占用 | +1MB |
| DND 控制器内存占用 | +1MB |
| 空闲状态总内存增量 | ≤ 5MB |
| 录制状态总内存增量 | ≤ 20MB |
| 定时精度（误差） | ±500ms |
| 快捷键响应延迟 | ≤ 50ms |
