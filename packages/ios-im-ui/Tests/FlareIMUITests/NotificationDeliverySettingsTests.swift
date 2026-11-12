import XCTest
@testable import FlareIMUI

final class NotificationDeliverySettingsTests: XCTestCase {
    func testStatusRowSaysThePermissionInTheSettingsWords() {
        XCTAssertEqual(FlareNotificationStatus.allCases.map { notificationStatusLabel($0) }, ["已开启", "已关闭", "未开启"])
        XCTAssertEqual(FlareNotificationStatus.allCases.map { notificationStatusLabel($0, strings: .english) },
                       ["On", "Off", "Not turned on"])
    }

    func testBackgroundRowUsesTheBatterySettingsWords() {
        XCTAssertEqual(FlareBackgroundDelivery.allCases.map { backgroundDeliveryLabel($0) }, ["不受限制", "已优化", "受限制"])
        XCTAssertEqual(FlareBackgroundDelivery.allCases.map { backgroundDeliveryLabel($0, strings: .english) },
                       ["Unrestricted", "Optimized", "Restricted"])
    }

    func testSectionCarriesTheRowsTheHostCanUse() {
        let iOS = NotificationDeliverySettingsView(status: nil).section
        XCTAssertEqual(iOS.items.map(\.key), ["notifications"])
        XCTAssertNil(iOS.items[0].detail)
        XCTAssertEqual(iOS.items[0].kind, .value)

        let android = NotificationDeliverySettingsView(status: .off, background: .restricted, footer: "note",
                                                       onStatusAction: {}).section
        XCTAssertEqual(android.items.map(\.key), ["notifications", "backgroundDelivery"])
        XCTAssertEqual(android.items.map(\.detail), ["已关闭", "受限制"])
        XCTAssertEqual(android.items[0].kind, .navigation)
        XCTAssertEqual(android.footer, "note")
    }

    func testTheSectionFormRunsTheGroupsRowsAndLeavesTheHostsRows() {
        var pressed = 0
        let view = NotificationDeliverySettingsView(status: .off, onStatusAction: { pressed += 1 }) { section, select in
            SettingsListView(sections: [section], onSelect: { _ = select($0) })
        }
        XCTAssertEqual(view.section.items.map(\.key), ["notifications"])
        XCTAssertTrue(view.select(view.section.items[0]))
        XCTAssertEqual(pressed, 1)
        // The host's own rows, and a background row the group does not draw, are the host's to handle.
        XCTAssertFalse(view.select(FlareSettingsItem(key: "language", label: "语言")))
        XCTAssertFalse(view.select(FlareSettingsItem(key: "backgroundDelivery", label: "后台接收消息")))
        XCTAssertEqual(pressed, 1)
    }

    func testAVendorActionWithoutALabelReadsTheKitsAutoStartLabel() {
        XCTAssertNil(FlareNotificationGuideAction(onSelect: {}).label)
        XCTAssertEqual(FlareNotificationGuideAction(label: "Auto-start", onSelect: {}).label, "Auto-start")
        XCTAssertEqual(FlareStrings().backgroundDeliveryAutoStart, "自启动管理")
        XCTAssertEqual(FlareStrings.english.backgroundDeliveryAutoStart, "Auto-start settings")
    }
}
