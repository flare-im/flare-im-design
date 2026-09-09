import XCTest
@testable import FlareIMUI

final class SearchDateRangeFilterTests: XCTestCase {
    private let cst = 480 // UTC+8, minutes east of UTC
    private let est = -300 // UTC-5

    private func iso(_ ms: Int64?) -> String? {
        guard let ms else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }

    func testDayBoundsAnchorToTheGivenZone() {
        XCTAssertEqual(iso(dayStartMs("2026-03-15", tzOffsetMinutes: 0)), "2026-03-15T00:00:00.000Z")
        XCTAssertEqual(iso(dayEndMs("2026-03-15", tzOffsetMinutes: 0)), "2026-03-15T23:59:59.999Z")
        XCTAssertEqual(iso(dayStartMs("2026-03-15", tzOffsetMinutes: cst)), "2026-03-14T16:00:00.000Z")
        XCTAssertEqual(iso(dayEndMs("2026-03-15", tzOffsetMinutes: cst)), "2026-03-15T15:59:59.999Z")
        XCTAssertEqual(iso(dayStartMs("2026-03-15", tzOffsetMinutes: est)), "2026-03-15T05:00:00.000Z")
        XCTAssertEqual(iso(dayEndMs("2026-03-15", tzOffsetMinutes: est)), "2026-03-16T04:59:59.999Z")
    }

    func testOneInclusiveDayAndBoundaries() {
        for tz in [0, cst, est] {
            XCTAssertEqual(dayEndMs("2026-03-15", tzOffsetMinutes: tz)! - dayStartMs("2026-03-15", tzOffsetMinutes: tz)!,
                           86_399_999, "tz \(tz)")
        }
        XCTAssertEqual(iso(dayStartMs("1970-01-01", tzOffsetMinutes: 0)), "1970-01-01T00:00:00.000Z")
        XCTAssertEqual(iso(dayEndMs("2026-02-28", tzOffsetMinutes: 0)), "2026-02-28T23:59:59.999Z")
        XCTAssertEqual(iso(dayStartMs("2024-02-29", tzOffsetMinutes: 0)), "2024-02-29T00:00:00.000Z")
        XCTAssertEqual(iso(dayEndMs("2026-12-31", tzOffsetMinutes: 0)), "2026-12-31T23:59:59.999Z")
    }

    func testRejectsAnythingThatIsNotARealDate() {
        for bad in ["", "   ", "2026-3-15", "15/03/2026", "2026-13-01", "2026-00-10",
                    "2026-02-30", "2026-04-31", "today"] {
            XCTAssertNil(dayStartMs(bad, tzOffsetMinutes: 0), bad)
            XCTAssertNil(dayEndMs(bad, tzOffsetMinutes: 0), bad)
        }
    }

