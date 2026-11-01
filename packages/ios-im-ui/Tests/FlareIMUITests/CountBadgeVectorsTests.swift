import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// `spec/count-badge-vectors.json`, the table the four kits run: what a navigation item's count badge and a filter tab's
/// badge read (``flareCountBadgeText(count:more:)``), and when a filter tab draws one
/// (``flareCountBadgeDrawn(count:more:)``).
final class CountBadgeVectorsTests: XCTestCase {
    private struct Vectors: Decodable {
        struct Case: Decodable { let id: String; let count: Int?; let more: Bool?; let text: String; let drawn: Bool }
        let cap: Int
        let overflow: String
        let cases: [Case]
    }

    private func vectors() throws -> Vectors {
        var root = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath()
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(
            Vectors.self, from: Data(contentsOf: root.appendingPathComponent("spec/count-badge-vectors.json")))
    }

    func testBadgesReadAsTheSharedTableSays() throws {
        let table = try vectors()
        XCTAssertGreaterThanOrEqual(table.cases.count, 14, "the shared table lost cases")
        XCTAssertEqual(table.cap, 99)
        XCTAssertEqual(table.overflow, "99+")
        for row in table.cases {
            XCTAssertEqual(flareCountBadgeText(count: row.count, more: row.more ?? false), row.text, "\(row.id) text")
            XCTAssertEqual(flareCountBadgeDrawn(count: row.count, more: row.more ?? false), row.drawn, "\(row.id) drawn")
            if row.more == nil {
                // A host that passes no `more` gets the default.
                XCTAssertEqual(flareCountBadgeText(count: row.count), row.text, "\(row.id) text by default")
                XCTAssertEqual(flareCountBadgeDrawn(count: row.count), row.drawn, "\(row.id) drawn by default")
            }
        }
    }

    func testAFilterTabDrawsTheSharedBadge() throws {
        for row in try vectors().cases {
            let option = FlareFilterTabOption(value: "requests", label: "申请", badge: row.count, badgeMore: row.more ?? false)
            let tabs = FilterTabsView(options: [option], selection: .constant("requests"))
            if row.drawn {
                XCTAssertNoThrow(try tabs.inspect().find(text: row.text), "\(row.id) draws \(row.text)")
            } else {
                XCTAssertThrowsError(try tabs.inspect().find(text: row.text), "\(row.id) draws no badge")
            }
        }
    }

    func testANavigationBadgeAndAFilterTabTakeMoreWithoutAnyHostChange() {
        // The new fields have defaults: a host that writes neither still builds and reads the same.
        XCTAssertFalse(FlareApplicationNavigationBadge(count: 3).more)
        XCTAssertFalse(FlareFilterTabOption(value: "requests", label: "申请", badge: 3, icon: "people").badgeMore)
        let more = FlareApplicationNavigationBadge(kind: .count, count: 5, more: true)
        XCTAssertEqual(flareCountBadgeText(count: more.count, more: more.more), "99+")
    }
}
