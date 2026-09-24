import XCTest
@testable import FlareIMUI

/// A search that takes a limit and returns no count can say a group is truncated (`hasMore`) but not by how
/// much. The row is then the plain "更多"; the counted "查看全部 N" is kept for a known total, which wins when
/// both are given. A whole list has no row at all.
final class SearchResultsMoreTests: XCTestCase {
    private let strings = FlareStrings()
    private let item = SearchResultItem(id: "u1", kind: .contact, title: "周屿")

    func testAKnownTotalIsCountedAndAnUnknownOneIsNot() {
        XCTAssertEqual(SearchResultGroup(kind: .contact, label: "联系人", items: [item], total: 9, hasMore: true).moreText(strings), strings.viewAll(9))
        XCTAssertEqual(SearchResultGroup(kind: .contact, label: "联系人", items: [item], hasMore: true).moreText(strings), strings.more)
        XCTAssertEqual(SearchResultGroup(kind: .contact, label: "联系人", items: [item], total: 1, hasMore: true).moreText(strings), strings.more)
        XCTAssertNil(SearchResultGroup(kind: .contact, label: "联系人", items: [item], total: 1).moreText(strings))
        XCTAssertNil(SearchResultGroup(kind: .contact, label: "联系人", items: [item]).moreText(strings))
    }
}
