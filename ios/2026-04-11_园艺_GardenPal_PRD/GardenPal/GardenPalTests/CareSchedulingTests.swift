import XCTest
@testable import GardenPal

final class CareSchedulingTests: XCTestCase {
    func testNextWateringFromLastWatered() throws {
        let cal = Calendar(identifier: .gregorian)
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 4
        comps.day = 1
        let last = try XCTUnwrap(cal.date(from: comps))
        let next = CareScheduling.nextWateringDate(from: last, lastWatered: last, intervalDays: 4)
        comps.day = 5
        let expected = try XCTUnwrap(cal.date(from: comps))
        XCTAssertEqual(cal.startOfDay(for: next), cal.startOfDay(for: expected))
    }

    func testRainDeferredNext() throws {
        let cal = Calendar(identifier: .gregorian)
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 4
        comps.day = 10
        let nextBefore = try XCTUnwrap(cal.date(from: comps))
        let deferred = CareScheduling.rainDeferredNext(previousNext: nextBefore, days: 1)
        let expected = try XCTUnwrap(cal.date(byAdding: .day, value: 1, to: nextBefore))
        XCTAssertEqual(cal.startOfDay(for: deferred), cal.startOfDay(for: expected))
    }

    func testIsDueToday() throws {
        let cal = Calendar.current
        let today = Date()
        XCTAssertTrue(CareScheduling.isDueToday(today, calendar: cal, reference: today))
        let tomorrow = try XCTUnwrap(cal.date(byAdding: .day, value: 1, to: today))
        XCTAssertFalse(CareScheduling.isDueToday(tomorrow, calendar: cal, reference: today))
    }
}
