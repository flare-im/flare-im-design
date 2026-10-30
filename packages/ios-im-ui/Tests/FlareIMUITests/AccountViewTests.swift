import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

final class AccountViewTests: XCTestCase {
    private func view() throws -> PluginViewModel {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("spec/account-view-vectors.json")
        let json = try JSONDecoder().decode(PluginJSONValue.self, from: Data(contentsOf: url))
        return try PluginVectors.decode(PluginViewModel.self, json["view"])
    }
    func testExactAmountsAndBindings() throws {
        let entries = FlareAccountEntry.entries(try view())
        XCTAssertEqual(entries.map(\.amount), ["+¥88.88", "-¥52.00", "+¥3.00", "+¥200.00", "+$0.88"])
        XCTAssertEqual(entries.first?.subtitle, "周五快乐")
        XCTAssertEqual(entries.first?.row.actions.first?.input["packetId"], .string("packet-01"))
        XCTAssertTrue(entries[3].row.actions.isEmpty)
    }
    func testDeduplicatesAndKeepsUnknownDatesUnknown() throws {
        let view = try view()
        guard case .rows(let block) = view.blocks.first else { return XCTFail("missing ledger") }
        let duplicate = PluginViewModel(available: true, title: "", blocks: [.rows(PluginRowsBlock(columns: block.columns, rows: block.rows + [block.rows[0]]))])
        XCTAssertEqual(FlareAccountEntry.entries(duplicate).count, block.rows.count)
        let unknown = PluginViewModel(available: true, title: "", blocks: [.rows(PluginRowsBlock(columns: [], rows: [PluginRow(key: "unknown", cells: [])]))])
        XCTAssertNil(FlareAccountEntry.entries(unknown).first?.timeMs)
    }
    @MainActor func testAccountPresentationShowsOriginalBalance() throws {
        let account = FlareAccountView(view: try view())
        XCTAssertNoThrow(try account.inspect().find(text: "¥1,288.66"))
        XCTAssertNoThrow(try account.inspect().find(text: "交易记录"))
    }
}
