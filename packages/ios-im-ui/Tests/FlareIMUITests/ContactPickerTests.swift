import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The contact picker: tab names, the user's own row, search, the empty state, a single pick handing one entry to the
/// host, and the order a multiple pick keeps.
final class ContactPickerTests: XCTestCase {
    private let s = FlareStrings()
    private let ada = FlareContactPickerEntry(userId: "u-ada", name: "Ada", subtitle: "Design")
    private let me = FlareContactPickerEntry(userId: "u-me", name: "Hugo", isSelf: true)
    private let bob = FlareContactPickerEntry(userId: "u-bob", name: "Bob", subtitle: "Ops")

    private var groups: [FlareContactPickerGroup] {
        [FlareContactPickerGroup(id: FlareContactPickerGroup.friends, entries: [ada, bob]),
         FlareContactPickerGroup(id: FlareContactPickerGroup.groupMembers, entries: [me, ada])]
    }

    func testTabsTakeTheKitsNamesForTheKnownGroups() {
        XCTAssertEqual(groups.map { $0.resolvedLabel(s) }, [s.contactPickerFriends, s.contactPickerGroupMembers])
        XCTAssertEqual(groups.map { $0.resolvedLabel(.english) }, ["Friends", "Group members"])
        XCTAssertEqual(FlareContactPickerGroup(id: "team", label: "Team", entries: []).resolvedLabel(s), "Team")
        XCTAssertEqual(FlareContactPickerGroup(id: "team", entries: []).resolvedLabel(s), "team")
    }

    func testTheUsersOwnRowIsMarked() {
        XCTAssertEqual(ContactPickerView.displayName(me, s), "Hugo（我）")
        XCTAssertEqual(ContactPickerView.displayName(me, .english), "Hugo (me)")
        XCTAssertEqual(ContactPickerView.displayName(ada, s), "Ada")
    }

    func testSearchMatchesNamesAndSubtitlesIgnoringCase() {
        let all = [ada, me, bob]
        XCTAssertEqual(ContactPickerView.filter(all, query: "  ").map(\.userId), ["u-ada", "u-me", "u-bob"])
        XCTAssertEqual(ContactPickerView.filter(all, query: "ADA").map(\.userId), ["u-ada"])
        XCTAssertEqual(ContactPickerView.filter(all, query: "ops").map(\.userId), ["u-bob"])
        XCTAssertTrue(ContactPickerView.filter(all, query: "zz").isEmpty)
    }

    func testAMultiplePickKeepsItsOrderAndEachPersonOnce() {
        var ids: [String] = []
        ids = ContactPickerView.toggled(ids, "u-bob")
        ids = ContactPickerView.toggled(ids, "u-ada")
        ids = ContactPickerView.toggled(ids, "u-me")
        ids = ContactPickerView.toggled(ids, "u-bob")
        XCTAssertEqual(ids, ["u-ada", "u-me"])
        XCTAssertEqual(ContactPickerView.pickedEntries(ids, in: groups), [ada, me],
                       "an entry in two groups is handed over once")
    }

    @MainActor
    func testASinglePickHandsTheRowToTheHost() throws {
        var picked: [[FlareContactPickerEntry]] = []
        let view = try ContactPickerView(groups: groups, onSelect: { picked.append($0) }).inspect()
        try view.find(ViewType.Button.self, where: { (try? $0.labelView().find(text: "Bob")) != nil }).tap()
        XCTAssertEqual(picked, [[bob]])
        XCTAssertNoThrow(try view.find(text: s.contactPickerTitle))
        XCTAssertNoThrow(try view.find(FilterTabsView.self), "two groups: tabs")
        XCTAssertNoThrow(try view.find(SearchBarView.self))
        XCTAssertThrowsError(try view.find(text: s.confirm), "one person: no confirm key")
    }

    @MainActor
    func testOneGroupHasNoTabsAndTheEmptyStateSaysSo() throws {
        let one = try ContactPickerView(groups: [FlareContactPickerGroup(id: FlareContactPickerGroup.friends, entries: [])],
                                        searchable: false, title: "Share a card").inspect()
        XCTAssertThrowsError(try one.find(FilterTabsView.self))
        XCTAssertThrowsError(try one.find(SearchBarView.self))
        XCTAssertNoThrow(try one.find(text: s.contactPickerEmpty))
        XCTAssertNoThrow(try one.find(text: "Share a card"))
    }

    @MainActor
    func testMultipleRowsAreCheckboxesWithAConfirmKey() throws {
        var cancelled = 0
        let view = try ContactPickerView(groups: groups, multiple: true, onCancel: { cancelled += 1 }).inspect()
        let confirm = try view.find(ViewType.Button.self, where: { (try? $0.labelView().find(text: self.s.confirm)) != nil })
        XCTAssertTrue(confirm.isDisabled(), "nothing picked yet")
        XCTAssertNoThrow(try view.find(CheckboxView.self))
        try view.find(ViewType.Button.self, where: { (try? $0.labelView().find(text: self.s.cancel)) != nil }).tap()
        XCTAssertEqual(cancelled, 1)
    }
}
