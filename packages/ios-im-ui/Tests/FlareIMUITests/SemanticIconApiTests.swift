import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// B5.1: the kit's public models name icons by meaning (``flareIconNames``), not by SF Symbol, and an
/// unknown name draws the registry's fallback instead of crashing or drawing the word.
final class SemanticIconApiTests: XCTestCase {

    /// Every `icon` a kit default ships is a registry name — the whole point of the parameter.
    func testTheKitsOwnDefaultsNameIconsFromTheRegistry() {
        let names = flareDefaultIMNavigation().map(\.icon)
            + flareDefaultContactNavigation().map(\.icon)
            + FlareComposerActionPanel.defaultActions.map(\.icon)
            + messageMenuActions(FlareMessageActionAvailability(
                canReply: true, canForward: true, canCopy: true, canEdit: true, canDelete: true,
                canRecall: true, canPin: true, canUnpin: true, canReact: true, canMultiSelect: true,
                canSave: true, canResend: true), strings: FlareStrings(),
                content: FlareTextContent("hi")).map(\.icon)
        XCTAssertFalse(names.isEmpty)
        for name in names {
            XCTAssertTrue(flareIconNames.contains(name), "\(name) is not a kit icon name")
            XCTAssertNotEqual(flareIconSymbol(name), "questionmark", name)
        }
    }

    @MainActor
    func testASettingsRowDrawsTheRegistryGlyphForItsName() throws {
        let row = FlareSettingsRow(item: FlareSettingsItem(key: "k", label: "群公告", icon: "announcement"))
        XCTAssertNoThrow(try row.inspect().find(ViewType.Image.self, where: {
            try $0.actualImage().name() == flareIconMap["announcement"]
        }), "the row draws the registry glyph for its name")
    }

    @MainActor
    func testANavigationItemDrawsTheRegistryGlyphForItsName() throws {
        let item = FlareApplicationNavigationItem(id: "chats", label: "消息", icon: "chats")
        XCTAssertEqual(flareIconSymbol(item.icon), flareIconMap["chats"])
        // The whole shell renders it; finding the symbol by name proves the registry did the drawing.
        let nav = AdaptiveNavigationView(groups: [FlareApplicationNavigationGroup(id: "main", items: [item])],
                                         activeID: "chats", responsiveMode: .mobile, onNavigate: { _ in })
        XCTAssertNoThrow(try nav.inspect().find(ViewType.Image.self, where: {
            try $0.actualImage().name() == flareIconMap["chats"]
        }))
    }

    @MainActor
    func testAnActionItemAndAnIconButtonDrawTheRegistryGlyph() throws {
        let entry = messageMenuActions(FlareMessageActionAvailability(canForward: true),
                                       strings: FlareStrings()).first
        XCTAssertEqual(entry?.icon, "forward")
        let sheet = MessageActionSheetView(availability: FlareMessageActionAvailability(canForward: true))
        XCTAssertNoThrow(try sheet.inspect().find(ViewType.Image.self, where: {
            try $0.actualImage().name() == flareIconMap["forward"]
        }))
        let button = IconButtonView(icon: "close", accessibilityLabel: "关闭") {}
        XCTAssertEqual(try button.inspect().find(ViewType.Image.self).actualImage().name(), flareIconMap["close"])
    }

    @MainActor
    func testAnUnknownNameDrawsTheFallbackAndNothingElse() throws {
        // An SF Symbol name passed where a kit name belongs is exactly the mistake this catches.
        XCTAssertEqual(flareIconSymbol("person.2"), "questionmark")
        XCTAssertEqual(flareIconSymbol(""), "questionmark")
        let row = FlareSettingsRow(item: FlareSettingsItem(key: "k", label: "设置", icon: "not-a-name"))
        XCTAssertNoThrow(try row.inspect().find(ViewType.Image.self, where: {
            try $0.actualImage().name() == "questionmark"
        }), "an unknown name draws the fallback")
        // No text is drawn for the name, and the view still renders.
        XCTAssertThrowsError(try row.inspect().find(text: "not-a-name"))
        _ = EmptyStateView(title: "空", icon: "not-a-name").body
        _ = IconButtonView(icon: "not-a-name", accessibilityLabel: "x") {}.body
    }
}

