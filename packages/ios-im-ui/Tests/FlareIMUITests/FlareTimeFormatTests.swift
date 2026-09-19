import XCTest
@testable import FlareIMUI

/// Locale-aware message and conversation times (FR-033) against a fixed now.
final class FlareTimeFormatTests: XCTestCase {
    private let english = Locale(identifier: "en_US")
    private let chinese = Locale(identifier: "zh_CN")

    /// A local-time date, so the rules are checked in whatever zone the tests run.
    private func local(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    /// ICU puts a narrow no-break space before the day period; compare with a plain space.
    private func plain(_ label: String) -> String { label.replacingOccurrences(of: "\u{202F}", with: " ") }

    func testMessageTimeFollowsTheLocaleClock() {
        let morning = local(2026, 9, 14, 9, 5)
        let evening = local(2026, 9, 14, 21, 40)
        XCTAssertEqual(plain(FlareTimeFormat.messageTime(morning, locale: english)), "9:05 AM")
        XCTAssertEqual(plain(FlareTimeFormat.messageTime(evening, locale: english)), "9:40 PM")
        XCTAssertEqual(FlareTimeFormat.messageTime(morning, locale: chinese), "09:05")
        XCTAssertEqual(FlareTimeFormat.messageTime(evening, locale: chinese), "21:40")
    }

    func testEveryTwentyFourHourLocaleShowsATwoDigitHour() {
        let morning = local(2026, 9, 14, 9, 5)
        // Japanese writes "H:mm"; the rule widens the hour.
        XCTAssertEqual(FlareTimeFormat.messageTime(morning, locale: Locale(identifier: "ja_JP")), "09:05")
        XCTAssertEqual(FlareTimeFormat.messageTime(morning, locale: Locale(identifier: "de_DE")), "09:05")
        // A quoted literal is text, not an hour field (Canadian French "HH 'h' mm").
        let french = FlareTimeFormat.messageTime(morning, locale: Locale(identifier: "fr_CA"))
        XCTAssertTrue(french.hasPrefix("09"), french)
        XCTAssertTrue(french.hasSuffix("05"), french)
    }

    func testConversationTimeBySameDayPreviousDaySameYearAndOlder() {
        let now = local(2026, 9, 14, 15, 30)
        func label(_ date: Date, _ locale: Locale, _ yesterday: String) -> String {
            plain(FlareTimeFormat.conversationTime(date, yesterday: yesterday, locale: locale, now: now))
        }
        XCTAssertEqual(label(local(2026, 9, 14, 9, 5), english, "Yesterday"), "9:05 AM")
        XCTAssertEqual(label(local(2026, 9, 14, 0, 1), chinese, "昨天"), "00:01")
        XCTAssertEqual(label(local(2026, 9, 13, 23, 59), english, "Yesterday"), "Yesterday")
        XCTAssertEqual(label(local(2026, 9, 13, 0, 1), chinese, "昨天"), "昨天")
        XCTAssertEqual(label(local(2026, 9, 12, 23, 59), english, "Yesterday"), "9/12")
        XCTAssertEqual(label(local(2026, 3, 2), english, "Yesterday"), "3/2")
        XCTAssertEqual(label(local(2026, 3, 2), chinese, "昨天"), "3/2")
        XCTAssertEqual(label(local(2025, 12, 31), english, "Yesterday"), "12/31/2025")
        XCTAssertEqual(label(local(2025, 12, 31), chinese, "昨天"), "2025/12/31")
    }

    func testYesterdayCrossesTheYearBoundary() {
        let newYear = local(2026, 1, 1, 8, 0)
        XCTAssertEqual(FlareTimeFormat.conversationTime(local(2025, 12, 31, 22, 0), yesterday: "Yesterday",
                                                        locale: english, now: newYear), "Yesterday")
        XCTAssertEqual(FlareTimeFormat.conversationTime(local(2025, 12, 30, 22, 0), yesterday: "Yesterday",
                                                        locale: english, now: newYear), "12/30/2025")
    }

    func testYesterdayCopyComesFromTheStrings() {
        XCTAssertEqual(FlareStrings().yesterday, "昨天")
        XCTAssertEqual(FlareStrings(yesterday: "Yesterday").yesterday, "Yesterday")
    }
}
