import CoreGraphics
import Foundation
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The shared paging table (`spec/message-list-paging-vectors.json`): what the two ends of the list draw, when the
/// list asks for a page by itself, and what the floating key at the bottom does. The four kits read the same table.
final class MessageListPagingVectorsTests: XCTestCase {
    private struct Table: Decodable {
        struct Auto: Decodable { let olderWithin: CGFloat; let newerWithin: CGFloat }
        struct End: Decodable {
            let has: Bool; let loading: Bool; let error: String?; let handled: Bool
            var model: FlareMessageListPaging.End { .init(has: has, loading: loading, error: error, handled: handled) }
        }
        struct EdgeCase: Decodable {
            struct Expected: Decodable { let spinner: Bool; let error: Bool; let button: Bool }
            let id: String; let has: Bool; let loading: Bool; let error: String?; let handled: Bool; let expected: Expected
        }
        struct RequestCase: Decodable {
            struct Expected: Decodable { let older: Bool; let newer: Bool }
            let id: String; let fromTop: CGFloat; let fromBottom: CGFloat; let older: End; let newer: End; let expected: Expected
        }
        struct LatestCase: Decodable {
            struct Expected: Decodable { let shown: Bool; let count: Int; let action: String? }
            let id: String; let hasNewer: Bool; let handled: Bool; let belowCount: Int; let expected: Expected
        }
        let autoRequest: Auto
        let edges: [EdgeCase]
        let requests: [RequestCase]
        let jumpToLatest: [LatestCase]
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let url = root.appendingPathComponent("spec/message-list-paging-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    }

    func testTheListAsksWithinTheDistancesTheTableNames() throws {
        let table = try table()
        XCTAssertEqual(table.autoRequest.olderWithin, FlareMessageListPaging.olderWithin)
        XCTAssertEqual(table.autoRequest.newerWithin, FlareMessageListPaging.newerWithin)
        XCTAssertGreaterThanOrEqual(table.edges.count, 11)
        XCTAssertGreaterThanOrEqual(table.requests.count, 21)
        XCTAssertGreaterThanOrEqual(table.jumpToLatest.count, 8)
    }

    func testEveryEndDrawsWhatTheTableSays() throws {
        for vector in try table().edges {
            let edge = FlareMessageListPaging.edge(.init(has: vector.has, loading: vector.loading, error: vector.error,
                                                         handled: vector.handled))
            XCTAssertEqual(edge, .init(spinner: vector.expected.spinner, error: vector.expected.error,
                                       button: vector.expected.button), vector.id)
        }
    }

    func testEveryScrollAsksWhatTheTableSays() throws {
        for vector in try table().requests {
            let wanted = FlareMessageListPaging.requests(fromTop: vector.fromTop, fromBottom: vector.fromBottom,
                                                         older: vector.older.model, newer: vector.newer.model)
            XCTAssertEqual(wanted, .init(older: vector.expected.older, newer: vector.expected.newer), vector.id)
        }
    }

    func testTheKeyAtTheBottomDoesWhatTheTableSays() throws {
        for vector in try table().jumpToLatest {
            let action: FlareMessageListPaging.LatestEntry.Action? = switch vector.expected.action {
            case "jumpToLatest": .jumpToLatest
            case "scrollToBottom": .scrollToBottom
            default: nil
            }
            XCTAssertEqual(FlareMessageListPaging.latestEntry(hasNewer: vector.hasNewer, handled: vector.handled,
                                                             belowCount: vector.belowCount),
                           .init(shown: vector.expected.shown, count: vector.expected.count, action: action), vector.id)
        }
    }

    /// A newer page and a message that arrived look alike to the window rule; only a detached window tells them apart.
    func testRowsAppendedToADetachedWindowAreANewerPage() {
        let window = ["m1", "m2", "m3"]
        XCTAssertTrue(FlareMessageListPaging.isNewerPage(from: window, to: window + ["m4"], wasDetached: true))
        XCTAssertFalse(FlareMessageListPaging.isNewerPage(from: window, to: window + ["m4"], wasDetached: false))
        XCTAssertFalse(FlareMessageListPaging.isNewerPage(from: window, to: ["m0"] + window, wasDetached: true))
        XCTAssertFalse(FlareMessageListPaging.isNewerPage(from: window, to: ["x1", "x2", "x3", "x4"], wasDetached: true))
        var follow = TimelineFollow()
        follow.readNewerPage(tailId: "m4")
        XCTAssertFalse(follow.followsAppended(includingOwn: false), "the reader of a newer page is not followed")
        XCTAssertEqual(follow.anchorTailId, "m4")
    }

    // MARK: the reading position of a detached window

    private func rows(_ range: ClosedRange<Int>, own: Bool = false) -> [TimelineFollow.Row] {
        range.map { TimelineFollow.Row(id: "m\($0)", own: own) }
    }

    func testANewerPageKeepsTheReaderEvenWhenItEndsInTheirOwnMessages() {
        var paging = TimelinePaging(detachedSinceRows: true)
        var follow = TimelineFollow()
        let window = rows(1...20)
        let next = TimelinePagingRows(rows: window + rows(21...30, own: true), detached: false)
        XCTAssertEqual(paging.rowsChanged(from: window.map(\.id), to: next, follow: &follow), .newerPage)
        XCTAssertFalse(follow.followTail)
        // Attached now: a message that arrives later is news, and the reader's own takes them down.
        let arrived = TimelinePagingRows(rows: next.rows + rows(31...31, own: true), detached: false)
        XCTAssertEqual(paging.rowsChanged(from: next.rows.map(\.id), to: arrived, follow: &follow), .latest)
    }

    func testAHostThatClearsTheDetachedStateFirstStillHasItsPageKeptInPlace() {
        var paging = TimelinePaging(detachedSinceRows: true)
        var follow = TimelineFollow()
        let window = rows(1...20)
        XCTAssertEqual(paging.rowsChanged(from: window.map(\.id), to: .init(rows: window, detached: false), follow: &follow), .keep)
        XCTAssertEqual(paging.rowsChanged(from: window.map(\.id), to: .init(rows: window + rows(21...25), detached: false),
                                          follow: &follow), .newerPage)
    }

    func testTheLatestWindowTheReaderAskedForOpensAtItsNewest() {
        var paging = TimelinePaging(detachedSinceRows: true)
        var follow = TimelineFollow()
        follow.readNewerPage(tailId: "m20")
        paging.jumpRequested = true
        let window = rows(1...20)
        // Still detached: the old window stays where it is until the host hands over the latest one.
        XCTAssertEqual(paging.rowsChanged(from: window.map(\.id), to: .init(rows: window, detached: true), follow: &follow), .keep)
        XCTAssertEqual(paging.rowsChanged(from: window.map(\.id), to: .init(rows: rows(500...540), detached: false),
                                          follow: &follow), .latest)
        XCTAssertFalse(paging.jumpRequested)
        XCTAssertTrue(follow.followTail)
    }

    func testAnAttachedWindowKeepsTheFollowRules() {
        var paging = TimelinePaging()
        var follow = TimelineFollow()
        let window = rows(1...20)
        XCTAssertEqual(paging.rowsChanged(from: window.map(\.id), to: .init(rows: window + rows(21...21), detached: false),
                                          follow: &follow), .latest, "a reader at the bottom follows a new message")
    }

    // MARK: the list

    private func messages(_ range: ClosedRange<Int>) -> [FlareMessageData] {
        range.map { FlareMessageData(id: "m\($0)", senderId: "ann", senderName: "Ann", content: FlareTextContent("第 \($0) 条")) }
    }

    @MainActor
    func testADetachedWindowOffersNewerPagesAndTheLatest() throws {
        var asked: [String] = []
        let list = MessageListView(messages: messages(1...5), currentUserId: "me",
                                   hasNewer: true, onLoadNewer: { asked.append("newer") },
                                   onJumpToLatest: { asked.append("latest") })
        try list.inspect().find(button: FlareStrings().messageListLoadNewer).tap()
        let key = try list.inspect().find(ScrollToLatestView.self)
        try key.find(ViewType.Button.self).tap()
        XCTAssertEqual(asked, ["newer", "latest"])
    }

    @MainActor
    func testAListLeftAtItsDefaultsHasNoNewerEndAndNoBackToLatestKey() throws {
        let list = MessageListView(messages: messages(1...5), currentUserId: "me", onLoadNewer: {}, onJumpToLatest: {})
        XCTAssertThrowsError(try list.inspect().find(button: FlareStrings().messageListLoadNewer))
        XCTAssertThrowsError(try list.inspect().find(ScrollToLatestView.self))
    }

    @MainActor
    func testADetachedWindowWithoutAJumpHasNoBackToLatestKey() throws {
        let list = MessageListView(messages: messages(1...5), currentUserId: "me", hasNewer: true, onLoadNewer: {})
        XCTAssertThrowsError(try list.inspect().find(ScrollToLatestView.self))
    }

    @MainActor
    func testANewerPageLoadingShowsASpinnerAndAFailureARetry() throws {
        let loading = MessageListView(messages: messages(1...5), currentUserId: "me",
                                      hasNewer: true, loadingNewer: true, newerError: "加载失败", onLoadNewer: {})
        XCTAssertThrowsError(try loading.inspect().find(button: FlareStrings().messageListLoadNewer))
        XCTAssertThrowsError(try loading.inspect().find(text: "加载失败"))
        XCTAssertNoThrow(try loading.inspect().find(ViewType.ProgressView.self))
        var retries = 0
        let failed = MessageListView(messages: messages(1...5), currentUserId: "me",
                                     hasNewer: true, newerError: "加载失败", onLoadNewer: { retries += 1 })
        XCTAssertNoThrow(try failed.inspect().find(text: "加载失败"))
        try failed.inspect().find(button: FlareStrings().messageListLoadNewer).tap()
        XCTAssertEqual(retries, 1)
    }
}
