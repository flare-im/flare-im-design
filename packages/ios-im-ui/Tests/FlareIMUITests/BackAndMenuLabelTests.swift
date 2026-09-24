import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// Batch 1 leftovers: back controls and header menus are named from the strings table (no English in
/// the Chinese UI), and their 44pt targets sit on the label, where a borderless or plain button is hit.
final class BackAndMenuLabelTests: XCTestCase {
    private let s = FlareStrings()

    func testTheStringsTableNamesTheHeaderMenus() {
        XCTAssertEqual(s.conversationHeaderAddActions, "添加会话操作")
        XCTAssertEqual(s.conversationHeaderMoreActions, "更多会话操作")
        XCTAssertEqual(s.back, "返回")
    }

    @MainActor
    func testTheHeaderNamesItsMenusAndMemberCountFromTheStringsTable() throws {
        let header = ConversationHeaderView(
            identity: ConversationIdentity(id: "g1", title: "Design", kind: .group, memberCount: 12),
            onAction: { _ in })
        let view = try header.inspect()
        XCTAssertNoThrow(try view.find(text: s.memberCount(12)))
        XCTAssertThrowsError(try view.find(text: "12 members"))
        // The menu trigger is the kit's own button now, not a system `Menu` (UIKit gave that a
        // ~250pt minimum width). The name still has to come from the strings table, and it has to
        // sit on the control the user actually touches.
        XCTAssertNoThrow(try view.find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.conversationHeaderAddActions }))
        XCTAssertNoThrow(try view.find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.conversationHeaderMoreActions }))
    }

    @MainActor
    func testTheCompactLayoutBackButtonTakesItsTargetOnTheLabel() throws {
        var panes: [FlarePane] = []
        let layout = ResponsiveLayoutView(activePane: .chat, onPaneChange: { panes.append($0) },
                                          list: AnyView(Text("list")), chat: AnyView(Text("chat")))
        let back = try layout.inspect().find(ViewType.Button.self, where: { try $0.labelView().find(text: self.s.back) != nil })
        let label = try back.labelView().find(ViewType.Label.self)
        XCTAssertEqual(try label.flexFrame().minWidth, FlareSizes.touchTargetMin)
        XCTAssertEqual(try label.flexFrame().minHeight, FlareSizes.touchTargetMin)
        XCTAssertThrowsError(try back.flexFrame(), "no frame outside the label, where it would not be hit")
        try back.tap()
        XCTAssertEqual(panes, [.list])
    }
}
