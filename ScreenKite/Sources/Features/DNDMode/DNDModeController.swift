import Foundation
import Combine
import AppKit

// MARK: - DNDModeController Protocol

protocol DNDModeControllerProtocol: AnyObject {
    var isDNDModeActive: Bool { get }
    var dndStatusChangedPublisher: AnyPublisher<Bool, Never> { get }
    var associatedRecordingId: UUID? { get }

    func enableDNDMode() throws
    func disableDNDMode()
    func getCurrentFocusState() -> FocusState
    func getDNDModeHistory() -> [DNDModeRecord]
}

// MARK: - Supporting Types

struct FocusState: Codable, Equatable {
    let isDNDEnabled: Bool
    let focusModeName: String?
    let enabledAt: Date
    let source: FocusStateSource

    static let disabled = FocusState(
        isDNDEnabled: false,
        focusModeName: nil,
        enabledAt: Date(),
        source: .system
    )
}

enum FocusStateSource: String, Codable {
    case system
    case userManual
    case appDND
}

struct DNDModeRecord: Codable, Identifiable {
    let id: UUID
    let enabledAt: Date
    var disabledAt: Date?
    let recordingId: UUID?
    var wasManuallyDisabled: Bool

    var duration: TimeInterval? {
        guard let disabled = disabledAt else { return nil }
        return disabled.timeIntervalSince(enabledAt)
    }
}

enum DNDError: Error, LocalizedError {
    case alreadyActive
    case recordingNotStarted
    case focusAPIUnavailable
    case permissionDenied
    case stateRestoreFailed

    var errorDescription: String? {
        switch self {
        case .alreadyActive: return "勿扰模式已在运行中"
        case .recordingNotStarted: return "请先开始录制后再启用勿扰模式"
        case .focusAPIUnavailable: return "当前 macOS 版本不支持勿扰模式控制"
        case .permissionDenied: return "系统权限不足，无法控制勿扰模式"
        case .stateRestoreFailed: return "录制结束，无法恢复原有的勿扰状态"
        }
    }
}

// MARK: - DNDModeControllerImpl

final class DNDModeControllerImpl: DNDModeControllerProtocol {

    // MARK: - Publishers
    private let _statusSubject = PassthroughSubject<Bool, Never>()
    var dndStatusChangedPublisher: AnyPublisher<Bool, Never> {
        _statusSubject.eraseToAnyPublisher()
    }

    private(set) var isDNDModeActive: Bool = false
    private(set) var associatedRecordingId: UUID?

    private let notificationService: NotificationServiceProtocol
    private var savedFocusState: FocusState?
    private var dndModeHistory: [DNDModeRecord] = []
    private var currentRecord: DNDModeRecord?
    private let historyKey = "com.screenkite.dnd_history.v1"

    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
        loadHistory()
    }

    func enableDNDMode() throws {
        guard !isDNDModeActive else {
            throw DNDError.alreadyActive
        }

        savedFocusState = getCurrentFocusState()

        guard setSystemDND(enabled: true) else {
            throw DNDError.focusAPIUnavailable
        }

        currentRecord = DNDModeRecord(
            id: UUID(),
            enabledAt: Date(),
            disabledAt: nil,
            recordingId: associatedRecordingId,
            wasManuallyDisabled: false
        )

        isDNDModeActive = true
        _statusSubject.send(true)

        notificationService.scheduleRecordingReminder(
            taskName: "勿扰录制",
            secondsBefore: 0,
            taskId: UUID()
        )
    }

    func disableDNDMode() {
        guard isDNDModeActive else { return }

        if let saved = savedFocusState, !saved.isDNDEnabled {
            _ = setSystemDND(enabled: false)
        }

        currentRecord?.disabledAt = Date()
        if let record = currentRecord {
            dndModeHistory.append(record)
            saveHistory()
        }

        isDNDModeActive = false
        savedFocusState = nil
        currentRecord = nil
        associatedRecordingId = nil

        _statusSubject.send(false)
    }

    func getCurrentFocusState() -> FocusState {
        let focusDefaults = UserDefaults(suiteName: "com.apple.controlcenter")
        let dndValue = focusDefaults?.integer(forKey: "NSStatusItem Visible DoNotDisturb")
        let isDNDEnabled = (dndValue ?? 0) == 1

        return FocusState(
            isDNDEnabled: isDNDEnabled,
            focusModeName: nil,
            enabledAt: Date(),
            source: isDNDEnabled ? .userManual : .system
        )
    }

    func getDNDModeHistory() -> [DNDModeRecord] {
        dndModeHistory
    }

    private func setSystemDND(enabled: Bool) -> Bool {
        guard let focusDefaults = UserDefaults(suiteName: "com.apple.controlcenter") else {
            return false
        }
        focusDefaults.set(enabled ? 1 : 0, forKey: "NSStatusItem Visible DoNotDisturb")
        focusDefaults.synchronize()

        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("com.apple.notificationcenterui.dndprefs_changed"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        return true
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return }
        dndModeHistory = (try? JSONDecoder().decode([DNDModeRecord].self, from: data)) ?? []
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(dndModeHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
}
