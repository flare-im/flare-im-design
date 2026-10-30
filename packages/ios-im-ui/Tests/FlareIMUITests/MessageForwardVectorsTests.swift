import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// `spec/message-forward-vectors.json`: the merged-forward record's layout, card copy and drawer title, in Chinese
/// and English, as facts and on the drawn card.
final class MessageForwardVectorsTests: XCTestCase {
    /// The host's mapping of the core's forward content, as an app writes it.
    private func record(_ input: PluginJSONValue) throws -> FlareForwardContent {
        let forward = try XCTUnwrap(input["forward"])
        let items = (forward["items"]?.arrayValue ?? []).map { item in
            FlareForwardItem(senderName: item["sourceSenderName"]?.stringValue ?? "",
                             sentAtMs: Int64(item["sourceMessageTimeMs"]?.numberValue ?? 0),
                             plainText: item["plainText"]?.stringValue ?? "",
                             content: item["content"].flatMap(content))
        }
        return FlareForwardContent(title: forward["title"]?.stringValue ?? "",
                                   mode: FlareForwardMode(wire: forward["mode"]?.intValue ?? 0), items: items)
    }

    private func content(_ json: PluginJSONValue) -> FlareMessageContent? {
        switch json["contentType"]?.stringValue {
        case "text": return FlareTextContent(json["text"]?["text"]?.stringValue ?? "")
        case "image": return FlareImageContent(url: json["image"]?["url"]?.stringValue ?? "")
        default: return nil
        }
    }

    private let languages: [(String, FlareStrings, Locale)] = [
        ("zh", FlareStrings(), Locale(identifier: "zh_CN")), ("en", .english, Locale(identifier: "en_US")),
    ]

    private func cases() throws -> [PluginJSONValue] {
        let cases = try XCTUnwrap(try SpecVectors.table("message-forward-vectors.json")["cases"]?.arrayValue)
        XCTAssertGreaterThanOrEqual(cases.count, 7, "the shared table lost cases")
        return cases
    }

    func testEveryRecordLaysOutAsTheTableSays() throws {
        for vector in try cases() {
            let id = vector["id"]?.stringValue ?? "?"
            let content = try record(try XCTUnwrap(vector["input"], id))
            let expect = try XCTUnwrap(vector["expect"], id)
            for (language, strings, locale) in languages {
                let view = flareForwardRecordView(content, strings: strings, locale: locale)
                let label = "\(id) \(language)"
                XCTAssertEqual(view.layout.rawValue, expect["layout"]?.stringValue, label)
                switch view.layout {
                case .empty:
                    XCTAssertEqual(strings.forwardRecordEmpty, expect["text"]?[language]?.stringValue, label)
                case .single:
                    XCTAssertEqual(flareForwardSummary(content.items[0], strings: strings, locale: locale),
                                   expect["text"]?[language]?.stringValue, label)
                case .card:
                    let facts = try XCTUnwrap(expect[language], label)
                    XCTAssertEqual(view.title, facts["title"]?.stringValue, "\(label) title")
                    XCTAssertEqual(view.subtitle, facts["subtitle"]?.stringValue, "\(label) subtitle")
                    let previews = facts["previews"]?.arrayValue ?? []
                    XCTAssertEqual(view.previews.map(\.sender), previews.compactMap { $0["sender"]?.stringValue },
                                   "\(label) senders")
                    XCTAssertEqual(view.previews.map(\.text), previews.compactMap { $0["text"]?.stringValue },
                                   "\(label) summaries")
                    XCTAssertEqual(view.more, facts["more"]?.stringValue, "\(label) more")
                    XCTAssertEqual(view.hint, facts["hint"]?.stringValue, "\(label) hint")
                    XCTAssertEqual(view.label, facts["label"]?.stringValue, "\(label) accessible name")
                    XCTAssertEqual(view.drawerTitle, facts["drawerTitle"]?.stringValue, "\(label) drawer title")
                }
            }
        }
    }

    /// The card draws the Chinese facts, is one button named by the record, and does not respond in multi-select.
    @MainActor
    func testTheCardDrawsTheRecordAndIsOneButton() throws {
        for vector in try cases() where vector["expect"]?["layout"]?.stringValue == "card" {
            let id = vector["id"]?.stringValue ?? "?"
            let content = try record(try XCTUnwrap(vector["input"], id))
            let facts = try XCTUnwrap(vector["expect"]?["zh"], id)
            let card = try FlareForwardMessageView(content: content).inspect()
            let button = try card.find(viewWithAccessibilityIdentifier: FlareForwardMessageView.cardID)
            XCTAssertEqual(try button.accessibilityLabel().string(), facts["label"]?.stringValue, id)
            XCTAssertNoThrow(try card.find(text: try XCTUnwrap(facts["title"]?.stringValue)), id)
            XCTAssertNoThrow(try card.find(text: try XCTUnwrap(facts["hint"]?.stringValue)), id)
            for preview in facts["previews"]?.arrayValue ?? [] {
                let line = "\(preview["sender"]?.stringValue ?? ""): \(preview["text"]?.stringValue ?? "")"
                XCTAssertNoThrow(try card.find(text: line), "\(id) \(line)")
            }
            if let more = facts["more"]?.stringValue { XCTAssertNoThrow(try card.find(text: more), id) }
            XCTAssertFalse(try card.find(ViewType.Button.self).isDisabled(), id)
            let selecting = try FlareForwardMessageView(content: content, selectionMode: true).inspect()
            XCTAssertTrue(try selecting.find(ViewType.Button.self).isDisabled(), "\(id): multi-select")
        }
    }

