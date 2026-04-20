import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var nickname: String
    var avatarURL: String?
    var bio: String?
    var joinDate: Date
    var totalWordCount: Int
    var streakDays: Int
    var badges: [Badge]
    var isPro: Bool

    static let mock = User(
        id: UUID(),
        nickname: "写作爱好者",
        avatarURL: nil,
        bio: "热爱用文字记录生活",
        joinDate: Date(),
        totalWordCount: 125800,
        streakDays: 23,
        badges: [.init(name: "首次完篇", icon: "star.fill", color: .yellow, earnedDate: Date())],
        isPro: true
    )
}

struct Badge: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    let earnedDate: Date

    init(name: String, icon: String, color: String, earnedDate: Date) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.earnedDate = earnedDate
    }
}
