import Foundation
import XCTest
import CoreImage
@testable import FlareIMUI

final class ScanVectorsTests: XCTestCase {
    func testExportedCodeDecodesToTheSameCanonicalUrl() throws {
        let value = "https://scan.example.test/u/0123456789ABCDEFGHIJKLZ"
        let data = try XCTUnwrap(FlareQrExport.pngData(payload: value))
        let image = try XCTUnwrap(CIImage(data: data))
        let detector = try XCTUnwrap(CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]))
        let code = try XCTUnwrap(detector.features(in: image).first as? CIQRCodeFeature)
        XCTAssertEqual(code.messageString, value)
    }
    private func table(_ name: String) throws -> [String: Any] {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("spec/\(name).json"))) as? [String: Any])
    }

    func testCameraArbitrationMatchesSharedVectors() throws {
        let cases = try XCTUnwrap(table("scan-gate-vectors")["cases"] as? [[String: Any]])
        for item in cases {
            let gate = FlareScanHitGate()
            for step in try XCTUnwrap(item["steps"] as? [[String: Any]]) {
                if step["dismiss"] as? Bool == true { gate.dismiss(); continue }
                let hit: FlareScanHit
                if let selected = step["select"] as? String { hit = gate.select(selected) }
                else {
                    hit = gate.observe(codes: (step["codes"] as? [String] ?? []).map { .init(raw: $0) }, tsMs: step["tsMs"] as? Double ?? 0)
                }
                let expected = try XCTUnwrap(step["expect"] as? [String: Any])
                let name = item["name"] as? String ?? ""
                switch hit {
                case .ignore: XCTAssertEqual(expected["kind"] as? String, "ignore", name)
                case .lock(let code, let ready):
                    XCTAssertEqual(expected["kind"] as? String, "lock", name)
                    XCTAssertEqual(expected["raw"] as? String, code.raw, name)
                    XCTAssertEqual(expected["ready"] as? Bool, ready, name)
                case .choose(let codes):
                    XCTAssertEqual(expected["kind"] as? String, "choose", name)
                    XCTAssertEqual(expected["raws"] as? [String], codes.map(\.raw), name)
                }
            }
        }
    }

    func testMarkerBoundsAndRefreshMatchSharedViewVectors() throws {
        let vectors = try table("scan-view-vectors")
        for item in try XCTUnwrap(vectors["markerBounds"] as? [[String: Any]]) {
            let points = (item["corners"] as? [[String: Double]] ?? []).map { FlareScanPoint(x: $0["x"] ?? .nan, y: $0["y"] ?? .nan) }
            let bounds = flareScanMarkerBounds(points)
            let expected = try XCTUnwrap(item["expect"] as? [String: Double])
            for (key, value) in ["left": bounds.left, "top": bounds.top, "width": bounds.width, "height": bounds.height] {
                XCTAssertEqual(value, try XCTUnwrap(expected[key]), accuracy: 0.000001)
            }
        }
        for item in try XCTUnwrap(vectors["pluginRefresh"] as? [[String: Any]]) {
            let allowed = flareScanPluginCanRefresh(visible: item["visible"] as? Bool ?? false,
                foreground: item["foreground"] as? Bool ?? false, loading: item["loading"] as? Bool ?? false,
                refreshing: item["refreshing"] as? Bool ?? false, busy: item["busy"] as? Bool ?? false,
                interaction: item["interaction"] as? Bool ?? false)
            XCTAssertEqual(allowed, item["expect"] as? Bool, item["name"] as? String ?? "")
        }
    }
}
