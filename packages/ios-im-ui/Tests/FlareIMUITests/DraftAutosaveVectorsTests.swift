import Foundation
import XCTest
@testable import FlareIMUI

/// The shared draft table (`spec/draft-vectors.json`): the composer's edits in, the writes this client
/// owes the core out. The Vue, Flutter and Compose kits run the same file through the same driver.
final class DraftAutosaveVectorsTests: XCTestCase {
    private struct Table: Decodable { let rules: Rules; let cases: [Vector] }
    private struct Rules: Decodable { let saveDelayMs: Int }
    private struct Vector: Decodable { let name: String; let steps: [Step]; let endAt: Int; let expect: [Expected] }
    private struct Step: Decodable { let at: Int; let op: String; let conversationId: String?; let text: String? }
    private struct Expected: Decodable { let at: Int; let conversationId: String; let text: String }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: root.appendingPathComponent("spec/draft-vectors.json")))
    }

    func testUsesTheTablesDelay() throws {
        XCTAssertEqual(try table().rules.saveDelayMs, FlareDraft.saveDelayMs)
    }

    func testEveryScriptWritesTheSameThingHere() throws { try runEveryScript(base: 0) }

    /// The same scripts with the clock where a real one is — see `TypingSignalVectorsTests`.
    func testEveryScriptWritesTheSameThingWithARealClock() throws { try runEveryScript(base: 1_767_000_000_000) }

    private func runEveryScript(base: Int) throws {
        for vector in try table().cases {
            let drafts = FlareDraftAutosave()
            var saves: [FlareDraftSave] = []
            for step in vector.steps {
                let at = base + step.at
                saves.append(contentsOf: drafts.tick(at))
                let cid = step.conversationId ?? ""
                let text = step.text ?? ""
                switch step.op {
                case "seed": drafts.seed(cid, text: text)
                case "edit": saves.append(contentsOf: drafts.edit(cid, text: text, nowMs: at))
                case "send": saves.append(contentsOf: drafts.send(cid, nowMs: at))
                case "restore": saves.append(contentsOf: drafts.restore(cid, failedText: text, nowMs: at))
                case "leave": saves.append(contentsOf: drafts.leave(nowMs: at))
                default: break
                }
            }
            saves.append(contentsOf: drafts.tick(base + vector.endAt))
            let expected = vector.expect.map { FlareDraftSave(conversationId: $0.conversationId, text: $0.text, atMs: base + $0.at) }
            XCTAssertEqual(saves, expected, "\(vector.name) @ base=\(base)")
        }
    }
}
