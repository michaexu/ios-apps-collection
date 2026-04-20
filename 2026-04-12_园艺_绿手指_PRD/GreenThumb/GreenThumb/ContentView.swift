//
//  ContentView.swift
//  GreenThumb
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("首页")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("日历")
                }
                .tag(1)
            
            EncyclopediaView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("百科")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
                .tag(3)
        }
        .tint(Color(hex: "#2E7D32"))
    }
}

#Preview {
    ContentView()
        .environmentObject(PlantStore())
        .environmentObject(TaskStore())
}
