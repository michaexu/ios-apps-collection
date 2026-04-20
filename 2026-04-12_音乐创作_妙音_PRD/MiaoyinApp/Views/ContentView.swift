//
//  ContentView.swift
//  妙音 - 主入口视图
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            CreateView()
                .tabItem {
                    Image(systemName: "mic.fill")
                    Text("创作")
                }
                .tag(AppState.Tab.create)
            
            MyWorksView()
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("作品")
                }
                .tag(AppState.Tab.works)
            
            CommunityView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("灵感")
                }
                .tag(AppState.Tab.community)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
                .tag(AppState.Tab.profile)
        }
        .accentColor(.miaoyinPrimary)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
