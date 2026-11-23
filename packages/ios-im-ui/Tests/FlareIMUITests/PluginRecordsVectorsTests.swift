import XCTest
@testable import FlareIMUI

/// §4.7 of docs/plugin-experience.md against `spec/plugin-view-vectors.json`: a page's sibling tabs (pageTabs) and a
/// rows block drawn as records (rowsIcon). The same rows run in the Vue, Flutter and Compose kits.
final class PluginRecordsVectorsTests: XCTestCase {
    private let s = FlareStrings()

    private func table() throws -> PluginJSONValue {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/plugin-view-vectors.json"))
        return try JSONDecoder().decode(PluginJSONValue.self, from: data)
    }

    private func decode<T: Decodable>(_ type: T.Type, _ json: PluginJSONValue?) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(try XCTUnwrap(json)))
    }

    private func rows(_ group: String, _ table: PluginJSONValue) throws -> [PluginJSONValue] {
        let mine = try XCTUnwrap(table[group]?.arrayValue, "the table lost \(group)").filter {
            ($0["platforms"]?.arrayValue ?? [.string("ios")]).contains(.string("ios"))
        }
        XCTAssertFalse(mine.isEmpty, "\(group) has no iOS rows")
        return mine
    }

    private func name(_ row: PluginJSONValue) -> String { row["name"]?.stringValue ?? "?" }

    /// A page view as the core resolves it: the view with its tabs.
    private func page(_ json: PluginJSONValue?) throws -> PluginPageViewModel? {
        guard let json, json != .null else { return nil }
        var object = json.objectValue ?? [:]
        if object["available"] == nil { object["available"] = true }
        if object["title"] == nil { object["title"] = "" }
        return try decode(PluginPageViewModel.self, .object(object))
    }

    func testPageTabs() throws {
        for row in try rows("pageTabs", try table()) {
            let ref = try decode(PluginPageRef.self, row["page"])
            let expect = try XCTUnwrap(row["expect"])
            if let views = row["views"]?.arrayValue {
                for json in views {
                    XCTAssertTrue(PluginPageRules.tabs(view: try page(json), page: ref.page, last: []).isEmpty, name(row))
                }
                continue
            }
            let last = try page(row["previous"])?.tabs ?? []
            let tabs = PluginPageRules.tabs(view: try page(row["view"]), page: ref.page, last: last)
            XCTAssertEqual(tabs.map(\.label), (expect["tabs"]?.arrayValue ?? []).compactMap(\.stringValue), name(row))
            if let selected = expect["selected"]?.numberValue {
                XCTAssertEqual(tabs.firstIndex(where: \.selected), Int(selected), name(row))
            }
            if let choose = row["choose"]?.numberValue {
                XCTAssertEqual(PluginPageRules.tabChoice(tabs, index: Int(choose)), expect["emitted"]?.stringValue, name(row))
            }
        }
    }

    func testRowsWithAnIconAreRecords() throws {
        let table = try table()
        let users = try decode([String: PluginUser].self, table["users"])
        for row in try rows("rowsIcon", table) {
            let block = try decode(PluginRowsBlock.self, row["block"])
            let expect = try XCTUnwrap(row["expect"])
            if let empty = expect["empty"] {
                XCTAssertTrue(block.rows.isEmpty, name(row))
                XCTAssertEqual(block.icon ?? "clock", empty["icon"]?.stringValue, name(row))
                XCTAssertEqual(block.emptyText ?? s.pluginViewEmpty, empty["title"]?.stringValue, name(row))
                continue
            }
            let facts = expect["rows"]?.arrayValue ?? []
            XCTAssertEqual(block.rows.count, facts.count, name(row))
            for (record, fact) in zip(block.rows, facts) {
                XCTAssertEqual(block.icon, fact["icon"]?.stringValue, "\(name(row)) icon")
                guard block.icon != nil else { continue }
                let line = PluginViewFormat.recordLine(block, PluginViewFormat.namedRow(record, resolved: users),
                                                       nowMs: 0, s, utcOffsetMinutes: 0)
                XCTAssertEqual(line.title, fact["title"]?.stringValue, "\(name(row)) title")
                XCTAssertEqual(line.line, fact["line"]?.stringValue, "\(name(row)) line")
                XCTAssertEqual(line.value, fact["value"]?.stringValue, "\(name(row)) value")
                let tags = (fact["tags"]?.arrayValue ?? []).map { ($0["text"]?.stringValue, $0["tone"]?.stringValue) }
                XCTAssertEqual(line.tags.map(\.text), tags.map(\.0), "\(name(row)) tags")
                XCTAssertEqual(line.tags.map { $0.tone?.rawValue }, tags.map(\.1), "\(name(row)) tag tones")
            }
        }
    }

    /// R2.3 (rowTap): a row whose only action opens a page is one control that runs it; every other row keeps its keys.
    func testARowWhoseOnlyActionOpensAPageIsOneControl() throws {
        for row in try rows("rowTap", try table()) {
            let block = try decode(PluginRowsBlock.self, row["block"])
            let expect = try XCTUnwrap(row["expect"])
            let facts = expect["rows"]?.arrayValue ?? []
            XCTAssertEqual(block.rows.map(\.key), facts.compactMap { $0["key"]?.stringValue }, name(row))
            for (item, fact) in zip(block.rows, facts) {
                let tap = PluginViewFormat.rowTap(block, item)
                XCTAssertEqual(tap?.action.id, fact["tap"]?.stringValue, "\(name(row)) \(item.key) tap")
                // The view draws no key on a tapped row (PluginRowsBlockView) and ends it with the chevron.
                let keys = tap == nil ? PluginViewFormat.rowKeys(block, item).map(\.action.id) : []
                XCTAssertEqual(keys, (fact["keys"]?.arrayValue ?? []).compactMap(\.stringValue), "\(name(row)) \(item.key) keys")
                XCTAssertEqual(tap != nil, fact["chevron"]?.boolValue, "\(name(row)) \(item.key) chevron")
            }
            // Only a page's rows are tapped whole; a card's rows and label rows keep their keys (as Vue, Compose).
            for item in block.rows {
                XCTAssertEqual(PluginRowsBlockView.rowTap(block, item, pageRows: true, labelRows: false)?.action.id,
                               PluginViewFormat.rowTap(block, item)?.action.id, name(row))
                XCTAssertNil(PluginRowsBlockView.rowTap(block, item, pageRows: false, labelRows: false), name(row))
                XCTAssertNil(PluginRowsBlockView.rowTap(block, item, pageRows: true, labelRows: true), name(row))
            }
            guard let emit = expect["emit"] else { continue }
            let tapped = try XCTUnwrap(block.rows.first { $0.key == emit["rowKey"]?.stringValue }, name(row))
            let key = try XCTUnwrap(PluginViewFormat.rowTap(block, tapped), name(row))
            XCTAssertEqual(key.action.id, emit["actionId"]?.stringValue, name(row))
            XCTAssertEqual(PluginJSONValue.object(key.input), emit["input"], name(row))
        }
    }

    /// R10: a money cell and a hero with a currency draw through the payment amount formatter.
    func testMoneyWithACurrencyDrawsWithItsSymbol() throws {
        let block = try JSONDecoder().decode(PluginRowsBlock.self, from: Data(#"""
            {"kind":"rows","source":"flare.wallet.ui.home","columns":[{"label":"余额","format":"text"}],"actions":[],
             "rows":[{"key":"w1","cells":[{"text":"1234.56","format":{"kind":"money","minor":"123456","scale":2,"currency":"CNY"}}],"actions":[]}]}
            """#.utf8))
        XCTAssertEqual(PluginViewFormat.rowLines(block, block.rows[0], nowMs: 0, s, utcOffsetMinutes: 0).primary, "¥1,234.56")
        let hero = try JSONDecoder().decode(PluginHeroBlock.self, from: Data(#"""
            {"kind":"hero","value":"1234.56","amount":true,"maskable":true,"tone":"neutral","format":{"kind":"money","minor":"123456","scale":2,"currency":"CNY"}}
            """#.utf8))
        XCTAssertEqual(PluginFormatRules.text(hero.value, hero.format, s), "¥1,234.56")
        // The account view (wallet home): its list rows' amounts and the hero it reads as its first field.
        let account = flareAccountDocument(PluginViewModel(available: true, title: "钱包", blocks: [
            .section(PluginSectionBlock(label: "", blocks: [.hero(hero)])),
            .rows(PluginRowsBlock(columns: [block.columns[0], PluginRowsColumn(label: "钱包", format: .text)],
                                  rows: [PluginRow(key: "w1", cells: block.rows[0].cells + [PluginRowCell(text: "余额钱包")])])),
        ]))
        XCTAssertEqual(FlareAccountEntry.entries(account).first?.amount, "¥1,234.56")
        XCTAssertEqual(account.fields.first.map { PluginFormatRules.text($0.value, $0.format, s) }, "¥1,234.56")
    }

    func testARecordValueReadsWithTheMinusSignAndPersonCellsAreNamed() {
        XCTAssertEqual(PluginViewFormat.signedValue("-5.00"), "\u{2212}5.00")
        XCTAssertEqual(PluginViewFormat.signedValue("+5.00"), "+5.00")
        // Only a leading hyphen is a sign: hyphens inside dates and ids stay hyphens.
        XCTAssertEqual(PluginViewFormat.signedValue("2026-11-19"), "2026-11-19")
        XCTAssertEqual(PluginViewFormat.signedValue("-2026-11-19"), "\u{2212}2026-11-19")
        XCTAssertEqual(PluginViewFormat.recordIcon("not-a-kit-icon", value: "+1"), "arrow-down")
        XCTAssertEqual(PluginViewFormat.recordIcon(nil, value: "-1"), "send")
        let row = PluginRow(key: "r", cells: [PluginRowCell(text: "1"), PluginRowCell(text: "u_bob0002", format: .person(userId: "u_bob0002"))])
        XCTAssertEqual(PluginViewFormat.namedRow(row, resolved: ["u_bob0002": PluginUser(name: "Bob")]).cells[1].text, "Bob")
        XCTAssertEqual(PluginViewFormat.namedRow(row, resolved: [:]).cells[1].text, "0002", "the fallback name, never the id")
        let view = PluginViewModel(available: true, title: "", blocks: [.rows(PluginRowsBlock(columns: [], rows: [row]))])
        XCTAssertEqual(PluginViewFormat.userIds(in: view), ["u_bob0002"])
    }
}
