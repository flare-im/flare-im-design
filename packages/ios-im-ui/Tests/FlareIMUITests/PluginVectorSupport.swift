import Foundation
import XCTest
@testable import FlareIMUI

/// `spec/plugin-view-vectors.json` for the plugin test classes: the table, its decoders and the rows facts that both
/// the card table and the page table hold.
enum PluginVectors {
    static func table() throws -> PluginJSONValue {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/plugin-view-vectors.json"))
        return try JSONDecoder().decode(PluginJSONValue.self, from: data)
    }

    static func decode<T: Decodable>(_ type: T.Type, _ json: PluginJSONValue?) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(try XCTUnwrap(json)))
    }

    static func clock(_ table: PluginJSONValue) -> PluginViewClock {
        PluginViewClock(nowMs: Int64(table["nowMs"]?.numberValue ?? 0),
                        utcOffsetMinutes: Int(table["utcOffsetMinutes"]?.numberValue ?? 0))
    }

    /// The name a variant fact uses for an action's key.
    static func variant(_ action: PluginViewAction) -> String {
        switch PluginViewFormat.variant(action) {
        case .danger: return "danger"
        case .primary: return "primary"
        default: return "secondary"
        }
    }

    static func badge(_ fact: PluginJSONValue?) throws -> PluginBadge? {
        guard let fact, fact != .null else { return nil }
        return try decode(PluginBadge.self, fact)
    }

    /// Checks a rows block against its list facts (rules.pageRows) and returns the texts the list must draw.
    static func checkRows(_ block: PluginRowsBlock, _ fact: PluginJSONValue, clock: PluginViewClock,
                          strings: FlareStrings, id: String) throws -> [String] {
        XCTAssertEqual(fact["layout"]?.stringValue, "list", "\(id): a native kit draws rows as a list")
        let rows = PluginViewFormat.rowsOnce(block.rows)
        let items = fact["items"]?.arrayValue ?? []
        XCTAssertEqual(rows.map(\.key), items.compactMap { $0["key"]?.stringValue }, "\(id) row keys")
        var shown: [String] = []
        for (row, item) in zip(rows, items) {
            let label = "\(id) row \(row.key)"
            XCTAssertEqual(row.badge, try badge(item["badge"]), "\(label) badge")
            let lines = PluginViewFormat.rowLines(block, row, nowMs: clock.now(), strings,
                                                  utcOffsetMinutes: clock.utcOffsetMinutes)
            XCTAssertEqual(lines.primary, item["primary"]?.stringValue, "\(label) primary")
            XCTAssertEqual(lines.secondary, item["secondary"]?.stringValue, "\(label) secondary")
            let keys = PluginViewFormat.rowKeys(block, row)
            let keyFacts = item["actions"]?.arrayValue ?? []
            XCTAssertEqual(keys.map(\.action.id), keyFacts.compactMap { $0["id"]?.stringValue }, "\(label) keys")
            for (key, keyFact) in zip(keys, keyFacts) {
                XCTAssertEqual(key.action.label, keyFact["label"]?.stringValue, "\(label) \(key.action.id) label")
                XCTAssertEqual(variant(key.action), keyFact["variant"]?.stringValue, "\(label) \(key.action.id) variant")
            }
            shown += [row.badge?.text, lines.primary, lines.secondary].compactMap { $0 } + keys.map(\.action.label)
        }
        let empty = rows.isEmpty ? (block.emptyText.flatMap { $0.isEmpty ? nil : $0 } ?? strings.pluginViewEmpty) : nil
        XCTAssertEqual(empty, fact["empty"]?.stringValue, "\(id) empty")
        if let empty { shown.append(empty) }
        return shown
    }
}
