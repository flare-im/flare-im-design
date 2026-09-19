import Foundation
import XCTest
@testable import FlareIMUI

/// FR-057: a failed refresh over rows worth keeping does not wipe what someone was reading.
final class ViewStateVectorsTests: XCTestCase {
    private struct Table: Decodable {
        struct Case: Decodable { let id: String; let status: String; let stale: Bool; let presentation: String }
        let cases: [Case]
    }

    func testPresentationMatchesTheSharedTable() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("spec/view-state-vectors.json")
        let table = try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
        XCTAssertGreaterThanOrEqual(table.cases.count, 10)
        for c in table.cases {
            let status = try XCTUnwrap(FlareApplicationViewStatus(rawValue: c.status), c.id)
            XCTAssertEqual(flareViewPresentation(status, stale: c.stale).rawValue, c.presentation, c.id)
        }
    }
}
