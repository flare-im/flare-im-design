import XCTest
@testable import FlareIMUI

/// `spec/display-name-vectors.json`, the table the four kits run: the id tail (``flareIdTail(_:)``, which the plugin
/// view's unresolved user name reads too) and the text of every projected name in Chinese (the defaults) and English
/// (`FlareStrings.english`).
final class DisplayNameVectorsTests: XCTestCase {
    private struct Vectors: Decodable {
        struct Tail: Decodable { let id: String; let input: String; let output: String }
        struct Text: Decodable { let id: String; let name: FlareDisplayName; let text: [String: String] }
        let idTail: [Tail]
        let text: [Text]
    }

    private func vectors() throws -> Vectors {
        var root = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath()
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(
            Vectors.self, from: Data(contentsOf: root.appendingPathComponent("spec/display-name-vectors.json")))
    }

    func testIdTailsFollowTheSharedTable() throws {
        let rows = try vectors().idTail
        XCTAssertGreaterThanOrEqual(rows.count, 12, "the shared table lost cases")
        for row in rows {
            // Compared scalar by scalar: Swift's == treats canonically equivalent strings as equal.
            XCTAssertEqual(Array(flareIdTail(row.input).unicodeScalars), Array(row.output.unicodeScalars), row.id)
            XCTAssertEqual(Array(PluginViewFormat.fallbackName(row.input).unicodeScalars),
                           Array(row.output.unicodeScalars), "\(row.id) fallback name")
        }
    }

    func testNamesReadAsTheSharedTableSaysInBothLanguages() throws {
        let rows = try vectors().text
        XCTAssertGreaterThanOrEqual(rows.count, 24, "the shared table lost cases")
        for row in rows {
            XCTAssertEqual(flareDisplayNameText(row.name, strings: FlareStrings()), row.text["zh-CN"], "\(row.id) zh-CN")
            XCTAssertEqual(flareDisplayNameText(row.name, strings: .english), row.text["en-US"], "\(row.id) en-US")
        }
    }

    func testTheWireRoundTripsAndRefusesWhatIsNotAName() throws {
        let decoder = JSONDecoder()
        let named = try decoder.decode(FlareDisplayName.self, from: Data(#"{"kind":"named","text":"Alice","source":"alias"}"#.utf8))
        XCTAssertEqual(named, .named(text: "Alice", source: .alias))
        let members = FlareDisplayName.members(names: ["张三", "李四"], total: 12)
        XCTAssertEqual(try decoder.decode(FlareDisplayName.self, from: try JSONEncoder().encode(members)), members)
        let unnamed = try decoder.decode(FlareDisplayName.self, from: Data(#"{"kind":"unnamed","entity":"person","idTail":"9876"}"#.utf8))
        XCTAssertEqual(unnamed, .unnamed(entity: .person, idTail: "9876"))
        XCTAssertThrowsError(try decoder.decode(FlareDisplayName.self, from: Data(#"{"kind":"nickname","text":"x"}"#.utf8)))
        XCTAssertThrowsError(try decoder.decode(FlareDisplayName.self, from: Data(#"{"kind":"unnamed","entity":"robot"}"#.utf8)))
    }

    func testAHostsOwnWordsWin() {
        var strings = FlareStrings()
        strings.displayNameUser = { "访客 \($0)" }
        XCTAssertEqual(flareDisplayNameText(.unnamed(entity: .person, idTail: "9876"), strings: strings), "访客 9876")
    }
}
