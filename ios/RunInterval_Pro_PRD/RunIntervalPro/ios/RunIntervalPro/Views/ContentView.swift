import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .presets

    enum Tab: String {
        case presets = "Presets"
        case library = "Library"
        case history = "History"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            PresetsView()
                .tabItem {
                    Label("Presets", systemImage: "bolt.fill")
                }
                .tag(Tab.presets)

            WorkoutLibraryView()
                .tabItem {
                    Label("Library", systemImage: "folder.fill")
                }
                .tag(Tab.library)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar.fill")
                }
                .tag(Tab.history)
        }
        .tint(Color(hex: "FF6B35"))
    }
}

#Preview {
    ContentView()
}
