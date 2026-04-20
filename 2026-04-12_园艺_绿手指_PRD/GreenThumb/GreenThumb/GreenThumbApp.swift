//
//  GreenThumbApp.swift
//  GreenThumb
//
//  绿手指 - 智能植物养护助手
//

import SwiftUI

@main
struct GreenThumbApp: App {
    @StateObject private var plantStore = PlantStore()
    @StateObject private var taskStore = TaskStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(plantStore)
                .environmentObject(taskStore)
        }
    }
}
