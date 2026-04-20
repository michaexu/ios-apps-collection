import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            PlantsListView()
                .tabItem {
                    Label("我的植物", systemImage: "leaf.fill")
                }
            DoctorHomeView()
                .tabItem {
                    Label("AI 医生", systemImage: "stethoscope")
                }
            RemindersHomeView()
                .tabItem {
                    Label("提醒", systemImage: "bell.fill")
                }
            ExploreHomeView()
                .tabItem {
                    Label("探索", systemImage: "book.fill")
                }
        }
        .tint(Theme.primary)
    }
}

#Preview {
    MainTabView()
}
