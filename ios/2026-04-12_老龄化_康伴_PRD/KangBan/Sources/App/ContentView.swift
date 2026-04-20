import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "首页"
        case medication = "用药"
        case health = "健康"
        case family = "家属"
        case profile = "我的"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .medication: return "pills.fill"
            case .health: return "heart.fill"
            case .family: return "person.2.fill"
            case .profile: return "person.crop.circle.fill"
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

            MedicationView()
                .tabItem {
                    Label(Tab.medication.rawValue, systemImage: Tab.medication.icon)
                }
                .tag(Tab.medication)

            HealthRecordView()
                .tabItem {
                    Label(Tab.health.rawValue, systemImage: Tab.health.icon)
                }
                .tag(Tab.health)

            FamilyView()
                .tabItem {
                    Label(Tab.family.rawValue, systemImage: Tab.family.icon)
                }
                .tag(Tab.family)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .tint(Color("PrimaryColor"))
        .font(.system(size: 20, weight: .medium))
    }
}

#Preview {
    ContentView()
        .environmentObject(MedicationViewModel())
        .environmentObject(HealthViewModel())
        .environmentObject(FamilyViewModel())
}
