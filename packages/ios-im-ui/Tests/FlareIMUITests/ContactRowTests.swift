import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// ContactItem / ContactList selection and trailing content (FR-029), and NewFriendRequests
/// direction with withdraw (FR-030).
final class ContactRowTests: XCTestCase {
    private let ada = Contact(id: "u1", name: "Ada", signature: "Keep it simple.")
    private let bob = Contact(id: "u2", name: "Bob")

    // MARK: Selection and trailing

    func testRowActionFollowsTheMode() {
        var calls: [String] = []
        let select: () -> Void = { calls.append("select") }
        let toggle: () -> Void = { calls.append("toggle") }
        ContactItemView.rowAction(selectable: false, onSelect: select, onToggleSelect: toggle)?()
        ContactItemView.rowAction(selectable: true, onSelect: select, onToggleSelect: toggle)?()
        XCTAssertEqual(calls, ["select", "toggle"])
        XCTAssertNil(ContactItemView.rowAction(selectable: true, onSelect: select, onToggleSelect: nil))
        XCTAssertNil(ContactItemView.rowAction(selectable: false, onSelect: nil, onToggleSelect: toggle))
    }

    @MainActor
    func testSelectableRowTogglesInsteadOfSelecting() throws {
        var toggles = 0
        var selects = 0
        let row = ContactItemView(item: ada, selectable: true, selected: true,
                                  onSelect: { selects += 1 }, onToggleSelect: { toggles += 1 })
        try row.inspect().find(button: "Ada").tap()
        XCTAssertEqual(toggles, 1)
        XCTAssertEqual(selects, 0)
        // The kit checkbox inside only shows the state: it takes no taps of its own.
        let checkbox = try row.inspect().find(CheckboxView.self)
        XCTAssertFalse(try checkbox.allowsHitTesting())
    }

    @MainActor
    func testTrailingControlsKeepTheirOwnTaps() throws {
        var removes = 0
        var selects = 0
        let row = ContactItemView(item: ada,
                                  trailing: AnyView(ButtonView(label: "Remove", variant: .secondary, size: .sm) { removes += 1 }),
                                  onSelect: { selects += 1 })
        try row.inspect().find(button: "Remove").tap()
        XCTAssertEqual(removes, 1)
        XCTAssertEqual(selects, 0)
        try row.inspect().find(button: "Ada").tap()
        XCTAssertEqual(selects, 1)
        XCTAssertEqual(removes, 1)
    }

    @MainActor
    func testRowWithoutAHandlerIsNotAControl() throws {
        XCTAssertTrue(try ContactItemView(item: ada).inspect().findAll(ViewType.Button.self).isEmpty)
        XCTAssertTrue(try ContactItemView(item: ada, selectable: true, onSelect: {}).inspect()
            .findAll(ViewType.Button.self).filter { (try? $0.find(text: "Ada")) != nil }.isEmpty)
    }

    @MainActor
    func testListTogglesTheTappedContactAndMarksSelectedIds() throws {
        var toggled: [String] = []
        var trailingFor: [String] = []
        let list = ContactListView(items: [ada, bob], selectable: true, selectedIds: ["u2"],
                                   trailing: { contact in trailingFor.append(contact.id); return AnyView(EmptyView()) },
                                   onSelect: { _ in XCTFail("selection mode does not select") },
                                   onToggleSelect: { toggled.append($0.id) })
        try list.inspect().find(button: "Bob").tap()
        XCTAssertEqual(toggled, ["u2"])
        XCTAssertEqual(Set(trailingFor), ["u1", "u2"])
    }

    // MARK: Friend request direction

    func testRequestsDefaultToIncoming() {
        XCTAssertEqual(FriendRequest(id: "r1", name: "Bob").direction, .incoming)
        XCTAssertEqual(FriendRequest(id: "r2", name: "Bob", direction: .outgoing).direction, .outgoing)
    }

    func testRowControlsByDirectionAndHandlers() {
        XCTAssertEqual(NewFriendRequestsView.rowControls(.incoming, hasAccept: true, hasReject: true, hasWithdraw: true),
                       [.decline, .accept])
        XCTAssertEqual(NewFriendRequestsView.rowControls(.incoming, hasAccept: true, hasReject: false, hasWithdraw: false),
                       [.accept])
        XCTAssertEqual(NewFriendRequestsView.rowControls(.incoming, hasAccept: false, hasReject: false, hasWithdraw: true), [])
        XCTAssertEqual(NewFriendRequestsView.rowControls(.outgoing, hasAccept: true, hasReject: true, hasWithdraw: true),
                       [.withdraw])
        XCTAssertEqual(NewFriendRequestsView.rowControls(.outgoing, hasAccept: true, hasReject: true, hasWithdraw: false), [])
    }

    @MainActor
    func testOutgoingRowShowsPendingAndWithdraws() throws {
        let strings = FlareStrings()
        var withdrawn: [String] = []
        let outgoing = [FriendRequest(id: "r1", name: "Bob", direction: .outgoing)]
        let view = NewFriendRequestsView(items: outgoing,
                                         onAccept: { _ in XCTFail("outgoing requests cannot be accepted") },
                                         onReject: { _ in XCTFail("outgoing requests cannot be declined") },
                                         onWithdraw: { withdrawn.append($0.id) })
        XCTAssertNoThrow(try view.inspect().find(text: strings.newFriendRequestsPending))
        XCTAssertThrowsError(try view.inspect().find(button: strings.newFriendRequestsAccept))
        XCTAssertThrowsError(try view.inspect().find(button: strings.reject))
        try view.inspect().find(button: strings.newFriendRequestsWithdraw).tap()
        XCTAssertEqual(withdrawn, ["r1"])
        XCTAssertThrowsError(try NewFriendRequestsView(items: outgoing).inspect().find(button: strings.newFriendRequestsWithdraw))
        XCTAssertEqual(strings.newFriendRequestsPending, "等待验证")
    }

    @MainActor
    func testIncomingRowAcceptsAndDeclines() throws {
        var answers: [String] = []
        let view = NewFriendRequestsView(items: [FriendRequest(id: "r1", name: "Ada", message: "hi")],
                                         acceptLabel: "Accept", declineLabel: "Decline",
                                         onAccept: { answers.append("accept \($0.id)") },
                                         onReject: { answers.append("decline \($0.id)") })
        try view.inspect().find(button: "Decline").tap()
        try view.inspect().find(button: "Accept").tap()
        XCTAssertEqual(answers, ["decline r1", "accept r1"])
        XCTAssertThrowsError(try view.inspect().find(text: FlareStrings().newFriendRequestsPending))
    }
}
