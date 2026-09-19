import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// FR-080: text bodies emphasize the core's mention entities — code-point offsets converted to UTF-16
/// spans, invalid and overlapping entities dropped, a stronger look for the reader and for @all on
/// incoming bubbles only, and no change to text without mentions.
final class TextMentionTests: XCTestCase {
    private let colors = FlareColors.light

    private typealias UI = AttributeScopes.SwiftUIAttributes

    private func substring(_ text: String, _ span: FlareTextMentionSpan) -> String {
        (text as NSString).substring(with: NSRange(location: span.start, length: span.length))
    }

    // MARK: Core entities → spans

    func testAnEmojiBeforeAMentionMovesTheSpanByItsUTF16Width() {
        // 👍🏽 is two code points and four UTF-16 units: "@" is code point 6 and UTF-16 unit 8.
        let text = "👍🏽 hi @Ann ok"
        let spans = FlareTextMentionSpan.spans(
            from: [FlareMentionEntity(type: FlareMentionEntity.typeUser, userId: "ann", start: 6, length: 4)],
            in: text, currentUserId: "me")
        XCTAssertEqual(spans, [FlareTextMentionSpan(start: 8, length: 4)])
        XCTAssertEqual(substring(text, spans[0]), "@Ann")
    }

    func testAMultiScalarEmojiBeforeAMentionStillHighlightsTheMention() {
        // The family emoji is one character, five code points (three people, two joiners) and eight UTF-16 units.
        let text = "👨‍👩‍👧@所有人 开会"
        let spans = FlareTextMentionSpan.spans(
            from: [FlareMentionEntity(type: FlareMentionEntity.typeAll, start: 5, length: 4)],
            in: text, currentUserId: "me")
        XCTAssertEqual(spans, [FlareTextMentionSpan(start: 8, length: 4, mentionsAll: true)])
        XCTAssertEqual(substring(text, spans[0]), "@所有人")
        XCTAssertEqual(TextMessageView.segments(text, mentions: spans).map(\.text), ["👨‍👩‍👧", "@所有人", " 开会"])
    }

    func testInvalidEntitiesAreIgnored() {
        let text = "hi @Ann"
        let entities = [
            FlareMentionEntity(type: 1, userId: "ann", start: -1, length: 4),   // before the text
            FlareMentionEntity(type: 1, userId: "ann", start: 3, length: 1),    // shorter than "@" and a letter
            FlareMentionEntity(type: 1, userId: "ann", start: 4, length: 4),    // past the end
            FlareMentionEntity(type: 1, userId: "ann", start: 0, length: 3),    // not on "@"
            FlareMentionEntity(type: 1, userId: "ann", start: 3, length: .max), // overflowing length
        ]
        XCTAssertEqual(FlareTextMentionSpan.spans(from: entities, in: text, currentUserId: "ann"), [])
        XCTAssertEqual(FlareTextMentionSpan.spans(from: [], in: text, currentUserId: "ann"), [])
    }

    func testSpansComeInTextOrderAndAnOverlappingSpanIsDropped() {
        let text = "@Ann @Bob @Cy"
        let entities = [
            FlareMentionEntity(type: 1, userId: "cy", start: 10, length: 3),
            FlareMentionEntity(type: 1, userId: "ann", start: 0, length: 8),   // "@Ann @Bo"
            FlareMentionEntity(type: 1, userId: "bob", start: 5, length: 4),   // overlaps the one before it
            FlareMentionEntity(type: 1, userId: "ann2", start: 0, length: 4),  // same start: the first entity wins
        ]
        let spans = FlareTextMentionSpan.spans(from: entities, in: text, currentUserId: "")
        XCTAssertEqual(spans.map { substring(text, $0) }, ["@Ann @Bo", "@Cy"])
    }

    func testSelfAndAllFlags() {
        let text = "@Ann @team @all"
        let entities = [
            FlareMentionEntity(type: FlareMentionEntity.typeUser, userId: "me", start: 0, length: 4),
            FlareMentionEntity(type: FlareMentionEntity.typeMulti, userIds: ["x", "me"], start: 5, length: 5),
            FlareMentionEntity(type: FlareMentionEntity.typeAll, start: 11, length: 4),
        ]
        let spans = FlareTextMentionSpan.spans(from: entities, in: text, currentUserId: "me")
        XCTAssertEqual(spans.map(\.mentionsSelf), [true, true, false])
        XCTAssertEqual(spans.map(\.mentionsAll), [false, false, true])
        XCTAssertEqual(spans.map(\.highlighted), [true, true, true])
        // Without a current user nobody is "me".
        XCTAssertEqual(FlareTextMentionSpan.spans(from: entities, in: text, currentUserId: "").map(\.mentionsSelf),
                       [false, false, false])
    }

    // MARK: Text body

