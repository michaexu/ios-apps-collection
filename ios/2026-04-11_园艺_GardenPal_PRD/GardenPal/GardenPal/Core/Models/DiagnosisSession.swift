import Foundation
import SwiftData

@Model
final class DiagnosisSession {
    var symptomKeysJSON: String
    var title: String
    var prevention: String
    var severity: Int
    var treatmentStepsJSON: String
    var createdAt: Date
    var plant: Plant?

    init(
        symptomKeys: [String],
        title: String,
        prevention: String,
        severity: Int,
        steps: [TreatmentStep],
        createdAt: Date = Date(),
        plant: Plant? = nil
    ) {
        self.symptomKeysJSON = (try? String(data: JSONEncoder().encode(symptomKeys), encoding: .utf8)) ?? "[]"
        self.title = title
        self.prevention = prevention
        self.severity = severity
        self.treatmentStepsJSON = (try? String(data: JSONEncoder().encode(steps), encoding: .utf8)) ?? "[]"
        self.createdAt = createdAt
        self.plant = plant
    }

    var symptomKeys: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(symptomKeysJSON.utf8))) ?? []
    }

    var treatmentSteps: [TreatmentStep] {
        get {
            (try? JSONDecoder().decode([TreatmentStep].self, from: Data(treatmentStepsJSON.utf8))) ?? []
        }
        set {
            treatmentStepsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    func setStep(done: Bool, stepId: String) {
        var steps = treatmentSteps
        guard let index = steps.firstIndex(where: { $0.id == stepId }) else { return }
        steps[index].done = done
        treatmentSteps = steps
    }
}

struct TreatmentStep: Codable, Equatable, Identifiable {
    var id: String
    var text: String
    var done: Bool
}
