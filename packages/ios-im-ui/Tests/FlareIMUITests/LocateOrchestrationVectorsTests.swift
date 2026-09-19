import Foundation
import XCTest
@testable import FlareIMUI

/// The shared locate table (`spec/locate-orchestration-vectors.json`) is the one trip four kits make when a
/// quote names a message that is not loaded. Each case scripts a run; the expectations count the whole trip,
/// so a kit that asks or pages a different number of times fails even when it lands on the same answer.
final class LocateOrchestrationVectorsTests: XCTestCase {
    private struct Table: Decodable {
        let maxPages: Int
        let settleAttempts: Int
        let cases: [Vector]
    }

    private struct Vector: Decodable {
        let id: String
        let historyPages: Int
        let foundAfterPages: Int?
        let failAtPage: Int?
        let cancelAfterShows: Int?
        let visibleFromShow: Int?
        let expected: Expected
    }

    private struct Expected: Decodable {
        let outcome: String
        let pagesRead: Int
        let showCalls: Int
    }

    /// The run the script describes, kept in one place so every case counts the same way.
    @MainActor
    private final class Script {
        let vector: Vector
        var pages = 0
        var shows = 0
        init(_ vector: Vector) { self.vector = vector }

        func isCurrent() -> Bool {
            guard let cancelAfter = vector.cancelAfterShows else { return true }
            return shows < cancelAfter
        }

        func show() -> Bool {
            shows += 1
            guard let found = vector.foundAfterPages else { return false }
            return pages >= found && shows >= (vector.visibleFromShow ?? 1)
        }

        func hasOlder() -> Bool { pages < vector.historyPages }

        func readOlder() -> Bool {
            pages += 1
            guard let fail = vector.failAtPage else { return true }
            return pages != fail
        }
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let url = root.appendingPathComponent("spec/locate-orchestration-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    }

    func testTheTableIsTheBudgetThisKitWasBuiltWith() throws {
        let table = try table()
        XCTAssertEqual(table.maxPages, FlareLocate.maxPages)
        XCTAssertEqual(table.settleAttempts, FlareLocate.settleAttempts)
        XCTAssertGreaterThanOrEqual(table.cases.count, 13)
    }

    @MainActor
    func testEveryRunEndsTheSameWayHere() async throws {
        for vector in try table().cases {
            let script = Script(vector)
            let outcome = await FlareLocate.run(
                showInList: { script.show() },
                hasOlder: { script.hasOlder() },
                readOlder: { script.readOlder() },
                settle: {},
                isCurrent: { script.isCurrent() })
            XCTAssertEqual("\(outcome)", vector.expected.outcome, "\(vector.id) outcome")
            XCTAssertEqual(script.pages, vector.expected.pagesRead, "\(vector.id) pages read")
            XCTAssertEqual(script.shows, vector.expected.showCalls, "\(vector.id) asks")
        }
    }
}
