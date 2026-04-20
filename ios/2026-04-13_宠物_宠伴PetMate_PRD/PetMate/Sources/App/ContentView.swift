//
//  ContentView.swift
//  PetMate
//
//  主界面 - 底部 Tab 导航
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @EnvironmentObject var petViewModel: PetViewModel

    enum Tab: String, CaseIterable {
        case home = "首页"
        case health = "健康"
        case services = "服务"
        case community = "社区"
        case profile = "我的"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .health: return "heart.fill"
            case .services: return "pawprint.fill"
            case .community: return "bubble.left.and.bubble.right.fill"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            HealthView()
                .tabItem {
                    Label(Tab.health.rawValue, systemImage: Tab.health.icon)
                }
                .tag(Tab.health)

            ServicesView()
                .tabItem {
                    Label(Tab.services.rawValue, systemImage: Tab.services.icon)
                }
                .tag(Tab.services)

            CommunityView()
                .tabItem {
                    Label(Tab.community.rawValue, systemImage: Tab.community.icon)
                }
                .tag(Tab.community)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .tint(Color(hex: "FF6B35"))
        .onAppear {
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - 颜色扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(PetViewModel())
        .environmentObject(HealthViewModel())
}
