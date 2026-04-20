//
//  FitPulseApp.swift
//  FitPulse
//
//  Created by FitPulse on 2026/4/13.
//

import SwiftUI

@main
struct FitPulseApp: App {
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var communityViewModel = CommunityViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userViewModel)
                .environmentObject(workoutViewModel)
                .environmentObject(communityViewModel)
        }
    }
}
