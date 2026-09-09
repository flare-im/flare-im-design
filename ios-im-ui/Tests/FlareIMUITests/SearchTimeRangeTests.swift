import XCTest
@testable import FlareIMUI
final class SearchTimeRangeTests: XCTestCase {
    func testInclusiveBoundsAndSnapshotIdentity() {
        XCTAssertTrue(FlareSearchRangeOption(id: "r", label: "range", fromTime: 0, toTime: 100).isValid)
        XCTAssertFalse(FlareSearchRangeOption(id: "r", label: "range", fromTime: 2, toTime: 1).isValid)
        XCTAssertFalse(FlareSearchRangeOption(id: "r", label: "range", fromTime: -1).isValid)
        XCTAssertNotEqual(FlareSearchCriteria(query: "x", filterId: "file", toTime: 100), FlareSearchCriteria(query: "x", filterId: "file", toTime: 101))
    }
}
