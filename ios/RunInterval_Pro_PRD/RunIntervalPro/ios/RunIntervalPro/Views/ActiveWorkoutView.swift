import SwiftUI

struct ActiveWorkoutView: View {
    let workout: Workout

    @StateObject private var timerService = TimerService()
    @Environment(\.dismiss) private var dismiss
    @State private var showStopConfirmation = false
    @State private var showReviewPrompt = false
    @State private var showSummary = false

    // Large timer font — at least 120pt per PRD
    private let timerFont = Font.system(size: 120, weight: .bold, design: .monospaced)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color based on current phase
                backgroundColor
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: currentPhaseType)

                VStack(spacing: 0) {
                    // Top bar
                    topBar

                    Spacer()

                    // Main timer display
                    timerDisplay(width: geometry.size.width)

                    Spacer()

                    // Phase info
                    phaseInfoSection

                    // Controls
                    controlsSection

                    // Next phase preview
                    if !timerService.nextPhasePreview.isEmpty {
                        nextPhasePreview
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 {
                        timerService.skipPhase()
                    } else if value.translation.width > 50 {
                        timerService.repeatPhase()
                    }
                }
        )
        .onTapGesture {
            timerService.toggle()
        }
        .onAppear {
            timerService.loadWorkout(workout)
            timerService.start()
        }
        .onChange(of: timerService.workoutComplete) { complete in
            if complete {
                showSummary = true
                if ReviewPromptManager.shouldPrompt {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showReviewPrompt = true
                    }
                }
            }
        }
        .overlay {
            if showSummary {
                workoutCompleteOverlay
            }
        }
        .overlay {
            if showReviewPrompt {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { showReviewPrompt = false }

                    ReviewPromptView(isPresented: $showReviewPrompt, workoutName: workout.name)
                        .transition(.scale.combined(with: .opacity))
                }
                .animation(.spring(response: 0.3), value: showReviewPrompt)
            }
        }
        .confirmationDialog("Stop Workout?", isPresented: $showStopConfirmation) {
            Button("Stop & Discard", role: .destructive) {
                timerService.reset()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Components

    private var topBar: some View {
        HStack {
            Button {
                showStopConfirmation = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(timerService.cycleProgress)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Elapsed time
            Text(formatElapsed(timerService.totalElapsedSeconds))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, 8)
    }

    private func timerDisplay(width: CGFloat) -> some View {
        VStack(spacing: 8) {
            // Phase type badge
            if let info = timerService.currentPhaseInfo {
                Text(info.phase.name.uppercased())
                    .font(.title3.bold())
                    .foregroundStyle(.white.opacity(0.8))
                    .tracking(4)
            }

            // Main countdown
            Text(timerService.currentPhaseInfo?.formattedRemaining ?? "0:00")
                .font(timerFont)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

            // Progress ring
            if let info = timerService.currentPhaseInfo {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 12)
                        .frame(width: 200, height: 200)

                    Circle()
                        .trim(from: 0, to: info.progress)
                        .stroke(.white, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: info.progress)
                }
            }
        }
    }

    private var phaseInfoSection: some View {
        HStack(spacing: 24) {
            VStack {
                Text("Phase")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(currentPhaseIndex + 1)/\(totalPhases)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }

            Divider()
                .frame(height: 30)
                .background(.white.opacity(0.3))

            VStack {
                Text("Elapsed")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text(formatElapsed(timerService.totalElapsedSeconds))
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(.white)
            }

            Divider()
                .frame(height: 30)
                .background(.white.opacity(0.3))

            VStack {
                Text("Total")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text(workout.totalDurationFormatted)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var controlsSection: some View {
        HStack(spacing: 32) {
            // Repeat phase
            Button {
                timerService.repeatPhase()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            }

            // Play/Pause — largest tap target
            Button {
                timerService.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 80, height: 80)

                    Image(systemName: playPauseIcon)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(backgroundColor)
                }
            }

            // Skip phase
            Button {
                timerService.skipPhase()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 20)
    }

    private var nextPhasePreview: some View {
        Text(timerService.nextPhasePreview)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.6))
            .padding(.top, 8)
    }

    // MARK: - Workout Complete Overlay
    private var workoutCompleteOverlay: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    Text("Workout Complete!")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text(workout.name)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                }

                // Stats
                HStack(spacing: 32) {
                    VStack {
                        Text(formatElapsed(timerService.totalElapsedSeconds))
                            .font(.title.bold().monospacedDigit())
                            .foregroundStyle(.white)
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    VStack {
                        Text("\(workout.phaseCount)")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        Text("Phases")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    VStack {
                        Text(workout.totalDurationFormatted)
                            .font(.title.bold().monospacedDigit())
                            .foregroundStyle(.white)
                        Text("Planned")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .foregroundStyle(backgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
            }
            .padding()
        }
    }

    // MARK: - Computed

    private var currentPhaseType: PhaseType {
        timerService.currentPhaseInfo?.phase.type ?? .work
    }

    private var backgroundColor: Color {
        currentPhaseType.color
    }

    private var playPauseIcon: String {
        switch timerService.state {
        case .running: return "pause.fill"
        case .paused, .idle: return "play.fill"
        case .finished: return "checkmark"
        }
    }

    private var currentPhaseIndex: Int {
        timerService.currentPhaseInfo?.phaseIndex ?? 0
    }

    private var totalPhases: Int {
        workout.phaseCount
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    ActiveWorkoutView(workout: PresetWorkout.classicHIIT.workout)
}
