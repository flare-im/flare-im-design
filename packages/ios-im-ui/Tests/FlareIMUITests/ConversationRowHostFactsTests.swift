import XCTest
@testable import FlareIMUI

/// `hostFacts` is the only way a host adds the two things it knows and the core does not: the draft this
/// device is holding, and who is typing. Without it an app could not set `typing` at all on Swift or Dart,
/// which is how the `typing` branch of `previewKind` stayed unreachable on four kits for several rounds.
final class ConversationRowHostFactsTests: XCTestCase {
    private let row = ConversationRowData(
        id: "c1", title: "Ann", preview: "see you at nine", timestampLabel: "09:00",
        unreadCount: 3, mentioned: true, tags: [ConversationRowTag(text: "群聊")])

    func testTypingChangesTheRowAndNothingElse() {
        let next = row.hostFacts(typing: true)
        XCTAssertTrue(next.typing)
        XCTAssertEqual(next.previewKind, "typing")
        XCTAssertEqual(next.id, row.id)
        XCTAssertEqual(next.preview, row.preview)
        XCTAssertEqual(next.unreadCount, row.unreadCount)
        XCTAssertEqual(next.mentioned, row.mentioned)
        XCTAssertEqual(next.tags.map { $0.text }, row.tags.map { $0.text })
        XCTAssertEqual(next.timestampLabel, row.timestampLabel)
    }

    func testADraftOutranksTyping() {
        XCTAssertEqual(row.hostFacts(draftPreview: "half a thought", typing: true).previewKind, "draft")
    }

    func testPassingNothingKeepsWhatTheRowHad() {
        let next = row.hostFacts()
        XCTAssertEqual(next.typing, row.typing)
        XCTAssertEqual(next.draftPreview, row.draftPreview)
        XCTAssertEqual(next.previewKind, row.previewKind)
    }
}
