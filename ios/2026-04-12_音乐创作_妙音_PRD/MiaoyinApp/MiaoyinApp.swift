//
//  MiaoyinApp.swift
//  妙音 - AI民谣音乐创作伴侣
//

import SwiftUI

@main
struct MiaoyinApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .create
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    
    enum Tab {
        case create
        case works
        case community
        case profile
    }
}
