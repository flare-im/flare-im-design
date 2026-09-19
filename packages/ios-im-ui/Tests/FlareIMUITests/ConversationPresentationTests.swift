import Foundation
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

final class ConversationPresentationTests: XCTestCase {
    private struct Fixture: Decodable { let cases: [Vector] }
    private struct Vector: Decodable {
        let id: String, draft: String, expectedKind: String, expectedUnread: String, expectedEmphasis: String
        let failed: Bool, typing: Bool, mentioned: Bool, pinned: Bool, muted: Bool
        let unreadCount: Int
    }
    func testCanonicalStateVectors() throws {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let fixture = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: root.appendingPathComponent("spec/conversation-state-vectors.json")))
        for vector in fixture.cases {
            let item = ConversationRowData(id: vector.id, title: "Chat", unreadCount: vector.unreadCount, pinned: vector.pinned, muted: vector.muted, mentioned: vector.mentioned, draftPreview: vector.draft, typing: vector.typing, failed: vector.failed)
            XCTAssertEqual(item.previewKind, vector.expectedKind, vector.id)
            XCTAssertEqual(item.unreadLabel, vector.expectedUnread, vector.id)
            XCTAssertEqual(item.titleEmphasis, vector.expectedEmphasis, vector.id)
        }
    }
    @MainActor
    func testRowOwnsOneRealButtonAndDoesNotInventAnAction() throws {
        var selected: String?
        let item = ConversationRowData(id: "one", title: "Chat")
        let row = ConversationRowView(item: item, onSelect: { selected = $0.id })
        let buttons = try row.inspect().findAll(ViewType.Button.self)
        XCTAssertEqual(buttons.count, 1)
        try buttons[0].tap()
        XCTAssertEqual(selected, "one")
        XCTAssertTrue(try ConversationRowView(item: item).inspect().findAll(ViewType.Button.self).isEmpty)
    }
}
