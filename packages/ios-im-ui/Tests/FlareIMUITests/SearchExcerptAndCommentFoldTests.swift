import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// A message hit shows the words around its first match (the Vue `FlareSearchResults` excerpt), and a moment comment
/// folds past its lines with the located one open under its label (the Vue `MomentCommentRow`).
final class SearchExcerptAndCommentFoldTests: XCTestCase {
    func testAMessageKeepsItsFirstHitInView() {
        let short = "周末一起去爬山吧"
        XCTAssertEqual(SearchResultsView.excerpt(short, query: "爬山"), short, "128 characters or fewer stay whole")

        let late = String(repeating: "一", count: 200) + "爬山" + String(repeating: "二", count: 100)
        XCTAssertEqual(SearchResultsView.excerpt(late, query: "  "), late, "no query, no cut")
        XCTAssertEqual(SearchResultsView.excerpt(late, query: "徒步"), late, "no hit, no cut")
        // 24 before the hit; the 128 run past the end, so only the front is cut.
        XCTAssertEqual(SearchResultsView.excerpt(late, query: "爬山"),
                       "…" + String(repeating: "一", count: 24) + "爬山" + String(repeating: "二", count: 100))

        let early = "爬山" + String(repeating: "三", count: 200)
        XCTAssertEqual(SearchResultsView.excerpt(early, query: "爬山"), "爬山" + String(repeating: "三", count: 126) + "…")

        let middle = String(repeating: "a", count: 100) + "Hike" + String(repeating: "b", count: 200)
        XCTAssertEqual(SearchResultsView.excerpt(middle, query: "hike"),
                       "…" + String(repeating: "a", count: 24) + "Hike" + String(repeating: "b", count: 100) + "…",
                       "case-insensitive, cut on both sides")

        let emoji = String(repeating: "👍🏽", count: 150) + "hike"
        XCTAssertEqual(SearchResultsView.excerpt(emoji, query: "hike"), "…" + String(repeating: "👍🏽", count: 24) + "hike",
                       "an emoji is one character, never cut in half")
    }

    private let short = MomentComment(id: "c1", author: MomentAuthor(id: "u_he", name: "何川"), text: "带上我")
    private let tall = MomentComment(id: "c2", author: MomentAuthor(id: "u_he", name: "何川"), text: "1\n2\n3\n4")

    func testACommentFoldsPastItsLines() {
        XCTAssertFalse(CommentThreadView.folds(short, maxLines: 3, measured: false))
        XCTAssertTrue(CommentThreadView.folds(short, maxLines: 3, measured: true), "measured past its lines")
        XCTAssertTrue(CommentThreadView.folds(tall, maxLines: 3, measured: false), "four lines are past three")
        XCTAssertFalse(CommentThreadView.folds(tall, maxLines: 5, measured: false), "a detail view allows five")
        XCTAssertFalse(CommentThreadView.folds(tall, maxLines: 0, measured: true), "0 never folds")
    }

    @MainActor
    func testTheLocatedCommentStartsOpenUnderItsLabel() throws {
        let strings = FlareStrings()
        let located = try CommentThreadView(comments: [tall, short], focusCommentId: "c2", focusLabel: "已定位评论").inspect()
        XCTAssertNoThrow(try located.find(text: "已定位评论"))
        XCTAssertNoThrow(try located.find(button: strings.collapse), "the located comment starts open")
        XCTAssertNoThrow(try CommentThreadView(comments: [tall]).inspect().find(button: strings.expand))
    }
}
