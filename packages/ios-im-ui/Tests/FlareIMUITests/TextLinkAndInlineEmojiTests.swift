import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// Batch 6 K4 and K5: a link in a received message can be opened, and the emoji-pack tokens a text
/// body carries are drawn instead of read out as `[key]`.
final class TextLinkAndInlineEmojiTests: XCTestCase {

    // MARK: K4 — links in text bodies and on link cards

    func testAHostThatTakesLinksGetsTheRawUrl() {
        XCTAssertEqual(TextMessageView.linkTap("https://flare.im/a?b=1", hostHandles: true),
                       .host("https://flare.im/a?b=1"))
        // Even a scheme the kit would never open itself is the host's decision to make.
        XCTAssertEqual(TextMessageView.linkTap("mailto:hi@flare.im", hostHandles: true),
                       .host("mailto:hi@flare.im"))
    }

    func testWithoutAHostTheKitOpensOnlyWebAddresses() {
        XCTAssertEqual(TextMessageView.linkTap("https://flare.im/a", hostHandles: false),
                       .system(URL(string: "https://flare.im/a")!))
        // What a person typing `flare.im` means.
        XCTAssertEqual(TextMessageView.linkTap("flare.im/a", hostHandles: false),
                       .system(URL(string: "https://flare.im/a")!))
        // Message text is written by other people: these never open.
        XCTAssertEqual(TextMessageView.linkTap("javascript:alert(1)", hostHandles: false), .ignored)
        XCTAssertEqual(TextMessageView.linkTap("java\tscript:alert(1)", hostHandles: false), .ignored)
        XCTAssertEqual(TextMessageView.linkTap("data:text/html,<script>", hostHandles: false), .ignored)
        XCTAssertEqual(TextMessageView.linkTap("file:///etc/passwd", hostHandles: false), .ignored)
        XCTAssertEqual(TextMessageView.linkTap("", hostHandles: false), .ignored)
    }

    @MainActor
    func testALinkCardOpensOnlyWhenItsUrlCanBeOpened() throws {
        let safe = MessageContentView(content: FlareLinkCardContent(url: "https://flare.im/post", title: "Flare"))
        XCTAssertNoThrow(try safe.inspect().find(ViewType.Button.self),
                         "a link card with a web address opens without a host handler")
        let unsafe = MessageContentView(content: FlareLinkCardContent(url: "javascript:alert(1)", title: "Flare"))
        XCTAssertThrowsError(try unsafe.inspect().find(ViewType.Button.self),
                             "a card that cannot be opened must not look tappable")
    }

    @MainActor
    func testTheLinkIntentReachesTheBodyFromTheTimeline() {
        // The timeline, the bubble and the body all take the intent (compile-level contract); the
        // routing itself is `linkTap` above.
        var opened: [String] = []
        let message = FlareMessageData(id: "m1", senderId: "u2", senderName: "Ann",
                                       content: FlareTextContent("看看 flare.im"), sentAtMs: 1_700_000_000_000)
        _ = MessageListView(messages: [message], currentUserId: "u1",
                            onOpenLink: { _, url in opened.append(url) }).body
        _ = MessageBubbleView(message: message, currentUserId: "u1",
                              onOpenLink: { _, url in opened.append(url) }).body
        _ = MessageContentView(content: FlareTextContent("看看 flare.im"),
                               onOpenLink: { opened.append($0) }).body
        XCTAssertTrue(opened.isEmpty)
    }

    // MARK: K5 — emoji-pack tokens inside a text body

    func testKnownTokensSplitOutAndUnknownOnesStayText() {
        let known: (String) -> Bool = { $0 == "grinning_face" }
        XCTAssertEqual(flareInlineEmojiRuns("开会 [grinning_face] 见", isKnown: known),
                       [.text("开会 "), .emoji(key: "grinning_face"), .text(" 见")])
        XCTAssertEqual(flareInlineEmojiRuns("[grinning_face][grinning_face]", isKnown: known),
                       [.emoji(key: "grinning_face"), .emoji(key: "grinning_face")])
        // A key the catalog does not have reads as what was written.
        XCTAssertEqual(flareInlineEmojiRuns("[not_a_key] 开会", isKnown: known), [.text("[not_a_key] 开会")])
        XCTAssertEqual(flareInlineEmojiRuns("没有表情", isKnown: known), [.text("没有表情")])
        XCTAssertEqual(flareInlineEmojiRuns("", isKnown: known), [])
        XCTAssertFalse(flareHasInlineEmoji("没有表情", isKnown: known))
        XCTAssertFalse(flareHasInlineEmoji("[not_a_key]", isKnown: known))
        XCTAssertTrue(flareHasInlineEmoji("[grinning_face]", isKnown: known))
    }

    func testTokensAreReadFromTheBundledCatalog() throws {
        let catalog = FlareEmojiStickerCatalog.shared
        try XCTSkipUnless(catalog.isLoaded, "no bundled emoji pack in this build")
        let key = try XCTUnwrap(catalog.loadedEmojiKeys().first)
        XCTAssertTrue(flareHasInlineEmoji("[\(key)]"))
        let image = try XCTUnwrap(flareInlineEmojiImage(key: key, side: 18))
        XCTAssertEqual(image.size.width, 18, accuracy: 0.5)
        // Kept, so a body full of the same token decodes and resizes once.
        XCTAssertTrue(flareInlineEmojiImage(key: key, side: 18) === image)
        XCTAssertNil(flareInlineEmojiImage(key: "../../etc/passwd", side: 18))
    }

    @MainActor
    func testABodyDrawsItsTokensBesideTextAndMentions() throws {
        let catalog = FlareEmojiStickerCatalog.shared
        try XCTSkipUnless(catalog.isLoaded, "no bundled emoji pack in this build")
        let key = try XCTUnwrap(catalog.loadedEmojiKeys().first)
        let text = "@所有人 开会 [\(key)]"
        // The mention keeps its own run, and only the plain run around it carries the token.
        let segments = TextMessageView.segments(text, mentions: [FlareTextMentionSpan(start: 0, length: 4, mentionsAll: true)])
        XCTAssertEqual(segments.map(\.text), ["@所有人", " 开会 [\(key)]"])
        XCTAssertTrue(flareHasInlineEmoji(segments[1].text))
        XCTAssertFalse(flareHasInlineEmoji(segments[0].text))
        _ = TextMessageView(text: text, mentions: [FlareTextMentionSpan(start: 0, length: 4, mentionsAll: true)]).body
        _ = TextMessageView(text: text, isSelf: true).body
        XCTAssertNoThrow(try TextMessageView(text: text).inspect().find(ViewType.Text.self))
    }
}
