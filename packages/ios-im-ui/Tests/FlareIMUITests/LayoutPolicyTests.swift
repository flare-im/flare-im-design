import XCTest
import SwiftUI
@testable import FlareIMUI
final class LayoutPolicyTests: XCTestCase {
    func testSharedApplicationLayoutVectors() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("spec/application-layout-vectors.json")
        struct Expected: Decodable { let mode: String; let paneMode: String; let detail: String }
        struct Vector: Decodable { let id: String; let width: Double; let scale: Double; let hasDetail: Bool; let navigation: Bool; let expected: Expected }
        struct Fixture: Decodable { let cases: [Vector] }
        for v in try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url)).cases {
            let mode = resolveApplicationResponsiveMode(width: v.width, textScale: v.scale)
            XCTAssertEqual(mode.rawValue, v.expected.mode, v.id)
            let presentation = resolveWorkspacePresentation(mode, hasDetail: v.hasDetail, width: v.width, textScale: v.scale, navigationWidth: v.navigation ? nil : 0)
            XCTAssertEqual(presentation.paneMode.rawValue, v.expected.paneMode, v.id)
            XCTAssertEqual(presentation.detail.rawValue, v.expected.detail, v.id)
        }
    }
    /// The one pane rule (FR-110): every layout in the kit asks it how many panes fit.
    func testTheOnePaneRuleFollowsTheSharedTable() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("spec/application-layout-vectors.json")
        struct Vector: Decodable {
            let id: String; let width: Double; let scale: Double; let hasDetail: Bool; let navigationWidth: Double
            let primaryWidth: Double?; let detailWidth: Double?; let expected: String; let why: String
        }
        struct Fixture: Decodable { let panes: [Vector] }
        let panes = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url)).panes
        XCTAssertGreaterThanOrEqual(panes.count, 20)
        for v in panes {
            let mode = resolvePaneMode(width: v.width, hasDetail: v.hasDetail, textScale: v.scale,
                                       navigationWidth: v.navigationWidth,
                                       primaryWidth: v.primaryWidth.map { CGFloat($0) } ?? FlareSizes.primaryPaneDefaultWidth,
                                       detailWidth: v.detailWidth.map { CGFloat($0) } ?? FlareSizes.detailPaneDefaultWidth)
            XCTAssertEqual(mode.rawValue, v.expected, "\(v.id): \(v.why)")
        }
        XCTAssertEqual(paneModeMinWidth(.dualPane, navigationWidth: resolveNavigationWidth(.tablet)), 752)
        XCTAssertEqual(paneModeMinWidth(.triplePane), 980)
        XCTAssertEqual(paneModeMinWidth(.singlePane), 0)
    }
}
