import SwiftUI
import XCTest
@testable import FlareIMUI

/// Multi-select contract shared with Flutter/Compose:
/// `multiSelectMode` / `selected` / `selectedIds` / `onToggleSelect(id)`.
final class MessageSelectionTests: XCTestCase {
    private let msgs = [
        FlareMessageData(id: "m1", senderId: "me", senderName: "me", content: FlareTextContent("hi")),
        FlareMessageData(id: "m2", senderId: "u2", senderName: "Ivy", content: FlareTextContent("yo")),
    ]

    func testSelectionSymbolIsNotColourOnly() {
        XCTAssertEqual(MessageBubbleView.selectionSymbol(selected: true), "checkmark.circle.fill")
        XCTAssertEqual(MessageBubbleView.selectionSymbol(selected: false), "circle")
        XCTAssertNotEqual(MessageBubbleView.selectionSymbol(selected: true),
                          MessageBubbleView.selectionSymbol(selected: false))
    }

    func testBubbleRowTapOnlyInMultiSelectModeWithHandler() {
        var toggled: [String] = []
        let handler: (String) -> Void = { toggled.append($0) }
        XCTAssertNil(MessageBubbleView.rowTap(multiSelectMode: false, id: "m1", onToggleSelect: handler))
        XCTAssertNil(MessageBubbleView.rowTap(multiSelectMode: true, id: "m1", onToggleSelect: nil))
        let tap = MessageBubbleView.rowTap(multiSelectMode: true, id: "m1", onToggleSelect: handler)
        XCTAssertNotNil(tap)
        tap?()
        XCTAssertEqual(toggled, ["m1"], "stable id is the first (only) argument")
    }

    func testListDerivesSelectedFromIdSet() {
        XCTAssertTrue(MessageListView.isSelected("m1", multiSelectMode: true, selectedIds: ["m1", "m9"]))
        XCTAssertFalse(MessageListView.isSelected("m2", multiSelectMode: true, selectedIds: ["m1"]))
        XCTAssertFalse(MessageListView.isSelected("m1", multiSelectMode: false, selectedIds: ["m1"]),
                       "selection only renders in multi-select mode")
    }

    func testListSuspendsLongPressInMultiSelectMode() {
        let lp: (FlareMessageData) -> Void = { _ in }
        XCTAssertTrue(MessageListView.longPressEnabled(multiSelectMode: false, onMessageLongPress: lp))
        XCTAssertFalse(MessageListView.longPressEnabled(multiSelectMode: true, onMessageLongPress: lp))
        XCTAssertFalse(MessageListView.longPressEnabled(multiSelectMode: false, onMessageLongPress: nil))
    }

    func testViewsConstructWithSelectionParameters() {
        _ = MessageBubbleView(message: msgs[0], currentUserId: "me").body
        _ = MessageBubbleView(message: msgs[0], currentUserId: "me", multiSelectMode: true, selected: true,
                              onToggleSelect: { _ in }).body
        _ = MessageBubbleView(message: msgs[1], currentUserId: "me", conversationKind: .group,
                              multiSelectMode: true, selected: false, onToggleSelect: { _ in }).body
        _ = MessageListView(messages: msgs, currentUserId: "me").body
        _ = MessageListView(messages: msgs, currentUserId: "me", onMessageLongPress: { _ in },
                            multiSelectMode: true, selectedIds: ["m2"], onToggleSelect: { _ in }).body
    }
}
