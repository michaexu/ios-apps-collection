import Foundation

enum CareScheduling {
    /// 基于上次浇水时间计算下次浇水；若从未浇水则以 `reference` 为起点。
    static func nextWateringDate(
        from reference: Date,
        lastWatered: Date?,
        intervalDays: Int
    ) -> Date {
        let calendar = Calendar.current
        let base = lastWatered ?? reference
        let interval = max(1, intervalDays)
        return calendar.date(byAdding: .day, value: interval, to: base) ?? reference
    }

    static func nextFertilizerDate(from reference: Date, lastFertilized: Date?, intervalDays: Int) -> Date? {
        let calendar = Calendar.current
        let base = lastFertilized ?? reference
        return calendar.date(byAdding: .day, value: max(1, intervalDays), to: base)
    }

    static func applyWatered(plant: Plant, at date: Date = Date()) {
        plant.lastWateredAt = date
        plant.nextWateringAt = nextWateringDate(
            from: date,
            lastWatered: date,
            intervalDays: plant.wateringIntervalDays
        )
    }

    /// 将「下次浇水」日期顺延（用于本地雨天推迟，不改上次浇水记录）。
    static func rainDeferredNext(previousNext: Date?, days: Int = 1) -> Date {
        let calendar = Calendar.current
        let base = previousNext ?? Date()
        return calendar.date(byAdding: .day, value: max(1, days), to: base) ?? base
    }

    /// 本地「雨天推迟」：将当前计划的下次浇水整体顺延（不改上次浇水记录）。
    static func applyRainDefer(plant: Plant, days: Int = 1) {
        plant.nextWateringAt = rainDeferredNext(previousNext: plant.nextWateringAt, days: days)
    }

    static func applyFertilized(plant: Plant, at date: Date = Date()) {
        plant.lastFertilizedAt = date
        plant.nextFertilizerAt = nextFertilizerDate(
            from: date,
            lastFertilized: date,
            intervalDays: plant.fertilizerIntervalDays
        )
    }

    static func isDueToday(_ date: Date?, calendar: Calendar = .current, reference: Date = Date()) -> Bool {
        guard let date else { return false }
        return calendar.isDate(date, inSameDayAs: reference)
    }

    static func isOverdue(_ date: Date?, reference: Date = Date()) -> Bool {
        guard let date else { return false }
        return date < reference && !Calendar.current.isDate(date, inSameDayAs: reference)
    }
}
