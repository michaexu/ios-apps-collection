import Foundation
import SwiftData

@Model
final class Plant {
    var nickname: String
    /// Key in `species_top200.json`; nil if fully manual.
    var speciesCatalogId: String?
    var customSpeciesLabel: String?
    @Attribute(.externalStorage) var photoData: Data?

    var orientationRaw: String
    var positionRaw: String
    var environmentRaw: String

    var wateringIntervalDays: Int
    var fertilizerIntervalDays: Int

    var lastWateredAt: Date?
    var nextWateringAt: Date?
    var lastFertilizedAt: Date?
    var nextFertilizerAt: Date?

    var userFlagNeedsAttention: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CareLog.plant)
    var careLogs: [CareLog] = []

    @Relationship(deleteRule: .cascade, inverse: \DiagnosisSession.plant)
    var diagnoses: [DiagnosisSession] = []

    init(
        nickname: String,
        speciesCatalogId: String? = nil,
        customSpeciesLabel: String? = nil,
        photoData: Data? = nil,
        orientation: BalconyOrientation,
        position: PlantPosition,
        environment: GrowingEnvironment,
        wateringIntervalDays: Int,
        fertilizerIntervalDays: Int = 30
    ) {
        self.nickname = nickname
        self.speciesCatalogId = speciesCatalogId
        self.customSpeciesLabel = customSpeciesLabel
        self.photoData = photoData
        self.orientationRaw = orientation.rawValue
        self.positionRaw = position.rawValue
        self.environmentRaw = environment.rawValue
        self.wateringIntervalDays = max(1, wateringIntervalDays)
        self.fertilizerIntervalDays = max(1, fertilizerIntervalDays)
        self.userFlagNeedsAttention = false
        self.createdAt = Date()
        let now = Date()
        self.lastWateredAt = nil
        self.nextWateringAt = Calendar.current.date(byAdding: .day, value: self.wateringIntervalDays, to: now)
        self.lastFertilizedAt = nil
        self.nextFertilizerAt = Calendar.current.date(byAdding: .day, value: self.fertilizerIntervalDays, to: now)
    }

    var orientation: BalconyOrientation {
        get { BalconyOrientation(rawValue: orientationRaw) ?? .south }
        set { orientationRaw = newValue.rawValue }
    }

    var position: PlantPosition {
        get { PlantPosition(rawValue: positionRaw) ?? .balcony }
        set { positionRaw = newValue.rawValue }
    }

    var environment: GrowingEnvironment {
        get { GrowingEnvironment(rawValue: environmentRaw) ?? .potted }
        set { environmentRaw = newValue.rawValue }
    }

    func displaySpeciesName(catalog: SpeciesCatalog) -> String {
        if let id = speciesCatalogId, let s = catalog.species(byId: id) {
            return s.nameCN
        }
        return customSpeciesLabel?.isEmpty == false ? (customSpeciesLabel ?? "") : "未指定品种"
    }

    func recomputeHealthStatus(referenceDate: Date = Date()) -> HealthStatus {
        if userFlagNeedsAttention { return .watch }
        if let due = nextWateringAt {
            let late = referenceDate.timeIntervalSince(due)
            if late > 86400 * 3 { return .urgent }
            if late > 0 { return .watch }
        }
        if let last = diagnoses.sorted(by: { $0.createdAt > $1.createdAt }).first, last.severity >= 3 {
            return .watch
        }
        return .healthy
    }
}
