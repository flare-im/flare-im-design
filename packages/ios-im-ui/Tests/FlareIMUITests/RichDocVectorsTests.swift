import Foundation
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The shared table (`spec/rich-doc-vectors.json`): what a rich-text body draws for a RichDoc v2 document.
/// Vue states the rule in the table's own shape; this kit reads the same file and turns its model into it.
final class RichDocVectorsTests: XCTestCase {
    private func cases() throws -> [[String: Any]] {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/rich-doc-vectors.json"))
        let table = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(table["cases"] as? [[String: Any]])
    }

    private func outline(_ run: FlareRichRun) -> [String: Any] {
        var out: [String: Any] = ["text": run.text]
        if !run.marks.isEmpty { out["marks"] = run.marks.map(\.rawValue) }
        if run.code { out["code"] = true }
        if let link = run.link { out["link"] = link }
        if let mention = run.mention { out["mention"] = mention }
        if let emoji = run.emoji { out["emoji"] = emoji }
        return out
    }

    private func outline(_ block: FlareRichBlock) -> [String: Any] {
        switch block {
        case .paragraph(let runs): return ["kind": "paragraph", "runs": runs.map(outline)]
        case .heading(let level, let runs): return ["kind": "heading", "level": level, "runs": runs.map(outline)]
        case .quote(let blocks): return ["kind": "quote", "blocks": blocks.map(outline)]
        case .code(let text, let language):
            var out: [String: Any] = ["kind": "code", "text": text]
            if let language { out["language"] = language }
            return out
        case .list(let ordered, let items): return ["kind": "list", "ordered": ordered, "items": items.map { $0.map(outline) }]
        case .divider: return ["kind": "divider"]
        }
    }

    private func generated(_ spec: [String: Any]) -> [String: Any] {
        let text: [String: Any] = ["type": "text", "text": "a"]
        if let levels = spec["nestedQuotes"] as? Int {
            var node: [String: Any] = ["type": "paragraph", "children": [text]]
            for _ in 0..<levels { node = ["type": "quote", "children": [node]] }
            return ["type": "doc", "version": 2, "children": [node]]
        }
        let count = spec["paragraphTextNodes"] as? Int ?? 0
        return ["type": "doc", "version": 2,
                "children": [["type": "paragraph", "children": Array(repeating: text, count: count)]]]
    }

    func testACoveredSpoilerIsBlankSpaceKeepingItsWhitespace() throws {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/rich-doc-vectors.json"))
        let table = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let covers = try XCTUnwrap(table["spoilerCovers"] as? [[String: String]])
        XCTAssertGreaterThanOrEqual(covers.count, 5)
        for cover in covers {
            XCTAssertEqual(flareRichSpoilerCover(cover["text"] ?? ""), cover["cover"], cover["text"] ?? "")
        }
    }

    func testEveryCaseDrawsWhatTheTableSays() throws {
        let cases = try cases()
        XCTAssertGreaterThanOrEqual(cases.count, 30)
        for vector in cases {
            let id = vector["id"] as? String ?? "?"
            if let spec = vector["generate"] as? [String: Any] {
                XCTAssertEqual(flareParseRichDoc(generated(spec)) != nil, vector["drawable"] as? Bool, id)
                continue
            }
            let blocks = flareParseRichDoc(vector["doc"])
            let actual: Any = blocks.map { $0.map(outline) } ?? NSNull()
            let expected: Any = vector["blocks"] ?? NSNull()
            XCTAssertEqual(NSArray(array: [actual]), NSArray(array: [expected]), id)
        }
    }
}

final class RichTextMessageViewTests: XCTestCase {
    private let paint = RichTextMessageView.Paint(colors: FlareColors.of(.light), isSelf: false, size: 15,
                                                  strings: FlareStrings(), revealed: false)

