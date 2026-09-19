import SwiftUI
import XCTest
@testable import FlareIMUI

/// The reply quote in the bubble and the thread's locate routing (FR-008).
final class ReplyQuoteTests: XCTestCase {
    private let quoted = FlareReplyTarget(senderName: "Bob", summary: "See you at 3", messageId: "m1")

    private func message(_ id: String, replyTo: FlareReplyTarget? = nil,
                         content: FlareMessageContent = FlareTextContent("ok"),
                         lifecycle: FlareMessageLifecycle? = nil,
                         serverId: String? = nil) -> FlareMessageData {
        FlareMessageData(id: id, senderId: "ann", senderName: "Ann", content: content, serverId: serverId,
                         lifecycle: lifecycle, replyTo: replyTo)
    }

    func testReplyTargetAndMessageDefaults() {
        XCTAssertNil(FlareReplyTarget(senderName: "Bob", summary: "hi").messageId)
        XCTAssertNil(message("1").replyTo)
        XCTAssertEqual(message("2", replyTo: quoted).replyTo, quoted)
    }

    func testNoticesShowNoQuote() {
        XCTAssertEqual(MessageBubbleView.quote(message("1", replyTo: quoted)), quoted)
        XCTAssertNil(MessageBubbleView.quote(message("2", replyTo: quoted, lifecycle: FlareMessageLifecycle(mutation: .recalled))))
        XCTAssertNil(MessageBubbleView.quote(message("3", replyTo: quoted, content: FlareNotificationContent("Ann joined"))))
    }

    func testQuoteIsAControlOnlyWithHandlerIdAndOutsideMultiSelect() {
        var located: [String] = []
        let handler: (String) -> Void = { located.append($0) }
        XCTAssertNil(MessageBubbleView.quoteLocate(message("1", replyTo: quoted), multiSelectMode: false, onLocateMessage: nil))
        XCTAssertNil(MessageBubbleView.quoteLocate(message("1", replyTo: quoted), multiSelectMode: true, onLocateMessage: handler))
        XCTAssertNil(MessageBubbleView.quoteLocate(message("1", replyTo: FlareReplyTarget(senderName: "Bob", summary: "x")),
                                                   multiSelectMode: false, onLocateMessage: handler))
        XCTAssertNil(MessageBubbleView.quoteLocate(message("1", replyTo: FlareReplyTarget(senderName: "Bob", summary: "x", messageId: "")),
                                                   multiSelectMode: false, onLocateMessage: handler))
        XCTAssertNil(MessageBubbleView.quoteLocate(message("1"), multiSelectMode: false, onLocateMessage: handler))
        MessageBubbleView.quoteLocate(message("1", replyTo: quoted), multiSelectMode: false, onLocateMessage: handler)?()
        XCTAssertEqual(located, ["m1"])
    }

    func testQuotingMediaKeepsTheBubbleChrome() {
        let image = FlareImageContent(url: "https://example.com/a.png")
        XCTAssertTrue(MessageBubbleView.isChromeless(message("1", content: image)))
        XCTAssertFalse(MessageBubbleView.isChromeless(message("2", replyTo: quoted, content: image)))
        XCTAssertFalse(MessageBubbleView.isChromeless(message("3", replyTo: quoted, content: FlareStickerContent(url: ""))))
        XCTAssertFalse(MessageBubbleView.isChromeless(message("4")))
    }

    func testListScrollsToLoadedQuotesAndAsksTheHostForOthers() {
        let reply = message("r", replyTo: quoted)
        let loaded = MessageRowIndex([message("m1"), reply])
        XCTAssertEqual(MessageListView.quoteLocateTarget(reply, rows: loaded, hostLocates: false), .row("m1"))
        XCTAssertEqual(MessageListView.quoteLocateTarget(reply, rows: loaded, hostLocates: true), .row("m1"),
                       "a loaded row scrolls into view without asking the host")
        let older = message("r2", replyTo: FlareReplyTarget(senderName: "Bob", summary: "earlier", messageId: "m0"))
        XCTAssertEqual(MessageListView.quoteLocateTarget(older, rows: loaded, hostLocates: true), .host("m0"))
        XCTAssertNil(MessageListView.quoteLocateTarget(older, rows: loaded, hostLocates: false))
        let unknown = message("r3", replyTo: FlareReplyTarget(senderName: "", summary: "x"))
        XCTAssertNil(MessageListView.quoteLocateTarget(unknown, rows: loaded, hostLocates: true))
    }

    // MARK: - FR-114: a quote carries one id, and a row answers to two

