import Foundation
import XCTest
@testable import FlareIMUI

/// The shared summary table (`spec/message-preview-vectors.json`): what a conversation row, a reply
/// strip and a bubble's quote say about a message. Vue is the reference implementation
/// (`utils/messagePreviewVectors.test.ts`); the three native kits answer to the same file.
///
/// A case's `fields` become this platform's content object: `text` at the root, everything else the
/// type's own payload, and `count` the number of items in the list the type carries. The kinds this
/// kit has no dedicated content struct for (forward, image group, quote, system) arrive as
/// ``FlareGenericContent`` tagged by the core's wire type — the same shape the host's adapter builds.
final class MessagePreviewVectorsTests: XCTestCase {
    private struct Table: Decodable {
        let fallbackKey: String
        let cases: [Vector]
    }

    private struct Vector: Decodable {
        let id: String
        let kind: String
        let fields: Fields
        let expected: [String: String]
        let replyExpected: [String: String]?
    }

    private struct Fields: Decodable {
        let text: String?
        let description: String?
        let animated: Bool?
        let fileName: String?
        let title: String?
        let count: Int?
        let quotedTextPreview: String?
        let key: String?
        let plainText: String?
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let url = root.appendingPathComponent("spec/message-preview-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    }

    /// `fields` → this kit's content model.
    private func content(_ vector: Vector) -> FlareMessageContent? {
        let f = vector.fields
        switch vector.kind {
        case "text": return FlareTextContent(f.text ?? "")
        case "image": return FlareImageContent(url: "", alt: f.description, animated: f.animated ?? false)
        case "video": return FlareVideoContent(url: "")
        case "audio": return FlareAudioContent(url: "")
        case "file": return FlareFileContent(name: f.fileName ?? "", url: "")
        case "location": return FlareLocationContent(name: f.title ?? "")
        case "card": return FlareCardContent(title: "")
        case "sticker": return FlareStickerContent(url: "")
        case "link_card": return FlareLinkCardContent(url: "", title: f.title ?? "")
        case "vote": return FlarePollContent(id: "v", title: "")
        case "task": return FlareTaskContent(id: "t", title: f.title ?? "")
        case "announcement": return FlareAnnouncementContent(id: "a", title: "")
        case "forward":
            return FlareGenericContent(contentType: vector.kind, label: "", itemCount: f.count ?? 0)
        case "image_group":
            return FlareImageGroupContent(images: Array(repeating: FlareImageContent(url: ""), count: f.count ?? 0))
        case "quote": return FlareGenericContent(contentType: "quote", label: f.quotedTextPreview ?? "")
        case "system": return FlareGenericContent(contentType: "system", label: "")
        case "emoji": return FlareEmojiContent(f.key ?? "")
        case "rich_text": return FlareRichTextContent(docJson: "", plainText: f.plainText ?? "")
        case "mini_program": return FlareMiniAppContent(appId: "", title: f.title ?? "")
        default: return nil
        }
    }

    /// Chinese is the kit's default copy; a host that speaks English overrides the same fields.
    private func strings(_ locale: String) -> FlareStrings {
        guard locale != "zh-CN" else { return FlareStrings() }
        return FlareStrings(
            previewMessage: "[Message]",
            previewRichText: "[Rich text]",
            previewGif: "[GIF]",
            previewImage: "[Image]",
            previewVideo: "[Video]",
            previewAudio: "[Voice]",
            previewFile: "[File]",
            previewFileNamed: { "[File] \($0)" },
            previewLocation: "[Location]",
            previewLocationNamed: { "[Location] \($0)" },
            previewCard: "[Contact]",
            previewCardNamed: { "[Contact] \($0)" },
            previewSticker: "[Sticker]",
            previewEmoji: "[Emoji]",
            previewQuote: "[Quote]",
            previewLink: "[Link]",
            previewForward: "[Forward]",
            previewForwardCount: { "[Forward] \($0) messages" },
            previewThread: "[Thread]",
            previewMiniProgram: "[Mini Program]",
            previewImageGroup: "[Album]",
            previewImageGroupCount: { "[Album] \($0)" },
            previewSystem: "[System]",
            previewNotification: "[Notification]",
            previewVote: "[Poll]",
            previewTask: "[Task]",
            previewSchedule: "[Schedule]",
            previewAnnouncement: "[Announcement]",
            previewCustom: "[Custom]",
            previewPlaceholder: "[Placeholder]",
            previewUnknown: "[Unknown]"
        )
    }

    /// What a jump says out loud. Posting it needs a device with an accessibility service; composing it
    /// does not, and the sentence is the part that can be wrong.
    func testALandedJumpIsNamedBySenderAndTheLineAReplyWouldShow() {
        let s = FlareStrings()
        let message = FlareMessageData(
            id: "m1", senderId: "u1", senderName: "Ann", content: FlareTextContent("明天见"))
        XCTAssertEqual(flareLocatedAnnouncement(message, strings: s), "已跳转到 Ann 的消息：明天见")

        // A sender nobody can name, and a body with nothing readable: neither leaves a hole in the sentence.
        let anonymous = FlareMessageData(
            id: "m2", senderId: "u2", senderName: "", content: FlareImageContent(url: ""))
        XCTAssertEqual(
            flareLocatedAnnouncement(anonymous, strings: s),
            "已跳转到 \(s.previewMessage) 的消息：\(s.previewImage)")
    }

    func testEveryVectorReadsTheSameInBothLocales() throws {
        let table = try table()
        XCTAssertFalse(table.cases.isEmpty)
        for vector in table.cases {
            guard let content = content(vector) else {
                XCTFail("no content mapping for kind \(vector.kind) (case \(vector.id))")
                continue
            }
            for locale in ["zh-CN", "en-US"] {
                let s = strings(locale)
                guard let expected = vector.expected[locale] else {
                    XCTFail("case \(vector.id) has no \(locale) expectation")
                    continue
                }
                XCTAssertEqual(
                    flareMessagePreviewText(content, strings: s, locale: locale), expected,
                    "\(vector.id) @ \(locale)")

                // What a reply strip or a quote shows: the summary, or the shared fallback when empty.
                let message = FlareMessageData(id: "m1", senderId: "u1", senderName: "Bob", content: content)
                let reply = FlareReplyTarget(replyingTo: message, strings: s, locale: locale)
                XCTAssertEqual(reply.summary, vector.replyExpected?[locale] ?? expected, "\(vector.id) reply @ \(locale)")
            }
        }
    }

    /// The table names the fallback key; this kit's field for it must be the one the reply uses.
    func testTheReplyFallbackIsTheKeyTheTableNames() throws {
        XCTAssertEqual(try table().fallbackKey, "preview.message")
        let blank = FlareMessageData(id: "m1", senderId: "u1", senderName: "Bob", content: FlareTextContent("   "))
        XCTAssertEqual(FlareReplyTarget(replyingTo: blank, strings: FlareStrings()).summary, FlareStrings().previewMessage)
        XCTAssertEqual(flareMessagePreviewText(blank.content, strings: FlareStrings()), "")
    }

    func testTheReplyTargetNamesTheSenderAndTheMessageItQuotes() {
        let message = FlareMessageData(id: "m9", senderId: "u1", senderName: "Bob", content: FlareTextContent("明天见"))
        let target = FlareReplyTarget(replyingTo: message, strings: FlareStrings())
        XCTAssertEqual(target, FlareReplyTarget(senderName: "Bob", summary: "明天见", messageId: "m9"))
        // A row that has reached the server is quoted by the id every other client knows it by, not
        // by the id this device draws it with (FR-114); the three kits and the apps agree on that.
        let sent = FlareMessageData(id: "client-9", senderId: "u1", senderName: "Bob",
                                    content: FlareTextContent("明天见"), serverId: "server-9")
        XCTAssertEqual(FlareReplyTarget(replyingTo: sent, strings: FlareStrings()).messageId, "server-9")
        // Still on its way: the id it was drawn with is all that exists yet.
        let pending = FlareMessageData(id: "client-10", senderId: "u1", senderName: "Bob",
                                       content: FlareTextContent("在路上"), serverId: "  ")
        XCTAssertEqual(FlareReplyTarget(replyingTo: pending, strings: FlareStrings()).messageId, "client-10")
        // An unknown row cannot be located, so the quote is not a control.
        let unkeyed = FlareMessageData(id: "", senderId: "u1", senderName: "Bob", content: FlareTextContent("hi"))
        XCTAssertNil(FlareReplyTarget(replyingTo: unkeyed, strings: FlareStrings()).messageId)
    }

    /// Kinds the shared table does not cover yet, but the kit's content model carries.
    func testTypesOutsideTheTableAreNamedToo() {
        let s = FlareStrings()
        XCTAssertEqual(flareMessagePreviewText(nil, strings: s), "")
        XCTAssertEqual(flareMessagePreviewText(FlareEmojiContent("🙂"), strings: s), "🙂")
        XCTAssertEqual(flareMessagePreviewText(FlareEmojiContent(""), strings: s), s.previewEmoji)
        XCTAssertEqual(flareMessagePreviewText(FlareNotificationContent("Ann joined"), strings: s), "Ann joined")
        XCTAssertEqual(flareMessagePreviewText(FlareNotificationContent(" "), strings: s), s.previewNotification)
        XCTAssertEqual(flareMessagePreviewText(FlareCalendarContent(id: "c", title: ""), strings: s), s.previewSchedule)
        XCTAssertEqual(flareMessagePreviewText(FlareMiniAppContent(appId: "a", title: ""), strings: s), s.previewMiniProgram)
        XCTAssertEqual(flareMessagePreviewText(FlarePlaceholderContent(""), strings: s), s.previewPlaceholder)
        XCTAssertEqual(flareMessagePreviewText(FlareGenericContent(contentType: "rich_text", label: ""), strings: s), s.previewRichText)
        XCTAssertEqual(flareMessagePreviewText(FlareRichTextContent(docJson: ""), strings: s), s.previewRichText)
        XCTAssertEqual(flareMessagePreviewText(FlareRichTextContent(docJson: "", plainText: "正文", title: "周报"), strings: s),
                       "周报 正文")
        XCTAssertEqual(flareMessagePreviewText(FlareGenericContent(contentType: "thread", label: ""), strings: s), s.previewThread)
        XCTAssertEqual(flareMessagePreviewText(FlareGenericContent(contentType: "custom", label: ""), strings: s), s.previewCustom)
        XCTAssertEqual(flareMessagePreviewText(FlareGenericContent(contentType: "unknown", label: ""), strings: s), s.previewUnknown)
        XCTAssertEqual(flareMessagePreviewText(FlareGenericContent(contentType: "image_group", label: "", itemCount: 0), strings: s), s.previewImageGroup)
        XCTAssertEqual(flareMessagePreviewText(FlareGenericContent(contentType: "forward", label: "", itemCount: 1), strings: s), s.previewForward)
        // A registered product type the kit does not know is shown by the text it came with, or not at all.
        XCTAssertEqual(flareMessagePreviewText(FlareGenericContent(contentType: "red_packet", label: "恭喜发财"), strings: s), "恭喜发财")
        XCTAssertEqual(flareMessagePreviewText(FlareGenericContent(contentType: "red_packet", label: ""), strings: s), "")
    }

    /// A moving image reads as a GIF whether the source says so or only its address does.
    func testMovingImagesAreNotCalledImages() {
        let s = FlareStrings()
        XCTAssertEqual(flareMessagePreviewText(FlareImageContent(url: "https://e.com/a.gif"), strings: s), s.previewGif)
        XCTAssertEqual(flareMessagePreviewText(FlareImageContent(url: "https://e.com/a.png?x=1", animated: true), strings: s), s.previewGif)
        XCTAssertEqual(flareMessagePreviewText(FlareImageContent(url: "https://e.com/a.png"), strings: s), s.previewImage)
        // A described still image is summarized by its description, a moving one by what it is.
        XCTAssertEqual(flareMessagePreviewText(FlareImageContent(url: "", alt: "封面"), strings: s), "封面")
        XCTAssertEqual(flareMessagePreviewText(FlareImageContent(url: "", alt: "封面", animated: true), strings: s), s.previewGif)
    }
}
