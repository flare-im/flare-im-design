import XCTest
@testable import FlareIMUI

final class ConversationActionSheetTests: XCTestCase {
    private let base = FlareConversationActionSnapshot(id: "c1", title: "设计评审")
    private let all = FlareConversationActionCapabilities(pin: true, mute: true, markRead: true,
                                                          archive: true, delete: true, hide: true)
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

    func testOrderAndDangerGroup() {
        let entries = conversationActions(.init(id: "c", title: "t", unreadCount: 2), capabilities: all)
        XCTAssertEqual(entries.map(\.action), [.pin, .mute, .markRead, .archive, .hide, .delete])
        XCTAssertEqual(entries.filter(\.danger).map(\.action), [.delete])
        XCTAssertEqual(entries.last?.danger, true)
    }

    func testLabelsFollowTextProps() {
        let view = ConversationActionSheetView(conversation: base, capabilities: all,
                                               pinText: "Pin", deleteText: "Delete")
        XCTAssertEqual(view.label(for: .pin), "Pin")
        XCTAssertEqual(view.label(for: .delete), "Delete")
        XCTAssertEqual(view.label(for: .unmute), "取消免打扰")
    }
}
