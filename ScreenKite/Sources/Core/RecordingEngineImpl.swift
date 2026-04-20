import Foundation
import AVFoundation
import Combine
import AppKit
import ScreenCaptureKit

/// ScreenKite 录制引擎实现
/// 使用 ScreenCaptureKit (macOS 12.3+) 进行屏幕捕获
@available(macOS 12.3, *)
final class RecordingEngineImpl: RecordingEngineProtocol {

    // MARK: - Published State
    private(set) var isRecording: Bool = false
    private(set) var isPaused: Bool = false
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var currentConfig: RecordingConfig?

    // MARK: - Publishers (内部 Subject, 外部 AnyPublisher)
    private let _stateSubject = PassthroughSubject<RecordingState, Never>()
    private let _markersSubject = PassthroughSubject<[RecordingMarker], Never>()

    var recordingStatePublisher: AnyPublisher<RecordingState, Never> {
        _stateSubject.eraseToAnyPublisher()
    }
    var markersPublisher: AnyPublisher<[RecordingMarker], Never> {
        _markersSubject.eraseToAnyPublisher()
    }

    // MARK: - Private State
    private var stream: SCStream?
    private var streamOutput: StreamOutput?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var pauseDuration: TimeInterval = 0
    private var lastPauseTime: Date?
    private var durationTimer: Timer?
    private var markers: [RecordingMarker] = []
    private var outputFileURL: URL?

    private let captureQueue = DispatchQueue(label: "com.screenkite.capture", qos: .userInitiated)

    // MARK: - Public Methods

    func start(with config: RecordingConfig) throws {
        guard !isRecording else { return }

        currentConfig = config
        isRecording = true
        isPaused = false
        recordingDuration = 0
        markers = []
        pauseDuration = 0
        outputFileURL = nil

        _stateSubject.send(.preparing)

        let fileName = "ScreenKite_\(Date().timeIntervalSince1970).mp4"
        let outputURL = config.outputDirectory.appendingPathComponent(fileName)
        outputFileURL = outputURL

        do {
            try setupAssetWriter(at: outputURL, config: config)
            try startCaptureSync(with: config)
            startDurationTimer()
            _stateSubject.send(.recording)
        } catch {
            _stateSubject.send(.error(.unknown(underlying: error)))
            throw error
        }
    }

    func pause() {
        guard isRecording, !isPaused else { return }
        isPaused = true
        lastPauseTime = Date()
        durationTimer?.invalidate()
        _stateSubject.send(.paused)
    }

    func resume() {
        guard isRecording, isPaused else { return }
        if let pauseTime = lastPauseTime {
            pauseDuration += Date().timeIntervalSince(pauseTime)
        }
        isPaused = false
        lastPauseTime = nil
        startDurationTimer()
        _stateSubject.send(.recording)
    }

    func stop() -> URL? {
        guard isRecording else { return nil }

        _stateSubject.send(.stopping)
        durationTimer?.invalidate()

        isRecording = false
        isPaused = false

        stream?.stopCapture()

        videoInput?.markAsFinished()
        audioInput?.markAsFinished()

        assetWriter?.finishWriting {}

        _stateSubject.send(.idle)
        return outputFileURL
    }

    func addMarker(label: String?) {
        guard isRecording else { return }
        let marker = RecordingMarker(
            timestamp: recordingDuration,
            label: label ?? "标记 \(markers.count + 1)"
        )
        markers.append(marker)
        _markersSubject.send(markers)
    }

    func shutdown() {
        durationTimer?.invalidate()
        stream?.stopCapture()
        assetWriter?.cancelWriting()
        isRecording = false
        isPaused = false
    }

    // MARK: - Private Methods

    private func setupAssetWriter(at url: URL, config: RecordingConfig) throws {
        assetWriter = try AVAssetWriter(outputURL: url, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 8_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true

        if let videoInput = videoInput, assetWriter?.canAdd(videoInput) == true {
            assetWriter?.add(videoInput)
        }

        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 128_000
        ]
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput?.expectsMediaDataInRealTime = true

        if let audioInput = audioInput, assetWriter?.canAdd(audioInput) == true {
            assetWriter?.add(audioInput)
        }
    }

    private func startCaptureSync(with config: RecordingConfig) throws {
        // 使用 async 包装
        let sem = DispatchSemaphore(value: 0)
        var captureError: Error?
        var content: SCShareableContent?

        Task {
            do {
                content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            } catch {
                captureError = error
            }
            sem.signal()
        }
        sem.wait()

        if let err = captureError { throw err }

        guard let display = content?.displays.first else {
            throw RecordingError.hardwareNotSupported
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])

        let streamConfig = SCStreamConfiguration()
        streamConfig.width = 1920
        streamConfig.height = 1080
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(config.frameRate))
        streamConfig.pixelFormat = kCVPixelFormatType_32BGRA
        streamConfig.showsCursor = true

        // macOS 13+ 音频捕获
        if #available(macOS 13.0, *) {
            if config.includeSystemAudio {
                streamConfig.capturesAudio = true
            }
        }

        stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
        streamOutput = StreamOutput(assetWriter: assetWriter, videoInput: videoInput, audioInput: audioInput)

        try stream?.addStreamOutput(streamOutput!, type: .screen, sampleHandlerQueue: captureQueue)

        if #available(macOS 13.0, *) {
            if config.includeSystemAudio || config.includeMicrophone {
                try stream?.addStreamOutput(streamOutput!, type: .audio, sampleHandlerQueue: captureQueue)
            }
        }

        // 同步启动 capture
        let startSem = DispatchSemaphore(value: 0)
        var startErr: Error?
        Task {
            do {
                try await stream?.startCapture()
            } catch {
                startErr = error
            }
            startSem.signal()
        }
        startSem.wait()

        if let err = startErr { throw err }
    }

    private func startDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            self.recordingDuration += 1
        }
    }
}

// MARK: - Stream Output Handler

@available(macOS 12.3, *)
private class StreamOutput: NSObject, SCStreamOutput {

    weak var assetWriter: AVAssetWriter?
    weak var videoInput: AVAssetWriterInput?
    weak var audioInput: AVAssetWriterInput?
    private var sessionStarted = false

    init(assetWriter: AVAssetWriter?, videoInput: AVAssetWriterInput?, audioInput: AVAssetWriterInput?) {
        self.assetWriter = assetWriter
        self.videoInput = videoInput
        self.audioInput = audioInput
        super.init()
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard assetWriter?.status == .unknown || assetWriter?.status == .writing else { return }

        if type == .screen {
            guard let videoInput = videoInput, videoInput.isReadyForMoreMediaData else { return }

            if !sessionStarted {
                assetWriter?.startWriting()
                assetWriter?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                sessionStarted = true
            }

            videoInput.append(sampleBuffer)

        } else {
            if #available(macOS 13.0, *) {
                if type == .audio {
                    guard let audioInput = audioInput, audioInput.isReadyForMoreMediaData, sessionStarted else { return }
                    audioInput.append(sampleBuffer)
                }
            }
        }
    }
}

// MARK: - ScreenCaptureKit Helper

enum ScreenCaptureKitHelper {
    @available(macOS 12.3, *)
    static func hasScreenRecordingPermission() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    static func requestPermission() {
        if #available(macOS 14.0, *) {
            CGRequestScreenCaptureAccess()
        } else {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
