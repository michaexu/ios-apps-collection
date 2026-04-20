import SwiftUI

struct WatchLibraryView: View {
    @State private var workouts: [Workout] = []

    var body: some View {
        Group {
            if workouts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No saved workouts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Open the iPhone app\nto manage workouts")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                List(workouts) { workout in
                    WatchLibraryRow(workout: workout)
                }
            }
        }
        .onAppear { loadWorkouts() }
    }

    private func loadWorkouts() {
        // Watch-only: show presets as quick-start options
        // Full library is managed on iPhone
        workouts = []
    }
}

struct WatchLibraryRow: View {
    let workout: Workout

    var body: some View {
        NavigationLink {
            WatchTimerView(workout: workout)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(workout.totalDurationFormatted) • \(workout.phaseCount) phases")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    WatchLibraryView()
}
