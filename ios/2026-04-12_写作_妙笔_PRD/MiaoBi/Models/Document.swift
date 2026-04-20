import Foundation

struct Document: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var folderId: UUID?
    var tags: [String]
    var createdAt: Date
    var modifiedAt: Date
    var wordCount: Int
    var status: DocumentStatus
    var isPinned: Bool
    var isPublished: Bool
    var publishPrivacy: PrivacyLevel

    enum DocumentStatus: String, Codable, CaseIterable {
        case draft = "草稿"
        case completed = "已完成"
        case archived = "已归档"
    }

    enum PrivacyLevel: String, Codable, CaseIterable {
        case privateOnly = "仅自己"
        case friendsOnly = "好友可见"
        case publicAll = "公开"
    }

    var readingTime: Int {
        max(wordCount / 400, 1)
    }

    mutating func updateWordCount() {
        wordCount = content.count
    }

    static let mockDocuments: [Document] = [
        Document(
            id: UUID(),
            title: "春天的故事",
            content: "春天来了，万物复苏。这是一个关于成长的故事...",
            folderId: nil,
            tags: ["散文", "随笔"],
            createdAt: Date().addingTimeInterval(-86400 * 2),
            modifiedAt: Date().addingTimeInterval(-3600),
            wordCount: 1234,
            status: .draft,
            isPinned: true,
            isPublished: false,
            publishPrivacy: .privateOnly
        ),
        Document(
            id: UUID(),
            title: "产品需求文档 v2.0",
            content: "## 项目背景\n\n本次需求围绕用户增长展开...",
            folderId: nil,
            tags: ["工作", "产品"],
            createdAt: Date().addingTimeInterval(-86400 * 5),
            modifiedAt: Date().addingTimeInterval(-86400),
            wordCount: 4567,
            status: .completed,
            isPinned: false,
            isPublished: false,
            publishPrivacy: .privateOnly
        ),
        Document(
            id: UUID(),
            title: "读《活着》有感",
            content: "余华的《活着》讲述了一个农民福贵的人生故事...",
            folderId: nil,
            tags: ["书评", "读书笔记"],
            createdAt: Date().addingTimeInterval(-86400 * 10),
            modifiedAt: Date().addingTimeInterval(-86400 * 3),
            wordCount: 2890,
            status: .draft,
            isPinned: false,
            isPublished: true,
            publishPrivacy: .publicAll
        )
    ]
}
