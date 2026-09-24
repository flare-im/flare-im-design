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
    func testTheMenuIsDrawnByTheKitSoNothingCanReverseItsOrder() {
        // The system menu reverses a menu that opens upward, and gives it a ~250pt minimum width.
        // The kit draws its own, so the host's order is the order and the width is the content's.
        let menu = ActionMenuView(items: [FlareActionItem(id: "a", label: "A")], accessibilityLabel: "More",
                                  onSelect: { _ in }) { Text("Open") }
        XCTAssertThrowsError(try menu.inspect().find(ViewType.Menu.self))
    }

    /// The width bounds are a cross-platform contract: Android's `ActionMenuMinWidth`/`MaxWidth`
    /// and the 8em/20em in the Vue and Flutter menus are these same numbers at a 14px base.
    func testTheWidthBoundsAreTheSameOnEveryPlatform() {
        XCTAssertEqual(ActionMenuRules.minWidth, 112)
        XCTAssertEqual(ActionMenuRules.maxWidth, 280)
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
        let items = [
            FlareActionItem(id: "search", label: "Search", icon: "search", group: "find"),
            FlareActionItem(id: "export", label: "Export", group: "data", enabled: false, disabledReason: "Owner only"),
            FlareActionItem(id: "leave", label: "Leave", icon: "logout", group: "danger", danger: true),
        ]
        let sections = ActionMenuRules.sections(items)
        let inspected = try menu.sheet(sections).inspect()
        XCTAssertEqual(try inspected.accessibilityLabel().string(), "More")
        XCTAssertEqual(sections.count, 3, "one section per group run")
        // The drawn surface keeps the host's order — the reason the kit stopped using the system
        // menu, which reverses itself when it opens upward.
        let drawn = inspected.findAll(ViewType.Text.self)
            .compactMap { try? $0.string() }
            .filter { ["Search", "Export", "Leave"].contains($0) }
        XCTAssertEqual(drawn, ["Search", "Export", "Leave"])

        try inspected.find(button: "Search").tap()
        XCTAssertEqual(selected, ["search"])

        let export = try inspected.find(button: "Export")
        XCTAssertTrue(export.isDisabled())
        XCTAssertNoThrow(try export.find(text: "Owner only"), "the reason is the second line")
        XCTAssertThrowsError(try export.tap(), "a disabled item never reports")
        XCTAssertEqual(selected, ["search"])

        // Destructive is the error colour now that the row is the kit's, not a system menu role.
        let colors = FlareColors.of(.light)
        let leaveRow = try menu.row(items[2], colors).inspect()
        XCTAssertEqual(try leaveRow.find(text: "Leave").attributes().foregroundColor(), colors.error)
        let searchRow = try menu.row(items[0], colors).inspect()
        XCTAssertEqual(try searchRow.find(text: "Search").attributes().foregroundColor(), colors.textPrimary,
                       "a normal item is not tinted as destructive")

        try inspected.find(button: "Leave").tap()
        XCTAssertEqual(selected, ["search", "leave"])
    }

    @MainActor
    func testAnItemCanNameItselfForAssistiveTechnology() throws {
        let menu = ActionMenuView(items: [
            FlareActionItem(id: "requests", label: "Requests", badge: "3", accessibilityLabel: "3 new requests"),
            FlareActionItem(id: "plain", label: "Plain"),
        ], accessibilityLabel: "Contacts", onSelect: { _ in }) { Text("Open") }
        let sections = ActionMenuRules.sections([
            FlareActionItem(id: "requests", label: "Requests", badge: "3", accessibilityLabel: "3 new requests"),
            FlareActionItem(id: "plain", label: "Plain"),
        ])
        let inspected = try menu.sheet(sections).inspect()
        XCTAssertEqual(try inspected.find(button: "Requests  3").accessibilityLabel().string(), "3 new requests")
        XCTAssertThrowsError(try inspected.find(button: "Plain").accessibilityLabel(), "no override, the row's own text stays")
    }

    // Rule 7: a menu with no visible item never opens — only its label is drawn.
    @MainActor
    func testAnEmptyMenuDrawsOnlyItsLabel() throws {
        let empty = ActionMenuView(items: [], accessibilityLabel: "More", onSelect: { _ in }) { Text("Trigger") }
        // Not just "no system menu" — with nothing to show there is no trigger button at all,
        // only the host's label.
        XCTAssertThrowsError(try empty.inspect().find(ViewType.Button.self))
        XCTAssertNoThrow(try empty.inspect().find(text: "Trigger"))
        XCTAssertNoThrow(try empty.inspect().find(text: "Trigger"))
        let hidden = ActionMenuView(items: [FlareActionItem(id: "h", label: "Hidden", visible: false)],
                                    accessibilityLabel: "More", onSelect: { _ in }) { Text("Trigger") }
        XCTAssertThrowsError(try hidden.inspect().find(ViewType.Menu.self))
        XCTAssertThrowsError(try hidden.inspect().find(button: "Hidden"))
    }
}
