import Foundation
import Combine

// MARK: - MockRecordingEngine (For Unit Testing)

final class MockRecordingEngine: RecordingEngineProtocol {

    var isRecording: Bool = false
    var isPaused: Bool = false
    var recordingDuration: TimeInterval = 0
    var currentConfig: RecordingConfig?

    let recordingStatePublisher = PassthroughSubject<RecordingState, Never>()
    let markersPublisher = PassthroughSubject<[RecordingMarker], Never>()

    private var markers: [RecordingMarker] = []
    private var durationTimer: Timer?
    private var startTime: Date?

    func start(with config: RecordingConfig) throws {
        currentConfig = config
        isRecording = true
        isPaused = false
        startTime = Date()
        recordingDuration = 0
        markers = []
        recordingStatePublisher.send(.recording)
        startDurationTimer()
    }

    func pause() {
        guard isRecording, !isPaused else { return }
        isPaused = true
        durationTimer?.invalidate()
        recordingStatePublisher.send(.paused)
    }

    func resume() {
        guard isRecording, isPaused else { return }
        isPaused = false
        recordingStatePublisher.send(.recording)
        startDurationTimer()
    }

    func stop() async -> URL? {
        isRecording = false
        isPaused = false
        durationTimer?.invalidate()
        recordingStatePublisher.send(.stopping)
        return FileManager.default.temporaryDirectory.appendingPathComponent("test_recording.mp4")
    }

    func addMarker(label: String?) {
        let marker = RecordingMarker(
            timestamp: recordingDuration,
            label: label ?? "Marker \(markers.count + 1)"
        )
        markers.append(marker)
        markersPublisher.send(markers)
    }

    func shutdown() {
        isRecording = false
        isPaused = false
        durationTimer?.invalidate()
    }

    private func startDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            self.recordingDuration += 1
        }
    }

    // MARK: - Test Helpers

    func simulateRecording() throws {
        let config = RecordingConfig()
        try start(with: config)
    }

    func simulateRecordingError() {
        recordingStatePublisher.send(.error(.permissionDenied))
    }
}
