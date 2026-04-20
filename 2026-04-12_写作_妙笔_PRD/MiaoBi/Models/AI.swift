import Foundation

struct AIWritingSuggestion: Identifiable, Equatable {
    let id: UUID
    let type: AIFunctionType
    let text: String
    let reason: String?
    let confidence: Double

    enum AIFunctionType: String, CaseIterable {
        case continueWrite = "续写"
        case inspiration = "灵感"
        case grammarFix = "语法纠错"
        case polish = "润色"
        case structure = "结构建议"
        case translate = "翻译"
        case sensitiveWord = "敏感词"
    }
}

struct SensitiveWordResult: Identifiable, Equatable {
    let id: UUID
    let word: String
    let range: Range<String.Index>
    let severity: Severity
    let alternatives: [String]

    enum Severity: String {
        case low = "低"
        case medium = "中"
        case high = "高"
    }
}

struct AIDailyUsage: Codable {
    var date: Date
    var continueWriteCount: Int
    var polishCount: Int
    var grammarFixCount: Int
    var inspirationCount: Int
    var translateCount: Int

    var totalUsed: Int {
        continueWriteCount + polishCount + grammarFixCount + inspirationCount + translateCount
    }

    static let freeLimit = 5

    var remaining: Int {
        max(Self.freeLimit - totalUsed, 0)
    }
}

enum PolishStyle: String, CaseIterable {
    case formal = "正式"
    case casual = "轻松"
    case literary = "文艺"
    var icon: String {
        switch self {
        case .formal: return "building.2"
        case .casual: return "face.smiling"
        case .literary: return "moon.stars"
        }
    }
}
