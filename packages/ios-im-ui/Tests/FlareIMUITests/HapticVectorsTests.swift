import Foundation
import XCTest
@testable import FlareIMUI

/// The shared haptics table (`spec/haptic-vectors.json`) is the one rule three kits follow for the tick a
/// gesture gives when it crosses the line where letting go starts to mean something else: one tick per
/// change of state, in both directions, never per frame. The tick itself is a device's to feel — this
/// counts the asks.
final class HapticVectorsTests: XCTestCase {
    private struct Table: Decodable {
        let cases: [Vector]
    }

    private struct Vector: Decodable {
        let id: String
        let states: [Bool]
        let expected: Expected
        let why: String
    }

    private struct Expected: Decodable {
        let ticks: Int
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let url = root.appendingPathComponent("spec/haptic-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    }

    func testEveryRunTicksTheSameNumberOfTimesHere() throws {
        let table = try table()
        XCTAssertGreaterThanOrEqual(table.cases.count, 8)
        for vector in table.cases {
            var ticks = 0
            for index in 1..<max(vector.states.count, 1) where
                flareHapticCrossed(was: vector.states[index - 1], now: vector.states[index]) {
                ticks += 1
            }
            XCTAssertEqual(ticks, vector.expected.ticks, "\(vector.id): \(vector.why)")
        }
    }
}
