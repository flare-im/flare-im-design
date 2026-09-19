import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The header's add and overflow menus are the kit ActionMenu over its actions (FR-024).
final class ConversationHeaderMenuTests: XCTestCase {
    private let group = ConversationIdentity(id: "g1", title: "Product room", kind: .group)
    private let hostActions = [
        ConversationHeaderAction(id: "mute", label: "Mute", icon: "mute", placement: .overflow, group: "prefs",
                                 order: 60, pressed: true),
        ConversationHeaderAction(id: "export", label: "Export", icon: "download", placement: .overflow, group: "data",
                                 order: 70, enabled: false, badge: "PDF", accessibilityLabel: "Export history",
                                 disabledReason: "Owner only"),
    ]

    func testDefaultIconsAreSemanticKitNames() {
        for kind in [ConversationHeaderKind.direct, .group] {
            let resolved = resolveConversationHeaderActions(identity: ConversationIdentity(id: "c", title: "C", kind: kind))
            for action in resolved {
                XCTAssertNotNil(flareIconMap[action.icon ?? ""], "\(action.id) icon \(action.icon ?? "nil") must resolve")
            }
        }
    }

    func testRegionsSplitPrimaryAddAndOverflowInResolvedOrder() {
        let resolved = resolveConversationHeaderActions(identity: group, actions: hostActions)
        let regions = ConversationHeaderView.regions(resolved, maxPrimary: 1)
        XCTAssertEqual(regions.primary.map(\.id), ["search"])
        XCTAssertEqual(regions.add.map(\.id), ["addMember", "share"])
        // Primary actions past the limit come first, then the overflow placements.
        XCTAssertEqual(regions.overflow.map(\.id), ["audioCall", "videoCall", "mute", "export", "details"])
        XCTAssertEqual(ConversationHeaderView.regions(resolved, maxPrimary: 3).overflow.map(\.id), ["mute", "export", "details"])
    }

    func testHeaderMenusBuildTheExpectedItems() {
        let resolved = resolveConversationHeaderActions(identity: group, actions: hostActions)
        let strings = FlareStrings()
        let overflow = ConversationHeaderView.regions(resolved, maxPrimary: 3).overflow
            .map { ConversationHeaderView.menuItem($0, kind: .group, strings: strings) }
        XCTAssertEqual(overflow, [
            FlareActionItem(id: "mute", label: "Mute", icon: "mute", group: "prefs", pressed: true),
            FlareActionItem(id: "export", label: "Export", icon: "download", group: "data", enabled: false, badge: "PDF",
                            accessibilityLabel: "Export history", disabledReason: "Owner only"),
            // The default action shows the strings table's words; host labels show as given.
            FlareActionItem(id: "details", label: strings.conversationHeaderDetails, icon: "info"),
        ])
        // Groups become sections; `details` has no group, so it stays with `data`.
        XCTAssertEqual(ActionMenuRules.sections(overflow).map { $0.map(\.id) }, [["mute"], ["export", "details"]])
        XCTAssertEqual(ActionMenuRules.symbol(overflow[0]), "checkmark", "a pressed action is checked")

        let add = ConversationHeaderView.regions(resolved, maxPrimary: 3).add
            .map { ConversationHeaderView.menuItem($0, kind: .group, strings: strings) }
        XCTAssertEqual(add.map(\.id), ["addMember", "share"])
        XCTAssertEqual(add.map { ActionMenuRules.symbol($0) }, ["person.badge.plus", "square.and.arrow.up"])
        XCTAssertFalse(add.contains(where: \.danger))
    }

    @MainActor
    func testChoosingAMenuItemDispatchesItsAction() throws {
        var dispatched: [String] = []
        let header = ConversationHeaderView(identity: group, actions: hostActions, onAction: { dispatched.append($0.id) })
        let more = try header.inspect().find(ViewType.Menu.self, where: {
            try $0.accessibilityLabel().string() == FlareStrings().conversationHeaderMoreActions
        })
        try more.find(button: "Mute").tap()
        XCTAssertEqual(dispatched, ["mute"])
        XCTAssertThrowsError(try more.find(button: "Export  PDF").tap(), "a disabled action never dispatches")
        try more.find(button: FlareStrings().conversationHeaderDetails).tap()
        XCTAssertEqual(dispatched, ["mute", "details"])

        let add = try header.inspect().find(ViewType.Menu.self, where: {
            try $0.accessibilityLabel().string() == FlareStrings().conversationHeaderAddActions
        })
        try add.find(button: FlareStrings().conversationHeaderAddMember).tap()
        XCTAssertEqual(dispatched, ["mute", "details", "addMember"])
    }
}
