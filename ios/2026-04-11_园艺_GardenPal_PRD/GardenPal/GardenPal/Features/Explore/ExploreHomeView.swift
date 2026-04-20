import SwiftUI

struct ExploreHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("植物百科（本地 JSON）") {
                    NavigationLink {
                        EncyclopediaView()
                    } label: {
                        Label("浏览百科", systemImage: "leaf.circle")
                    }
                }

                Section("阳台规划（规则推荐）") {
                    NavigationLink {
                        BalconyPlannerView()
                    } label: {
                        Label("规划助手", systemImage: "square.grid.3x3")
                    }
                }

                Section("关于") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("本地模式说明", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("探索")
        }
    }
}
