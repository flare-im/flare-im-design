import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// FR-082: the timeline dates its first message and every change of local calendar day — never a time
/// gap inside a day — labels today and yesterday with the strings table's words, adds the year only
/// for another year, and draws the unread divider after the date separator.
final class TimelineDateSeparatorTests: XCTestCase {
    private let strings = FlareStrings()
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func message(_ id: String, _ sentAt: Date?, sender: String = "peer", text: String? = nil) -> FlareMessageData {
        FlareMessageData(id: id, senderId: sender, senderName: sender, content: FlareTextContent(text ?? "message \(id)"),
                         sentAtMs: sentAt.map { Int64($0.timeIntervalSince1970 * 1000) } ?? 0)
    }

    private func dates(_ entries: [MessageListView.TimelineEntry]) -> [Int] {
        entries.enumerated().compactMap { index, entry in
            if case .date = entry { return index }
            return nil
        }
    }

    func testTheFirstMessageIsDated() {
        let messages = [message("a", date(2026, 6, 10, 9))]
        let entries = MessageListView.timelineEntries(messages, unreadFromId: nil, currentUserId: "me")
        XCTAssertEqual(entries, [.date(sentAtMs: messages[0].sentAtMs), .message(id: "a", position: .single)])
    }

    func testHoursApartOnTheSameDayDrawNoSeparator() {
        let messages = [message("a", date(2026, 6, 10, 0, 5)), message("b", date(2026, 6, 10, 13)),
                        message("c", date(2026, 6, 10, 23, 55))]
        let entries = MessageListView.timelineEntries(messages, unreadFromId: nil, currentUserId: "me")
        XCTAssertEqual(dates(entries), [0], "only the first message is dated")
    }

    func testCrossingMidnightDrawsASeparatorThatEndsTheSenderRun() {
        // Three minutes apart from one sender would be one run; the day between them ends it.
        let messages = [message("a", date(2026, 6, 10, 23, 58)), message("b", date(2026, 6, 11, 0, 1))]
        let entries = MessageListView.timelineEntries(messages, unreadFromId: nil, currentUserId: "me")
        XCTAssertEqual(entries, [
            .date(sentAtMs: messages[0].sentAtMs), .message(id: "a", position: .single),
            .date(sentAtMs: messages[1].sentAtMs), .message(id: "b", position: .single),
        ])
    }

    func testARunNeverContinuesAcrossADateSeparator() {
        let messages = [
            message("a", date(2026, 6, 10, 23, 55)), message("b", date(2026, 6, 10, 23, 57)),
            message("c", date(2026, 6, 10, 23, 59)), message("d", date(2026, 6, 11, 0, 1)),
            message("e", date(2026, 6, 11, 0, 2)), message("f", date(2026, 6, 11, 0, 3)),
        ]
        let positions = MessageListView.timelineEntries(messages, unreadFromId: nil, currentUserId: "me").compactMap { entry -> MessageGroupPosition? in
            if case let .message(_, position) = entry { return position }
            return nil
        }
        XCTAssertEqual(positions, [.first, .middle, .last, .first, .middle, .last],
                       "the row above the separator closes its run and the row below it opens a new one")
        // The first row's own separator opens the timeline, not a run: a lone first run stays whole.
        let sameDay = Array(messages.prefix(3))
        XCTAssertEqual(MessageListView.timelineEntries(sameDay, unreadFromId: nil, currentUserId: "me").compactMap { entry -> MessageGroupPosition? in
            if case let .message(_, position) = entry { return position }
            return nil
        }, [.first, .middle, .last])
    }

    func testUndatedMessagesNeitherStartADayNorResetTheDay() {
        let messages = [message("a", nil), message("b", date(2026, 6, 10, 9)), message("c", nil),
                        message("d", date(2026, 6, 10, 18))]
        let entries = MessageListView.timelineEntries(messages, unreadFromId: nil, currentUserId: "me")
        XCTAssertEqual(entries.filter { if case .date = $0 { return true } else { return false } },
                       [.date(sentAtMs: messages[1].sentAtMs)])
    }

