import Foundation
import XCTest
@testable import FlareIMUI

final class PluginRefreshVectorsTests: XCTestCase {
    private func table(_ name: String) throws -> [String: Any] {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("spec/\(name).json"))) as? [String: Any])
    }

    func testPluginRefreshMatchesSharedVectors() throws {
        let vectors = try table("plugin-refresh-vectors")
        for item in try XCTUnwrap(vectors["pluginRefresh"] as? [[String: Any]]) {
            let allowed = flareScanPluginCanRefresh(visible: item["visible"] as? Bool ?? false,
                foreground: item["foreground"] as? Bool ?? false, loading: item["loading"] as? Bool ?? false,
                refreshing: item["refreshing"] as? Bool ?? false, busy: item["busy"] as? Bool ?? false,
                interaction: item["interaction"] as? Bool ?? false)
            XCTAssertEqual(allowed, item["expect"] as? Bool, item["name"] as? String ?? "")
        }
    }

    /// §12.1: done lands on the nearest overview or records page below the top one, else closes.
    func testDoneTargetMatchesSharedVectors() throws {
        let rows = try XCTUnwrap(try table("plugin-refresh-vectors")["doneTarget"] as? [[String: Any]])
        XCTAssertFalse(rows.isEmpty)
        for row in rows {
            let stack = try XCTUnwrap(row["stack"] as? [String]).map { try XCTUnwrap(PluginPageKind(rawValue: $0)) }
            let expect = try XCTUnwrap(row["expect"] as? [String: Any])
            XCTAssertEqual(PluginRefreshRules.doneTarget(stack), expect["target"] as? Int, row["name"] as? String ?? "")
        }
    }
}
