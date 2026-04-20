import SwiftUI

@main
struct KangBanApp: App {
    @StateObject private var medicationViewModel = MedicationViewModel()
    @StateObject private var healthViewModel = HealthViewModel()
    @StateObject private var familyViewModel = FamilyViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(medicationViewModel)
                .environmentObject(healthViewModel)
                .environmentObject(familyViewModel)
                .preferredColorScheme(.light)
        }
    }
}
