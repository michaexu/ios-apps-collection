import SwiftUI

// MARK: - AppState
class AppState: ObservableObject {
    @Published var isFirstLaunch: Bool
    @Published var currentTab: Tab = .home
    @Published var showSOSAlert: Bool = false
    @Published var isSOSActive: Bool = false

    enum Tab: Int {
        case home = 0
        case familyCircle = 1
        case sameAgeCircle = 2
        case health = 3
    }

    init() {
        self.isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunched")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunched")
        }
    }
}

// MARK: - User
struct User: Identifiable, Codable {
    let id: String
    var name: String
    var avatar: String
    var age: Int
    var phone: String
    var familyCode: String

    static let mock = User(
        id: "u001",
        name: "张大爷",
        avatar: "person.circle.fill",
        age: 68,
        phone: "138****1234",
        familyCode: "ABC123"
    )
}

// MARK: - Medication
struct Medication: Identifiable, Codable {
    let id: String
    var name: String
    var dosage: String
    var unit: String
    var times: [Date]
    var remainingDays: Int
    var isTaken: Bool = false

    var nextTime: Date? {
        times.sorted().first { $0 > Date() }
    }
}

// MARK: - HealthRecord
struct HealthRecord: Identifiable, Codable {
    let id: String
    var date: Date
    var bloodPressureSystolic: Int?
    var bloodPressureDiastolic: Int?
    var heartRate: Int?
    var bloodSugar: Double?
    var weight: Double?
    var note: String

    var hasData: Bool {
        bloodPressureSystolic != nil || heartRate != nil || bloodSugar != nil || weight != nil
    }
}

// MARK: - FamilyMember
struct FamilyMember: Identifiable, Codable {
    let id: String
    var name: String
    var avatar: String
    var relationship: String
    var isOnline: Bool
    var lastActive: Date?

    static let mockFamily: [FamilyMember] = [
        FamilyMember(id: "f001", name: "儿子 小张", avatar: "person.circle.fill", relationship: "儿子", isOnline: true, lastActive: Date()),
        FamilyMember(id: "f002", name: "女儿 小李", avatar: "person.circle.fill", relationship: "女儿", isOnline: false, lastActive: Date().addingTimeInterval(-3600)),
        FamilyMember(id: "f003", name: "老伴", avatar: "person.circle.fill", relationship: "老伴", isOnline: true, lastActive: Date())
    ]
}

// MARK: - ChatMessage
struct ChatMessage: Identifiable, Codable {
    let id: String
    var senderId: String
    var senderName: String
    var content: String
    var type: MessageType
    var timestamp: Date
    var isRead: Bool

    enum MessageType: String, Codable {
        case text
        case image
        case voice
        case location
    }

    static let mockMessages: [ChatMessage] = [
        ChatMessage(id: "m001", senderId: "f001", senderName: "儿子 小张", content: "爸，今天记得按时吃药！", type: .text, timestamp: Date().addingTimeInterval(-3600), isRead: true),
        ChatMessage(id: "m002", senderId: "f002", senderName: "女儿 小李", content: "👍", type: .text, timestamp: Date().addingTimeInterval(-3000), isRead: true),
        ChatMessage(id: "m003", senderId: "f001", senderName: "儿子 小张", content: "周末我带全家回去看您！", type: .text, timestamp: Date().addingTimeInterval(-1800), isRead: false)
    ]
}

// MARK: - Post
struct Post: Identifiable, Codable {
    let id: String
    var authorId: String
    var authorName: String
    var authorAvatar: String
    var content: String
    var imageUrls: [String]
    var topic: String?
    var likeCount: Int
    var commentCount: Int
    var isLiked: Bool
    var timestamp: Date

    static let mockPosts: [Post] = [
        Post(id: "p001", authorId: "u002", authorName: "王阿姨", authorAvatar: "person.circle.fill", content: "今天天气真好，和老姐妹们去公园跳舞了！💃", imageUrls: [], topic: "今天最开心的事", likeCount: 23, commentCount: 5, isLiked: false, timestamp: Date().addingTimeInterval(-7200)),
        Post(id: "p002", authorId: "u003", authorName: "李大爷", authorAvatar: "person.circle.fill", content: "分享一道我的拿手菜——红烧肉！", imageUrls: [], topic: "分享一道拿手菜", likeCount: 45, commentCount: 12, isLiked: true, timestamp: Date().addingTimeInterval(-14400))
    ]
}

// MARK: - Comment
struct Comment: Identifiable, Codable {
    let id: String
    var postId: String
    var authorId: String
    var authorName: String
    var content: String
    var timestamp: Date
}

// MARK: - InterestGroup
struct InterestGroup: Identifiable {
    let id: String
    var name: String
    var icon: String
    var memberCount: Int
    var isJoined: Bool

    static let groups: [InterestGroup] = [
        InterestGroup(id: "g001", name: "广场舞", icon: "figure.dance", memberCount: 1234, isJoined: true),
        InterestGroup(id: "g002", name: "书法", icon: "paintbrush", memberCount: 876, isJoined: false),
        InterestGroup(id: "g003", name: "钓鱼", icon: "fish", memberCount: 543, isJoined: false),
        InterestGroup(id: "g004", name: "园艺", icon: "leaf", memberCount: 321, isJoined: false),
        InterestGroup(id: "g005", name: "棋牌", icon: "square.grid.2x2", memberCount: 2100, isJoined: true),
        InterestGroup(id: "g006", name: "太极拳", icon: "figure.mind.and.body", memberCount: 654, isJoined: false)
    ]
}

// MARK: - SOSRecord
struct SOSRecord: Identifiable, Codable {
    let id: String
    var timestamp: Date
    var type: SOSType
    var location: String
    var status: SOSStatus

    enum SOSType: String, Codable {
        case shake
        case longPress
        case fall
    }

    enum SOSStatus: String, Codable {
        case sent
        case acknowledged
        case resolved
    }
}

// MARK: - Reminder
struct Reminder: Identifiable, Codable {
    let id: String
    var title: String
    var time: Date
    var type: ReminderType
    var isCompleted: Bool

    enum ReminderType: String, Codable {
        case medication
        case appointment
        case exercise
        case custom
    }
}

// MARK: - Weather
struct Weather: Codable {
    var city: String
    var temperature: Int
    var condition: String
    var icon: String
    var humidity: Int
    var windSpeed: Int
    var advice: String

    static let mock = Weather(
        city: "北京",
        temperature: 22,
        condition: "晴",
        icon: "sun.max.fill",
        humidity: 45,
        windSpeed: 3,
        advice: "今天天气很好，适合外出散步，记得多喝水！"
    )
}

// MARK: - HealthSummary
struct HealthSummary: Codable {
    var steps: Int
    var heartRate: Int?
    var sleepHours: Double
    var calories: Int
}

// MARK: - Color Extension
extension Color {
    static let primaryOrange = Color(hex: "F5A623")
    static let primaryBlue = Color(hex: "1A5276")
    static let backgroundGray = Color(hex: "F5F5F5")
    static let sosRed = Color(hex: "E74C3C")
    static let safeGreen = Color(hex: "27AE60")
    static let warmGray = Color(hex: "7F8C8D")
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
            (a, r, g, b) = (1, 1, 1, 0)
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