    func testTheUnreadDividerComesAfterTheDateSeparatorAndStartsASenderRun() {
        let messages = [
            message("a", date(2026, 6, 10, 22)),
            message("b", date(2026, 6, 11, 8), sender: "me"),
            message("c", date(2026, 6, 11, 8, 1)),
            message("d", date(2026, 6, 11, 8, 2)),
            message("e", date(2026, 6, 11, 8, 3)),
        ]
        let unreadAtDayStart = MessageListView.timelineEntries(messages, unreadFromId: "b", currentUserId: "me")
        XCTAssertEqual(Array(unreadAtDayStart[2...4]), [
            .date(sentAtMs: messages[1].sentAtMs), .unread(count: 3), .message(id: "b", position: .single),
        ], "the day, then where the unread messages start inside it; my own message is not counted")

        // Inside a run: the row above closes it and the first unread row opens a new one.
        let unreadInsideRun = MessageListView.timelineEntries(messages, unreadFromId: "d", currentUserId: "me")
        XCTAssertEqual(unreadInsideRun.suffix(4), [
            .message(id: "c", position: .single), .unread(count: 2),
            .message(id: "d", position: .first), .message(id: "e", position: .last),
        ])
        XCTAssertFalse(MessageListView.timelineEntries(messages, unreadFromId: "gone", currentUserId: "me")
            .contains { if case .unread = $0 { return true } else { return false } })
    }

    func testLabelsSayTodayAndYesterdayThenTheDateWithTheYearOnlyForAnotherYear() {
        let now = date(2026, 6, 10, 12)
        let chinese = Locale(identifier: "zh_CN")
        func label(_ date: Date, _ locale: Locale = Locale(identifier: "zh_CN")) -> String {
            FlareTimeFormat.timelineDateLabel(date, today: strings.today, yesterday: strings.yesterday,
                                              locale: locale, now: now)
        }
        XCTAssertEqual(label(date(2026, 6, 10, 0, 1)), "今天")
        XCTAssertEqual(label(date(2026, 6, 9, 23, 59)), "昨天")
        let earlierThisYear = label(date(2026, 3, 2, 9), chinese)
        XCTAssertFalse(earlierThisYear.contains("2026"), earlierThisYear)
        XCTAssertTrue(earlierThisYear.contains("3") && earlierThisYear.contains("2"), earlierThisYear)
        let previousYear = label(date(2025, 12, 31, 23), chinese)
        XCTAssertTrue(previousYear.contains("2025"), previousYear)
        XCTAssertTrue(label(date(2025, 12, 31, 23), Locale(identifier: "en_US")).contains("2025"))
        XCTAssertFalse(label(date(2026, 1, 5, 23), Locale(identifier: "en_US")).contains("2026"))
    }

    @MainActor
    func testTheListDrawsTheDatePillThenTheUnreadDividerThenTheMessage() throws {
        let today = calendar.startOfDay(for: Date())
        let yesterdayNoon = today.addingTimeInterval(-12 * 3600)
        let todayMorning = today.addingTimeInterval(60)
        let list = MessageListView(
            messages: [message("a", yesterdayNoon, text: "earlier"), message("b", todayMorning, text: "unread one")],
            currentUserId: "me", unreadFromId: "b")
        let texts = try list.inspect().findAll(ViewType.Text.self).map { try $0.string() }
        let order = [strings.yesterday, "earlier", strings.today, strings.newMessages(1), "unread one"]
            .map { label in texts.firstIndex(of: label) }
        XCTAssertFalse(order.contains(nil), "\(texts)")
        XCTAssertEqual(order.compactMap { $0 }, order.compactMap { $0 }.sorted(), "\(texts)")
    }
}
