import Foundation
import Combine
import Carbon

// MARK: - HotkeyManager Protocol

protocol HotkeyManagerProtocol: AnyObject {
    var hotkeyPressedPublisher: AnyPublisher<HotkeyAction, Never> { get }
    var bindingsDidChangePublisher: AnyPublisher<Void, Never> { get }

    func register(_ binding: HotkeyBinding) throws
    func unregister(_ action: HotkeyAction)
    func updateBinding(_ action: HotkeyAction, newBinding: HotkeyBinding) throws
    func getBinding(for action: HotkeyAction) -> HotkeyBinding?
    func getAllBindings() -> [HotkeyAction: HotkeyBinding]
    func checkConflict(_ binding: HotkeyBinding) -> HotkeyConflict?
    func start()
    func stop()
}

// MARK: - HotkeyBinding

struct HotkeyBinding: Equatable, Codable {
    let keyCode: UInt32
    let modifiers: UInt32
    let action: HotkeyAction
    var customName: String?

    var displayString: String {
        HotkeyDisplayString(keyCode: keyCode, modifiers: modifiers)
    }
}

enum HotkeyAction: String, Codable, CaseIterable, Hashable {
    case startOrResume = "startOrResume"
    case pauseOrResume = "pauseOrResume"
    case stop = "stop"
    case addMarker = "addMarker"

    var displayName: String {
        switch self {
        case .startOrResume: return "开始/恢复录制"
        case .pauseOrResume: return "暂停/恢复录制"
        case .stop:          return "停止录制"
        case .addMarker:     return "添加时间戳标记"
        }
    }
}

struct HotkeyConflict {
    let binding: HotkeyBinding
    let conflictType: ConflictType
    let conflictDescription: String
}

enum ConflictType {
    case systemReserved
    case appConflict
    case selfConflict
}

// MARK: - KeyCode Constants

enum KeyCode {
    static let f9: UInt32  = 17
    static let f10: UInt32 = 16
    static let f11: UInt32 = 15
    static let f12: UInt32 = 14
    static let space: UInt32 = 49
    static let escape: UInt32 = 53

    static let noModifier: UInt32 = 0
    static let commandKey: UInt32  = 256
    static let shiftKey: UInt32     = 512
    static let optionKey: UInt32    = 2048
    static let controlKey: UInt32   = 4096
}

let defaultHotkeyBindings: [HotkeyAction: HotkeyBinding] = [
    .startOrResume: HotkeyBinding(keyCode: 17, modifiers: 0, action: .startOrResume),
    .pauseOrResume: HotkeyBinding(keyCode: 16, modifiers: 0, action: .pauseOrResume),
    .stop:          HotkeyBinding(keyCode: 15, modifiers: 0, action: .stop),
    .addMarker:     HotkeyBinding(keyCode: 14, modifiers: 0, action: .addMarker),
]

func HotkeyDisplayString(keyCode: UInt32, modifiers: UInt32) -> String {
    var parts: [String] = []

    if modifiers & KeyCode.controlKey != 0 { parts.append("^") }
    if modifiers & KeyCode.optionKey != 0  { parts.append("⌥") }
    if modifiers & KeyCode.shiftKey != 0   { parts.append("⇧") }
    if modifiers & KeyCode.commandKey != 0 { parts.append("⌘") }

    let keyName: String
    switch keyCode {
    case 17:  keyName = "F9"
    case 16:  keyName = "F10"
    case 15:  keyName = "F11"
    case 14:  keyName = "F12"
    case 49:  keyName = "Space"
    case 53:  keyName = "Esc"
    case 36:  keyName = "↩"
    case 48:  keyName = "⇥"
    case 51:  keyName = "⌫"
    case 123: keyName = "←"
    case 124: keyName = "→"
    case 125: keyName = "↓"
    case 126: keyName = "↑"
    default:  keyName = "Key(\(keyCode))"
    }
    parts.append(keyName)

    return parts.joined()
}

// MARK: - HotkeyError

enum HotkeyError: Error, LocalizedError {
    case permissionDenied
    case registrationFailed(String)
    case invalidKeyCode(UInt32)
    case conflictDetected(HotkeyConflict)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "快捷键功能需要辅助功能权限，请在系统设置 → 隐私与安全性 → 辅助功能 中授权 ScreenKite"
        case .registrationFailed(let msg):
            return "快捷键注册失败: \(msg)"
        case .invalidKeyCode(let code):
            return "不支持的快捷键 (keyCode: \(code))"
        case .conflictDetected(let conflict):
            return "快捷键冲突: \(conflict.conflictDescription)"
        }
    }
}

// MARK: - SubjectHolder for HotkeyManager

private final class HotkeySubjects {
    let hotkeyPressed = PassthroughSubject<HotkeyAction, Never>()
    let bindingsDidChange = PassthroughSubject<Void, Never>()
}

// MARK: - HotkeyManagerImpl

final class HotkeyManagerImpl: HotkeyManagerProtocol {

    // Protocol requires AnyPublisher, so use computed properties backed by internal subjects
    var hotkeyPressedPublisher: AnyPublisher<HotkeyAction, Never> {
        subjects.hotkeyPressed.eraseToAnyPublisher()
    }
    var bindingsDidChangePublisher: AnyPublisher<Void, Never> {
        subjects.bindingsDidChange.eraseToAnyPublisher()
    }

    private let subjects = HotkeySubjects()

