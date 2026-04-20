import SwiftUI
import SwiftData
import UserNotifications

struct RemindersHomeView: View {
    @Query(sort: \Plant.nickname) private var plants: [Plant]

    @State private var monthAnchor: Date = Date()
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var showAuthAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("通知权限") {
                    LabeledContent("状态") {
                        Text(authDescription)
                    }
                    Button("请求通知权限并安排每日 8:00 提醒") {
                        Task { await requestAuthAndSchedule() }
                    }
                    Text("本地 MVP：每日汇总一次待浇水数量，不涉及网络天气。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("今日待办") {
                    let due = plantsDueToday
                    if due.isEmpty {
                        Text("今日暂无必须完成的浇水任务")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(due) { plant in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plant.nickname).font(.headline)
                                if let d = plant.nextWateringAt {
                                    Text("计划：\(d.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("雨天（本地）") {
                    Button("将所有植物的「下次浇水」统一推迟 1 天") {
                        for p in plants {
                            CareScheduling.applyRainDefer(plant: p, days: 1)
                        }
                        Task { await rescheduleSummary() }
                    }
                }

                Section("养护日历（简化）") {
                    MonthStrip(month: monthAnchor, plants: plants)
                    HStack {
                        Button {
                            monthAnchor = Calendar.current.date(byAdding: .month, value: -1, to: monthAnchor) ?? monthAnchor
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        Spacer()
                        Text(monthAnchor.formatted(.dateTime.month(.wide).year()))
                            .font(.headline)
                        Spacer()
                        Button {
                            monthAnchor = Calendar.current.date(byAdding: .month, value: 1, to: monthAnchor) ?? monthAnchor
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("提醒")
            .task { await refreshAuth() }
            .alert("需要通知权限", isPresented: $showAuthAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("请在系统设置中开启通知，以接收每日养护提醒。")
            }
        }
    }

    private var plantsDueToday: [Plant] {
        plants.filter { CareScheduling.isDueToday($0.nextWateringAt) || CareScheduling.isOverdue($0.nextWateringAt) }
    }

    private var authDescription: String {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return "已授权"
        case .denied: return "已拒绝"
        case .notDetermined: return "未请求"
        @unknown default: return "未知"
        }
    }

    private func refreshAuth() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authStatus = settings.authorizationStatus
    }

    private func requestAuthAndSchedule() async {
        let ok = await NotificationScheduler.requestAuthorizationIfNeeded()
        await refreshAuth()
        if !ok {
            showAuthAlert = true
            return
        }
        await rescheduleSummary()
    }

    private func rescheduleSummary() async {
        let count = plants.filter { CareScheduling.isDueToday($0.nextWateringAt) }.count
        await NotificationScheduler.scheduleMorningSummary(plantsNeedingWater: count)
    }
}

private struct MonthStrip: View {
    let month: Date
    let plants: [Plant]

    var body: some View {
        let days = daysInMonthGrid()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { w in
                Text(w).font(.caption2).foregroundStyle(.secondary)
            }
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    let has = hasTask(on: day)
                    Text("\(Calendar.current.component(.day, from: day))")
                        .font(.caption)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(
                            Circle()
                                .fill(has ? Theme.primary.opacity(0.2) : Color.clear)
                        )
                } else {
                    Color.clear.frame(height: 28)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func hasTask(on day: Date) -> Bool {
        let cal = Calendar.current
        return plants.contains { plant in
            if let w = plant.nextWateringAt, cal.isDate(w, inSameDayAs: day) { return true }
            if let f = plant.nextFertilizerAt, cal.isDate(f, inSameDayAs: day) { return true }
            return false
        }
    }

    private func daysInMonthGrid() -> [Date?] {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: month) ?? 1..<31
        let comps = cal.dateComponents([.year, .month], from: month)
        guard let first = cal.date(from: comps) else { return [] }
        let weekday = cal.component(.weekday, from: first)
        let leading = (weekday + 6) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for d in range {
            if let date = cal.date(byAdding: .day, value: d - 1, to: first) {
                cells.append(date)
            }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}
