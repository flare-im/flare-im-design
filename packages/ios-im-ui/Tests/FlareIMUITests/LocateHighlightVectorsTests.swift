import CoreGraphics
import Foundation
import XCTest
@testable import FlareIMUI

/// The shared locate-mark table (`spec/locate-highlight-vectors.json`) is the one rule four kits follow: how
/// long the mark lasts, how it fades, and what a reader who asked for less motion gets instead — which is the
/// same mark, held still, never nothing. Vue's stylesheet holds the same numbers and its own test checks
/// them; the Flutter and Compose tests read this same file.
final class LocateHighlightVectorsTests: XCTestCase {
    private struct Table: Decodable {
        let durationMs: Double
        let cases: [Vector]
    }

    private struct Vector: Decodable {
        let id: String
        let elapsedMs: Double
        let reducedMotion: Bool
        let expected: Expected
    }

    private struct Expected: Decodable {
        let marked: Bool
        let alpha: Double
        let spread: Double
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let url = root.appendingPathComponent("spec/locate-highlight-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    }

    func testTheTableIsTheWindowThisKitWasBuiltWith() throws {
        let table = try table()
        XCTAssertEqual(table.durationMs, FlareLocateHighlight.durationMs)
        XCTAssertGreaterThanOrEqual(table.cases.count, 12)
    }

    func testEveryCaseResolvesTheSameWayHere() throws {
        for vector in try table().cases {
            let mark = FlareLocateHighlight.resolve(
                elapsedMs: vector.elapsedMs, reduceMotion: vector.reducedMotion)
            XCTAssertEqual(mark.marked, vector.expected.marked, "\(vector.id) marked")
            XCTAssertEqual(mark.alpha, vector.expected.alpha, accuracy: 0.001, "\(vector.id) alpha")
            XCTAssertEqual(
                Double(mark.spread), vector.expected.spread, accuracy: 0.001, "\(vector.id) spread")
        }
    }
}
