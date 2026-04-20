import Foundation

struct SpeciesDTO: Codable, Equatable, Identifiable {
    var id: String
    var nameCN: String
    var nameEN: String?
    var family: String?
    var wateringCycleDays: Int
    var sunlight: String
    var soilType: String?
    var temperatureRange: String?
    var humidity: String?
    var commonIssues: String?
    var careTips: String?

    enum CodingKeys: String, CodingKey {
        case id
        case nameCN = "name_cn"
        case nameEN = "name_en"
        case family
        case wateringCycleDays = "watering_cycle_days"
        case sunlight
        case soilType = "soil_type"
        case temperatureRange = "temperature_range"
        case humidity
        case commonIssues = "common_issues"
        case careTips = "care_tips"
    }
}

final class SpeciesCatalog: @unchecked Sendable {
    static let shared = SpeciesCatalog()

    private(set) var all: [SpeciesDTO] = []
    private var byId: [String: SpeciesDTO] = [:]

    private init() {
        reload()
    }

    func reload() {
        guard let url = Bundle.main.url(forResource: "species_top200", withExtension: "json") else {
            all = []
            byId = [:]
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([SpeciesDTO].self, from: data)
            all = decoded.sorted { $0.nameCN < $1.nameCN }
            byId = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
        } catch {
            all = []
            byId = [:]
        }
    }

    func species(byId id: String) -> SpeciesDTO? { byId[id] }

    func search(_ query: String) -> [SpeciesDTO] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return all }
        return all.filter {
            $0.nameCN.localizedCaseInsensitiveContains(q)
                || ($0.nameEN ?? "").localizedCaseInsensitiveContains(q)
                || ($0.family ?? "").localizedCaseInsensitiveContains(q)
        }
    }

    func recommendations(orientation: BalconyOrientation, approximateWidthMeters: Double) -> [SpeciesDTO] {
        let needsStrongLight = orientation == .south || orientation == .west
        let compact = approximateWidthMeters < 1.2

        return all.filter { species in
            let sun = species.sunlight
            if needsStrongLight {
                if sun.contains("全日照") || sun.contains("直射") || sun.contains("强") { return true }
            } else {
                if sun.contains("散射") || sun.contains("阴") || sun.contains("半阴") { return true }
            }
            if compact, sun.contains("大型") || species.nameCN.contains("树") { return false }
            return true
        }
    }
}
