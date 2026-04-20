import SwiftUI

struct WorkoutEditorView: View {
    @StateObject private var viewModel: WorkoutEditorViewModel
    @Environment(\.dismiss) private var dismiss
    let onSave: (Workout) -> Void

    init(workout: Workout?, onSave: @escaping (Workout) -> Void) {
        _viewModel = StateObject(wrappedValue: WorkoutEditorViewModel(workout: workout))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Workout Info") {
                    TextField("Workout Name", text: $viewModel.workoutName)

                    TextField("Description (optional)", text: $viewModel.workoutDescription, axis: .vertical)
                        .lineLimit(2...4)

                    Picker("Folder", selection: $viewModel.selectedFolder) {
                        ForEach(viewModel.folders, id: \.self) { folder in
                            Text(folder).tag(folder)
                        }
                    }
                }

                // Repeat count
                Section("Repetitions") {
                    Stepper("Repeat \(viewModel.repeatCount) time\(viewModel.repeatCount == 1 ? "" : "s")",
                            value: $viewModel.repeatCount, in: 1...99)
                }

                // Phases
                Section {
                    ForEach(Array(viewModel.phases.enumerated()), id: \.element.id) { index, phase in
                        PhaseEditorRow(phase: binding(for: phase), onDelete: {
                            viewModel.removePhase(at: index)
                        })
                    }
                    .onMove { from, to in
                        viewModel.movePhase(from: from, to: to)
                    }

                    // Add phase buttons
                    HStack {
                        ForEach([PhaseType.work, .rest, .warmup, .cooldown], id: \.self) { type in
                            Button {
                                var phase = Phase(name: type.displayName, type: type, durationSeconds: 60, order: viewModel.phases.count)
                                viewModel.phases.append(phase)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: type.systemImage)
                                    Text(type.displayName)
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(type.color.opacity(0.15))
                                .foregroundStyle(type.color)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    HStack {
                        Text("Phases")
                        Spacer()
                        Text(viewModel.totalDurationFormatted)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                // Preview
                if !viewModel.phases.isEmpty {
                    Section("Preview") {
                        PhaseTimelinePreview(phases: viewModel.phases, repeatCount: viewModel.repeatCount)
                    }
                }
            }
            .navigationTitle(viewModel.isNew ? "New Workout" : "Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let saved = viewModel.save()
                        onSave(saved)
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func binding(for phase: Phase) -> Binding<Phase> {
        guard let idx = viewModel.phases.firstIndex(where: { $0.id == phase.id }) else {
            return .constant(phase)
        }
        return $viewModel.phases[idx]
    }
}

// MARK: - PhaseEditorRow
struct PhaseEditorRow: View {
    @Binding var phase: Phase
    let onDelete: () -> Void

    @State private var showingTypePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(phase.type.color)
                    .frame(width: 12, height: 12)

                TextField("Phase Name", text: $phase.name)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Menu {
                    ForEach(PhaseType.allCases) { type in
                        Button {
                            phase.type = type
                            if phase.name == phase.type.displayName || phase.name.isEmpty {
                                phase.name = type.displayName
                            }
                        } label: {
                            Label(type.displayName, systemImage: type.systemImage)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: phase.type.systemImage)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            HStack {
                // Duration picker
                DurationPicker(durationSeconds: $phase.durationSeconds)
                    .labelsHidden()

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - DurationPicker
struct DurationPicker: View {
    @Binding var durationSeconds: Int

    var body: some View {
        HStack(spacing: 4) {
            Picker("Minutes", selection: Binding(
                get: { durationSeconds / 60 },
                set: { durationSeconds = $0 * 60 + (durationSeconds % 60) }
            )) {
                ForEach(0..<120) { min in
                    Text("\(min)m").tag(min)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 70, height: 100)
            .clipped()

            Picker("Seconds", selection: Binding(
                get: { durationSeconds % 60 },
                set: { durationSeconds = (durationSeconds / 60) * 60 + $0 }
            )) {
                ForEach(0..<60) { sec in
                    Text("\(sec)s").tag(sec)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 70, height: 100)
            .clipped()
        }
    }
}

// MARK: - PhaseTimelinePreview
struct PhaseTimelinePreview: View {
    let phases: [Phase]
    let repeatCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // One block per phase
            HStack(spacing: 2) {
                ForEach(phases.indices, id: \.self) { idx in
                    let phase = phases[idx]
                    let totalDur = phases.reduce(0) { $0 + $1.durationSeconds }
                    let flex = CGFloat(phase.durationSeconds) / CGFloat(totalDur)

                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(phase.type.color)
                            .frame(height: 24)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                Text("\(phase.durationSeconds / 60)m\(phase.durationSeconds % 60 > 0 ? "\(phase.durationSeconds % 60)s" : "")")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }

                        Text(phase.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(width: 60)
                }
            }

            if repeatCount > 1 {
                Text("× \(repeatCount) repeats")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    WorkoutEditorView(workout: nil) { _ in }
}
