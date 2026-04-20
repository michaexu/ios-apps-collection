import Foundation

struct Folder: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var parentId: UUID?
    var createdAt: Date
    var documentCount: Int
    var color: String
    var icon: String

    static let mockFolders: [Folder] = [
        Folder(id: UUID(), name: "我的随笔", parentId: nil, createdAt: Date(), documentCount: 5, color: "blue", icon: "book"),
        Folder(id: UUID(), name: "工作文档", parentId: nil, createdAt: Date(), documentCount: 12, color: "green", icon: "briefcase"),
        Folder(id: UUID(), name: "小说", parentId: nil, createdAt: Date(), documentCount: 3, color: "purple", icon: "book.closed"),
        Folder(id: UUID(), name: "读书笔记", parentId: nil, createdAt: Date(), documentCount: 8, color: "orange", icon: "text.book.closed")
    ]
}
