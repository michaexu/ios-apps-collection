import SwiftUI
import WatchKit

struct WatchTimerView: View {
    let workout: Workout
    @State private var timerText = "0:00"
    @State private var phaseName = ""
    @State private var phaseColor: Color = .orange
    @State private var isRunning = false
    @State private var remainingSeconds = 0
    @State private var progress: Double = 0.0

    private let timerFont = Font.system(size: 48, weight: .bold, design: .monospaced)

    var body: some View {
        VStack(spacing: 4) {
            Text(phaseName)
                .font(.headline)
                .foregroundStyle(phaseColor)

            Text(timerText)
                .font(timerFont)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)

            ProgressView(value: progress)
                .tint(phaseColor)
                .padding(.horizontal, 20)

            HStack(spacing: 20) {
                Button {
                    WKInterfaceDevice.current().play(.retry)
                } label: {
                    Image(systemName: "backward.fill")
                }
                .buttonStyle(.plain)

                Button {
                    isRunning.toggle()
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)

                Button {
                    WKInterfaceDevice.current().play(.retry)
                } label: {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .onAppear {
            loadWorkout()
        }
    }

    private func loadWorkout() {
        let phases = workout.cycles.flatMap { cycle in
            (0..<cycle.repeatCount).flatMap { _ in cycle.phases }
        }
        if let first = phases.first {
            remainingSeconds = first.durationSeconds
            phaseName = first.name
            progress = 0.0
            updateTimerText()
        }
    }

    private func updateTimerText() {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        timerText = String(format: "%d:%02d", m, s)
    }
}

#Preview {
    WatchTimerView(workout: Workout(
        name: "Test",
        cycles: [Cycle(phases: [
            Phase(name: "Work", type: .work, durationSeconds: 30, order: 0),
            Phase(name: "Rest", type: .rest, durationSeconds: 10, order: 1)
        ], repeatCount: 3)]
    ))
}
