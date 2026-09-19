import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// K4 (FR-084): a long settings value goes under its label on up to three lines; a short one stays at the
/// end on one line; a toggle never stacks.
final class SettingsRowStackingTests: XCTestCase {
    private func item(_ detail: String?, kind: FlareSettingKind = .navigation) -> FlareSettingsItem {
        FlareSettingsItem(key: "k", label: "群公告", icon: "announcement", kind: kind, detail: detail)
    }

    func testOnlyAValueLongerThanSixteenCodePointsStacks() {
        XCTAssertEqual(FlareSettingsRow.stackAfterCharacters, 16)
        XCTAssertFalse(FlareSettingsRow.stacksValue(item("一二三四五六七八九十一二三四五六")), "16 characters stay inline")
        XCTAssertTrue(FlareSettingsRow.stacksValue(item("一二三四五六七八九十一二三四五六七")), "17 stack")
        XCTAssertFalse(FlareSettingsRow.stacksValue(item(nil)))
        XCTAssertTrue(FlareSettingsRow.stacksValue(item(String(repeating: "a", count: 17), kind: .value)))
        XCTAssertFalse(FlareSettingsRow.stacksValue(item(String(repeating: "a", count: 40), kind: .toggle)), "toggles never stack")
        // Code points, as Vue's Array.from counts: one emoji with a skin tone is two.
        XCTAssertTrue(FlareSettingsRow.stacksValue(item(String(repeating: "👍🏽", count: 9))))
        XCTAssertFalse(FlareSettingsRow.stacksValue(item(String(repeating: "👍🏽", count: 8))))
    }

    @MainActor
    func testAStackedValueWrapsOnUpToThreeLinesUnderTheLabelAndAShortOneKeepsOneLine() throws {
        let long = "本群用于产品设计评审，每周三下午两点同步进度，请提前准备好材料。"
        let stacked = try FlareSettingsRow(item: item(long), onSelect: { _ in }).inspect()
        let value = try stacked.find(text: long)
        XCTAssertEqual(try value.lineLimit(), 3)
        XCTAssertNoThrow(try stacked.find(ViewType.VStack.self).find(text: "群公告"), "the label and the value share a column")
        XCTAssertNoThrow(try stacked.find(ViewType.Image.self, where: { try $0.actualImage().name() == "chevron.right" }))

        let short = try FlareSettingsRow(item: item("设计评审"), onSelect: { _ in }).inspect()
        XCTAssertEqual(try short.find(text: "设计评审").lineLimit(), 1)
        XCTAssertThrowsError(try short.find(ViewType.VStack.self))
    }
}
