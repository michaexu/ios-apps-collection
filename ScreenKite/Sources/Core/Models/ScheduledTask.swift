import Foundation

// MARK: - ScheduledTask

/// 定时任务模型
struct ScheduledTask: Codable, Identifiable, Equatable {
    let id: UUID

    /// 任务名称（用户可见）
    var name: String

    /// 触发类型
    var triggerType: TriggerType

    /// 计划触发时间（一次性任务使用）
    var scheduledDate: Date

    /// 重复天数（仅 weekly 类型，1=周一 ... 7=周日）
    var repeatDays: [Int]?

    /// 录制配置
    var recordingConfig: RecordingConfig

    /// 录制最大时长（秒），nil=无限制
    var durationLimit: TimeInterval?

    /// 是否启用
    var isEnabled: Bool

    /// 创建时间
    let createdAt: Date

    /// 上次触发时间
    var lastTriggeredAt: Date?

    /// 备注
    var note: String?

    init(
        id: UUID = UUID(),
        name: String,
        triggerType: TriggerType,
        scheduledDate: Date,
        repeatDays: [Int]? = nil,
        recordingConfig: RecordingConfig,
        durationLimit: TimeInterval? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        lastTriggeredAt: Date? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.triggerType = triggerType
        self.scheduledDate = scheduledDate
        self.repeatDays = repeatDays
        self.recordingConfig = recordingConfig
        self.durationLimit = durationLimit
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.lastTriggeredAt = lastTriggeredAt
        self.note = note
    }

    /// 计算下次触发时间
    /// - Parameter fromDate: 基准时间，默认为当前时间
    /// - Returns: 下次触发时间（若已过期且无重复则返回 nil）
    func nextTriggerDate(fromDate: Date = Date()) -> Date? {
        switch triggerType {
        case .once:
            // 一次性任务：若未过期则返回 scheduledDate
            return scheduledDate > fromDate ? scheduledDate : nil

        case .daily:
            // 每日任务：找到当天还未触发的时间点
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current

            let nowComponents = calendar.dateComponents([.year, .month, .day], from: fromDate)
            let scheduledComponents = calendar.dateComponents([.hour, .minute], from: scheduledDate)

            var targetComponents = nowComponents
            targetComponents.hour = scheduledComponents.hour
            targetComponents.minute = scheduledComponents.minute
            targetComponents.second = 0

            guard let targetDate = calendar.date(from: targetComponents) else { return nil }

            // 若今天时间已过，则加一天
            return targetDate > fromDate ? targetDate : calendar.date(byAdding: .day, value: 1, to: targetDate)

        case .weekly:
            guard let days = repeatDays, !days.isEmpty else { return nil }
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current

            let scheduledComponents = calendar.dateComponents([.hour, .minute], from: scheduledDate)
            let fromWeekday = calendar.component(.weekday, from: fromDate) // 1=周日, 2=周一

            // 找到下一个匹配的日子
            for offset in 0..<8 {
                guard let candidateDate = calendar.date(byAdding: .day, value: offset, to: fromDate) else { continue }
                let candidateWeekday = calendar.component(.weekday, from: candidateDate)
                // calendar.weekday: 1=周日, 2=周一 ... 7=周六
                // repeatDays: 1=周一 ... 7=周日
                // 转换: candidateWeekday=2 -> 周一 -> repeatDays 包含 1
                let mappedWeekday = candidateWeekday == 1 ? 7 : candidateWeekday - 1

                if days.contains(mappedWeekday) {
                    var targetComponents = calendar.dateComponents([.year, .month, .day], from: candidateDate)
                    targetComponents.hour = scheduledComponents.hour
                    targetComponents.minute = scheduledComponents.minute
                    targetComponents.second = 0

                    guard let result = calendar.date(from: targetComponents) else { continue }
                    // 如果恰好是今天，检查时间是否已过
                    if offset == 0 && result <= fromDate {
                        continue
                    }
                    return result
                }
            }
            return nil
        }
    }
}

// MARK: - TriggerType

/// 触发类型
enum TriggerType: String, Codable, CaseIterable {
    /// 一次性触发
    case once
    /// 每日重复
    case daily
    /// 每周重复
    case weekly

    var displayName: String {
        switch self {
        case .once:  return "仅一次"
        case .daily: return "每日"
        case .weekly: return "每周"
        }
    }

    var description: String {
        switch self {
        case .once:  return "在指定时间触发一次后自动删除"
        case .daily: return "每天在指定时间自动触发"
        case .weekly: return "在指定日期的指定时间自动触发"
        }
    }
}

// MARK: - SchedulerError

/// 调度错误类型
enum SchedulerError: Error, LocalizedError {
    case taskNotFound(UUID)
    case taskExpired
    case storageFailed(underlying: Error)
    case invalidConfiguration(String)
    case alreadyScheduled(UUID)
    case recordingEngineUnavailable

    var errorDescription: String? {
        switch self {
        case .taskNotFound(let id):
            return "未找到定时任务: \(id.uuidString)"
        case .taskExpired:
            return "该任务已过期（一次性任务）"
        case .storageFailed(let err):
            return "存储失败: \(err.localizedDescription)"
        case .invalidConfiguration(let msg):
            return "配置无效: \(msg)"
        case .alreadyScheduled(let id):
            return "任务已存在: \(id.uuidString)"
        case .recordingEngineUnavailable:
            return "录制引擎不可用"
        }
    }
}