    private var bindings: [HotkeyAction: HotkeyBinding] = [:]
    private var carbonRefs: [HotkeyAction: EventHotKeyRef?] = [:]
    private var hotKeyIDs: [HotkeyAction: UInt32] = [:]
    private weak var recordingEngine: RecordingEngineProtocol?
    private var isRunning = false
    private var hasAccessibilityPermission = false
    private var eventHandlerRef: EventHandlerRef?

    init(recordingEngine: RecordingEngineProtocol) {
        self.recordingEngine = recordingEngine
        bindings = defaultHotkeyBindings
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        checkAccessibilityPermission()
        registerAllBindings()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        unregisterAllBindings()
    }

    func register(_ binding: HotkeyBinding) throws {
        guard hasAccessibilityPermission else {
            throw HotkeyError.permissionDenied
        }

        if let conflict = checkConflict(binding) {
            throw HotkeyError.conflictDetected(conflict)
        }

        // 注销旧绑定（如果存在）
        if let existingBinding = bindings[binding.action] {
            unregisterCarbon(binding: existingBinding)
        }

        try registerCarbon(binding: binding)
        bindings[binding.action] = binding
        subjects.bindingsDidChange.send()
    }

    func unregister(_ action: HotkeyAction) {
        guard let binding = bindings[action] else { return }
        unregisterCarbon(binding: binding)
        bindings.removeValue(forKey: action)
        subjects.bindingsDidChange.send()
    }

    func updateBinding(_ action: HotkeyAction, newBinding: HotkeyBinding) throws {
        try register(newBinding)
    }

    func getBinding(for action: HotkeyAction) -> HotkeyBinding? {
        bindings[action]
    }

    func getAllBindings() -> [HotkeyAction: HotkeyBinding] {
        bindings
    }

    func checkConflict(_ binding: HotkeyBinding) -> HotkeyConflict? {
        // 检查与已有绑定的冲突
        for (action, existing) in bindings where action != binding.action {
            if existing.keyCode == binding.keyCode && existing.modifiers == binding.modifiers {
                return HotkeyConflict(
                    binding: binding,
                    conflictType: .selfConflict,
                    conflictDescription: "与「\(action.displayName)」快捷键冲突"
                )
            }
        }

        // 系统保留快捷键检查
        let reservedKeys: Set<UInt32> = [53] // Esc
        if reservedKeys.contains(binding.keyCode) && binding.modifiers == 0 {
            return HotkeyConflict(
                binding: binding,
                conflictType: .systemReserved,
                conflictDescription: "该快捷键为系统保留"
            )
        }

        return nil
    }

    // MARK: - Carbon Registration

    private func registerAllBindings() {
        for (_, binding) in bindings {
            do {
                try registerCarbon(binding: binding)
            } catch {
                print("[HotkeyManager] 注册 \(binding.action.displayName) 失败: \(error)")
            }
        }
    }

    private func unregisterAllBindings() {
        for (_, binding) in bindings {
            unregisterCarbon(binding: binding)
        }
    }

    private func registerCarbon(binding: HotkeyBinding) throws {
        // 为每个 action 分配唯一 ID
        let hID = hotKeyIDs[binding.action] ?? UInt32(binding.action.hashValue & 0xFFFF)
        hotKeyIDs[binding.action] = hID

        var hotkeyIDStruct = EventHotKeyID(signature: OSType(0x534B4854), id: hID) // "SKHT"
        var ref: EventHotKeyRef?

        let carbonMods = carbonModifiers(from: binding.modifiers)

        let status = RegisterEventHotKey(
            binding.keyCode,
            carbonMods,
            hotkeyIDStruct,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        guard status == noErr else {
            throw HotkeyError.registrationFailed("RegisterEventHotKey 返回 \(status)")
        }

        carbonRefs[binding.action] = ref

        // 安装全局事件处理器（如果尚未安装）
        installEventHandler()
    }

    private func unregisterCarbon(binding: HotkeyBinding) {
        guard let ref = carbonRefs[binding.action] else { return }
        UnregisterEventHotKey(ref)
        carbonRefs[binding.action] = nil
    }

    private func carbonModifiers(from swiftModifiers: UInt32) -> UInt32 {
        var carbonMods: UInt32 = 0
        if swiftModifiers & KeyCode.commandKey  != 0 { carbonMods |= UInt32(cmdKey) }
        if swiftModifiers & KeyCode.shiftKey    != 0 { carbonMods |= UInt32(shiftKey) }
        if swiftModifiers & KeyCode.optionKey   != 0 { carbonMods |= UInt32(optionKey) }
        if swiftModifiers & KeyCode.controlKey  != 0 { carbonMods |= UInt32(controlKey) }
        return carbonMods
    }

    // MARK: - Event Handler

    private func installEventHandler() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManagerImpl>.fromOpaque(userData).takeUnretainedValue()
            manager.handleHotKeyEvent(event)
            return noErr
        }

        var ref: EventHandlerRef?
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &ref
        )

        if status == noErr {
            eventHandlerRef = ref
        }
    }

    private func handleHotKeyEvent(_ event: EventRef?) {
        guard let event = event,
              let engine = recordingEngine else { return }

        var hID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hID
        )

        guard status == noErr else { return }

        // 找到对应的 action
        for (act, storedId) in hotKeyIDs {
            if storedId == hID.id {
                // 安全门控：非录制状态下只有 startOrResume 响应
                if !engine.isRecording && act != .startOrResume {
                    return
                }
                subjects.hotkeyPressed.send(act)
                break
            }
        }
    }

    // MARK: - Accessibility Permission

    private func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)
    }

    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)
    }
}
