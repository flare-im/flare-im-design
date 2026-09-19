import Foundation
import XCTest
@testable import FlareIMUI

/// The shared typing table (`spec/typing-vectors.json`), `signal` half: the composer's edits in, the
/// reports this client owes the conversation out. The Vue, Flutter and Compose kits run the same file
/// through the same driver, so a rule that is right here is right there or the difference is a failure.
final class TypingSignalVectorsTests: XCTestCase {
    private struct Table: Decodable {
        let rules: Rules
        let signal: Signal
    }

    private struct Rules: Decodable {
        let idleStopMs: Int
        let refreshMs: Int
        let peerTtlMs: Int
    }

    private struct Signal: Decodable { let cases: [Vector] }

    private struct Vector: Decodable {
        let name: String
        let steps: [Step]
        let endAt: Int
        let expect: [Expected]
    }

    private struct Step: Decodable {
        let at: Int
        let op: String
        let conversationId: String?
        let text: String?
    }

    private struct Expected: Decodable {
        let at: Int
        let conversationId: String
        let typing: Bool
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let url = root.appendingPathComponent("spec/typing-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    }

    func testUsesTheTablesConstantsSoTheFourKitsCannotDriftApartQuietly() throws {
        let rules = try table().rules
        XCTAssertEqual(rules.idleStopMs, FlareTyping.idleStopMs)
        XCTAssertEqual(rules.refreshMs, FlareTyping.refreshMs)
        XCTAssertEqual(rules.peerTtlMs, FlareTyping.peerTtlMs)
    }

    func testRefreshesBeforeThePeersBeliefExpires() {
        // The invariant the table states. Two apps shipped without it and went silent mid-sentence.
        XCTAssertLessThan(FlareTyping.refreshMs, FlareTyping.peerTtlMs)
    }

    func testEveryScriptReportsTheSameThingHere() throws {
        try runEveryScript(base: 0)
    }

    /// The same scripts again with the clock where a real one is. A table whose times start at zero is
    /// comfortably inside a 32-bit int; a wall clock is not, and a kit that stored "now" in one would wrap
    /// to a negative instant and never stop typing — a defect no zero-based script can see. The Compose kit
    /// was written that way first; this is the guard that found it.
    func testEveryScriptReportsTheSameThingWithARealClock() throws {
        try runEveryScript(base: 1_767_000_000_000)
    }

    private func runEveryScript(base: Int) throws {
        for vector in try table().signal.cases {
            let signal = FlareTypingSignal()
            var reports: [FlareTypingReport] = []
            for step in vector.steps {
                let at = base + step.at
                // Time first, then the step: an idle stop that fell due in between must be reported before it.
                reports.append(contentsOf: signal.tick(at))
                switch step.op {
                case "edit": reports.append(contentsOf: signal.edit(step.conversationId ?? "", text: step.text ?? "", nowMs: at))
                case "send": reports.append(contentsOf: signal.send(step.conversationId ?? "", nowMs: at))
                case "close": reports.append(contentsOf: signal.close(nowMs: at))
                default: break
                }
            }
            reports.append(contentsOf: signal.tick(base + vector.endAt))
            let expected = vector.expect.map {
                FlareTypingReport(conversationId: $0.conversationId, typing: $0.typing, atMs: base + $0.at)
            }
            XCTAssertEqual(reports, expected, "\(vector.name) @ base=\(base)")
        }
    }
}
