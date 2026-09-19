import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The seams FR-129 left unimplemented on SwiftUI: a list that is empty has to be able to say what
/// to do about it, and a screen header has to be able to say what the screen is reached through.
/// Each one falls back to the kit's own answer, so a host that gives nothing still gets a full view.
final class EmptyAndLeadingSlotTests: XCTestCase {
    private let ada = Contact(id: "u1", name: "Ada")
    private let room = GroupSummary(id: "g1", name: "设计评审组", memberCount: 18)

    @MainActor
    func testContactListDrawsTheKitEmptyStateWhenTheHostGivesNone() throws {
        let list = ContactListView(items: [])
        XCTAssertNoThrow(try list.inspect().find(EmptyStateView.self))
    }

    @MainActor
    func testContactListTakesTheHostEmptyState() throws {
        let list = ContactListView(items: [], empty: AnyView(Text("换个筛选条件试试")))
        XCTAssertEqual(try list.inspect().find(text: "换个筛选条件试试").string(), "换个筛选条件试试")
        XCTAssertThrowsError(try list.inspect().find(EmptyStateView.self))
    }

    @MainActor
    func testContactListShowsNeitherOnceThereIsSomeoneToList() throws {
        let list = ContactListView(items: [ada], empty: AnyView(Text("换个筛选条件试试")))
        XCTAssertThrowsError(try list.inspect().find(text: "换个筛选条件试试"))
    }

    @MainActor
    func testGroupListTakesTheHostEmptyState() throws {
        let list = GroupListView(items: [], empty: AnyView(Text("建一个群")))
        XCTAssertEqual(try list.inspect().find(text: "建一个群").string(), "建一个群")
    }

    @MainActor
    func testGroupListKeepsItsOwnEmptyStateAndDropsBothOnceListed() throws {
        let list = GroupListView(items: [])
        XCTAssertNoThrow(try list.inspect().find(EmptyStateView.self))
        let listed = GroupListView(items: [room], empty: AnyView(Text("建一个群")))
        XCTAssertThrowsError(try listed.inspect().find(text: "建一个群"))
    }

    @MainActor
    func testMessageListTakesTheHostEmptyState() throws {
        let list = MessageListView(messages: [], currentUserId: "me",
                                   empty: AnyView(Text("说点什么吧")), conversationId: "c1")
        XCTAssertEqual(try list.inspect().find(text: "说点什么吧").string(), "说点什么吧")
    }

    @MainActor
    func testMessageListEmptyTextStaysTheShorthand() throws {
        let list = MessageListView(messages: [], currentUserId: "me",
                                   emptyText: "还没有消息", conversationId: "c1")
        XCTAssertEqual(try list.inspect().find(text: "还没有消息").string(), "还没有消息")
    }

    @MainActor
    func testScreenHeaderPutsTheLeadingControlBeforeTheTitle() throws {
        let header = ScreenHeaderView(title: "通讯录",
                                      leading: { Button("返回") {} },
                                      actions: { Button("添加") {} })
        let row = try header.inspect().hStack()
        // Before the title, not after it: a back key that follows the heading is not a back key.
        XCTAssertEqual(try row.button(0).labelView().text().string(), "返回")
        XCTAssertEqual(try row.text(1).string(), "通讯录")
        XCTAssertNoThrow(try row.find(button: "添加"))
    }

    @MainActor
    func testScreenHeaderWithoutALeadingControlStillReads() throws {
        let header = ScreenHeaderView(title: "通讯录")
        XCTAssertEqual(try header.inspect().find(text: "通讯录").string(), "通讯录")
    }

    @MainActor
    func testEmptyStateTakesHostControlsUnderTheText() throws {
        var invited = 0
        let view = EmptyStateView(title: "还没有联系人",
                                  actions: AnyView(Button("邀请同事") { invited += 1 }))
        try view.inspect().find(button: "邀请同事").tap()
        XCTAssertEqual(invited, 1)
    }

    @MainActor
    func testEmptyStateActionTextAndActionsCanBothBeThere() throws {
        let view = EmptyStateView(title: "还没有联系人", actionText: "重试",
                                  actions: AnyView(Button("邀请同事") {}))
        XCTAssertNoThrow(try view.inspect().find(button: "重试"))
        XCTAssertNoThrow(try view.inspect().find(button: "邀请同事"))
    }
}
