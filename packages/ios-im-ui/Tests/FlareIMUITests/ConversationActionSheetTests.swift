import XCTest
@testable import FlareIMUI

final class ConversationActionSheetTests: XCTestCase {
    private let base = FlareConversationActionSnapshot(id: "c1", title: "设计评审")
    private let all = FlareConversationActionCapabilities(pin: true, mute: true, markRead: true,
                                                          archive: true, delete: true, hide: true)
    private let every = FlareConversationActionCapabilities(pin: true, mute: true, markRead: true, markUnread: true,
                                                            archive: true, clearHistory: true, delete: true, hide: true)
    private func ids(_ c: FlareConversationActionSnapshot,
                     _ caps: FlareConversationActionCapabilities) -> [FlareConversationAction] {
        conversationActions(c, capabilities: caps).map(\.action)
    }

    func testNothingWithoutCapabilities() {
        XCTAssertEqual(ids(base, .init()), [])
    }

    func testEachCapabilityRevealsItsAction() {
        XCTAssertEqual(ids(base, .init(pin: true)), [.pin])
        XCTAssertEqual(ids(base, .init(mute: true)), [.mute])
        XCTAssertEqual(ids(base, .init(archive: true)), [.archive])
        XCTAssertEqual(ids(base, .init(hide: true)), [.hide])
        XCTAssertEqual(ids(base, .init(clearHistory: true)), [.clearHistory])
        XCTAssertEqual(ids(base, .init(delete: true)), [.delete])
    }

    func testInvertsByState() {
        XCTAssertEqual(ids(.init(id: "c", title: "t", pinned: true), .init(pin: true)), [.unpin])
        XCTAssertEqual(ids(.init(id: "c", title: "t", muted: true), .init(mute: true)), [.unmute])
        XCTAssertEqual(ids(.init(id: "c", title: "t", archived: true), .init(archive: true)), [.unarchive])
    }

    func testMarkReadOnlyWithUnread() {
        XCTAssertEqual(ids(base, .init(markRead: true)), [])
        XCTAssertEqual(ids(.init(id: "c", title: "t", unreadCount: 3), .init(markRead: true)), [.markRead])
    }

    func testMarkUnreadOnlyWhenNothingIsUnread() {
        let unread = FlareConversationActionSnapshot(id: "c", title: "t", unreadCount: 3)
        XCTAssertEqual(ids(base, .init(markRead: true, markUnread: true)), [.markUnread])
        XCTAssertEqual(ids(unread, .init(markRead: true, markUnread: true)), [.markRead])
        XCTAssertEqual(ids(unread, .init(markUnread: true)), [])
    }

    func testOrderAndDangerGroup() {
        let caps = FlareConversationActionCapabilities(pin: true, mute: true, markRead: true, archive: true,
                                                       clearHistory: true, delete: true, hide: true)
        let entries = conversationActions(.init(id: "c", title: "t", unreadCount: 2), capabilities: caps)
        XCTAssertEqual(entries.map(\.action), [.pin, .mute, .markRead, .archive, .hide, .clearHistory, .delete])
        XCTAssertEqual(entries.filter(\.danger).map(\.action), [.clearHistory, .delete])
        XCTAssertEqual(entries.last?.danger, true)
    }

    func testFullOrderWithEveryCapability() {
        XCTAssertEqual(ids(base, every), [.pin, .mute, .markUnread, .archive, .hide, .clearHistory, .delete])
        XCTAssertEqual(conversationActions(base, capabilities: every).filter(\.danger).map(\.action),
                       [.clearHistory, .delete])
    }

    func testLabelsFollowTextProps() {
        let view = ConversationActionSheetView(conversation: base, capabilities: all,
                                               pinText: "Pin", deleteText: "Delete")
        XCTAssertEqual(view.label(for: .pin), "Pin")
        XCTAssertEqual(view.label(for: .delete), "Delete")
        XCTAssertEqual(view.label(for: .unmute), "取消免打扰")
        XCTAssertEqual(view.label(for: .markUnread), "标为未读")
        XCTAssertEqual(view.label(for: .clearHistory), "清空本地记录")
    }

    func testMarkUnreadAndClearHistoryCopyComesFromTheStringsTable() {
        let view = ConversationActionSheetView(conversation: base, capabilities: every)
        let english = view.resolveCopy(FlareStrings(conversationActionSheetMarkUnread: "Mark as unread",
                                                    conversationActionSheetClearHistory: "Clear local history"))
        XCTAssertEqual(english.markUnreadText, "Mark as unread")
        XCTAssertEqual(english.clearHistoryText, "Clear local history")
        XCTAssertEqual(ConversationActionSheetView.symbol(for: .markUnread), flareIconMap["mark-unread"])
        XCTAssertNotEqual(ConversationActionSheetView.symbol(for: .clearHistory),
                          ConversationActionSheetView.symbol(for: .delete),
                          "clearing local history is not deleting the conversation")
    }

    func testEachActionDrawsItsRegistryIcon() {
        let expected: [FlareConversationAction: String] = [
            .pin: "pin", .unpin: "unpin", .markRead: "read", .markUnread: "mark-unread",
            .archive: "archive", .unarchive: "unarchive", .clearHistory: "clear-history", .delete: "delete",
        ]
        for (action, name) in expected {
            XCTAssertEqual(ConversationActionSheetView.symbol(for: action), flareIconMap[name], "\(action) draws \(name)")
        }
        XCTAssertNotEqual(ConversationActionSheetView.symbol(for: .pin), ConversationActionSheetView.symbol(for: .unpin))
    }
}
