import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Add sample data for previews
        let sampleInspiration = InspirationEntity(context: viewContext)
        sampleInspiration.id = UUID()
        sampleInspiration.title = "北欧风格钩针杯垫"
        sampleInspiration.content = "看到一个很漂亮的北欧风格钩针杯垫教程，想试试做几个"
        sampleInspiration.tags = ["编织", "钩针", "家居"]
        sampleInspiration.createdAt = Date()
        sampleInspiration.updatedAt = Date()
        sampleInspiration.isConverted = false

        let sampleProject = ProjectEntity(context: viewContext)
        sampleProject.id = UUID()
        sampleProject.name = "手工皮革钱包"
        sampleProject.projectDescription = "用植鞣革制作一个简约风格的对折钱包"
        sampleProject.category = "其他"
        sampleProject.status = "inProgress"
        sampleProject.priority = 2
        sampleProject.createdAt = Date()
        sampleProject.updatedAt = Date()
        sampleProject.lastActivityAt = Date()
        sampleProject.totalCost = 85.0
        sampleProject.estimatedHours = 8.0
        sampleProject.actualHours = 3.5

        let sampleMaterial = MaterialEntity(context: viewContext)
        sampleMaterial.id = UUID()
        sampleMaterial.name = "羊毛线"
        sampleMaterial.brand = "奥林巴斯"
        sampleMaterial.specification = "100g/团"
        sampleMaterial.category = "毛线/纱线"
        sampleMaterial.unit = "团"
        sampleMaterial.currentStock = 5
        sampleMaterial.minStockAlert = 1
        sampleMaterial.purchasePrice = 28.0
        sampleMaterial.purchaseChannel = "淘宝"
        sampleMaterial.createdAt = Date()
        sampleMaterial.updatedAt = Date()

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ZaoWuJi")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
