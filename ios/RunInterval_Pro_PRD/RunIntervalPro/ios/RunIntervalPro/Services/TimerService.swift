import Foundation
import AVFoundation
import Combine

// MARK: - TimerState
enum TimerState: Equatable {
    case idle
    case running
    case paused
    case finished
}

// MARK: - CurrentPhaseInfo
struct CurrentPhaseInfo: Equatable {
    let phase: Phase
    let phaseIndex: Int
    let cycleIndex: Int
    let cycleRepeatIndex: Int
    let remainingSeconds: Int
    let totalElapsed: Int

    var formattedRemaining: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var progress: Double {
        guard phase.durationSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(phase.durationSeconds))
    }
}

// MARK: - TimerService
@MainActor
final class TimerService: ObservableObject {
    // MARK: - Published State
    @Published private(set) var state: TimerState = .idle
    @Published private(set) var currentPhaseInfo: CurrentPhaseInfo?
    @Published private(set) var totalElapsedSeconds: Int = 0
    @Published private(set) var nextPhasePreview: String = ""
    @Published private(set) var cycleProgress: String = ""
    @Published private(set) var workoutComplete: Bool = false
    @Published private(set) var shouldPromptForReview: Bool = false
    @Published private(set) currentHeartRate: Double = 0
    @Published private(set) activeEnergyBurned: Double = 0

    // MARK: - Private
    private var workout: Workout?
    private var flatPhases: [(phase: Phase, cycleIndex: Int, repeatIndex: Int)] = []
    private var currentFlatIndex: Int = 0
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var hapticGenerator: UIImpactFeedbackGenerator?
    private var healthKitService: HealthKitService?
    private var notificationService: NotificationService?
    private var workoutStartTime: Date?

    private let reviewPromptThreshold = 5  // ASO PRD §6.1: prompt after 5th workout

    // MARK: - Config
    private let announceCountdown = true
    private let announceHalfway = true

    // MARK: - Public

    func loadWorkout(_ workout: Workout, healthKitService: HealthKitService? = nil, notificationService: NotificationService? = nil) {
        self.workout = workout
        self.healthKitService = healthKitService
        self.notificationService = notificationService
        buildFlatPhases()
        currentFlatIndex = 0
        totalElapsedSeconds = 0
        workoutComplete = false
        state = .idle
        workoutStartTime = nil
        updatePhaseInfo()
    }

    func start() {
        guard !flatPhases.isEmpty else { return }
        prepareAudioSession()
        state = .running
        
        // 开始HealthKit会话
        if let healthKitService = healthKitService {
            Task {
                do {
                    if let workout = workout {
                        let activityType = HealthKitService.mapIntervalTypeToActivityType(workout: workout)
                        try await healthKitService.startWorkout(activityType: activityType)
                        workoutStartTime = Date()
                    }
                } catch {
                    print("HealthKit启动失败: \(error.localizedDescription)")
                }
            }
        }
        
        startTimer()
        playAnnouncement(for: flatPhases[currentFlatIndex].phase)
    }

    func pause() {
        state = .paused
        timer?.invalidate()
        timer = nil
        healthKitService?.pauseWorkout()
    }

    func resume() {
        state = .running
        startTimer()
        healthKitService?.resumeWorkout()
    }

    func toggle() {
        switch state {
        case .idle, .paused: start()
        case .running: pause()
        case .finished: reset()
        }
    }

    func skipPhase() {
        guard state == .running || state == .paused else { return }
        advanceToNextPhase()
    }

    func repeatPhase() {
        guard state == .running || state == .paused,
              currentFlatIndex > 0 else { return }
        currentFlatIndex -= 1
        let info = currentPhaseInfo
        if let info = info {
            totalElapsedSeconds -= (info.phase.durationSeconds - info.remainingSeconds)
        }
        updatePhaseInfo()
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        state = .idle
        currentFlatIndex = 0
        totalElapsedSeconds = 0
        workoutComplete = false
        updatePhaseInfo()
    }

    // MARK: - Private

    private func buildFlatPhases() {
        guard let workout = workout else { return }
        flatPhases = []
        for (cycleIdx, cycle) in workout.cycles.enumerated() {
            for repeatIdx in 0..<cycle.repeatCount {
                for phase in cycle.phases {
                    flatPhases.append((phase, cycleIdx, repeatIdx))
                }
            }
        }
    }

