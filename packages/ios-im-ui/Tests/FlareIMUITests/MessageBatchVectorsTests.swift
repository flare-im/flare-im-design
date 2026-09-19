import Foundation
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// FR-034: the message batch toolbar answers the same question the conversation one does — what may a
/// host do with this selection right now. `spec/message-batch-vectors.json` is the answer, on four kits.
final class MessageBatchVectorsTests: XCTestCase {
    private let s = FlareStrings()

    private struct Table: Decodable {
        struct Case: Decodable {
            let id: String
            let selected: Int
            let capabilities: [String]
            let busy: Bool
            let available: [String]
        }
        let order: [String]
        let minimumSelection: [String: Int]
        let cases: [Case]
    }

    private func table() throws -> Table {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("spec/message-batch-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    }

    private func capabilities(_ names: [String]) -> MessageBatchCapabilities {
        MessageBatchCapabilities(forwardEach: names.contains("forwardEach"), forwardMerged: names.contains("forwardMerged"),
                                 pin: names.contains("pin"), pinSelf: names.contains("pinSelf"), delete: names.contains("delete"))
    }

    private func ids(_ count: Int) -> [String] { (0..<count).map { "m\($0)" } }

    func testAvailabilityMatchesTheSharedTable() throws {
        let table = try table()
        XCTAssertGreaterThanOrEqual(table.cases.count, 8)
        for c in table.cases {
            let available = messageBatchActionsAvailable(ids(c.selected), capabilities(c.capabilities), c.busy)
            XCTAssertEqual(available.map(\.rawValue), c.available, c.id)
        }
    }

    func testTheDeclaredOrderAndMinimumsAreTheTables() throws {
        let table = try table()
        XCTAssertEqual(MessageBatchAction.allCases.map(\.rawValue), table.order)
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: flareMessageBatchMinimumSelection.map { ($0.key.rawValue, $0.value) }),
                       table.minimumSelection)
    }

    func testAMissingCapabilityObjectAllowsNothing() {
        XCTAssertEqual(messageBatchActionsAvailable(ids(3), nil, false), [])
    }

    @MainActor
    func testTheToolbarReportsOneActionWithTheIdsItWasGiven() throws {
        var reported: [String] = []
        var selectedAll = 0, cleared = 0
        let bar = MessageBatchToolbarView(
            selectedIds: ["a", "b"], total: 5,
            capabilities: MessageBatchCapabilities(forwardEach: true, forwardMerged: true, pin: true, pinSelf: true, delete: true),
            onAction: { action, ids in reported.append("\(action.rawValue):\(ids.joined(separator: ","))") },
            onSelectAll: { selectedAll += 1 }, onClearSelection: { cleared += 1 })

        try bar.inspect().find(button: s.messageBatchPin).tap()
        try bar.inspect().find(button: s.forwardMerged).tap()
        try bar.inspect().find(button: s.selectAll).tap()
        try bar.inspect().find(button: s.messageBatchClear).tap()

        XCTAssertEqual(reported, ["pin:a,b", "forwardMerged:a,b"])
        XCTAssertEqual(selectedAll, 1)
        XCTAssertEqual(cleared, 1)
    }

    @MainActor
    func testOnlyTheDeclaredActionsAreDrawnAndAShortSelectionCannotMerge() throws {
        var reported: [String] = []
        let bar = MessageBatchToolbarView(
            selectedIds: ["a"], total: 5,
            capabilities: MessageBatchCapabilities(forwardEach: true, forwardMerged: true),
            onAction: { action, _ in reported.append(action.rawValue) })

        XCTAssertThrowsError(try bar.inspect().find(button: s.messageBatchPin), "pinning is not declared")
        XCTAssertThrowsError(try bar.inspect().find(button: s.delete))
        XCTAssertTrue(try bar.inspect().find(button: s.forwardMerged).isDisabled(), "merging needs two")

        try bar.inspect().find(button: s.forwardEach).tap()
        XCTAssertEqual(reported, ["forwardEach"])
    }
}