    /// A message this device sent keeps its client id as the list's row id after the server names it,
    /// and a quote points at it by the core's id. The list has to recognise the row by either — before
    /// this, the bubble asked the host to locate a message that was on screen.
    func testAQuoteNamingTheCoreIdFindsTheRowTheListDrawsUnderItsOwnId() {
        let own = message("cli-1", serverId: "srv-1")
        let byCoreId = message("r1", replyTo: FlareReplyTarget(senderName: "Ann", summary: "mine", messageId: "srv-1"))
        let byRowId = message("r2", replyTo: FlareReplyTarget(senderName: "Ann", summary: "mine", messageId: "cli-1"))
        let rows = MessageRowIndex([own, byCoreId, byRowId])

        XCTAssertEqual(MessageListView.quoteLocateTarget(byCoreId, rows: rows, hostLocates: true), .row("cli-1"),
                       "the core's id finds the row, and the answer is the id the list can scroll to")
        XCTAssertEqual(MessageListView.quoteLocateTarget(byRowId, rows: rows, hostLocates: true), .row("cli-1"),
                       "the row's own id answers the same way")

        let gone = message("r3", replyTo: FlareReplyTarget(senderName: "Ann", summary: "old", messageId: "srv-0"))
        XCTAssertEqual(MessageListView.quoteLocateTarget(gone, rows: rows, hostLocates: true), .host("srv-0"),
                       "a message neither id matches is the host's to find, by the core id the quote named")
    }

    /// The rule itself: both ids answer, the answer is always the row id, and nothing else is.
    func testARowIsFoundByEitherOfItsIds() {
        let rows = MessageRowIndex([message("cli-1", serverId: "srv-1"), message("srv-2"),
                                    message("cli-3", serverId: "")])
        XCTAssertEqual(rows.rowId(for: "srv-1"), "cli-1")
        XCTAssertEqual(rows.rowId(for: "cli-1"), "cli-1")
        XCTAssertEqual(rows.rowId(for: "srv-2"), "srv-2", "a row whose two ids are one string answers once")
        XCTAssertEqual(rows.rowId(for: "cli-3"), "cli-3", "a blank core id leaves the row id doing the work")
        XCTAssertNil(rows.rowId(for: "srv-3"))
        XCTAssertNil(rows.rowId(for: ""), "a blank id names nothing")
        XCTAssertNil(rows.rowId(for: "   "))
        XCTAssertEqual(rows.rowId(for: " srv-1 "), "cli-1", "a padded id is the same id")
        XCTAssertNil(MessageRowIndex().rowId(for: "srv-1"), "no rows, no answer")
    }

    /// A row is always reachable under its own id, even where an older row carries that string as its
    /// core id — the ack that renamed it must not make the newer row unreachable.
    func testARowIdIsNeverShadowedByAnotherRowsCoreId() {
        let rows = MessageRowIndex([message("old", serverId: "srv-9"), message("srv-9")])
        XCTAssertEqual(rows.rowId(for: "srv-9"), "srv-9")
    }

    func testQuoteLabelNamesTheSenderWhenKnown() {
        let chinese = FlareStrings()
        XCTAssertEqual(chinese.messageQuoteLabel("Bob", "See you"), "引用 Bob：See you")
        XCTAssertEqual(chinese.messageQuoteLabel("", "See you"), "引用：See you")
        let english = FlareStrings(messageQuoteLabel: { $0.isEmpty ? "Quoted: \($1)" : "Quoted \($0): \($1)" })
        XCTAssertEqual(english.messageQuoteLabel("Bob", "See you"), "Quoted Bob: See you")
        XCTAssertEqual(english.messageQuoteLabel("", "See you"), "Quoted: See you")
    }

    @MainActor
    func testQuotedBubblesAndListsBuild() {
        _ = MessageBubbleView(message: message("1", replyTo: quoted), currentUserId: "me", onLocateMessage: { _ in }).body
        _ = MessageBubbleView(message: message("2", replyTo: FlareReplyTarget(senderName: "", summary: "x")), currentUserId: "ann").body
        _ = MessageBubbleView(message: message("3", replyTo: quoted), currentUserId: "me", multiSelectMode: true).body
        _ = MessageListView(messages: [message("m1"), message("r", replyTo: quoted)], currentUserId: "me",
                            onLocateMessage: { _ in }).body
    }

    #if os(macOS)
    @MainActor
    func testQuoteSpansTheContentWithoutWideningTheBubble() {
        func width<Content: View>(_ view: Content, proposed: CGFloat) -> CGFloat {
            NSHostingController(rootView: view).sizeThatFits(in: CGSize(width: proposed, height: 1_000)).width
        }
        let shortQuote = FlareQuoteStack(trailing: false, spacing: FlareSizes.spacingSm) {
            Text("Hi").frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: 120, height: 20)
        }
        XCTAssertEqual(width(shortQuote, proposed: 300), 120, accuracy: 0.5)
        let longQuote = FlareQuoteStack(trailing: true, spacing: FlareSizes.spacingSm) {
            Text(String(repeating: "a long quoted line ", count: 30)).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: 60, height: 20)
        }
        XCTAssertEqual(width(longQuote, proposed: 300), 300, accuracy: 0.5)
    }
    #endif
}
