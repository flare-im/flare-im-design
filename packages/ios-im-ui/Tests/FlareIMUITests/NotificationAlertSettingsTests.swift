import Foundation
import XCTest
@testable import FlareIMUI

/// The shared table (`spec/notification-alert-vectors.json`) behind ``NotificationAlertSettingsView``: the rows, times,
/// the next-day end, the weekday picks and their words in both languages. The Vue, Flutter and Compose kits run the
/// same file.
final class NotificationAlertSettingsTests: XCTestCase {
    private struct Table: Decodable {
        struct Rows: Decodable { let quietHoursEnabled: Bool; let sections: [[String]] }
        struct Time: Decodable { let minute: Int; let text: String }
        struct End: Decodable { let start: Int; let end: Int; let nextDay: Bool; let zh: String; let en: String }
        struct Toggle: Decodable { let mask: Int; let day: Int; let on: Bool; let result: Int }
        struct DayOn: Decodable { let mask: Int; let day: Int; let on: Bool }
        struct Summary: Decodable { let mask: Int; let kind: String; let zh: String; let en: String }
        let rows: [Rows]
        let time: [Time]
        let end: [End]
        let weekdayToggle: [Toggle]
        let weekdayOn: [DayOn]
        let summary: [Summary]
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(
            Table.self, from: Data(contentsOf: root.appendingPathComponent("spec/notification-alert-vectors.json")))
    }

    func testTheSectionsListTheRowsOfTheTable() throws {
        for row in try table().rows {
            let value = FlareNotificationAlertPreferences(quietHours: FlareQuietHours(enabled: row.quietHoursEnabled))
            let sections = NotificationAlertSettingsView(value: value).sections
            XCTAssertEqual(sections.map { $0.items.map(\.key) }, row.sections)
            XCTAssertEqual(sections.filter { !($0.footer ?? "").isEmpty }.count, 3)
        }
    }

    func testAMinuteReadsAsHoursAndMinutes() throws {
        for time in try table().time {
            XCTAssertEqual(formatMinuteOfDay(time.minute), time.text)
            if time.minute < 1440 { XCTAssertEqual(parseMinuteOfDay(time.text), time.minute) }
        }
    }

    func testTheEndReadsAsTheNextDayWhenItIsNotAfterTheStart() throws {
        for end in try table().end {
            let quiet = FlareQuietHours(startMinute: end.start, endMinute: end.end)
            XCTAssertEqual(quietHoursEndsNextDay(quiet), end.nextDay)
            XCTAssertEqual(quietHoursEndText(quiet), end.zh)
            XCTAssertEqual(quietHoursEndText(quiet, strings: .english), end.en)
        }
    }

    func testAWeekdayPickNeverEmptiesTheWeek() throws {
        let rules = try table()
        for pick in rules.weekdayToggle {
            XCTAssertEqual(weekdayToggle(pick.mask, day: pick.day, on: pick.on), pick.result, "\(pick)")
        }
        for day in rules.weekdayOn {
            XCTAssertEqual(weekdayIsOn(day.mask, day: day.day), day.on, "\(day)")
        }
    }

    func testTheDaysReadInBothLanguages() throws {
        for summary in try table().summary {
            let kind: String
            switch weekdaySummary(summary.mask) {
            case .everyDay: kind = "everyDay"
            case .weekdays: kind = "weekdays"
            case .weekends: kind = "weekends"
            case .days: kind = "days"
            }
            XCTAssertEqual(kind, summary.kind)
            XCTAssertEqual(weekdaySummaryText(summary.mask), summary.zh)
            XCTAssertEqual(weekdaySummaryText(summary.mask, strings: .english), summary.en)
        }
    }

    func testTheSectionFormRunsTheGroupsRowsAndLeavesTheHostsRows() {
        var changes: [FlareNotificationAlertPreferences] = []
        let view = NotificationAlertSettingsView(value: FlareNotificationAlertPreferences(),
                                                 onChange: { changes.append($0) }) { sections, select, toggle in
            SettingsListView(sections: sections, onToggle: { _ = toggle($0, $1) }, onSelect: { _ = select($0) })
        }
        let quietHours = view.sections[0].items[0]
        XCTAssertTrue(view.toggle(quietHours, true))
        XCTAssertEqual(changes.last?.quietHours.enabled, true)
        XCTAssertTrue(view.select(view.sections[1].items[0]))
        XCTAssertFalse(view.select(FlareSettingsItem(key: "language", label: "语言")))
        XCTAssertFalse(view.toggle(FlareSettingsItem(key: "sound", label: "声音", kind: .toggle), true))
        XCTAssertEqual(changes.count, 1)
    }

    func testRowsTakeNoInputWhileDisabled() {
        var changes = 0
        let view = NotificationAlertSettingsView(value: FlareNotificationAlertPreferences(), disabled: true,
                                                 onChange: { _ in changes += 1 })
        XCTAssertTrue(view.sections.flatMap(\.items).allSatisfy(\.disabled))
        XCTAssertTrue(view.toggle(view.sections[0].items[0], true))
        XCTAssertEqual(changes, 0)
    }

    func testASheetAlreadyOpenKeepsWorkingWhileDisabled() {
        var changes: [FlareNotificationAlertPreferences] = []
        let view = NotificationAlertSettingsView(
            value: FlareNotificationAlertPreferences(quietHours: FlareQuietHours(enabled: true)), disabled: true,
            onChange: { changes.append($0) })
        view.pickTime(.end, "07:30")
        XCTAssertEqual(changes.last?.quietHours.endMinute, 7 * 60 + 30)
        view.toggleDay(FlareSettingsItem(key: "weekday:6", label: "周日", kind: .toggle, value: true), false)
        XCTAssertEqual(changes.last?.quietHours.weekdays, 63)
        view.pickChoice(.preview, FlareNotificationPreview.hidden.rawValue)
        XCTAssertEqual(changes.last?.preview, .hidden)
        XCTAssertEqual(changes.count, 3)
    }
}
