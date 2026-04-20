import Foundation

enum BalconyOrientation: String, CaseIterable, Identifiable, Codable {
    case east = "东"
    case south = "南"
    case west = "西"
    case north = "北"
    var id: String { rawValue }
}

enum PlantPosition: String, CaseIterable, Identifiable, Codable {
    case balcony = "阳台"
    case windowsill = "窗台"
    case indoor = "室内"
    var id: String { rawValue }
}

enum GrowingEnvironment: String, CaseIterable, Identifiable, Codable {
    case potted = "盆栽"
    case hydroponic = "水培"
    case soilBed = "土培"
    var id: String { rawValue }
}

enum HealthStatus: Int, Codable, CaseIterable, Identifiable {
    case healthy = 0
    case watch = 1
    case urgent = 2
    case withered = 3
    var id: Int { rawValue }
}

enum CareKind: String, Codable, CaseIterable, Identifiable {
    case water = "浇水"
    case fertilize = "施肥"
    case repot = "换盆"
    case prune = "修剪"
    case other = "其他"
    var id: String { rawValue }
}
