import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// Lifecycle mutation and reactions as the thread renders them (Compose
/// `MessageProjectionTest` parity); fixtures only.
final class MessageProjectionTests: XCTestCase {
    private let recalled = FlareMessageLifecycle(mutation: .recalled)
    private let reactions = [ReactionGroup(emoji: "👍", count: 2, reactedBySelf: true), ReactionGroup(emoji: "🎉", count: 1)]

    private func message(_ id: String, _ sender: String, _ text: String,
                         lifecycle: FlareMessageLifecycle? = nil, reactions: [ReactionGroup] = []) -> FlareMessageData {
        FlareMessageData(id: id, senderId: sender, senderName: sender == "me" ? "我" : "Ann",
                         content: FlareTextContent(text), lifecycle: lifecycle, reactions: reactions)
    }

    func testRecalledFollowsTheLifecycleMutation() {
        XCTAssertTrue(message("1", "ann", "x", lifecycle: recalled).isRecalled)
        XCTAssertFalse(message("2", "ann", "x").isRecalled)
        XCTAssertFalse(message("3", "ann", "x", lifecycle: FlareMessageLifecycle(mutation: .edited)).isRecalled)
        XCTAssertFalse(message("4", "ann", "x", lifecycle: FlareMessageLifecycle(mutation: .deleted)).isRecalled)
    }

    func testRecalledNoticeNamesWhoRecalled() {
        let s = FlareStrings()
        XCTAssertEqual(MessageBubbleView.recalledNotice(isSelf: true, conversationKind: .group, senderName: "我", strings: s),
                       "你撤回了一条消息")
        XCTAssertEqual(MessageBubbleView.recalledNotice(isSelf: true, conversationKind: .single, senderName: "我", strings: s),
                       "你撤回了一条消息")
        XCTAssertEqual(MessageBubbleView.recalledNotice(isSelf: false, conversationKind: .group, senderName: "Ann", strings: s),
                       "Ann 撤回了一条消息")
        XCTAssertEqual(MessageBubbleView.recalledNotice(isSelf: false, conversationKind: .single, senderName: "Ann", strings: s),
                       "对方撤回了一条消息")

        let english = FlareStrings(messageRecalledSelf: "You unsent a message",
                                   messageRecalledPeer: "Message unsent",
                                   messageRecalledGroupOther: { "\($0) unsent a message" })
        XCTAssertEqual(MessageBubbleView.recalledNotice(isSelf: false, conversationKind: .group, senderName: "Ann", strings: english),
                       "Ann unsent a message")
        XCTAssertEqual(MessageBubbleView.recalledNotice(isSelf: false, conversationKind: .single, senderName: "Ann", strings: english),
                       "Message unsent")
    }

    func testReactionsDefaultToEmpty() {
        XCTAssertTrue(FlareMessageData(id: "1", senderId: "ann", senderName: "Ann", content: FlareTextContent("hi")).reactions.isEmpty)
    }

    func testNoticeRowsCarryNoMessageActions() {
        XCTAssertTrue(MessageListView.isActionable(message("1", "ann", "hi")))
        XCTAssertFalse(MessageListView.isActionable(message("2", "ann", "hi", lifecycle: recalled)))
        XCTAssertFalse(MessageListView.isActionable(
            FlareMessageData(id: "3", senderId: "system", senderName: "", content: FlareNotificationContent("群聊已创建"))))
    }

    func testReactionToggleOnlyWithHandler() {
        var toggled: [String] = []
        let msg = message("1", "ann", "hi", reactions: reactions)
        XCTAssertNil(MessageBubbleView.reactionToggle(msg, onReact: nil))
        MessageBubbleView.reactionToggle(msg, onReact: { toggled.append("\($0.id) \($1)") })?("🎉")
        XCTAssertEqual(toggled, ["1 🎉"])
    }

    @MainActor
    func testRecalledMessageShowsANoticeInsteadOfItsContent() throws {
        let edge = MessageRowPresentation(showAvatar: true, reserveAvatarSpace: true, showSenderName: true)
        // Control: the same row, not recalled, does render content, sender, avatar and pills.
        let live = MessageBubbleView(message: message("1", "ann", "私密内容 A", reactions: reactions),
                                     currentUserId: "me", conversationKind: .group, rowPresentation: edge)
        for probe in ["私密内容 A", "Ann"] { XCTAssertNoThrow(try live.inspect().find(text: probe)) }
        XCTAssertNoThrow(try live.inspect().find(AvatarView.self))
        XCTAssertNoThrow(try live.inspect().find(ReactionSummaryView.self))

        let peer = MessageBubbleView(message: message("1", "ann", "私密内容 A", lifecycle: recalled, reactions: reactions),
                                     currentUserId: "me", conversationKind: .group, rowPresentation: edge,
                                     multiSelectMode: true, selected: true, onToggleSelect: { _ in })
        XCTAssertEqual(try peer.inspect().find(text: "Ann 撤回了一条消息").string(), "Ann 撤回了一条消息")
        XCTAssertThrowsError(try peer.inspect().find(text: "私密内容 A"))
        XCTAssertThrowsError(try peer.inspect().find(text: "Ann"), "no sender name")
        XCTAssertThrowsError(try peer.inspect().find(ReactionSummaryView.self))
        XCTAssertThrowsError(try peer.inspect().find(AvatarView.self))
        XCTAssertThrowsError(try peer.inspect().find(ViewType.Image.self), "no selection control")

        let own = MessageBubbleView(message: message("2", "me", "私密内容 B", lifecycle: recalled), currentUserId: "me")
        XCTAssertNoThrow(try own.inspect().find(text: "你撤回了一条消息"))
        XCTAssertThrowsError(try own.inspect().find(MessageMetaView.self), "no status")
    }

    @MainActor
    func testReactionPillsToggleTheCurrentUsersReaction() throws {
        var toggled: [String] = []
        let bubble = MessageBubbleView(message: message("1", "ann", "上线了", reactions: reactions), currentUserId: "me",
                                       onReact: { toggled.append("\($0.id) \($1)") })
        let pills = try bubble.inspect().find(ReactionSummaryView.self).findAll(ViewType.Button.self)
        XCTAssertEqual(pills.count, 2, "hideAdd: no add pill under a bubble")
        try pills[1].tap()
        XCTAssertEqual(toggled, ["1 🎉"])
    }

    @MainActor
    func testReactionPillsAreDisplayOnlyWithoutAHandler() throws {
        let bubble = MessageBubbleView(message: message("1", "ann", "上线了", reactions: reactions), currentUserId: "me")
        let summary = try bubble.inspect().find(ReactionSummaryView.self)
        XCTAssertNoThrow(try summary.find(text: "👍"))
        // Labels, not buttons: nothing to announce or tap, and row gestures pass through.
        XCTAssertEqual(summary.findAll(ViewType.Button.self).count, 0)
        XCTAssertThrowsError(try MessageBubbleView(message: message("2", "ann", "x"), currentUserId: "me")
            .inspect().find(ReactionSummaryView.self), "no reactions, no summary")
    }

    func testListConstructsWithReactionHandler() {
        _ = MessageListView(messages: [message("1", "ann", "上线了", reactions: reactions),
                                       message("2", "me", "私密内容", lifecycle: recalled)],
                            currentUserId: "me", conversationKind: .group,
                            onMessageLongPress: { _ in }, onSwipeReply: { _ in },
                            onReact: { _, _ in }).body
    }
}
