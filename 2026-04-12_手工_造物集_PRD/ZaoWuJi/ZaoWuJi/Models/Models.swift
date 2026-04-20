import Foundation
import SwiftData

// MARK: - Inspiration Model
@Model
final class Inspiration {
    var id: UUID
    var title: String
    var content: String
    var imageData: Data?
    var linkURL: String?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var isConverted: Bool
    var convertedProjectID: UUID?

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        imageData: Data? = nil,
        linkURL: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isConverted: Bool = false,
        convertedProjectID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.imageData = imageData
        self.linkURL = linkURL
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isConverted = isConverted
        self.convertedProjectID = convertedProjectID
    }
}

// MARK: - Project Model
@Model
final class Project {
    var id: UUID
    var name: String
    var projectDescription: String
    var category: String
    var status: String  // "planning", "inProgress", "finishing", "completed", "paused"
    var priority: Int   // 1-3
    var stages: [ProjectStage]
    var photoDataList: [Data]
    var inspirationID: UUID?
    var totalCost: Double
    var estimatedHours: Double
    var actualHours: Double
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var lastActivityAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        projectDescription: String = "",
        category: String = "其他",
        status: String = "planning",
        priority: Int = 2,
        stages: [ProjectStage] = [],
        photoDataList: [Data] = [],
        inspirationID: UUID? = nil,
        totalCost: Double = 0,
        estimatedHours: Double = 0,
        actualHours: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        lastActivityAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.projectDescription = projectDescription
        self.category = category
        self.status = status
        self.priority = priority
        self.stages = stages
        self.photoDataList = photoDataList
        self.inspirationID = inspirationID
        self.totalCost = totalCost
        self.estimatedHours = estimatedHours
        self.actualHours = actualHours
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.lastActivityAt = lastActivityAt
    }

    var progressPercentage: Double {
        guard !stages.isEmpty else { return 0 }
        let completed = stages.filter { $0.isCompleted }.count
        return Double(completed) / Double(stages.count)
    }

    var statusDisplayName: String {
        switch status {
        case "planning": return "规划中"
        case "inProgress": return "制作中"
        case "finishing": return "收尾中"
        case "completed": return "已完成"
        case "paused": return "已暂停"
        default: return "未知"
        }
    }
}

// MARK: - ProjectStage Model
@Model
final class ProjectStage {
    var id: UUID
    var name: String
    var stageDescription: String
    var isCompleted: Bool
    var completedAt: Date?
    var order: Int
    var notes: String

    init(
        id: UUID = UUID(),
        name: String = "",
        stageDescription: String = "",
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        order: Int = 0,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.stageDescription = stageDescription
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.order = order
        self.notes = notes
    }
}

// MARK: - Material Model
@Model
final class Material {
    var id: UUID
    var name: String
    var brand: String
    var specification: String
    var category: String
    var unit: String
    var currentStock: Double
    var minStockAlert: Double
    var purchasePrice: Double
    var purchaseChannel: String
    var imageData: Data?
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        brand: String = "",
        specification: String = "",
        category: String = "其他",
        unit: String = "个",
        currentStock: Double = 0,
        minStockAlert: Double = 1,
        purchasePrice: Double = 0,
        purchaseChannel: String = "",
        imageData: Data? = nil,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.specification = specification
        self.category = category
        self.unit = unit
        self.currentStock = currentStock
        self.minStockAlert = minStockAlert
        self.purchasePrice = purchasePrice
        self.purchaseChannel = purchaseChannel
        self.imageData = imageData
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isLowStock: Bool {
        currentStock <= minStockAlert
    }
}

// MARK: - MaterialConsumption Model
@Model
final class MaterialConsumption {
    var id: UUID
    var materialID: UUID
    var materialName: String
    var projectID: UUID
    var projectName: String
    var quantity: Double
    var unit: String
    var unitPrice: Double
    var totalCost: Double
    var consumedAt: Date

    init(
        id: UUID = UUID(),
        materialID: UUID,
        materialName: String,
        projectID: UUID,
        projectName: String,
        quantity: Double,
        unit: String,
        unitPrice: Double,
        consumedAt: Date = Date()
    ) {
        self.id = id
        self.materialID = materialID
        self.materialName = materialName
        self.projectID = projectID
        self.projectName = projectName
        self.quantity = quantity
        self.unit = unit
        self.unitPrice = unitPrice
        self.totalCost = quantity * unitPrice
        self.consumedAt = consumedAt
    }
}

// MARK: - PurchaseRecord Model
@Model
final class PurchaseRecord {
    var id: UUID
    var materialID: UUID
    var materialName: String
    var quantity: Double
    var unit: String
    var unitPrice: Double
    var totalAmount: Double
    var channel: String
    var purchasedAt: Date
    var notes: String

    init(
        id: UUID = UUID(),
        materialID: UUID,
        materialName: String,
        quantity: Double,
        unit: String,
        unitPrice: Double,
        channel: String = "",
        purchasedAt: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.materialID = materialID
        self.materialName = materialName
        self.quantity = quantity
        self.unit = unit
        self.unitPrice = unitPrice
        self.totalAmount = quantity * unitPrice
        self.channel = channel
        self.purchasedAt = purchasedAt
        self.notes = notes
    }
}

// MARK: - Portfolio (Artwork) Model
@Model
final class Artwork {
    var id: UUID
    var title: String
    var artworkDescription: String
    var projectID: UUID?
    var projectName: String
    var photoDataList: [Data]
    var story: String
    var tags: [String]
    var visibility: String  // "private", "friends", "public"
    var totalCost: Double
    var sellingPrice: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        artworkDescription: String = "",
        projectID: UUID? = nil,
        projectName: String = "",
        photoDataList: [Data] = [],
        story: String = "",
        tags: [String] = [],
        visibility: String = "private",
        totalCost: Double = 0,
        sellingPrice: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artworkDescription = artworkDescription
        self.projectID = projectID
        self.projectName = projectName
        self.photoDataList = photoDataList
        self.story = story
        self.tags = tags
        self.visibility = visibility
        self.totalCost = totalCost
        self.sellingPrice = sellingPrice
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var profit: Double {
        sellingPrice - totalCost
    }
}

// MARK: - Constants
enum ProjectCategory: String, CaseIterable {
    case knitting = "编织"
    case woodwork = "木工"
    case pottery = "陶艺"
    case baking = "烘焙"
    case jewelry = "首饰"
    case painting = "绘画"
    case sewing = "缝纫"
    case other = "其他"

    var icon: String {
        switch self {
        case .knitting: return "🧶"
        case .woodwork: return "🪵"
        case .pottery: return "🏺"
        case .baking: return "🍰"
        case .jewelry: return "💍"
        case .painting: return "🎨"
        case .sewing: return "🧵"
        case .other: return "✨"
        }
    }
}

enum MaterialCategory: String, CaseIterable {
    case yarn = "毛线/纱线"
    case fabric = "布料"
    case wood = "木材"
    case clay = "陶土/粘土"
    case metal = "金属配件"
    case paint = "颜料/涂料"
    case tool = "工具"
    case packaging = "包装材料"
    case other = "其他"
}

let defaultProjectStages: [String] = ["准备材料", "制作中", "收尾整理", "完成"]
