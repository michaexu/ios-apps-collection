import SwiftUI
import SwiftData

@main
struct GardenPalApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Plant.self,
            CareLog.self,
            DiagnosisSession.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
