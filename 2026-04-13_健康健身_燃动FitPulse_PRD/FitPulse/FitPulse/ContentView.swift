//
//  ContentView.swift
//  FitPulse
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        Group {
            if userViewModel.hasCompletedAssessment {
                MainTabView()
            } else {
                AssessmentView()
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
                .tag(0)
            
            TrainingView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("训练")
                }
                .tag(1)
            
            CommunityView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("燃圈")
                }
                .tag(2)
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("数据")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
                .tag(4)
        }
        .accentColor(Color(hex: "#E65100"))
    }
}

#Preview {
    ContentView()
        .environmentObject(UserViewModel())
        .environmentObject(WorkoutViewModel())
        .environmentObject(CommunityViewModel())
}
