//
//  FlowStateApp.swift
//  FlowState
//
//  FlowState - 一站式深度工作管理平台
//  iOS 17+ SwiftUI MVVM Architecture
//

import SwiftUI

@main
struct FlowStateApp: App {
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var focusViewModel = FocusViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskViewModel)
                .environmentObject(focusViewModel)
        }
    }
}
