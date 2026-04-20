import Foundation
import SwiftUI

// MARK: - PresetWorkout
struct PresetWorkout: Identifiable {
    let id = UUID()
    let internalName: String
    let displayName: String
    let description: String
    let workout: Workout
    let isPro: Bool

    static let all: [PresetWorkout] = [
        classicHIIT,
        pyramidIntervals,
        fartlek,
        tempoRun,
        yasso800s,
        halfMarathonPace,
        tabata20_10,
        progressive5K
    ]

    static let freePresets: [PresetWorkout] = [classicHIIT, tempoRun, tabata20_10]

    // MARK: - Preset Definitions

    static let classicHIIT = PresetWorkout(
        internalName: "classic_hiit",
        displayName: "Classic HIIT",
        description: "30s work / 10s rest × 8 — High intensity intervals",
        workout: Workout(
            name: "Classic HIIT",
            workoutDescription: "30s work / 10s rest × 8",
            cycles: [
                Cycle(
                    phases: [
                        Phase(name: "Work", type: .work, durationSeconds: 30, order: 0),
                        Phase(name: "Rest", type: .rest, durationSeconds: 10, order: 1)
                    ],
                    repeatCount: 8
                )
            ]
        ),
        isPro: false
    )

    static let pyramidIntervals = PresetWorkout(
        internalName: "pyramid_intervals",
        displayName: "Pyramid Intervals",
        description: "1-2-3-2-1 min with equal rest — Building endurance",
        workout: {
            var phases: [Phase] = []
            let durations = [60, 120, 180, 120, 60]
            for (i, dur) in durations.enumerated() {
                phases.append(Phase(name: "Work", type: .work, durationSeconds: dur, order: i * 2))
                phases.append(Phase(name: "Rest", type: .rest, durationSeconds: dur, order: i * 2 + 1))
            }
            return Workout(
                name: "Pyramid Intervals",
                workoutDescription: "1-2-3-2-1 min with equal rest",
                cycles: [Cycle(phases: phases, repeatCount: 1)]
            )
        }(),
        isPro: true
    )

    static let fartlek = PresetWorkout(
        internalName: "fartlek",
        displayName: "Fartlek",
        description: "Randomized work/rest periods — Speed play",
        workout: {
            let durations = [60, 90, 120, 60, 180, 90]
            var phases: [Phase] = []
            for (i, dur) in durations.enumerated() {
                phases.append(Phase(name: "Fast", type: .work, durationSeconds: dur, order: i * 2))
                phases.append(Phase(name: "Easy", type: .rest, durationSeconds: dur, order: i * 2 + 1))
            }
            return Workout(
                name: "Fartlek",
                workoutDescription: "Randomized work/rest periods",
                cycles: [Cycle(phases: phases, repeatCount: 1)]
            )
        }(),
        isPro: true
    )

    static let tempoRun = PresetWorkout(
        internalName: "tempo_run",
        displayName: "Tempo Run",
        description: "10 min warm / 20 min tempo / 10 min cool",
        workout: Workout(
            name: "Tempo Run",
            workoutDescription: "10 min warm / 20 min tempo / 10 min cool",
            cycles: [
                Cycle(phases: [
                    Phase(name: "Warm Up", type: .warmup, durationSeconds: 600, order: 0),
                    Phase(name: "Tempo", type: .work, durationSeconds: 1200, order: 1),
                    Phase(name: "Cool Down", type: .cooldown, durationSeconds: 600, order: 2)
                ])
            ]
        ),
        isPro: false
    )

    static let yasso800s = PresetWorkout(
        internalName: "yasso_800s",
        displayName: "Yasso 800s",
        description: "800m effort / equal recovery × 6-10 — Marathon training",
        workout: Workout(
            name: "Yasso 800s",
            workoutDescription: "800m effort / equal recovery × 8",
            cycles: [
                Cycle(phases: [
                    Phase(name: "800m Effort", type: .work, durationSeconds: 180, order: 0),
                    Phase(name: "Recovery", type: .rest, durationSeconds: 180, order: 1)
                ], repeatCount: 8)
            ]
        ),
        isPro: true
    )

    static let halfMarathonPace = PresetWorkout(
        internalName: "half_marathon_pace",
        displayName: "Half Marathon Pace",
        description: "12 min warm / 50 min HM pace / 8 min cool",
        workout: Workout(
            name: "Half Marathon Pace",
            workoutDescription: "12 min warm / 50 min HM pace / 8 min cool",
            cycles: [
                Cycle(phases: [
                    Phase(name: "Warm Up", type: .warmup, durationSeconds: 720, order: 0),
                    Phase(name: "HM Pace", type: .work, durationSeconds: 3000, order: 1),
                    Phase(name: "Cool Down", type: .cooldown, durationSeconds: 480, order: 2)
                ])
            ]
        ),
        isPro: true
    )

    static let tabata20_10 = PresetWorkout(
        internalName: "tabata_20_10",
        displayName: "Tabata 20/10",
        description: "20s work / 10s rest × 10 — Classic Tabata",
        workout: Workout(
            name: "Tabata 20/10",
            workoutDescription: "20s work / 10s rest × 10",
            cycles: [
                Cycle(phases: [
                    Phase(name: "Work", type: .work, durationSeconds: 20, order: 0),
                    Phase(name: "Rest", type: .rest, durationSeconds: 10, order: 1)
                ], repeatCount: 10)
            ]
        ),
        isPro: false
    )

    static let progressive5K = PresetWorkout(
        internalName: "progressive_5k",
        displayName: "Progressive 5K",
        description: "Easy start, build to 5K race pace in final km",
        workout: Workout(
            name: "Progressive 5K",
            workoutDescription: "Easy start, build to 5K race pace",
            cycles: [
                Cycle(phases: [
                    Phase(name: "Easy", type: .warmup, durationSeconds: 600, order: 0),
                    Phase(name: "Build", type: .work, durationSeconds: 1200, order: 1),
                    Phase(name: "5K Pace", type: .work, durationSeconds: 600, order: 2),
                    Phase(name: "Cool Down", type: .cooldown, durationSeconds: 300, order: 3)
                ])
            ]
        ),
        isPro: true
    )
}
