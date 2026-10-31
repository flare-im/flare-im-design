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
        let around: Around
    }

    private struct Around: Decodable {
        struct Anchor: Decodable { let messageId: String; let seq: Int64? }
        struct Expected: Decodable { let outcome: String; let openCalls: Int; let showCalls: Int; let askedIds: [String] }
        struct Case: Decodable {
            let id: String
            let anchor: Anchor
            let loaded: Bool
            let openAnswer: String?
            let drawnFromShow: Int
            let cancelAfterShows: Int?
            let cancelAfterOpen: Bool?
            let expected: Expected
        }
        let settleAttempts: Int
        let cases: [Case]
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

    @MainActor
    func testEveryRunAroundTheMessageEndsTheSameWayHere() async throws {
        let around = try table().around
        XCTAssertEqual(around.settleAttempts, FlareLocate.settleAttempts)
        XCTAssertGreaterThanOrEqual(around.cases.count, 13)
        for vector in around.cases {
            let anchor = FlareLocateAnchor(messageId: vector.anchor.messageId, seq: vector.anchor.seq)
            let key = (vector.openAnswer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            var opens = 0
            var opened = false
            var asked: [String] = []
            var handed: [FlareLocateAnchor] = []
            let outcome = await FlareLocate.runAround(
                anchor: anchor,
                showInList: { id in
                    asked.append(id)
                    if vector.loaded && id == anchor.messageId { return true }
                    return opened && !key.isEmpty && id == key && asked.count >= vector.drawnFromShow
                },
                openAround: { given in
                    opens += 1
                    handed.append(given)
                    opened = true
                    return vector.openAnswer
                },
                settle: {},
                isCurrent: {
                    (vector.cancelAfterShows.map { asked.count < $0 } ?? true) && !((vector.cancelAfterOpen ?? false) && opened)
                })
            XCTAssertEqual("\(outcome)", vector.expected.outcome, "\(vector.id) outcome")
            XCTAssertEqual(opens, vector.expected.openCalls, "\(vector.id) opens")
            XCTAssertEqual(asked.count, vector.expected.showCalls, "\(vector.id) asks")
            XCTAssertEqual(asked, vector.expected.askedIds, "\(vector.id) asked ids")
            for given in handed { XCTAssertEqual(given, anchor, "\(vector.id) anchor handed over") }
        }
    }
}
