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
}
