import XCTest
@testable import FlareIMUI

/// Entry times, day headings over page rows and the maskable hero (`spec/plugin-view-vectors.json` rules.entryTime,
/// rowsGroupByDay, heroMask and the rowDays facts): what the account renderer showed, in plain blocks.
final class PluginPlainAccountTests: XCTestCase {
    private func table() throws -> PluginJSONValue {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/plugin-view-vectors.json"))
        return try JSONDecoder().decode(PluginJSONValue.self, from: data)
    }

    func testDayHeadingsFollowTheSharedFacts() throws {
        let table = try table()
        let facts = try XCTUnwrap(table["rowDays"])
        let times = (facts["timesMs"]?.arrayValue ?? []).map { $0.numberValue.map { Int64($0) } }
        let block = PluginRowsBlock(
            columns: [PluginRowsColumn(label: "金额"), PluginRowsColumn(label: "时间", format: .time)],
            rows: times.enumerated().map { index, ms in
                PluginRow(key: "\(index)", cells: [PluginRowCell(text: "1"), PluginRowCell(text: "", timeMs: ms)])
            },
            groupByDay: true)
        let now = Int64(table["nowMs"]?.numberValue ?? 0)
        let offset = Int(facts["utcOffsetMinutes"]?.numberValue ?? 0)
        let expected = { (key: String) in (facts[key]?.arrayValue ?? []).map(\.stringValue) }
        XCTAssertEqual(PluginViewFormat.rowDayHeadings(block, nowMs: now, FlareStrings(), utcOffsetMinutes: offset),
                       expected("zh"))
        XCTAssertEqual(PluginViewFormat.rowDayHeadings(block, nowMs: now, FlareStrings.english, utcOffsetMinutes: offset),
                       expected("en"))
        let flat = PluginRowsBlock(columns: block.columns, rows: block.rows)
        XCTAssertTrue(PluginViewFormat.rowDayHeadings(flat, nowMs: now, FlareStrings(), utcOffsetMinutes: offset)
            .allSatisfy { $0 == nil })
    }

    func testTheNewFieldsDecode() throws {
        let entry = try JSONDecoder().decode(PluginEntry.self, from: Data(#"{"index":1,"text":"5.00","timeMs":7}"#.utf8))
        XCTAssertEqual(entry.timeMs, 7)
        let rows = try JSONDecoder().decode(PluginRowsBlock.self, from: Data(#"{"columns":[],"rows":[],"groupByDay":true}"#.utf8))
        XCTAssertTrue(rows.groupByDay)
        let hero = try JSONDecoder().decode(PluginHeroBlock.self,
                                            from: Data(#"{"value":"12.00","amount":true,"tone":"brand","maskable":true}"#.utf8))
        XCTAssertTrue(hero.maskable)
        let plain = try JSONDecoder().decode(PluginHeroBlock.self, from: Data(#"{"value":"12.00"}"#.utf8))
        XCTAssertFalse(plain.maskable)
    }
}
