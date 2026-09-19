import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// SearchBar entry mode (FR-027): read-only is a single button with `onActivate`, display-only
/// without it, and never a text field.
final class SearchBarEntryTests: XCTestCase {
    func testRoleFollowsReadOnlyAndHandler() {
        XCTAssertEqual(SearchBarView.role(readOnly: false, onActivate: nil), .field)
        XCTAssertEqual(SearchBarView.role(readOnly: false, onActivate: {}), .field)
        XCTAssertEqual(SearchBarView.role(readOnly: true, onActivate: {}), .entry)
        XCTAssertEqual(SearchBarView.role(readOnly: true, onActivate: nil), .display)
    }

    @MainActor
    func testReadOnlyEntryIsOneButtonLabelledByThePlaceholder() throws {
        var activations = 0
        let entry = SearchBarView(text: .constant(""), placeholder: "Search chats", readOnly: true,
                                  onActivate: { activations += 1 })
        let buttons = try entry.inspect().findAll(ViewType.Button.self)
        XCTAssertEqual(buttons.count, 1)
        XCTAssertTrue(try entry.inspect().findAll(ViewType.TextField.self).isEmpty)
        XCTAssertEqual(try buttons[0].accessibilityLabel().string(), "Search chats")
        try buttons[0].tap()
        XCTAssertEqual(activations, 1)
    }

    @MainActor
    func testEntryWithoutPlaceholderIsLabelledSearch() throws {
        let entry = SearchBarView(text: .constant(""), readOnly: true, onActivate: {})
        XCTAssertEqual(try entry.inspect().find(ViewType.Button.self).accessibilityLabel().string(), FlareStrings().search)
    }

    @MainActor
    func testReadOnlyWithoutHandlerIsDisplayOnly() throws {
        let display = SearchBarView(text: .constant("design"), readOnly: true)
        XCTAssertTrue(try display.inspect().findAll(ViewType.Button.self).isEmpty)
        XCTAssertTrue(try display.inspect().findAll(ViewType.TextField.self).isEmpty)
        XCTAssertEqual(try display.inspect().find(text: "design").string(), "design")
    }

    @MainActor
    func testOnlyTheEditableBarOffersClear() throws {
        let field = SearchBarView(text: .constant("abc"))
        XCTAssertEqual(try field.inspect().findAll(ViewType.TextField.self).count, 1)
        XCTAssertEqual(try field.inspect().findAll(ViewType.Button.self).count, 1, "the clear button")
        let entry = SearchBarView(text: .constant("abc"), readOnly: true, onActivate: {})
        XCTAssertEqual(try entry.inspect().findAll(ViewType.Button.self).count, 1, "the entry itself, no clear button")
    }
}
