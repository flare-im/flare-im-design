import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// K6 (FR-103): with a keyboard the mention picker keeps focus in its search field, highlights the first
/// match, moves the highlight with the arrows, picks it with Return and closes with Escape.
final class MentionPickerKeyboardTests: XCTestCase {
    private let s = FlareStrings()
    private let people = [
        MentionCandidate(id: "u1", name: "Ann", detail: "设计"),
        MentionCandidate(id: "u2", name: "张伟", detail: "产品"),
        MentionCandidate(id: "u3", name: "Bob"),
    ]

    func testTheRowsPutEveryoneFirstAndFilterByNameOrDetail() {
        let all = MentionPickerView.results(people, allowEveryone: true, everyoneLabel: s.everyone, query: "")
        XCTAssertEqual(all.map(\.id), [MentionPickerView.everyoneId, "u1", "u2", "u3"])
        XCTAssertTrue(all[0].isEveryone)
        XCTAssertEqual(MentionPickerView.results(people, allowEveryone: true, everyoneLabel: s.everyone, query: " 产品 ").map(\.id), ["u2"])
        XCTAssertEqual(MentionPickerView.results(people, allowEveryone: true, everyoneLabel: s.everyone, query: "ANN").map(\.id), ["u1"])
        XCTAssertEqual(MentionPickerView.results(people, allowEveryone: true, everyoneLabel: s.everyone, query: "所有").map(\.id),
                       [MentionPickerView.everyoneId], "everyone matches its own word, not an English literal")
        XCTAssertEqual(MentionPickerView.results(people, allowEveryone: false, everyoneLabel: s.everyone, query: "").count, 3)
    }

    func testTheArrowsMoveTheHighlightAndWrap() {
        XCTAssertEqual(MentionPickerView.movedHighlight(0, by: 1, count: 3), 1)
        XCTAssertEqual(MentionPickerView.movedHighlight(2, by: 1, count: 3), 0, "down from the last wraps to the first")
        XCTAssertEqual(MentionPickerView.movedHighlight(0, by: -1, count: 3), 2, "up from the first wraps to the last")
        XCTAssertEqual(MentionPickerView.movedHighlight(1, by: -1, count: 0), 0, "no rows, no highlight to move")
    }

    func testTheSearchFieldTakesFocusOnlyWhereAKeyboardIsTheInput() {
        #if os(macOS)
        XCTAssertTrue(MentionPickerView.focusesSearchOnOpen(.ios()))
        #else
        XCTAssertFalse(MentionPickerView.focusesSearchOnOpen(.ios()), "touch keeps its behaviour")
        XCTAssertTrue(MentionPickerView.focusesSearchOnOpen(.ios(hasPointer: true)))
        #endif
    }

    @MainActor
    func testReturnPicksTheHighlightedFirstMatch() throws {
        var picked: [String] = []
        let picker = MentionPickerView(candidates: people, allowEveryone: true, onSelect: { picked.append($0.id) })
        try picker.inspect().find(ViewType.TextField.self).callOnSubmit()
        XCTAssertEqual(picked, [MentionPickerView.everyoneId], "the first row is highlighted when the picker opens")
        try picker.inspect().find(button: "张伟").tap()
        XCTAssertEqual(picked, [MentionPickerView.everyoneId, "u2"], "touch still picks the tapped row")
    }
}