    private func updatePhaseInfo() {
        guard currentFlatIndex < flatPhases.count else {
            currentPhaseInfo = nil
            nextPhasePreview = ""
            cycleProgress = ""
            return
        }

        let current = flatPhases[currentFlatIndex]
        let elapsed = current.phase.durationSeconds - (currentPhaseInfo?.remainingSeconds ?? current.phase.durationSeconds)

        currentPhaseInfo = CurrentPhaseInfo(
            phase: current.phase,
            phaseIndex: currentFlatIndex,
            cycleIndex: current.cycleIndex,
            cycleRepeatIndex: current.repeatIndex,
            remainingSeconds: current.phase.durationSeconds - elapsed,
            totalElapsed: totalElapsedSeconds
        )

        // Next phase preview
        if currentFlatIndex + 1 < flatPhases.count {
            let next = flatPhases[currentFlatIndex + 1]
            nextPhasePreview = "Next: \(next.phase.name)"
        } else {
            nextPhasePreview = "Last phase"
        }

        // Cycle progress
        let cycleCount = workout?.cycles.count ?? 0
        if current.cycleIndex < cycleCount, let cycle = workout?.cycles[current.cycleIndex] {
            cycleProgress = "Round \(current.repeatIndex + 1)/\(cycle.repeatCount) • Cycle \(current.cycleIndex + 1)/\(cycleCount)"
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard state == .running,
              var info = currentPhaseInfo else { return }

        let newRemaining = info.remainingSeconds - 1
        totalElapsedSeconds += 1

        // Countdown announcements
        if newRemaining == 10 || newRemaining == 3 {
            playCountdown(newRemaining)
        }

        if newRemaining <= 0 {
            advanceToNextPhase()
        } else {
            currentPhaseInfo = CurrentPhaseInfo(
                phase: info.phase,
                phaseIndex: info.phaseIndex,
                cycleIndex: info.cycleIndex,
                cycleRepeatIndex: info.cycleRepeatIndex,
                remainingSeconds: newRemaining,
                totalElapsed: totalElapsedSeconds
            )
        }
    }

    private func advanceToNextPhase() {
        currentFlatIndex += 1

        if currentFlatIndex >= flatPhases.count {
            finishWorkout()
            return
        }

        let next = flatPhases[currentFlatIndex]
        playAnnouncement(for: next.phase)
        triggerHaptic(for: next.phase.type)
        updatePhaseInfo()
    }

    private func finishWorkout() {
        timer?.invalidate()
        timer = nil
        state = .finished
        workoutComplete = true
        currentPhaseInfo = nil
        triggerHaptic(style: .heavy)

        // 结束HealthKit会话
        if let healthKitService = healthKitService {
            Task {
                do {
                    try await healthKitService.endWorkout()
                } catch {
                    print("HealthKit结束失败: \(error.localizedDescription)")
                }
            }
        }

        // Persist completed workout
        if let w = workout {
            let summary = WorkoutSummary(
                id: UUID(),
                workoutName: w.name,
                completedAt: Date(),
                totalDurationSeconds: totalElapsedSeconds,
                phasesCompleted: flatPhases.count,
                heartRateData: healthKitService?.currentHeartRate,
                caloriesBurned: healthKitService?.activeEnergyBurned
            )
            StorageService.shared.addSummary(summary)

            // ASO §6.1: prompt for review after 5th completed workout
            checkReviewPrompt()
        }
    }

    private func checkReviewPrompt() {
        let completedCount = StorageService.shared.loadSummaries().count
        // Prompt when user has completed exactly 5, 10, 15... workouts (once per version)
        if completedCount >= reviewPromptThreshold && completedCount % reviewPromptThreshold == 0 {
            shouldPromptForReview = true
        }
    }

    private func playAnnouncement(for phase: Phase) {
        // Simple system sound as placeholder — real implementation uses AVSpeechSynthesizer
        AudioServicesPlaySystemSound(1052)
    }

    private func playCountdown(_ seconds: Int) {
        AudioServicesPlaySystemSound(1057)
    }

    private func prepareAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    private func triggerHaptic(for type: PhaseType) {
        let generator = UIImpactFeedbackGenerator(style: type == .work ? .heavy : .medium)
        generator.impactOccurred()
    }

    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// Placeholder — imported from UIKit in a real file
import UIKit
