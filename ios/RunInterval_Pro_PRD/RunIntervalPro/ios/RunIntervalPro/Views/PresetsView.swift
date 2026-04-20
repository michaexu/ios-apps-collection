import SwiftUI

struct PresetsView: View {
    @StateObject private var libraryVM = WorkoutLibraryViewModel()
    @State private var selectedWorkout: Workout?
    @State private var showingActiveWorkout = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero: Quick Start
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RunInterval Pro")
                            .font(.largeTitle.bold())

                        Text("Your structured interval training companion")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Free presets
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Quick Start", icon: "bolt.fill", badge: "FREE")

                        ForEach(PresetWorkout.freePresets) { preset in
                            PresetCard(preset: preset) {
                                selectedWorkout = preset.workout
                                showingActiveWorkout = true
                            }
                        }
                    }

                    Divider()
                        .padding(.horizontal)

                    // Pro presets
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Pro Presets", icon: "star.fill", badge: "PRO")

                        ForEach(PresetWorkout.all.filter { $0.isPro }) { preset in
                            PresetCard(preset: preset) {
                                selectedWorkout = preset.workout
                                showingActiveWorkout = true
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 80)
                }
                .padding(.top)
            }
            .navigationDestination(isPresented: $showingActiveWorkout) {
                if let workout = selectedWorkout {
                    ActiveWorkoutView(workout: workout)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String, badge: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "FF6B35"))
            Text(title)
                .font(.headline)
            Spacer()
            Text(badge)
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(hex: "FF6B35").opacity(0.15))
                .foregroundStyle(Color(hex: "FF6B35"))
                .clipShape(Capsule())
        }
    }
}

// MARK: - PresetCard
struct PresetCard: View {
    let preset: PresetWorkout
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            HStack(spacing: 16) {
                // Phase preview dots
                VStack(spacing: 4) {
                    ForEach(phasePreviewDots.prefix(4), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label(formatDuration(preset.workout.totalSeconds), systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Label("\(preset.workout.phaseCount) phases", systemImage: "list.bullet")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "FF6B35"))
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var phasePreviewDots: [Color] {
        var colors: [Color] = []
        for cycle in preset.workout.cycles {
            for phase in cycle.phases {
                colors.append(phase.type.color)
            }
        }
        return colors
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    PresetsView()
}
