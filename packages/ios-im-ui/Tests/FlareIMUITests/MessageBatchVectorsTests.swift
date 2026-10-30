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
            let selectedIds: [String]?
            let unforwardable: [String]?
            let capabilities: [String]
            let busy: Bool
            let available: [String]
            let reports: [String: [String]]?
            let unforwardableCount: Int?
        }
        struct Forward: Decodable { let actions: [String] }
        let order: [String]
        let minimumSelection: [String: Int]
        let forward: Forward
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

    private func selection(_ c: Table.Case) -> [String] { c.selectedIds ?? ids(c.selected) }

    func testAvailabilityMatchesTheSharedTable() throws {
        let table = try table()
        XCTAssertGreaterThanOrEqual(table.cases.count, 14)
        for c in table.cases {
            XCTAssertEqual(selection(c).count, c.selected, c.id)
            let available = messageBatchActionsAvailable(selection(c), capabilities(c.capabilities), c.busy,
                                                         Set(c.unforwardable ?? []))
            XCTAssertEqual(available.map(\.rawValue), c.available, c.id)
        }
    }

    func testTheReportedIdsAndTheUnforwardableCountAreTheTables() throws {
        let table = try table()
        let cases = table.cases.filter { $0.reports != nil }
        XCTAssertGreaterThanOrEqual(cases.count, 6)
        for c in cases {
            let unforwardable = Set(c.unforwardable ?? [])
            for (name, reported) in c.reports ?? [:] {
                let action = try XCTUnwrap(MessageBatchAction(rawValue: name), name)
                XCTAssertEqual(messageBatchActionIds(action, selection(c), unforwardable), reported, "\(c.id) \(name)")
            }
            XCTAssertEqual(messageBatchUnforwardableCount(selection(c), unforwardable), c.unforwardableCount, c.id)
        }
        XCTAssertEqual(MessageBatchAction.allCases.filter(\.forwards).map(\.rawValue), table.forward.actions)
    }

    /// The forward keys report only the forwardable ids, merging turns off with one left, and the count names the rest.
    @MainActor
    func testTheToolbarLeavesTheUnforwardableIdsOutOfTheForwardKeys() throws {
        var reported: [String] = []
        let bar = MessageBatchToolbarView(
            selectedIds: ["c", "a", "b"], total: 5,
            capabilities: MessageBatchCapabilities(forwardEach: true, forwardMerged: true, delete: true),
            unforwardableIds: ["a", "z"],
            onAction: { action, ids in reported.append("\(action.rawValue):\(ids.joined(separator: ","))") })
        try bar.inspect().find(button: s.forwardEach).tap()
        try bar.inspect().find(button: s.forwardMerged).tap()
        try bar.inspect().find(button: s.delete).tap()
        XCTAssertEqual(reported, ["forwardEach:c,b", "forwardMerged:c,b", "delete:c,a,b"])
        XCTAssertNoThrow(try bar.inspect().find(text: "1 条不支持转发"))

        let one = MessageBatchToolbarView(selectedIds: ["a", "b"], total: 5,
                                          capabilities: MessageBatchCapabilities(forwardEach: true, forwardMerged: true),
                                          unforwardableIds: ["a"])
        XCTAssertTrue(try one.inspect().find(button: s.forwardMerged).isDisabled(), "one forwardable id cannot merge")
        XCTAssertFalse(try one.inspect().find(button: s.forwardEach).isDisabled())
        let none = MessageBatchToolbarView(selectedIds: ["a", "b"], total: 5,
                                           capabilities: MessageBatchCapabilities(forwardEach: true))
        XCTAssertThrowsError(try none.inspect().find(text: "0 条不支持转发"))
        XCTAssertEqual(FlareStrings.english.messageBatchUnforwardableText(1, locale: Locale(identifier: "en_US")),
                       "1 message can't be forwarded")
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
