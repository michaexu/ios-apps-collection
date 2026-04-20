import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            InspirationWallView()
                .tabItem {
                    Label("灵感墙", systemImage: "lightbulb")
                }
                .tag(0)

            ProjectBoardView()
                .tabItem {
                    Label("项目看板", systemImage: "rectangle.3.group")
                }
                .tag(1)

            MaterialLibraryView()
                .tabItem {
                    Label("材料库", systemImage: "shippingbox")
                }
                .tag(2)

            CostEngineView()
                .tabItem {
                    Label("成本引擎", systemImage: "chart.bar.xaxis")
                }
                .tag(3)

            PortfolioView()
                .tabItem {
                    Label("作品集", systemImage: "photo.on.rectangle.angled")
                }
                .tag(4)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.circle")
                }
                .tag(5)
        }
        .tint(Color.accent)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