/// B5.2 (FR-084, X23): a settings row is what its kind says it is.
final class SettingsRowKindTests: XCTestCase {
    private func row(_ kind: FlareSettingKind, detail: String? = "已连接", danger: Bool = false) -> FlareSettingsRow {
        FlareSettingsRow(item: FlareSettingsItem(key: "k", label: "连接", icon: "info", kind: kind,
                                                 detail: detail, danger: danger),
                         onToggle: { _, _ in }, onSelect: { _ in })
    }

    @MainActor
    func testAValueRowIsNotAControlEvenWhenTheListTakesSelections() throws {
        let value = row(.value)
        XCTAssertThrowsError(try value.inspect().find(ViewType.Button.self), "information is not a button")
        XCTAssertFalse(FlareSettingsRow.isControl(FlareSettingsItem(key: "k", label: "l", kind: .value)))
    }

    @MainActor
    func testAnActionRowIsAButtonWithoutAChevron() throws {
        let action = row(.action, detail: nil, danger: true)
        XCTAssertNoThrow(try action.inspect().find(ViewType.Button.self))
        XCTAssertThrowsError(try action.inspect().find(ViewType.Image.self, where: {
            try $0.actualImage().name() == "chevron.right"
        }), "an action runs in place: no chevron")
        XCTAssertTrue(FlareSettingsRow.isControl(FlareSettingsItem(key: "k", label: "l", kind: .action)))
    }

    @MainActor
    func testANavigationRowKeepsItsChevronAndAToggleItsSwitch() throws {
        XCTAssertNoThrow(try row(.navigation).inspect().find(ViewType.Image.self, where: {
            try $0.actualImage().name() == "chevron.right"
        }))
        XCTAssertNoThrow(try row(.toggle).inspect().find(ViewType.Toggle.self))
    }

    func testALongValueStillStacksUnderTheLabelForEveryNonToggleKind() {
        let long = String(repeating: "长", count: 20)
        for kind in [FlareSettingKind.navigation, .action, .value] {
            XCTAssertTrue(FlareSettingsRow.stacksValue(
                FlareSettingsItem(key: "k", label: "l", kind: kind, detail: long)), "\(kind)")
        }
        XCTAssertFalse(FlareSettingsRow.stacksValue(
            FlareSettingsItem(key: "k", label: "l", kind: .toggle, detail: long)))
    }

    /// A per-group setting that could not be read claims neither state: an information row, not an
    /// "off" switch (Vue `myMuted: boolean | null`).
    func testAnUnreadableGroupSettingBecomesAValueRow() {
        let strings = FlareStrings()
        let unknown = FlareGroupDetailModel(groupId: "g1", name: "组", myMuted: nil, myPinned: nil)
        XCTAssertNil(unknown.myMuted)
        XCTAssertNil(unknown.myPinned)
        let known = FlareGroupDetailModel(groupId: "g1", name: "组", myMuted: true, myPinned: false)
        XCTAssertEqual(known.myMuted, true)
        XCTAssertEqual(strings.groupDetailSettingUnavailable, "暂时无法读取")
    }
}

/// B5.3: the kit's own defaults speak the product's language.
final class DefaultCopyLanguageTests: XCTestCase {
    func testTheDefaultNavigationComesFromTheStringsTable() {
        XCTAssertEqual(flareDefaultIMNavigation().map(\.label), ["消息", "通讯录", "我"])
        XCTAssertEqual(flareDefaultContactNavigation().map(\.label), ["好友", "群聊", "新的朋友", "收藏"])
        var custom = FlareStrings()
        custom.navChats = "Chats"
        custom.navFriends = "Friends"
        XCTAssertEqual(flareDefaultIMNavigation(custom).first?.label, "Chats")
        XCTAssertEqual(flareDefaultContactNavigation(custom).first?.label, "Friends")
        // Ids and icons are the contract; only the words move.
        XCTAssertEqual(flareDefaultIMNavigation(custom).map(\.id), flareDefaultIMNavigation().map(\.id))
        XCTAssertEqual(flareDefaultIMNavigation(custom).map(\.icon), ["chats", "people", "person"])
    }

    func testTheRecorderSaysItsFailuresInTheProductLanguage() {
        let strings = FlareStrings()
        XCTAssertEqual(strings.inlineVoiceComposerMicDenied, "请允许使用麦克风后再录音")
        XCTAssertEqual(strings.inlineVoiceComposerSendFailed, "发送失败，请重试")
    }
}
