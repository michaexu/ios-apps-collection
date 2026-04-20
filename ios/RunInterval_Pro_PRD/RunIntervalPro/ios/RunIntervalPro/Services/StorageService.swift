import Foundation

// MARK: - StorageService
final class StorageService {
    static let shared = StorageService()

    private let workoutsKey = "saved_workouts"
    private let summariesKey = "workout_summaries"
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - Workouts

    func saveWorkouts(_ workouts: [Workout]) {
        do {
            let data = try encoder.encode(workouts)
            userDefaults.set(data, forKey: workoutsKey)
        } catch {
            print("Failed to save workouts: \(error)")
        }
    }

    func loadWorkouts() -> [Workout] {
        guard let data = userDefaults.data(forKey: workoutsKey) else { return [] }
        do {
            return try decoder.decode([Workout].self, from: data)
        } catch {
            print("Failed to load workouts: \(error)")
            return []
        }
    }

    func saveWorkout(_ workout: Workout) {
        var workouts = loadWorkouts()
        if let idx = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[idx] = workout
        } else {
            workouts.append(workout)
        }
        saveWorkouts(workouts)
    }

    func deleteWorkout(_ workout: Workout) {
        var workouts = loadWorkouts()
        workouts.removeAll { $0.id == workout.id }
        saveWorkouts(workouts)
    }

    // MARK: - Workout Summaries

    func saveSummaries(_ summaries: [WorkoutSummary]) {
        do {
            let data = try encoder.encode(summaries)
            userDefaults.set(data, forKey: summariesKey)
        } catch {
            print("Failed to save summaries: \(error)")
        }
    }

    func loadSummaries() -> [WorkoutSummary] {
        guard let data = userDefaults.data(forKey: summariesKey) else { return [] }
        do {
            return try decoder.decode([WorkoutSummary].self, from: data)
        } catch {
            print("Failed to load summaries: \(error)")
            return []
        }
    }

    func addSummary(_ summary: WorkoutSummary) {
        var summaries = loadSummaries()
        summaries.insert(summary, at: 0)
        if summaries.count > 500 { summaries = Array(summaries.prefix(500)) }
        saveSummaries(summaries)
    }

    // MARK: - Folders

    static let defaultFolders = ["Speed Work", "Long Run", "Recovery", "Races", "Custom"]
}
