import XCTest
@testable import FlareIMUI

final class RecentSearchesTests: XCTestCase {
    func testRememberTrimsMovesRepeatToFrontAndCaps() {
        XCTAssertEqual(flareRememberSearch(["b", "a"], "  a "), ["a", "b"])
        XCTAssertEqual(flareRememberSearch(["c", "b", "a"], "d", max: 3), ["d", "c", "b"])
        XCTAssertEqual(flareRememberSearch(["a"], "   "), ["a"])
        XCTAssertEqual(flareRememberSearch(["a"], "b", max: -1), [])
    }
}
