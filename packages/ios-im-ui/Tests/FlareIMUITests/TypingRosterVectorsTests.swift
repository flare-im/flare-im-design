import Foundation
import XCTest
@testable import FlareIMUI

/// The shared typing table (`spec/typing-vectors.json`), `roster` half: facts about peers in, the people
/// typing out. The Vue, Flutter and Compose kits run the same file through the same driver.
final class TypingRosterVectorsTests: XCTestCase {
    private struct Table: Decodable {
        let rules: Rules
        let roster: Roster
    }

    private struct Rules: Decodable { let peerTtlMs: Int }
    private struct Roster: Decodable { let selfId: String; let cases: [Vector] }

    private struct Vector: Decodable {
        let name: String
        let watch: String
        let steps: [Step]
        let endAt: Int
        let expect: [Snapshot]
        let nextExpiryAtEnd: Int??
    }

    private struct Step: Decodable {
        let at: Int
        let op: String
        let conversationId: String?
        let userId: String?
        let userIds: [String]?
        let senderId: String?
    }

    private struct Snapshot: Decodable, Equatable { let at: Int; let typers: [String] }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: root.appendingPathComponent("spec/typing-vectors.json")))
    }

    func testExpiresABeliefOnTheTablesTtl() throws {
        XCTAssertEqual(try table().rules.peerTtlMs, FlareTyping.peerTtlMs)
    }

    func testEveryScriptBelievesTheSameThingHere() throws { try runEveryScript(base: 0) }

    /// The same scripts with the clock where a real one is — see `TypingSignalVectorsTests`.
    func testEveryScriptBelievesTheSameThingWithARealClock() throws { try runEveryScript(base: 1_767_000_000_000) }

    private func runEveryScript(base: Int) throws {
        let loaded = try table()
        for vector in loaded.roster.cases {
            let roster = FlareTypingRoster(selfId: loaded.roster.selfId)
            var seen: [Snapshot] = []
            var last: [String] = []
            let ids = Set(vector.steps.map { $0.conversationId ?? "" })

            func record(_ at: Int) {
                let typers = roster.typers(vector.watch)
                guard typers != last else { return }
                last = typers
                seen.append(Snapshot(at: at - base, typers: typers))
            }
            func snapshot() -> [[String]] { ids.sorted().map { roster.typers($0) } }
            func advance(to: Int) {
                // Beliefs expire at their own deadline, so the record carries that instant, not the step's.
                // The bound is not decoration: this loop asks the rule when to prune next, so a rule that
                // stops making progress would spin here forever, and a harness that hangs is worse than
                // one that fails.
                var guardCount = 0
                while let next = roster.nextExpiry, next <= to {
                    guardCount += 1
                    XCTAssertLessThan(guardCount, vector.steps.count + 64, "\(vector.name): prune made no progress")
                    if guardCount >= vector.steps.count + 64 { return }
                    let before = snapshot()
                    roster.prune(next)
                    XCTAssertNotEqual(snapshot(), before, "\(vector.name): prune at \(next) dropped nothing")
                    record(next)
                }
            }

            for step in vector.steps {
                let at = base + step.at
                advance(to: at)
                switch step.op {
                case "started": roster.started(step.conversationId ?? "", userId: step.userId ?? "", nowMs: at)
                case "stopped": roster.stopped(step.conversationId ?? "", userId: step.userId ?? "")
                case "replaced": roster.replaced(step.conversationId ?? "", userIds: step.userIds ?? [], nowMs: at)
                case "sent": roster.sent(step.conversationId ?? "", senderId: step.senderId ?? "")
                default: break
                }
                record(at)
            }
            advance(to: base + vector.endAt)

            XCTAssertEqual(seen, vector.expect, "\(vector.name) @ base=\(base)")
            if let declared = vector.nextExpiryAtEnd {
                let next = roster.nextExpiry
                XCTAssertEqual(next.map { $0 - base }, declared, "\(vector.name) next expiry")
            }
        }
    }
}
