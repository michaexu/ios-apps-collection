import SwiftUI

@main
struct YingmenApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject private var analysisViewModel = AnalysisViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(accountViewModel)
                .environmentObject(analysisViewModel)
                .preferredColorScheme(.light)
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var isOnboardingCompleted: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingCompleted, forKey: "isOnboardingCompleted")
        }
    }
    @Published var currentUserId: String?
    @Published var familyMembers: [FamilyMember] = []
    @Published var riskProfile: RiskProfile?

    init() {
        self.isOnboardingCompleted = UserDefaults.standard.bool(forKey: "isOnboardingCompleted")
        self.currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        loadFamilyMembers()
        loadRiskProfile()
    }

    func completeOnboarding(riskAnswers: [RiskAnswer]) {
        let profile = RiskProfile.calculate(from: riskAnswers)
        self.riskProfile = profile
        UserDefaults.standard.set(profile.rawValue, forKey: "riskProfile")
        self.isOnboardingCompleted = true
    }

    func loadFamilyMembers() {
        if let data = UserDefaults.standard.data(forKey: "familyMembers"),
           let members = try? JSONDecoder().decode([FamilyMember].self, from: data) {
            self.familyMembers = members
        }
    }

    func saveFamilyMembers() {
        if let data = try? JSONEncoder().encode(familyMembers) {
            UserDefaults.standard.set(data, forKey: "familyMembers")
        }
    }

    func loadRiskProfile() {
        if let value = UserDefaults.standard.object(forKey: "riskProfile") as? Int,
           let profile = RiskProfile(rawValue: value) {
            self.riskProfile = profile
        }
    }
}

struct FamilyMember: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var phone: String
    var role: FamilyRole
    var joinedAt: Date
    var isOwner: Bool

    init(id: UUID = UUID(), name: String, phone: String, role: FamilyRole, joinedAt: Date = Date(), isOwner: Bool = false) {
        self.id = id
        self.name = name
        self.phone = phone
        self.role = role
        self.joinedAt = joinedAt
        self.isOwner = isOwner
    }
}

enum FamilyRole: String, Codable, CaseIterable {
    case owner = "户主"
    case spouse = "配偶"
    case child = "子女"
    case other = "其他"
}

struct RiskAnswer: Identifiable {
    let id: Int
    let questionId: String
    var selectedOption: Int
}

enum RiskProfile: Int, CaseIterable {
    case conservative = 1
    case moderateConservative = 2
    case moderate = 3
    case moderateAggressive = 4
    case aggressive = 5

    var displayName: String {
        switch self {
        case .conservative: return "保守型"
        case .moderateConservative: return "稳健型"
        case .moderate: return "平衡型"
        case .moderateAggressive: return "进取型"
        case .aggressive: return "激进型"
        }
    }

    var description: String {
        switch self {
        case .conservative:
            return "您偏好低风险资产，本金安全是首要考量，适合存款、国债等稳健产品。"
        case .moderateConservative:
            return "您希望在保持本金安全的前提下适度参与市场波动，配置以固收为主。"
        case .moderate:
            return "您接受适度的风险，追求收益与风险的平衡，股债均衡配置。"
        case .moderateAggressive:
            return "您愿意承受较高波动以换取更高潜在收益，权益类资产占比较高。"
        case .aggressive:
            return "您追求最大化收益，可承受较大市值波动，以权益资产为核心配置。"
        }
    }

    var color: Color {
        switch self {
        case .conservative: return Color(hex: "2ECC71")
        case .moderateConservative: return Color(hex: "27AE60")
        case .moderate: return Color(hex: "3498DB")
        case .moderateAggressive: return Color(hex: "E67E22")
        case .aggressive: return Color(hex: "E74C3C")
        }
    }

    static func calculate(from answers: [RiskAnswer]) -> RiskProfile {
        guard !answers.isEmpty else { return .moderate }
        let total = answers.reduce(0) { $0 + $1.selectedOption }
        let average = Double(total) / Double(answers.count)
        if average <= 1.5 { return .conservative }
        if average <= 2.5 { return .moderateConservative }
        if average <= 3.5 { return .moderate }
        if average <= 4.5 { return .moderateAggressive }
        return .aggressive
    }
}

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
