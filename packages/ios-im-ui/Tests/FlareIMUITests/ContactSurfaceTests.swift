import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The contact surfaces a contact card leads to: a friend request's source line, the add key's host wording and a
/// stranger's primary action on the contact page.
final class ContactSurfaceTests: XCTestCase {
    private let s = FlareStrings()

    // MARK: Friend request source

    @MainActor
    func testTheSourceIsALineOfItsOwnUnderTheMessage() throws {
        let request = FriendRequest(id: "r1", name: "Ivy", message: "一起做设计", source: "通过名片添加，由 Kai 推荐")
        XCTAssertEqual(request.source, "通过名片添加，由 Kai 推荐")
        let view = try NewFriendRequestsView(items: [request]).inspect()
        let message = try view.find(text: "一起做设计")
        let source = try view.find(text: "通过名片添加，由 Kai 推荐")
        XCTAssertEqual(try source.lineLimit(), 1, "one line, truncated")
        XCTAssertEqual(try message.lineLimit(), 1)
        XCTAssertThrowsError(try view.find(ViewType.Text.self, where: {
            let text = try $0.string()
            return text.contains("一起做设计") && text.contains("Kai")
        }), "never on the message's line")

        let plain = try NewFriendRequestsView(items: [FriendRequest(id: "r2", name: "Kai", message: "hi")]).inspect()
        XCTAssertEqual(try plain.findAll(ViewType.Text.self).map { try $0.string() }.filter { $0.contains("名片") }, [])
        XCTAssertNil(FriendRequest(id: "r3", name: "Lu").source)
        let sourceOnly = try NewFriendRequestsView(items: [FriendRequest(id: "r4", name: "Lu", source: "来自群聊")]).inspect()
        XCTAssertNoThrow(try sourceOnly.find(text: "来自群聊"), "a source shows without a message too")
    }

    // MARK: Relation action bar

    func testTheAddKeyTakesTheHostsWordingElseTheKits() {
        let caps = FlareRelationCapabilities(add: true, block: true)
        let worded = RelationActionBarView(relation: .none, capabilities: caps, addText: "添加到通讯录")
        XCTAssertEqual(worded.label(for: .add), "添加到通讯录")
        XCTAssertEqual(worded.resolveCopy(.english).addText, "添加到通讯录", "the host's words win in every language")
        let plain = RelationActionBarView(relation: .none, capabilities: caps)
        XCTAssertEqual(plain.label(for: .add), s.relationActionBarAdd)
        XCTAssertEqual(plain.resolveCopy(.english).addText, FlareStrings.english.relationActionBarAdd)
        XCTAssertEqual(worded.label(for: .block), plain.label(for: .block), "only the add key changes")
    }

    // MARK: Contact detail primary action

    private let stranger = Contact(id: "u_lin", name: "林夏", presence: .online)

    func testThePrimaryActionLeadsTheRowAndMessageFollowsAsSecondary() {
        XCTAssertEqual(FlareContactDetail.intents(primary: true, message: true, call: false, video: false), [.primary, .message])
        XCTAssertEqual(FlareContactDetail.intents(primary: true, message: false, call: false, video: false), [.primary])
        XCTAssertEqual(FlareContactDetail.intents(message: true, call: true, video: false), [.message, .call])
        XCTAssertEqual(FlareContactDetail.primaryIntent(in: [.primary, .message]), .primary)
        XCTAssertEqual(FlareContactDetail.primaryIntent(in: [.message, .call]), .message, "a friend's page leads with Message")
        XCTAssertNil(FlareContactDetail.primaryIntent(in: [.call]))
        XCTAssertTrue(FlareContactDetail.hasPrimaryAction(label: "添加到通讯录", handled: true))
        XCTAssertFalse(FlareContactDetail.hasPrimaryAction(label: "添加到通讯录", handled: false), "needs its handler")
        XCTAssertFalse(FlareContactDetail.hasPrimaryAction(label: " ", handled: true), "needs its label")
        XCTAssertFalse(FlareContactDetail.hasPrimaryAction(label: nil, handled: true))
    }

    @MainActor
    func testAStrangersPageOffersThePrimaryActionInTheRowNotTheFooter() throws {
        var added = 0
        let copy = FlareContactDetailLabels().resolve(s)
        let detail = FlareContactDetail(contact: stranger, onMessage: {},
                                        extraActions: [FlareDetailExtraAction(id: "report", label: "举报")],
                                        primaryActionLabel: "添加到通讯录", onPrimaryAction: { added += 1 })
        let view = try detail.inspect()
        let row = try view.find(ViewType.HStack.self, where: { (try? $0.find(text: copy.message)) != nil })
        XCTAssertNoThrow(try row.find(text: "添加到通讯录"), "in the action row, beside Message")
        try view.find(button: "添加到通讯录").tap()
        XCTAssertEqual(added, 1)
        XCTAssertNoThrow(try view.find(button: copy.message), "Message is still offered")
        XCTAssertThrowsError(try view.find(ButtonView.self, where: { (try? $0.find(text: "添加到通讯录")) != nil }),
                             "not drawn as a footer key")

        let without = try FlareContactDetail(contact: stranger, onMessage: {}, primaryActionLabel: "添加到通讯录").inspect()
        XCTAssertThrowsError(try without.find(button: "添加到通讯录"), "no handler, no key")
    }
}
