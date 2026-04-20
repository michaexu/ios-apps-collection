//
//  PetMateApp.swift
//  PetMate
//
//  PetMate - AI驱动的宠物全生命周期管理平台
// 懂它，更爱它
//

import SwiftUI

@main
struct PetMateApp: App {
    @StateObject private var petViewModel = PetViewModel()
    @StateObject private var healthViewModel = HealthViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(petViewModel)
                .environmentObject(healthViewModel)
                .preferredColorScheme(.light)
        }
    }
}
