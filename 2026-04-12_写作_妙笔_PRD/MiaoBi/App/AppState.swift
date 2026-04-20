import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User? = nil
    @Published var selectedTab: Tab = .write
    @Published var todayWordCount: Int = 0
    @Published var dailyGoal: Int = 1000

    enum Tab: Int {
        case write = 0
        case discover = 1
        case mine = 2
    }

    var goalProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(todayWordCount) / Double(dailyGoal), 1.0)
    }

    init() {
        // Load mock data for demo
        self.isLoggedIn = true
        self.currentUser = User.mock
        self.todayWordCount = 680
    }
}
