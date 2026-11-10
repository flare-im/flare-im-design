import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

final class MessageListEmptyRecoveryTests: XCTestCase {
    private let strings = FlareStrings()

    @MainActor
    func testAnEmptyWindowWithKnownHistoryOffersOneManualRetryInsteadOfClaimingNoMessages() throws {
        var older = 0
        var newer = 0
        let list = MessageListView(messages: [], currentUserId: "me", hasOlder: true,
            onLoadOlder: { older += 1 }, hasNewer: true, onLoadNewer: { newer += 1 })
        let view = try list.inspect()
        XCTAssertNoThrow(try view.find(EmptyStateView.self))
        XCTAssertNoThrow(try view.find(text: strings.conversationWorkspaceChatFailure))
        XCTAssertThrowsError(try view.find(text: strings.messageListEmpty))
        XCTAssertThrowsError(try view.find(button: strings.messageListLoadOlder))
        XCTAssertThrowsError(try view.find(button: strings.messageListLoadNewer))
        XCTAssertEqual(older, 0, "Drawing an incomplete window must not start paging")
        XCTAssertEqual(newer, 0)
        try view.find(button: strings.retry).tap()
        XCTAssertEqual(older, 1)
        XCTAssertEqual(newer, 0, "One retry must not fan out to both ends")
    }

    @MainActor
    func testTheOnlyAvailableNewerEndTakesTheManualRetry() throws {
        var older = 0
        var newer = 0
        let list = MessageListView(messages: [], currentUserId: "me", onLoadOlder: { older += 1 },
            hasNewer: true, newerError: "Newer page unavailable", onLoadNewer: { newer += 1 })
        let view = try list.inspect()
        XCTAssertNoThrow(try view.find(text: "Newer page unavailable"))
        XCTAssertThrowsError(try view.find(text: strings.messageListEmpty))
        XCTAssertEqual(newer, 0)
        try view.find(button: strings.retry).tap()
        XCTAssertEqual(older, 0)
        XCTAssertEqual(newer, 1)
    }

    @MainActor
    func testInitialAndPageLoadingShowOneSpinnerWithoutAnEmptyOrFailureClaim() throws {
        for (initial, older, newer) in [(true, false, false), (false, true, false), (false, false, true)] {
            var requests = 0
            let list = MessageListView(messages: [], currentUserId: "me", loading: initial, loadingOlder: older,
                hasOlder: true, olderError: "Old failure", onLoadOlder: { requests += 1 },
                hasNewer: true, loadingNewer: newer, newerError: "New failure", onLoadNewer: { requests += 1 })
            let view = try list.inspect()
            XCTAssertEqual(view.findAll(ViewType.ProgressView.self).count, 1)
            XCTAssertThrowsError(try view.find(text: strings.messageListEmpty))
            XCTAssertThrowsError(try view.find(text: "Old failure"))
            XCTAssertThrowsError(try view.find(text: "New failure"))
            XCTAssertThrowsError(try view.find(button: strings.retry))
            XCTAssertEqual(requests, 0)
        }
    }

    @MainActor
    func testTheSpecificOlderFailureWinsOverNewerAndFallbackCopy() throws {
        let list = MessageListView(messages: [], currentUserId: "me", hasOlder: true,
            olderError: "Earlier page unavailable", onLoadOlder: {}, hasNewer: true,
            newerError: "Newer page unavailable", onLoadNewer: {})
        let view = try list.inspect()
        XCTAssertNoThrow(try view.find(text: "Earlier page unavailable"))
        XCTAssertThrowsError(try view.find(text: "Newer page unavailable"))
        XCTAssertThrowsError(try view.find(text: strings.conversationWorkspaceChatFailure))
        XCTAssertThrowsError(try view.find(text: strings.messageListEmpty))
    }

    @MainActor
    func testTheHostEmptySlotStillOwnsAnIdlePlaceholder() throws {
        let list = MessageListView(messages: [], currentUserId: "me", empty: AnyView(Text("Host placeholder")),
            hasOlder: true, olderError: "Older error", onLoadOlder: {})
        let view = try list.inspect()
        XCTAssertNoThrow(try view.find(text: "Host placeholder"))
        XCTAssertThrowsError(try view.find(EmptyStateView.self))
        XCTAssertThrowsError(try view.find(text: strings.messageListEmpty))
    }

    @MainActor
    func testAConfirmedEmptyConversationKeepsItsOriginalEmptyState() throws {
        let list = MessageListView(messages: [], currentUserId: "me")
        let view = try list.inspect()
        XCTAssertNoThrow(try view.find(text: strings.messageListEmpty))
        XCTAssertThrowsError(try view.find(EmptyStateView.self))
        XCTAssertThrowsError(try view.find(button: strings.retry))
    }

    @MainActor
    func testAPendingMessageKeepsTheTimelineEvenWhileHistoryIsUnavailable() throws {
        let pending = FlareMessageData(id: "pending", senderId: "me", senderName: "Me",
            content: FlareTextContent("Pending draft"), status: .pending)
        let list = MessageListView(messages: [pending], currentUserId: "me", loading: true,
            hasOlder: true, onLoadOlder: {})
        let view = try list.inspect()
        XCTAssertNoThrow(try view.find(text: "Pending draft"))
        XCTAssertNoThrow(try view.find(button: strings.messageListLoadOlder))
        XCTAssertThrowsError(try view.find(EmptyStateView.self))
        XCTAssertThrowsError(try view.find(text: strings.messageListEmpty))
    }
}
