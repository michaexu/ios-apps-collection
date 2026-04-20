import Foundation
import Combine

@MainActor
final class WorkoutLibraryViewModel: ObservableObject {
    @Published var savedWorkouts: [Workout] = []
    @Published var selectedFolder: String? = nil
    @Published var searchText: String = ""
    @Published var showingCreateSheet = false
    @Published var showingShareSheet = false
    @Published var workoutToShare: Workout?

    let folders = StorageService.defaultFolders

    var filteredWorkouts: [Workout] {
        var result = savedWorkouts
        if let folder = selectedFolder {
            result = result.filter { $0.folderName == folder }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.workoutDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    init() {
        loadWorkouts()
    }

    func loadWorkouts() {
        savedWorkouts = StorageService.shared.loadWorkouts()
    }

    func saveWorkout(_ workout: Workout) {
        StorageService.shared.saveWorkout(workout)
        loadWorkouts()
    }

    func deleteWorkout(_ workout: Workout) {
        StorageService.shared.deleteWorkout(workout)
        loadWorkouts()
    }

    func duplicateWorkout(_ workout: Workout) {
        var copy = workout
        copy.id = UUID()
        copy.name = "\(workout.name) (Copy)"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        StorageService.shared.saveWorkout(copy)
        loadWorkouts()
    }

    func importWorkout(_ workout: Workout) {
        StorageService.shared.saveWorkout(workout)
        loadWorkouts()
    }

    func foldersWithWorkoutCounts() -> [(folder: String, count: Int)] {
        folders.map { folder in
            (folder, savedWorkouts.filter { $0.folderName == folder }.count)
        }
    }
}
