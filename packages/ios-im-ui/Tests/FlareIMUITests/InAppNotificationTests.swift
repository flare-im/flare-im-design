import Foundation
import XCTest
@testable import FlareIMUI

/// The shared queue table (`spec/in-app-notification-vectors.json`): items fed into ``FlareInAppNotifications``,
/// what shows and waits, and when the visible banner's time starts over. The Vue, Flutter and Compose kits run the
/// same file.
final class InAppNotificationTests: XCTestCase {
    private struct Table: Decodable {
        struct Limits: Decodable { let durationMs: Int; let pendingLimit: Int }
        let limits: Limits
        let cases: [Vector]
    }
    private struct Vector: Decodable { let name: String; let steps: [Step] }
    private struct Step: Decodable {
        let op: String
        let item: String?
        let collapseIds: [String]?
        let current: String?
        let pending: [String]
        let restart: Bool
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(
            Table.self, from: Data(contentsOf: root.appendingPathComponent("spec/in-app-notification-vectors.json")))
    }

    private func item(_ text: String) -> FlareInAppNotification {
        let parts = text.split(separator: "/", maxSplits: 1).map(String.init)
        return FlareInAppNotification(collapseId: parts[0], conversationId: String(parts[0].dropFirst(2)),
                                      title: parts[0], body: parts[1])
    }

    private func written(_ entry: FlareInAppNotification?) -> String? {
        entry.map { "\($0.collapseId)/\($0.body)" }
    }

    func testTheLimitsAreTheSharedOnes() throws {
        let limits = try table().limits
        XCTAssertEqual(Int(inAppNotificationDuration * 1000), limits.durationMs)
        XCTAssertEqual(inAppNotificationPendingLimit, limits.pendingLimit)
    }

    @MainActor func testEveryCaseQueuesAsTheTableSays() throws {
        let cases = try table().cases
        XCTAssertFalse(cases.isEmpty)
        for vector in cases {
            let presenter = FlareInAppNotifications()
            for (index, step) in vector.steps.enumerated() {
                let before = presenter.revision
                switch step.op {
                case "present": presenter.present(item(try XCTUnwrap(step.item)))
                case "dismiss": presenter.dismiss()
                case "clear": presenter.clear(step.collapseIds ?? [])
                case "clearAll": presenter.clearAll()
                default: XCTFail("unknown op \(step.op)")
                }
                let place = "\(vector.name) step \(index + 1)"
                XCTAssertEqual(written(presenter.current), step.current, place)
                XCTAssertEqual(presenter.pending.compactMap { written($0) }, step.pending, place)
                XCTAssertEqual(presenter.revision != before, step.restart, place)
            }
        }
    }

    func testAReaderHearsTheLabelTitleTagCountAndBody() {
        let alice = FlareInAppNotification(collapseId: "c:a", conversationId: "a", messageId: "m1", title: "Alice",
                                           body: "are you free?", count: 3, channel: .mentions)
        XCTAssertEqual(alice.spoken(.english), "New message, Alice, [Mention], [3 messages], are you free?")
        XCTAssertEqual(alice.spoken(), "新消息, Alice, [有人@我], [3条], are you free?")
        let bob = FlareInAppNotification(collapseId: "c:b", conversationId: "b", title: "Bob", body: "lunch",
                                         channel: .urgent)
        XCTAssertEqual(bob.tag(.english), "[Urgent]")
        XCTAssertEqual(bob.spoken(.english), "New message, Bob, [Urgent], lunch")
        XCTAssertFalse(bob.showsCount)
    }
}
