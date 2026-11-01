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
        XCTAssertGreaterThanOrEqual(rows.count, 30, "the shared table lost cases")
        for row in rows {
            XCTAssertEqual(flareDisplayNameText(row.name, strings: FlareStrings()), row.text["zh-CN"], "\(row.id) zh-CN")
            XCTAssertEqual(flareDisplayNameText(row.name, strings: .english), row.text["en-US"], "\(row.id) en-US")
        }
    }

    func testTheWireRoundTripsAndNeverFails() throws {
        let decoder = JSONDecoder()
        let named = try decoder.decode(FlareDisplayName.self, from: Data(#"{"kind":"named","text":"Alice","source":"alias"}"#.utf8))
        XCTAssertEqual(named, .named(text: "Alice", source: .alias))
        let members = FlareDisplayName.members(names: ["张三", "李四"], total: 12)
        XCTAssertEqual(try decoder.decode(FlareDisplayName.self, from: try JSONEncoder().encode(members)), members)
        let unnamed = try decoder.decode(FlareDisplayName.self, from: Data(#"{"kind":"unnamed","entity":"person","idTail":"9876"}"#.utf8))
        XCTAssertEqual(unnamed, .unnamed(entity: .person, idTail: "9876"))
        let unknownUser = FlareDisplayName.unnamed(entity: .person, idTail: "")
        for json in [#"{"kind":"nickname","text":"x"}"#, #"{"kind":"named"}"#, #"{}"#, #""named""#, #"[1]"#] {
            XCTAssertEqual(try decoder.decode(FlareDisplayName.self, from: Data(json.utf8)), unknownUser, json)
        }
        XCTAssertEqual(try decoder.decode(FlareDisplayName.self, from: Data(#"{"kind":"unnamed","entity":"robot","idTail":"9876"}"#.utf8)),
                       .unnamed(entity: .person, idTail: "9876"))
        XCTAssertEqual(try decoder.decode([FlareDisplayName].self, from: Data(#"[{"kind":"x"},{"kind":"named","text":"A"}]"#.utf8)),
                       [unknownUser, .named(text: "A")])
    }

    /// A name a host holds as decoded JSON (a dictionary off an SDK bridge) reads exactly as `Codable` reads the same
    /// text: every name in the shared table, and the values a core newer than the kit or a broken bridge can hand over.
    func testDecodedJSONReadsAsCodableReadsTheWire() throws {
        let decoder = JSONDecoder()
        func both(_ json: String) throws -> (codable: FlareDisplayName, dictionary: FlareDisplayName?) {
            let data = Data(json.utf8)
            return (try decoder.decode(FlareDisplayName.self, from: data),
                    FlareDisplayName(json: try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)))
        }
        var root = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath()
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let table = try JSONSerialization.jsonObject(
            with: Data(contentsOf: root.appendingPathComponent("spec/display-name-vectors.json"))) as? [String: Any]
        let rows = try XCTUnwrap(table?["text"] as? [[String: Any]])
        XCTAssertGreaterThanOrEqual(rows.count, 30, "the shared table lost cases")
        for row in rows {
            let name = try XCTUnwrap(row["name"])
            let wire = String(decoding: try JSONSerialization.data(withJSONObject: name, options: .fragmentsAllowed),
                              as: UTF8.self)
            let read = try both(wire)
            XCTAssertEqual(read.dictionary, read.codable, "\(row["id"] ?? "?")")
        }
        for json in [#"{"kind":"named","text":"Alice","source":"alias"}"#, #"{"kind":"named","text":"0401","source":"nickname"}"#,
                     #"{"kind":"named","text":5}"#, #"{"kind":"named"}"#, #"{"kind":"nickname","text":"x"}"#, #"{"kind":1}"#,
                     #"{"kind":null}"#, #"{}"#, #""named""#, #"[1]"#, #"12"#,
                     #"{"kind":"members","names":["张三",1,null,"李四"],"total":12.9}"#,
                     #"{"kind":"members","names":"张三","total":-3}"#, #"{"kind":"members","total":"12"}"#,
                     #"{"kind":"members","names":["A"],"total":true}"#, #"{"kind":"members","names":["A"],"total":1e20}"#,
                     #"{"kind":"unnamed","entity":"robot","idTail":"9876"}"#, #"{"kind":"unnamed","idTail":9876}"#,
                     #"{"kind":"unnamed"}"#] {
            let read = try both(json)
            XCTAssertEqual(read.dictionary, read.codable, json)
        }
        XCTAssertEqual(try both(#"{"kind":"members","names":["张三",1,"李四"],"total":12.9}"#).dictionary,
                       .members(names: ["张三", "李四"], total: 12))
    }

    func testOnlyAMissingNameReadsAsNone() {
        XCTAssertNil(FlareDisplayName(json: nil))
        XCTAssertNil(FlareDisplayName(json: NSNull()))
        XCTAssertEqual(FlareDisplayName(json: ["kind": "members", "names": ["张三", "李四"], "total": 12] as [String: Any]),
                       .members(names: ["张三", "李四"], total: 12), "built in Swift")
        XCTAssertEqual(FlareDisplayName(json: ["kind": "unnamed", "entity": "group", "idTail": ""] as [String: Any]),
                       .unnamed(entity: .group))
        XCTAssertEqual(FlareDisplayName(json: "Alice"), .unnamed(entity: .person), "text is not a name the SDK projected")
    }

    func testQuoteSendersReadAsTheSharedTableSaysInBothLanguages() throws {
        struct Quotes: Decodable {
            struct Case: Decodable {
                let id: String
                let sender: FlareDisplayName?
                let senderName: String?
                let senderId: String?
                let text: [String: String]
            }
            let quoteSender: [Case]
        }
        var root = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath()
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let rows = try JSONDecoder().decode(
            Quotes.self, from: Data(contentsOf: root.appendingPathComponent("spec/display-name-vectors.json"))).quoteSender
        XCTAssertGreaterThanOrEqual(rows.count, 14, "the shared table lost cases")
        for row in rows {
            let target = FlareReplyTarget(senderName: row.senderName ?? "", summary: "上一条消息", senderId: row.senderId,
                                          sender: row.sender)
            XCTAssertEqual(flareQuoteSenderText(target, strings: FlareStrings()), row.text["zh-CN"], "\(row.id) zh-CN")
            XCTAssertEqual(flareQuoteSenderText(target, strings: .english), row.text["en-US"], "\(row.id) en-US")
        }
    }

    func testAHostsOwnWordsWin() {
        var strings = FlareStrings()
        strings.displayNameUser = { "访客 \($0)" }
        XCTAssertEqual(flareDisplayNameText(.unnamed(entity: .person, idTail: "9876"), strings: strings), "访客 9876")
    }
}
