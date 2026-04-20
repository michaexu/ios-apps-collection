import SwiftUI
import WatchKit

struct WatchContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchPresetsView()
                .tag(0)

            WatchLibraryView()
                .tag(1)
        }
    }
}

#Preview {
    WatchContentView()
}
