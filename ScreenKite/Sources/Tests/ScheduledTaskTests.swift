import XCTest
@testable import ScreenKite

// MARK: - ScheduledTask Unit Tests

final class ScheduledTaskTests: XCTestCase {

    private var calendar: Calendar?

    override func setUp() {
        super.setUp()
        calendar = Calendar.current
        guard let tz = TimeZone(identifier: "Asia/Shanghai") else { return }; calendar.timeZone = tz
    }

    // MARK: - nextTriggerDate Tests

    func testOnce_triggerInFuture() {
        let futureDate = Date().addingTimeInterval(3600) // 1小时后
        let task = makeTask(triggerType: .once, scheduledDate: futureDate)

        let next = task.nextTriggerDate()

        XCTAssertNotNil(next)
        XCTAssertEqual(next!, futureDate)
    }

    func testOnce_triggerInPast() {
        let pastDate = Date().addingTimeInterval(-3600) // 1小时前
        let task = makeTask(triggerType: .once, scheduledDate: pastDate)

        let next = task.nextTriggerDate()

        XCTAssertNil(next)
    }

    func testDaily_sameTimeTodayInFuture() {
        // 创建一个今天下午 3 点的日期（如果当前还没到）
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 23
        components.minute = 59
        components.second = 0
        guard let todayTarget = calendar.date(from: components) else { return }

        let task = makeTask(triggerType: .daily, scheduledDate: todayTarget)

        let next = task.nextTriggerDate(fromDate: now)

        XCTAssertNotNil(next)
        // 如果当前时间已过今天的目标时间，应该是明天的
        if now >= todayTarget {
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayTarget) else { return }
            XCTAssertEqual(next!, tomorrow, "应返回明天同一时间")
        }
    }

    func testDaily_targetTimeAlreadyPassed() {
        // 创建一个今天早上 6 点的日期（已经过去）
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 6
        components.minute = 0
        components.second = 0
        guard let todayMorning = calendar.date(from: components), todayMorning < now else { return }

        let task = makeTask(triggerType: .daily, scheduledDate: todayMorning)

        let next = task.nextTriggerDate(fromDate: now)

        XCTAssertNotNil(next)
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayMorning) else { return }
        XCTAssertEqual(next!, tomorrow)
    }

    func testWeekly_matchingDayToday() {
        // 今天 + 1小时
        let targetDate = Date().addingTimeInterval(3600)
        let todayWeekday = calendar.component(.weekday, from: targetDate)
        // calendar.weekday: 1=周日, 2=周一 ... 7=周六
        // repeatDays: 1=周一 ... 7=周日
        let mappedWeekday = todayWeekday == 1 ? 7 : todayWeekday - 1

        let task = makeTask(triggerType: .weekly, scheduledDate: targetDate, repeatDays: [mappedWeekday])

        let next = task.nextTriggerDate()

        XCTAssertNotNil(next)
        // 应该返回今天的目标时间（不是明天）
        let nextWeekday = calendar.component(.weekday, from: next!)
        XCTAssertEqual(nextWeekday, todayWeekday)
    }

    func testWeekly_noMatchingDay() {
        let futureDate = Date().addingTimeInterval(3600)
        let todayWeekday = calendar.component(.weekday, from: futureDate)
        let mappedWeekday = todayWeekday == 1 ? 7 : todayWeekday - 1
        // 设置为另一个不匹配的日子
        let otherDay = mappedWeekday == 1 ? 3 : 1

        let task = makeTask(triggerType: .weekly, scheduledDate: futureDate, repeatDays: [otherDay])

        let next = task.nextTriggerDate()

        XCTAssertNotNil(next)
        let nextWeekday = calendar.component(.weekday, from: next!)
        let mappedNext = nextWeekday == 1 ? 7 : nextWeekday - 1
        XCTAssertEqual(mappedNext, otherDay)
    }

    func testDisabledTask_returnsNil() {
        let futureDate = Date().addingTimeInterval(3600)
        var task = makeTask(triggerType: .once, scheduledDate: futureDate)
        task.isEnabled = false

        let next = task.nextTriggerDate()

        XCTAssertNil(next)
    }

    func testWeekly_multipleDays() {
        let futureDate = Date().addingTimeInterval(3600)
        let task = makeTask(triggerType: .weekly, scheduledDate: futureDate, repeatDays: [1, 3, 5])

        let next = task.nextTriggerDate()

        XCTAssertNotNil(next)
        let weekday = calendar.component(.weekday, from: next!)
        let mapped = weekday == 1 ? 7 : weekday - 1
        XCTAssertTrue([1, 3, 5].contains(mapped))
    }

    // MARK: - Helper

    private func makeTask(
        triggerType: TriggerType,
        scheduledDate: Date,
        repeatDays: [Int]? = nil
    ) -> ScheduledTask {
        let config = RecordingConfig(
            captureType: .fullScreen,
            targetWindow: nil,
            captureRect: nil,
            includeSystemAudio: false,
            includeMicrophone: true,
            frameRate: 30,
            outputFormat: .mp4(.h264),
            outputDirectory: FileManager.default.temporaryDirectory
        )
        return ScheduledTask(
            name: "Test Task",
            triggerType: triggerType,
            scheduledDate: scheduledDate,
            repeatDays: repeatDays,
            recordingConfig: config,
            durationLimit: nil,
            isEnabled: true
        )
    }
}