    func testSegmentsIgnoreSpansThatDoNotFitTheText() {
        let text = "👍 @Ann @Bob"
        let segments = TextMessageView.segments(text, mentions: [
            FlareTextMentionSpan(start: 1, length: 3),     // starts inside the surrogate pair
            FlareTextMentionSpan(start: 3, length: 4),     // "@Ann"
            FlareTextMentionSpan(start: 5, length: 4),     // overlaps "@Ann"
            FlareTextMentionSpan(start: 8, length: 40),    // past the end
        ])
        XCTAssertEqual(segments.map(\.text), ["👍 ", "@Ann", " @Bob"])
        XCTAssertEqual(segments.map { $0.mention != nil }, [false, true, false])
        XCTAssertEqual(segments.map(\.text).joined(), text, "segments never lose or repeat text")
    }

    func testIncomingMentionsUseThePrimaryTextColourAndOnlyTheReaderOrAllGetTheSelectedGround() throws {
        let text = "@Ann look @me"
        let spans = [FlareTextMentionSpan(start: 0, length: 4), FlareTextMentionSpan(start: 10, length: 3, mentionsSelf: true)]
        let attributed = TextMessageView.attributed(TextMessageView.segments(text, mentions: spans), outgoing: false,
                                                    colors: colors, fontSize: 15, linkColor: colors.primary,
                                                    flatHighlight: true)
        let ann = try XCTUnwrap(attributed.runs.first { String(attributed[$0.range].characters) == "@Ann" })
        XCTAssertEqual(ann[UI.FontAttribute.self], .system(size: 15, weight: .medium))
        XCTAssertEqual(ann[UI.ForegroundColorAttribute.self], colors.primaryText)
        XCTAssertNil(ann[UI.BackgroundColorAttribute.self], "a mention of someone else has no ground")
        let me = try XCTUnwrap(attributed.runs.first { String(attributed[$0.range].characters) == "@me" })
        XCTAssertEqual(me[UI.FontAttribute.self], .system(size: 15, weight: .medium))
        XCTAssertEqual(me[UI.BackgroundColorAttribute.self], colors.bgSelected)
        let plain = try XCTUnwrap(attributed.runs.first { String(attributed[$0.range].characters) == " look " })
        XCTAssertNil(plain[UI.FontAttribute.self])
        XCTAssertNil(plain[UI.BackgroundColorAttribute.self])
        XCTAssertTrue(TextMessageView.drawsRoundedHighlight(TextMessageView.segments(text, mentions: spans), outgoing: false))
    }

    func testOutgoingMentionsInheritTheBubbleForegroundWithNoGround() throws {
        let text = "@all ship it"
        let spans = [FlareTextMentionSpan(start: 0, length: 4, mentionsAll: true)]
        let segments = TextMessageView.segments(text, mentions: spans)
        let attributed = TextMessageView.attributed(segments, outgoing: true, colors: colors, fontSize: 15,
                                                    linkColor: colors.messageOutgoingForeground, flatHighlight: true)
        let all = try XCTUnwrap(attributed.runs.first { String(attributed[$0.range].characters) == "@all" })
        XCTAssertEqual(all[UI.FontAttribute.self], .system(size: 15, weight: .semibold))
        XCTAssertNil(all[UI.ForegroundColorAttribute.self], "the bubble's own foreground")
        XCTAssertNil(all[UI.BackgroundColorAttribute.self])
        XCTAssertFalse(TextMessageView.drawsRoundedHighlight(segments, outgoing: true))
    }

    func testALinkOutsideAMentionStaysALink() throws {
        let text = "@Ann see flare.im"
        let attributed = TextMessageView.attributed(
            TextMessageView.segments(text, mentions: [FlareTextMentionSpan(start: 0, length: 4)]),
            outgoing: false, colors: colors, fontSize: 15, linkColor: colors.primary, flatHighlight: false)
        let link = try XCTUnwrap(attributed.runs.first { String(attributed[$0.range].characters) == "flare.im" })
        XCTAssertEqual(link[AttributeScopes.FoundationAttributes.LinkAttribute.self], URL(string: "https://flare.im"))
        XCTAssertEqual(String(attributed.characters), text)
    }

    @MainActor
    func testTextWithoutMentionsRendersThePlainBody() throws {
        let body = try TextMessageView(text: "hello flare.im").inspect()
        XCTAssertEqual(try body.find(ViewType.Text.self).string(), "hello flare.im")
        XCTAssertEqual(TextMessageView.segments("hello", mentions: []), [TextMessageView.Segment(text: "hello", mention: nil)])
        XCTAssertFalse(TextMessageView.drawsRoundedHighlight(TextMessageView.segments("hello", mentions: []), outgoing: false))
    }

    @MainActor
    func testTheContentViewPassesTheMentionsToTheTextBody() throws {
        let content = FlareTextContent("@me hi", mentions: [FlareTextMentionSpan(start: 0, length: 3, mentionsSelf: true)])
        let view = try MessageContentView(content: content).inspect()
        XCTAssertEqual(try view.find(TextMessageView.self).find(ViewType.Text.self).string(), "@me hi")
    }
}