    func testDeviceZoneIsUsedWithoutAnOffset() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let start = Date(timeIntervalSince1970: Double(dayStartMs("2026-03-15")!) / 1000)
        let end = Date(timeIntervalSince1970: Double(dayEndMs("2026-03-15")!) / 1000)
        let startParts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: start)
        XCTAssertEqual([startParts.year, startParts.month, startParts.day], [2026, 3, 15])
        XCTAssertEqual([startParts.hour, startParts.minute, startParts.second], [0, 0, 0])
        let endParts = calendar.dateComponents([.day, .hour, .minute, .second], from: end)
        XCTAssertEqual([endParts.day, endParts.hour, endParts.minute, endParts.second], [15, 23, 59, 59])
    }

    func testRangeFromDatesCoversTheWholeDayAndSpansMonths() {
        let sameDay = rangeFromDates("2026-03-15", "2026-03-15", tzOffsetMinutes: cst)!
        XCTAssertEqual(iso(sameDay.fromTime), "2026-03-14T16:00:00.000Z")
        XCTAssertEqual(iso(sameDay.toTime), "2026-03-15T15:59:59.999Z")
        let month = rangeFromDates("2026-01-28", "2026-02-03", tzOffsetMinutes: 0)!
        XCTAssertEqual(iso(month.fromTime), "2026-01-28T00:00:00.000Z")
        XCTAssertEqual(iso(month.toTime), "2026-02-03T23:59:59.999Z")
        let year = rangeFromDates("2025-12-30", "2026-01-02", tzOffsetMinutes: cst)!
        XCTAssertEqual(iso(year.fromTime), "2025-12-29T16:00:00.000Z")
        XCTAssertEqual(iso(year.toTime), "2026-01-02T15:59:59.999Z")
    }

    func testOpenEndsAndUnrestricted() {
        let fromOnly = rangeFromDates("2026-03-15", "", tzOffsetMinutes: cst)!
        XCTAssertEqual(fromOnly.fromTime, dayStartMs("2026-03-15", tzOffsetMinutes: cst))
        XCTAssertNil(fromOnly.toTime)
        let toOnly = rangeFromDates("", "2026-03-15", tzOffsetMinutes: cst)!
        XCTAssertNil(toOnly.fromTime)
        XCTAssertEqual(toOnly.toTime, dayEndMs("2026-03-15", tzOffsetMinutes: cst))
        XCTAssertTrue(unrestrictedRange(rangeFromDates("", "", tzOffsetMinutes: cst)!))
    }

    func testRefusesIllegalRanges() {
        XCTAssertNil(rangeFromDates("2026-03-16", "2026-03-15", tzOffsetMinutes: cst))
        XCTAssertNil(rangeFromDates("2027-01-01", "2026-12-31", tzOffsetMinutes: 0))
        XCTAssertNotNil(rangeFromDates("2026-03-15", "2026-03-15", tzOffsetMinutes: cst))
        XCTAssertNil(rangeFromDates("2026-02-30", "2026-03-15", tzOffsetMinutes: 0))
        XCTAssertNil(rangeFromDates("2026-03-15", "tomorrow", tzOffsetMinutes: 0))
        XCTAssertNil(rangeFromDates("1969-12-31", "", tzOffsetMinutes: 0))
        XCTAssertNil(rangeFromDates("", "1969-12-31", tzOffsetMinutes: 0))
    }

    func testDatesFromRangeRoundTrips() {
        for tz in [0, cst, est] {
            let range = rangeFromDates("2026-03-15", "2026-04-02", tzOffsetMinutes: tz)!
            XCTAssertEqual(datesFromRange(range, tzOffsetMinutes: tz),
                           FlareSearchDateDraft(from: "2026-03-15", to: "2026-04-02"), "tz \(tz)")
        }
        let local = rangeFromDates("2026-03-15", "2026-04-02")!
        XCTAssertEqual(datesFromRange(local), FlareSearchDateDraft(from: "2026-03-15", to: "2026-04-02"))
        XCTAssertEqual(datesFromRange(FlareSearchTimeRange(), tzOffsetMinutes: cst),
                       FlareSearchDateDraft(from: "", to: ""))
        XCTAssertEqual(datesFromRange(FlareSearchTimeRange(fromTime: -1), tzOffsetMinutes: cst),
                       FlareSearchDateDraft(from: "", to: ""))
        XCTAssertEqual(datesFromRange(rangeFromDates("2026-03-15", "2026-03-15", tzOffsetMinutes: cst)!,
                                      tzOffsetMinutes: est),
                       FlareSearchDateDraft(from: "2026-03-14", to: "2026-03-15"))
    }

    func testMatchedOptionIdMatchesByValue() {
        let options = [
            FlareSearchRangeOption(id: "today", label: "今天", fromTime: 1_000, toTime: 2_000),
            FlareSearchRangeOption(id: "week", label: "近 7 天", fromTime: 500),
            FlareSearchRangeOption(id: "all", label: "不限时间"),
        ]
        XCTAssertEqual(matchedOptionId(FlareSearchTimeRange(fromTime: 1_000, toTime: 2_000), options), "today")
        XCTAssertEqual(matchedOptionId(FlareSearchTimeRange(fromTime: 500), options), "week")
        XCTAssertEqual(matchedOptionId(FlareSearchTimeRange(), options), "all")
        XCTAssertNil(matchedOptionId(FlareSearchTimeRange(fromTime: 1_000, toTime: 2_001), options))
        XCTAssertNil(matchedOptionId(FlareSearchTimeRange(toTime: 500), options))
        XCTAssertNil(matchedOptionId(FlareSearchTimeRange(fromTime: 1_000, toTime: 2_000), []))
    }

    func testShouldOpenCustomRange() {
        let options = [FlareSearchRangeOption(id: "today", label: "今天", fromTime: 1_000, toTime: 2_000)]
        XCTAssertFalse(shouldOpenCustomRange(FlareSearchTimeRange(fromTime: 7), options,
                                             allowCustom: false, customActive: true))
        XCTAssertTrue(shouldOpenCustomRange(FlareSearchTimeRange(), options,
                                            allowCustom: true, customActive: true))
        XCTAssertTrue(shouldOpenCustomRange(FlareSearchTimeRange(fromTime: 7, toTime: 9), options, allowCustom: true))
        XCTAssertFalse(shouldOpenCustomRange(FlareSearchTimeRange(fromTime: 1_000, toTime: 2_000),
                                             options, allowCustom: true))
        XCTAssertFalse(shouldOpenCustomRange(FlareSearchTimeRange(), options, allowCustom: true))
    }

    func testViewBuildsForEveryShape() {
        let options = [
            FlareSearchRangeOption(id: "today", label: "今天", fromTime: 1_000, toTime: 2_000),
            FlareSearchRangeOption(id: "bad", label: "非法", fromTime: 2, toTime: 1),
        ]
        for value in [FlareSearchTimeRange(), FlareSearchTimeRange(fromTime: 1_000, toTime: 2_000),
                      FlareSearchTimeRange(fromTime: 7), FlareSearchTimeRange(toTime: 9)] {
            for disabled in [false, true] {
                _ = SearchDateRangeFilterView(value: value, options: options, allowCustom: true,
                                              minDate: "2020-01-01", maxDate: "2030-12-31",
                                              tzOffsetMinutes: 480, disabled: disabled,
                                              onChange: { _ in }, onClear: {}).body
            }
        }
        _ = SearchDateRangeFilterView(value: FlareSearchTimeRange(fromTime: 7), options: options,
                                      allowCustom: false, customActive: true, onChange: { _ in }).body
    }
}
