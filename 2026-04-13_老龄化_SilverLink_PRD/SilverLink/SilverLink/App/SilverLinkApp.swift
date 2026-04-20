import SwiftUI

@main
struct SilverLinkApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var healthStore = HealthStore()
    @StateObject private var familyStore = FamilyStore()
    @StateObject private var safetyStore = SafetyStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .environmentObject(healthStore)
                .environmentObject(familyStore)
                .environmentObject(safetyStore)
                .preferredColorScheme(.light)
        }
    }
}