    func testALinkCarriesOnlyTheSafeAddress() {
        let safe = RichTextMessageView.attributed(FlareRichRun("文档", link: "flare.im"), paint: paint, size: 15, weight: .regular)
        XCTAssertEqual(safe.runs.first?.link, safeExternalURL("flare.im").flatMap(URL.init(string:)))
        XCTAssertNotNil(safe.runs.first?.link)
        // The model never carries a refused href, and the view re-checks what it is given.
        let refused = RichTextMessageView.attributed(FlareRichRun("别点", link: "javascript:alert(1)"), paint: paint, size: 15, weight: .regular)
        XCTAssertNil(refused.runs.first?.link)
    }

    func testACoveredSpoilerLinksToRevealAndIsReadAsItsName() {
        let run = FlareRichRun("42", marks: [.spoiler])
        let covered = RichTextMessageView.attributed(run, paint: paint, size: 15, weight: .regular)
        XCTAssertEqual(covered.runs.first?.link, RichTextMessageView.spoilerURL)
        XCTAssertEqual(covered.runs.first?.backgroundColor, paint.foreground)
        XCTAssertEqual(String(covered.characters), "\u{3000}\u{3000}", "the words are not drawn while covered")
        XCTAssertEqual(RichTextMessageView.spokenText([FlareRichRun("谜底是 "), run], paint: paint),
                       "谜底是 " + FlareStrings().messageSpoilerReveal)
        let revealedPaint = RichTextMessageView.Paint(colors: paint.colors, isSelf: false, size: 15,
                                                      strings: FlareStrings(), revealed: true)
        let revealed = RichTextMessageView.attributed(run, paint: revealedPaint, size: 15, weight: .regular)
        XCTAssertNil(revealed.runs.first?.link)
        XCTAssertNil(revealed.runs.first?.backgroundColor)
    }

    func testTapsRevealOrGoWhereATextLinkGoes() {
        XCTAssertEqual(RichTextMessageView.linkTap(RichTextMessageView.spoilerURL, hostHandles: true), .reveal)
        let url = URL(string: "https://flare.im/docs")!
        XCTAssertEqual(RichTextMessageView.linkTap(url, hostHandles: true), .link(.host("https://flare.im/docs")))
        XCTAssertEqual(RichTextMessageView.linkTap(url, hostHandles: false), .link(.system(url)))
        XCTAssertEqual(RichTextMessageView.linkTap(URL(string: "file:///etc/passwd")!, hostHandles: false), .link(.ignored))
    }

    func testMarksAndMentionsTakeTheirLook() {
        let bold = RichTextMessageView.attributed(FlareRichRun("结论", marks: [.bold, .strike]), paint: paint, size: 15, weight: .regular)
        XCTAssertEqual(bold.runs.first?.strikethroughStyle, .single)
        let mention = RichTextMessageView.attributed(FlareRichRun("@Ada", mention: "u_ada"), paint: paint, size: 15, weight: .regular)
        XCTAssertEqual(mention.runs.first?.foregroundColor, paint.colors.primaryText)
    }

    func testTheBodyDrawsTitleBlocksOrItsFallback() throws {
        let docJson = #"{"type":"doc","version":2,"children":[{"type":"heading","level":2,"children":[{"type":"text","text":"议程"}]},{"type":"bullet_list","children":[{"type":"list_item","children":[{"type":"paragraph","children":[{"type":"text","text":"准备"}]}]}]}]}"#
        let view = RichTextMessageView(docJson: docJson, plainText: "议程 准备", title: "周会")
        XCTAssertNoThrow(try view.inspect().find(text: "周会"))
        XCTAssertNoThrow(try view.inspect().find(text: "•"))
        let broken = RichTextMessageView(docJson: #"{"type":"doc""#, plainText: "周报已发出")
        XCTAssertNoThrow(try broken.inspect().find(text: "周报已发出"))
        let empty = RichTextMessageView(docJson: "")
        XCTAssertNoThrow(try empty.inspect().find(text: FlareStrings().previewRichText))
    }

    func testTheDispatcherAndCopyUseTheRichBody() throws {
        let content = FlareRichTextContent(docJson: #"{"type":"doc","version":2,"children":[]}"#, plainText: "周会纪要")
        XCTAssertNoThrow(try MessageContentView(content: content).inspect().find(RichTextMessageView.self))
        XCTAssertEqual(flareCopyableText(content), "周会纪要")
    }
}
