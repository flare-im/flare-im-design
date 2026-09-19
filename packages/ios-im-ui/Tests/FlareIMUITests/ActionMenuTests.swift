import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// ActionMenu (FR-024): one item model, one grouping rule, one selection rule.
final class ActionMenuTests: XCTestCase {
    private func ids(_ sections: [[FlareActionItem]]) -> [[String]] { sections.map { $0.map(\.id) } }

    func testItemDefaults() {
        let item = FlareActionItem(id: "a", label: "A")
        XCTAssertNil(item.icon)
        XCTAssertNil(item.group)
        XCTAssertTrue(item.visible)
        XCTAssertTrue(item.enabled)
        XCTAssertNil(item.badge)
        XCTAssertNil(item.accessibilityLabel)
        XCTAssertNil(item.disabledReason)
        XCTAssertNil(item.pressed)
        XCTAssertFalse(item.danger)
        XCTAssertEqual(item, FlareActionItem(id: "a", label: "A"))
        XCTAssertNotEqual(item, FlareActionItem(id: "a", label: "A", pressed: false))
    }

    // Rule 1: host order is kept; the kit never sorts.
    func testHostOrderIsKept() {
        let items = ["zeta", "alpha", "mid"].map { FlareActionItem(id: $0, label: $0.uppercased()) }
        XCTAssertEqual(ids(ActionMenuRules.sections(items)), [["zeta", "alpha", "mid"]])
    }

    @MainActor
    func testTheMenuKeepsItsOrderWhenItOpensUpward() {
        // The system reverses a menu that opens upward unless its order is fixed.
        let menu = ActionMenuView(items: [FlareActionItem(id: "a", label: "A")], accessibilityLabel: "More",
                                  onSelect: { _ in }) { Text("Open") }
        XCTAssertTrue(String(describing: type(of: menu.body)).contains("MenuOrder"))
    }

    // Rule 2: a separator before an item whose group is set and differs from the last group seen.
    func testASectionStartsWhereTheGroupChanges() {
        let items = [
            FlareActionItem(id: "a", label: "A", group: "x"),
            FlareActionItem(id: "b", label: "B", group: "x"),
            FlareActionItem(id: "c", label: "C", group: "y"),
            FlareActionItem(id: "d", label: "D", group: "x"),
        ]
        XCTAssertEqual(ids(ActionMenuRules.sections(items)), [["a", "b"], ["c"], ["d"]])
    }

    func testItemsWithoutAGroupKeepTheCurrentOne() {
        let items = [
            FlareActionItem(id: "plain", label: "Plain"),
            FlareActionItem(id: "x1", label: "X1", group: "x"),
            FlareActionItem(id: "loose", label: "Loose"),
            FlareActionItem(id: "x2", label: "X2", group: "x"),
            FlareActionItem(id: "danger", label: "Danger", group: "danger", danger: true),
            FlareActionItem(id: "tail", label: "Tail"),
        ]
        // The first item never has a separator before it; `loose` stays with x, so x2 continues it.
        XCTAssertEqual(ids(ActionMenuRules.sections(items)), [["plain"], ["x1", "loose", "x2"], ["danger", "tail"]])
        XCTAssertEqual(ids(ActionMenuRules.sections([FlareActionItem(id: "solo", label: "Solo", group: "x")])), [["solo"]])
    }

    func testInvisibleItemsAreLeftOutBeforeGrouping() {
        let items = [
            FlareActionItem(id: "a", label: "A", group: "x"),
            FlareActionItem(id: "hidden", label: "Hidden", group: "y", visible: false),
            FlareActionItem(id: "b", label: "B"),
        ]
        // The hidden item's group is never seen, so `b` stays in x's section.
        XCTAssertEqual(ids(ActionMenuRules.sections(items)), [["a", "b"]])
        XCTAssertTrue(ActionMenuRules.sections([FlareActionItem(id: "h", label: "H", visible: false)]).isEmpty)
        XCTAssertTrue(ActionMenuRules.sections([]).isEmpty)
    }

