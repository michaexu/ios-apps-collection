//
//  Models.swift
//  GreenThumb
//
//  核心数据模型
//

import Foundation
import SwiftUI

// MARK: - Plant Model

struct Plant: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var scientificName: String
    var family: String
    var description: String
    var imageURL: String?
    var localImageName: String?
    var addedDate: Date = Date()
    var healthStatus: HealthStatus = .healthy
    var careInfo: CareInfo
    var diaryEntries: [DiaryEntry] = []
    var tags: [String] = []
    
    enum HealthStatus: String, Codable, CaseIterable {
        case healthy = "健康"
        case needsAttention = "需关注"
        case critical = "有问题"
        
        var color: Color {
            switch self {
            case .healthy: return .green
            case .needsAttention: return .yellow
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .healthy: return "checkmark.circle.fill"
            case .needsAttention: return "exclamationmark.circle.fill"
            case .critical: return "xmark.circle.fill"
            }
        }
    }
}

// MARK: - Care Info

struct CareInfo: Codable, Hashable {
    var wateringFrequencyDays: Int       // 浇水间隔天数
    var sunlightRequirement: SunlightLevel
    var temperatureMin: Int              // 最低温度 °C
    var temperatureMax: Int              // 最高温度 °C
    var humidityLevel: HumidityLevel
    var soilType: String
    var fertilizingFrequencyDays: Int    // 施肥间隔天数
    var lastWatered: Date?
    var lastFertilized: Date?
    var lastRepotted: Date?
    var nextWateringDate: Date?
    var nextFertilizingDate: Date?
    
    enum SunlightLevel: String, Codable, CaseIterable {
        case fullSun = "全日照"
        case partialSun = "半日照"
        case shade = "耐阴"
        case indirectLight = "散射光"
    }
    
    enum HumidityLevel: String, Codable, CaseIterable {
        case low = "低湿度"
        case medium = "中等湿度"
        case high = "高湿度"
    }
}

// MARK: - Care Task

struct CareTask: Identifiable, Codable {
    var id: UUID = UUID()
    var plantId: UUID
    var plantName: String
    var taskType: TaskType
    var dueDate: Date
    var isCompleted: Bool = false
    var completedDate: Date?
    var isSkipped: Bool = false
    var notes: String = ""
    
    enum TaskType: String, Codable, CaseIterable {
        case watering = "浇水"
        case fertilizing = "施肥"
        case repotting = "换盆"
        case pruning = "修剪"
        case pestControl = "病虫防治"
        case observation = "观察记录"
        
        var icon: String {
            switch self {
            case .watering: return "drop.fill"
            case .fertilizing: return "sparkles"
            case .repotting: return "arrow.up.circle.fill"
            case .pruning: return "scissors"
            case .pestControl: return "shield.fill"
            case .observation: return "eye.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .watering: return .blue
            case .fertilizing: return .orange
            case .repotting: return .brown
            case .pruning: return .green
            case .pestControl: return .red
            case .observation: return .purple
            }
        }
    }
}

// MARK: - Diary Entry

struct DiaryEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var content: String
    var imageURLs: [String] = []
    var mood: Mood = .happy
    
    enum Mood: String, Codable, CaseIterable {
        case happy = "😊"
        case neutral = "😐"
        case worried = "😟"
        case excited = "🎉"
    }
}

// MARK: - Encyclopedia Entry

struct EncyclopediaEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var scientificName: String
    var family: String
    var origin: String
    var description: String
    var careInfo: CareInfo
    var floweringSeason: String
    var propagationMethods: [String]
    var commonProblems: [CommonProblem]
    var tags: [String]
    var imageName: String?
    
    struct CommonProblem: Identifiable, Codable {
        var id: UUID = UUID()
        var symptom: String
        var cause: String
        var solution: String
    }
}

// MARK: - Disease Diagnosis

struct DiagnosisResult: Identifiable {
    var id: UUID = UUID()
    var diseaseName: String
    var confidence: Double
    var severity: Severity
    var description: String
    var causes: [String]
    var treatmentSteps: [String]
    var preventionTips: [String]
    
    enum Severity: String, CaseIterable {
        case mild = "轻度"
        case moderate = "中度"
        case severe = "重度"
        
        var color: Color {
            switch self {
            case .mild: return .yellow
            case .moderate: return .orange
            case .severe: return .red
            }
        }
    }
}

// MARK: - Community Post

struct CommunityPost: Identifiable, Codable {
    var id: UUID = UUID()
    var authorName: String
    var authorAvatar: String?
    var plantName: String
    var content: String
    var imageURLs: [String] = []
    var likes: Int = 0
    var comments: Int = 0
    var isLiked: Bool = false
    var createdAt: Date = Date()
    var tags: [String] = []
}

// MARK: - User Profile

struct UserProfile: Codable {
    var id: UUID = UUID()
    var name: String = "园艺爱好者"
    var avatar: String?
    var bio: String = ""
    var location: String = ""
    var joinDate: Date = Date()
    var plantCount: Int = 0
    var diaryCount: Int = 0
    var followersCount: Int = 0
    var followingCount: Int = 0
    var isMember: Bool = false
    var memberExpireDate: Date?
    var badges: [Badge] = []
    
    struct Badge: Identifiable, Codable {
        var id: UUID = UUID()
        var name: String
        var icon: String
        var description: String
        var earnedDate: Date
    }
}

// MARK: - Identification Result

struct IdentificationResult: Identifiable {
    var id: UUID = UUID()
    var plantName: String
    var scientificName: String
    var confidence: Double
    var description: String
    var careInfo: CareInfo
    var alternativeResults: [AlternativeResult]
    
    struct AlternativeResult: Identifiable {
        var id: UUID = UUID()
        var plantName: String
        var confidence: Double
    }
}
