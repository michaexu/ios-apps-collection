import CoreData
import Foundation

// MARK: - InspirationEntity
@objc(InspirationEntity)
public class InspirationEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var linkURL: String?
    @NSManaged public var tags: [String]?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var isConverted: Bool
    @NSManaged public var convertedProjectID: UUID?
}

extension InspirationEntity: Identifiable {}

// MARK: - ProjectEntity
@objc(ProjectEntity)
public class ProjectEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var projectDescription: String?
    @NSManaged public var category: String?
    @NSManaged public var status: String?
    @NSManaged public var priority: Int16
    @NSManaged public var stagesData: Data?
    @NSManaged public var photoDataList: [Data]?
    @NSManaged public var inspirationID: UUID?
    @NSManaged public var totalCost: Double
    @NSManaged public var estimatedHours: Double
    @NSManaged public var actualHours: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var completedAt: Date?
    @NSManaged public var lastActivityAt: Date?
}

extension ProjectEntity: Identifiable {}

// MARK: - MaterialEntity
@objc(MaterialEntity)
public class MaterialEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var brand: String?
    @NSManaged public var specification: String?
    @NSManaged public var category: String?
    @NSManaged public var unit: String?
    @NSManaged public var currentStock: Double
    @NSManaged public var minStockAlert: Double
    @NSManaged public var purchasePrice: Double
    @NSManaged public var purchaseChannel: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension MaterialEntity: Identifiable {}

// MARK: - MaterialConsumptionEntity
@objc(MaterialConsumptionEntity)
public class MaterialConsumptionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var materialID: UUID?
    @NSManaged public var materialName: String?
    @NSManaged public var projectID: UUID?
    @NSManaged public var projectName: String?
    @NSManaged public var quantity: Double
    @NSManaged public var unit: String?
    @NSManaged public var unitPrice: Double
    @NSManaged public var totalCost: Double
    @NSManaged public var consumedAt: Date?
}

extension MaterialConsumptionEntity: Identifiable {}

// MARK: - ArtworkEntity
@objc(ArtworkEntity)
public class ArtworkEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var artworkDescription: String?
    @NSManaged public var projectID: UUID?
    @NSManaged public var projectName: String?
    @NSManaged public var photoDataList: [Data]?
    @NSManaged public var story: String?
    @NSManaged public var tags: [String]?
    @NSManaged public var visibility: String?
    @NSManaged public var totalCost: Double
    @NSManaged public var sellingPrice: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension ArtworkEntity: Identifiable {}