    func testRowPartsFollowTheItem() {
        let plain = FlareActionItem(id: "search", label: "Search", icon: "search")
        XCTAssertEqual(ActionMenuRules.title(plain), "Search")
        XCTAssertNil(ActionMenuRules.secondLine(plain))
        XCTAssertEqual(ActionMenuRules.symbol(plain), "magnifyingglass", "icons are semantic kit names")
        XCTAssertEqual(ActionMenuRules.traits(plain), [])
        XCTAssertNil(ActionMenuRules.symbol(FlareActionItem(id: "t", label: "Text only")))
        XCTAssertEqual(ActionMenuRules.symbol(FlareActionItem(id: "u", label: "Unknown", icon: "no-such-icon")), "questionmark")

        // The badge is compact trailing text on the title line.
        XCTAssertEqual(ActionMenuRules.title(FlareActionItem(id: "r", label: "Requests", badge: "3")), "Requests  3")
        XCTAssertEqual(ActionMenuRules.title(FlareActionItem(id: "r", label: "Requests", badge: "")), "Requests")

        // A disabled item's reason is its second line; an enabled item never shows one.
        let disabled = FlareActionItem(id: "export", label: "Export", enabled: false, disabledReason: "Owner only")
        XCTAssertEqual(ActionMenuRules.secondLine(disabled), "Owner only")
        XCTAssertNil(ActionMenuRules.secondLine(FlareActionItem(id: "export", label: "Export", disabledReason: "Owner only")))
        XCTAssertNil(ActionMenuRules.secondLine(FlareActionItem(id: "export", label: "Export", enabled: false)))
    }

    // Rule 4: pressed != nil is checkable — a check while true, exposed as selected.
    func testPressedMakesACheckableItem() {
        let on = FlareActionItem(id: "mute", label: "Mute", icon: "mute", pressed: true)
        let off = FlareActionItem(id: "mute", label: "Mute", icon: "mute", pressed: false)
        XCTAssertEqual(ActionMenuRules.symbol(on), "checkmark")
        XCTAssertEqual(ActionMenuRules.traits(on), .isSelected)
        XCTAssertEqual(ActionMenuRules.symbol(off), "bell.slash")
        XCTAssertEqual(ActionMenuRules.traits(off), [])
        XCTAssertEqual(ActionMenuRules.symbol(FlareActionItem(id: "p", label: "Plain", pressed: true)), "checkmark")
    }

    // Rule 3 + 5: an enabled item reports its id; a disabled one never does; danger is destructive.
    @MainActor
    func testTheMenuReportsEnabledItemsOnly() throws {
        var selected: [String] = []
        let menu = ActionMenuView(items: [
            FlareActionItem(id: "search", label: "Search", icon: "search", group: "find"),
            FlareActionItem(id: "export", label: "Export", group: "data", enabled: false, disabledReason: "Owner only"),
            FlareActionItem(id: "leave", label: "Leave", icon: "logout", group: "danger", danger: true),
        ], accessibilityLabel: "More", onSelect: { selected.append($0) }) {
            Image(systemName: "ellipsis")
        }
        let inspected = try menu.inspect().find(ViewType.Menu.self)
        XCTAssertEqual(try inspected.accessibilityLabel().string(), "More")
        XCTAssertEqual(inspected.findAll(ViewType.Section.self).count, 3, "one section per group run")

        try inspected.find(button: "Search").tap()
        XCTAssertEqual(selected, ["search"])

        let export = try inspected.find(button: "Export")
        XCTAssertTrue(export.isDisabled())
        XCTAssertNoThrow(try export.find(text: "Owner only"), "the reason is the second line")
        XCTAssertThrowsError(try export.tap(), "a disabled item never reports")
        XCTAssertEqual(selected, ["search"])

        let leave = try inspected.find(button: "Leave")
        XCTAssertEqual(try leave.role(), .destructive)
        XCTAssertNil(try inspected.find(button: "Search").role())
        try leave.tap()
        XCTAssertEqual(selected, ["search", "leave"])
    }

    @MainActor
    func testAnItemCanNameItselfForAssistiveTechnology() throws {
        let menu = ActionMenuView(items: [
            FlareActionItem(id: "requests", label: "Requests", badge: "3", accessibilityLabel: "3 new requests"),
            FlareActionItem(id: "plain", label: "Plain"),
        ], accessibilityLabel: "Contacts", onSelect: { _ in }) { Text("Open") }
        let inspected = try menu.inspect().find(ViewType.Menu.self)
        XCTAssertEqual(try inspected.find(button: "Requests  3").accessibilityLabel().string(), "3 new requests")
        XCTAssertThrowsError(try inspected.find(button: "Plain").accessibilityLabel(), "no override, the system label stays")
    }

    // Rule 7: a menu with no visible item never opens — only its label is drawn.
    @MainActor
    func testAnEmptyMenuDrawsOnlyItsLabel() throws {
        let empty = ActionMenuView(items: [], accessibilityLabel: "More", onSelect: { _ in }) { Text("Trigger") }
        XCTAssertThrowsError(try empty.inspect().find(ViewType.Menu.self))
        XCTAssertNoThrow(try empty.inspect().find(text: "Trigger"))
        let hidden = ActionMenuView(items: [FlareActionItem(id: "h", label: "Hidden", visible: false)],
                                    accessibilityLabel: "More", onSelect: { _ in }) { Text("Trigger") }
        XCTAssertThrowsError(try hidden.inspect().find(ViewType.Menu.self))
        XCTAssertThrowsError(try hidden.inspect().find(button: "Hidden"))
    }
}
