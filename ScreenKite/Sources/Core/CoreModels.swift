import Foundation
import AppKit
import Combine

// MARK: - RecordingEngine Protocol

/// 录制引擎核心协议
protocol RecordingEngineProtocol: AnyObject {
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    var recordingDuration: TimeInterval { get }
    var currentConfig: RecordingConfig? { get }
    var recordingStatePublisher: AnyPublisher<RecordingState, Never> { get }
    var markersPublisher: AnyPublisher<[RecordingMarker], Never> { get }

    func start(with config: RecordingConfig) throws
    func pause()
    func resume()
    func stop() async -> URL?
    func addMarker(label: String?)
    func shutdown()
}

// MARK: - RecordingConfig

/// 录制配置（支持 Codable 序列化）
struct RecordingConfig: Codable, Equatable {
    var captureType: CaptureType
    /// 目标窗口 ID（用于标识，不存储窗口引用）
    var targetWindowID: Int?
    var captureRect: CaptureRect?
    var includeSystemAudio: Bool
    var includeMicrophone: Bool
    var frameRate: Int
    var outputFormat: OutputFormat
    var outputDirectory: URL

    init(
        captureType: CaptureType = .fullScreen,
        targetWindowID: Int? = nil,
        captureRect: CaptureRect? = nil,
        includeSystemAudio: Bool = false,
        includeMicrophone: Bool = true,
        frameRate: Int = 30,
        outputFormat: OutputFormat = .mp4,
        outputDirectory: URL = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first!
    ) {
        self.captureType = captureType
        self.targetWindowID = targetWindowID
        self.captureRect = captureRect
        self.includeSystemAudio = includeSystemAudio
        self.includeMicrophone = includeMicrophone
        self.frameRate = frameRate
        self.outputFormat = outputFormat
        self.outputDirectory = outputDirectory
    }
}

// MARK: - CaptureType

enum CaptureType: String, Codable, Equatable {
    case fullScreen = "fullScreen"
    case specifiedWindow = "specifiedWindow"
    case specifiedRegion = "specifiedRegion"
}

// MARK: - OutputFormat

enum OutputFormat: Codable, Equatable {
    case mp4
    case mov
    case gif
}

// MARK: - CaptureRect

/// 录制区域（支持 Codable）
struct CaptureRect: Codable, Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }

    init(cgRect: CGRect) {
        self.x = cgRect.origin.x
        self.y = cgRect.origin.y
        self.width = cgRect.size.width
        self.height = cgRect.size.height
    }
}

// MARK: - RecordingState

enum RecordingState {
    case idle
    case preparing
    case recording
    case paused
    case stopping
    case error(RecordingError)
}

// MARK: - RecordingMarker

struct RecordingMarker: Codable, Identifiable {
    let id: UUID
    let timestamp: TimeInterval
    let label: String?
    let createdAt: Date

    init(id: UUID = UUID(), timestamp: TimeInterval, label: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.timestamp = timestamp
        self.label = label
        self.createdAt = createdAt
    }
}

// MARK: - RecordingError

enum RecordingError: Error, LocalizedError {
    case permissionDenied
    case hardwareNotSupported
    case resourceBusy
    case configurationInvalid(String)
    case unknown(underlying: Error?)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "屏幕录制权限被拒绝，请在系统设置中授权"
        case .hardwareNotSupported:
            return "当前硬件不支持屏幕录制"
        case .resourceBusy:
            return "系统资源忙，请稍后重试"
        case .configurationInvalid(let reason):
            return "录制配置无效: \(reason)"
        case .unknown(let underlying):
            return "未知错误: \(underlying?.localizedDescription ?? "无")"
        }
    }
}

// MARK: - SchedulerStorageProtocol

/// 调度任务持久化存储协议
protocol SchedulerStorageProtocol {
    func loadAll() -> AnyPublisher<[ScheduledTask], Error>
    func save(_ task: ScheduledTask) -> AnyPublisher<Void, Error>
    func delete(_ taskId: UUID) -> AnyPublisher<Void, Error>
    func saveAll(_ tasks: [ScheduledTask]) -> AnyPublisher<Void, Error>
}
