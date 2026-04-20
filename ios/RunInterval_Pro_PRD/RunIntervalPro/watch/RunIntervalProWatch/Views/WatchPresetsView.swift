import SwiftUI
import WatchKit

struct WatchPresetsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("RunInterval")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                ForEach(freePresets) { preset in
                    WatchPresetRow(preset: preset)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var freePresets: [WatchPresetItem] {
        [
            WatchPresetItem(
                displayName: "Classic HIIT",
                description: "30s/10s × 8",
                workout: Workout(
                    name: "Classic HIIT",
                    cycles: [Cycle(phases: [
                        Phase(name: "Work", type: .work, durationSeconds: 30, order: 0),
                        Phase(name: "Rest", type: .rest, durationSeconds: 10, order: 1)
                    ], repeatCount: 8)]
                )
            ),
            WatchPresetItem(
                displayName: "Tempo Run",
                description: "10m warm / 20m tempo",
                workout: Workout(
                    name: "Tempo Run",
                    cycles: [Cycle(phases: [
                        Phase(name: "Warm Up", type: .warmup, durationSeconds: 600, order: 0),
                        Phase(name: "Tempo", type: .work, durationSeconds: 1200, order: 1),
                        Phase(name: "Cool Down", type: .cooldown, durationSeconds: 600, order: 2)
                    ])]
                )
            ),
            WatchPresetItem(
                displayName: "Tabata 20/10",
                description: "20s/10s × 10",
                workout: Workout(
                    name: "Tabata 20/10",
                    cycles: [Cycle(phases: [
                        Phase(name: "Work", type: .work, durationSeconds: 20, order: 0),
                        Phase(name: "Rest", type: .rest, durationSeconds: 10, order: 1)
                    ], repeatCount: 10)]
                )
            )
        ]
    }
}

struct WatchPresetItem: Identifiable {
    let id = UUID()
    let displayName: String
    let description: String
    let workout: Workout
}

struct WatchPresetRow: View {
    let preset: WatchPresetItem

    var body: some View {
        Button {
            WKInterfaceDevice.current().play(.start)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.displayName)
                        .font(.headline)
                        .lineLimit(1)

                    Text(preset.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(formatDuration(preset.workout.totalSeconds))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "play.fill")
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    WatchPresetsView()
}
