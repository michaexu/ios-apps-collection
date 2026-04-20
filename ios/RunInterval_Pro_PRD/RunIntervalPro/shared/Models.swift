import Foundation

// MARK: - PhaseType
enum PhaseType: String, Codable, CaseIterable, Identifiable, Hashable {
    case work
    case rest
    case warmup
    case cooldown
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .work: return "Work"
        case .rest: return "Rest"
        case .warmup: return "Warm Up"
        case .cooldown: return "Cool Down"
        case .custom: return "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .work: return "flame.fill"
        case .rest: return "pause.circle.fill"
        case .warmup: return "figure.run"
        case .cooldown: return "wind"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Phase
struct Phase: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var type: PhaseType
    var durationSeconds: Int
    var order: Int

    init(id: UUID = UUID(), name: String, type: PhaseType, durationSeconds: Int, order: Int) {
        self.id = id
        self.name = name
        self.type = type
        self.durationSeconds = durationSeconds
        self.order = order
    }

    var formattedDuration: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        if m > 0 {
            return s > 0 ? "\(m)m \(s)s" : "\(m)m"
        }
        return "\(s)s"
    }
}

// MARK: - Cycle
struct Cycle: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var phases: [Phase]
    var repeatCount: Int

    init(id: UUID = UUID(), phases: [Phase], repeatCount: Int = 1) {
        self.id = id
        self.phases = phases
        self.repeatCount = repeatCount
    }

    var totalSeconds: Int {
        phases.reduce(0) { $0 + $1.durationSeconds } * repeatCount
    }
}

// MARK: - Workout
struct Workout: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var workoutDescription: String
    var cycles: [Cycle]
    var folderName: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        workoutDescription: String = "",
        cycles: [Cycle] = [],
        folderName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.workoutDescription = workoutDescription
        self.cycles = cycles
        self.folderName = folderName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var totalSeconds: Int {
        cycles.reduce(0) { $0 + $1.totalSeconds }
    }

    var totalDurationFormatted: String {
        let t = totalSeconds
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    var phaseCount: Int {
        cycles.reduce(0) { $0 + $1.phases.count * $1.repeatCount }
    }
}

// MARK: - WorkoutSummary
struct WorkoutSummary: Codable, Identifiable {
    let id: UUID
    let workoutName: String
    let completedAt: Date
    let totalDurationSeconds: Int
    let phasesCompleted: Int
}