    /// The record is a card in the timeline and summarises as a forward.
    func testTheRecordIsACardAndSummarisesAsAForward() {
        let two = FlareForwardContent(mode: .merged, items: [FlareForwardItem(plainText: "a"), FlareForwardItem(plainText: "b")])
        XCTAssertEqual(two.specContentType, "forward")
        XCTAssertEqual(flareMessageSurface(FlareMessageSurfaceInput(contentType: two.specContentType)), .card)
        XCTAssertEqual(flareMessagePreviewText(two, strings: FlareStrings()), FlareStrings().previewForwardCount(2))
        XCTAssertEqual(flareMessagePreviewText(FlareForwardContent(title: "记录", items: [FlareForwardItem(plainText: "a")]),
                                               strings: FlareStrings()), "记录")
        XCTAssertFalse(MessageContentView.drawsCardShell(two, surface: .card, custom: false),
                       "the record draws its own shell")
    }

    func testTheDrawerInitialFollowsTheSharedCases() throws {
        let block = try XCTUnwrap(try SpecVectors.table("message-forward-vectors.json")["senderInitials"])
        let cases = try XCTUnwrap(block["cases"]?.arrayValue)
        XCTAssertGreaterThanOrEqual(cases.count, 4)
        for vector in cases {
            let name = try XCTUnwrap(vector["senderName"]?.stringValue)
            XCTAssertEqual(flareForwardSenderInitial(FlareForwardItem(senderName: name)), vector["initial"]?.stringValue,
                           "\"\(name)\"")
        }
    }

    func testTheDrawerRowsShowTheInitialAndTheContentBeyondText() {
        XCTAssertEqual(ForwardRecordDetails.initial(FlareForwardItem(senderName: " 林夏 ")), "林")
        XCTAssertEqual(ForwardRecordDetails.initial(FlareForwardItem(senderName: "ivy")), "I")
        XCTAssertEqual(ForwardRecordDetails.initial(FlareForwardItem()), "?")
        XCTAssertTrue(ForwardRecordDetails.drawsContent(FlareForwardItem(content: FlareImageContent(url: "https://a/b.png"))))
        XCTAssertFalse(ForwardRecordDetails.drawsContent(FlareForwardItem(content: FlareTextContent("收到"))))
        XCTAssertFalse(ForwardRecordDetails.drawsContent(FlareForwardItem(plainText: "收到")))
    }

    /// `rules.palette`: a record's items are someone else's messages whoever forwarded it. A rich text item — the one
    /// item drawn inline in a record the viewer forwarded, and a row of the drawer — takes the neutral palette, never
    /// the outgoing bubble's white.
    @MainActor
    func testRecordItemsTakeTheNeutralPaletteWhoeverForwardedThem() throws {
        let colors = FlareColors.of(.light, brand: .violet)
        XCTAssertNotEqual(colors.messageOutgoingForeground, colors.messageIncomingForeground)
        let rich = FlareRichTextContent(docJson: #"{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"周报"}]}]}"#,
                                        plainText: "周报")
        let single = FlareForwardContent(mode: .single, items: [FlareForwardItem(senderName: "林夏", content: rich)])
        let inline = try FlareForwardMessageView(content: single, isSelf: true).inspect()
            .find(RichTextMessageView.self).vStack().foregroundColor()
        XCTAssertEqual(inline, colors.messageIncomingForeground, "the inline item of a record the viewer forwarded")
        let merged = FlareForwardContent(mode: .merged, items: [FlareForwardItem(senderName: "林夏", content: rich),
                                                                 FlareForwardItem(senderName: "周屿", plainText: "收到")])
        let row = try ForwardRecordDetails(content: merged).inspect().find(RichTextMessageView.self).vStack().foregroundColor()
        XCTAssertEqual(row, colors.messageIncomingForeground, "a drawer row")
    }

    /// The surface's foreground reaches a rich text body as it reaches a text body: the failure surface and a forward
    /// record set it; without one the body takes its side's.
    func testARichTextBodyTakesTheSurfacesForeground() {
        let colors = FlareColors.of(.light, brand: .violet)
        func paint(_ isSelf: Bool, _ surface: Color?) -> RichTextMessageView.Paint {
            RichTextMessageView.Paint(colors: colors, isSelf: isSelf, size: 15, strings: FlareStrings(), revealed: false,
                                      bodyForeground: surface)
        }
        XCTAssertEqual(paint(true, nil).foreground, colors.messageOutgoingForeground)
        XCTAssertEqual(paint(false, nil).foreground, colors.messageIncomingForeground)
        XCTAssertEqual(paint(true, colors.messageFailedForeground).foreground, colors.messageFailedForeground,
                       "a failed message's failure surface")
        XCTAssertEqual(paint(true, colors.messageFailedForeground).link, colors.messageFailedForeground)
        XCTAssertEqual(paint(false, colors.textPrimary).foreground, colors.textPrimary, "a forward record's palette")
        XCTAssertEqual(paint(false, colors.textPrimary).link, colors.primary)
    }

    func testTheDrawerTimeIsTheClockTodayElseTheDateAndClock() {
        let zh = Locale(identifier: "zh_CN")
        let now = Date(timeIntervalSince1970: 1_761_100_000)
        let sameDay = now.addingTimeInterval(-60)
        XCTAssertEqual(FlareTimeFormat.dateTime(sameDay, locale: zh, now: now), FlareTimeFormat.messageTime(sameDay, locale: zh))
        let earlier = now.addingTimeInterval(-3 * 86_400)
        let label = FlareTimeFormat.dateTime(earlier, locale: zh, now: now)
        XCTAssertTrue(label.hasSuffix(FlareTimeFormat.messageTime(earlier, locale: zh)), label)
        XCTAssertTrue(label.contains("月") && label.contains("日"), label)
    }
}
