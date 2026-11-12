import CoreGraphics
import Foundation
import XCTest
@testable import FlareIMUI

/// The shared swipe-to-reply table (`spec/swipe-reply-vectors.json`) is the one rule three kits follow:
/// which direction counts, when the list's own scrolling wins instead, how far the row follows the finger,
/// and where the gesture arms. The same file is read by the Flutter and Compose tests, so a number that
/// drifts on this platform fails on this platform alone.
final class SwipeReplyVectorsTests: XCTestCase {
    private struct Table: Decodable {
        let armDistance: Double
        let maxTravel: Double
        let cases: [Vector]
    }

    private struct Vector: Decodable {
        let id: String
        let dx: Double
        let dy: Double
        let rtl: Bool
        let expected: Expected
    }

    private struct Expected: Decodable {
        let travel: Double
        let armed: Bool
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let url = root.appendingPathComponent("spec/swipe-reply-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    }

    func testTheTableIsTheGeometryThisKitWasBuiltWith() throws {
        let table = try table()
        XCTAssertEqual(CGFloat(table.armDistance), FlareSwipeReply.armDistance)
        XCTAssertEqual(CGFloat(table.maxTravel), FlareSwipeReply.maxTravel)
        XCTAssertGreaterThanOrEqual(table.cases.count, 19)
    }

    func testEveryCaseResolvesTheSameWayHere() throws {
        for vector in try table().cases {
            let gesture = FlareSwipeReply.resolve(
                dx: CGFloat(vector.dx), dy: CGFloat(vector.dy), rtl: vector.rtl)
            XCTAssertEqual(
                Double(gesture.travel), vector.expected.travel, accuracy: 0.001,
                "\(vector.id) travel")
            XCTAssertEqual(gesture.armed, vector.expected.armed, "\(vector.id) armed")
        }
    }

    /// The pan that carries the swipe on iOS 18 begins only on a drag that the table would also give to the row:
    /// a vertical or mostly vertical drag is the timeline's from its first point.
    func testOnlyAMostlySidewaysDragIsTheSwipes() {
        XCTAssertTrue(FlareSwipeReply.claims(dx: 300, dy: 40))
        XCTAssertTrue(FlareSwipeReply.claims(dx: -125, dy: 100))
        XCTAssertFalse(FlareSwipeReply.claims(dx: 120, dy: 100))
        XCTAssertFalse(FlareSwipeReply.claims(dx: 10, dy: 600))
        XCTAssertFalse(FlareSwipeReply.claims(dx: 0, dy: 0))
        for (dx, dy) in [(300.0, 40.0), (120.0, 100.0), (10.0, 600.0)] {
            // Whatever the start claims, a drag the row cannot follow resolves to nothing.
            if !FlareSwipeReply.claims(dx: dx, dy: dy) {
                XCTAssertEqual(FlareSwipeReply.resolve(dx: dx, dy: dy, rtl: false), .none)
            }
        }
    }
}
