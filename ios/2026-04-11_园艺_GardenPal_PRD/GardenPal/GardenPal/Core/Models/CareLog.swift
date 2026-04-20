import Foundation
import SwiftData

@Model
final class CareLog {
    var careKindRaw: String
    var notes: String?
    var createdAt: Date
    var plant: Plant?

    init(careKind: CareKind, notes: String? = nil, createdAt: Date = Date(), plant: Plant? = nil) {
        self.careKindRaw = careKind.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.plant = plant
    }

    var careKind: CareKind {
        get { CareKind(rawValue: careKindRaw) ?? .other }
        set { careKindRaw = newValue.rawValue }
    }
}
