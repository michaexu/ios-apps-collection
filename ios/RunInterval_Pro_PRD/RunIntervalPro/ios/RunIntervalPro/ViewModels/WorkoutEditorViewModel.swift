import Foundation
import Combine

@MainActor
final class WorkoutEditorViewModel: ObservableObject {
    @Published var workout: Workout
    @Published var workoutName: String = ""
    @Published var workoutDescription: String = ""
    @Published var selectedFolder: String = "Custom"
    @Published var phases: [Phase] = []
    @Published var repeatCount: Int = 1

    let folders = StorageService.defaultFolders
    let isNew: Bool

    init(workout: Workout? = nil) {
        if let workout = workout {
            self.workout = workout
            self.isNew = false
        } else {
            self.workout = Workout(name: "", cycles: [])
            self.isNew = true
        }
        self.workoutName = self.workout.name
        self.workoutDescription = self.workout.workoutDescription
        self.selectedFolder = self.workout.folderName ?? "Custom"
        self.phases = self.workout.cycles.first?.phases ?? []
        self.repeatCount = self.workout.cycles.first?.repeatCount ?? 1
    }

    var totalDuration: Int {
        phases.reduce(0) { $0 + $1.durationSeconds } * repeatCount
    }

    var totalDurationFormatted: String {
        let t = totalDuration
        let m = t / 60
        let s = t % 60
        return String(format: "%d:%02d", m, s)
    }

    var canSave: Bool {
        !workoutName.trimmingCharacters(in: .whitespaces).isEmpty && !phases.isEmpty
    }

    func addPhase(type: PhaseType = .work) {
        let newPhase = Phase(
            name: type.displayName,
            type: type,
            durationSeconds: 60,
            order: phases.count
        )
        phases.append(newPhase)
    }

    func removePhase(at index: Int) {
        guard index < phases.count else { return }
        phases.remove(at: index)
        for i in 0..<phases.count {
            phases[i].order = i
        }
    }

    func movePhase(from source: IndexSet, to destination: Int) {
        phases.move(fromOffsets: source, toOffset: destination)
        for i in 0..<phases.count {
            phases[i].order = i
        }
    }

    func save() -> Workout {
        var updated = workout
        updated.name = workoutName.trimmingCharacters(in: .whitespaces)
        updated.workoutDescription = workoutDescription
        updated.folderName = selectedFolder
        updated.cycles = [
            Cycle(phases: phases.enumerated().map { idx, p in
                var phase = p
                phase.order = idx
                return phase
            }, repeatCount: repeatCount)
        ]
        updated.updatedAt = Date()
        if isNew {
            updated.createdAt = Date()
        }
        StorageService.shared.saveWorkout(updated)
        return updated
    }
}
