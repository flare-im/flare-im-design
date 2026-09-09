import XCTest
@testable import FlareIMUI
final class LayoutPolicyTests: XCTestCase {
    func testSharedDeviceVectors() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("spec/device-layout-vectors.json")
        struct Vector: Decodable { let width: Double; let scale: Double; let detail: Bool; let expected: Int }
        for v in try JSONDecoder().decode([Vector].self, from: Data(contentsOf: url)) {
            XCTAssertEqual(FlareLayoutPolicy.paneCount(width: v.width, hasDetail: v.detail, textScale: v.scale), v.expected, "width=\(v.width), scale=\(v.scale)")
        }
    }
}
