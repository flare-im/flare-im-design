import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The header's identity target and toggle actions (FR-055).
final class ConversationHeaderIdentityTests: XCTestCase {
    private let details = ConversationHeaderAction(id: "details", label: "Details")

    func testIdentityActionIsFilteredLikeHeaderActionsAndNeedsAHandler() {
        let identity = ConversationIdentity(id: "c1", title: "Design", action: details)
        let all = ConversationHeaderConfiguration()
        func resolve(_ identity: ConversationIdentity, _ capabilities: ConversationHeaderCapabilities? = nil,
                     _ configuration: ConversationHeaderConfiguration = ConversationHeaderConfiguration(),
                     hasOnAction: Bool = true) -> String? {
            ConversationHeaderView.identityAction(identity, capabilities: capabilities, configuration: configuration,
                                                  hasOnAction: hasOnAction)?.id
        }
        XCTAssertEqual(resolve(identity), "details")
        XCTAssertEqual(resolve(identity, .init(availableActionIds: ["details"])), "details")
        XCTAssertNil(resolve(identity, .init(availableActionIds: [])))
        XCTAssertNil(resolve(identity, nil, .init(removeActionIds: ["details"])))
        XCTAssertNil(resolve(identity, nil, all, hasOnAction: false), "no handler, no control")
        XCTAssertNil(resolve(ConversationIdentity(id: "c1", title: "Design",
                                                  action: ConversationHeaderAction(id: "details", label: "Details", visible: false))))
        XCTAssertNil(resolve(ConversationIdentity(id: "c1", title: "Design",
                                                  action: ConversationHeaderAction(id: "details", label: "Details", enabled: false))))
        XCTAssertNil(resolve(ConversationIdentity(id: "c1", title: "Design")))
    }

    func testIdentityLabelDefaultsToTitleAndActionLabel() {
        let identity = ConversationIdentity(id: "c1", title: "Design", action: details)
        XCTAssertEqual(ConversationHeaderView.identityLabel(identity, action: details, strings: FlareStrings()), "Design，Details")
        let english = FlareStrings(conversationHeaderIdentityLabel: { "\($0), \($1)" })
        XCTAssertEqual(ConversationHeaderView.identityLabel(identity, action: details, strings: english), "Design, Details")
        let labelled = ConversationHeaderAction(id: "details", label: "Details", accessibilityLabel: "Open Design details")
        XCTAssertEqual(ConversationHeaderView.identityLabel(identity, action: labelled, strings: english), "Open Design details")
    }

    func testPressedMakesAToggle() {
        let plain = ConversationHeaderAction(id: "mute", label: "Mute")
        XCTAssertNil(plain.pressed)
        XCTAssertEqual(ConversationHeaderView.toggleTraits(plain), [])
        XCTAssertEqual(ConversationHeaderView.toggleTraits(ConversationHeaderAction(id: "mute", label: "Mute", pressed: true)),
                       .isSelected)
        XCTAssertEqual(ConversationHeaderView.toggleTraits(ConversationHeaderAction(id: "mute", label: "Mute", pressed: false)), [])
    }

    @MainActor
    func testIdentityBlockIsOneButtonDispatchingTheAction() throws {
        var dispatched: [String] = []
        let header = ConversationHeaderView(
            identity: ConversationIdentity(id: "c1", title: "Design", subtitle: "12 members", action: details),
            capabilities: ConversationHeaderCapabilities(availableActionIds: ["details"]),
            showBack: true, onBack: {}, onAction: { dispatched.append($0.id) })
        let identity = try header.inspect().find(button: "Design")
        XCTAssertNoThrow(try identity.find(text: "12 members"), "the subtitle is part of the same button")
        XCTAssertEqual(try identity.accessibilityLabel().string(), "Design，Details")
        try identity.tap()
        XCTAssertEqual(dispatched, ["details"])
        // The back button stays its own control, named from the strings table with a 44pt target on its label.
        let back = try header.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == FlareStrings().back })
        XCTAssertEqual(try back.labelView().find(ViewType.Image.self).actualImage().name(), flareIconMap["back"])
        XCTAssertEqual(try back.labelView().find(ViewType.Image.self).flexFrame().minWidth, FlareSizes.touchTargetMin)
        XCTAssertThrowsError(try header.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == "Back" }),
                             "no English literal in the Chinese header")
    }

    @MainActor
    func testIdentityWithoutAUsableActionIsNotAControl() throws {
        let plain = ConversationHeaderView(identity: ConversationIdentity(id: "c1", title: "Design"),
                                           capabilities: ConversationHeaderCapabilities(availableActionIds: []),
                                           onAction: { _ in })
        XCTAssertThrowsError(try plain.inspect().find(button: "Design"))
        let unhandled = ConversationHeaderView(identity: ConversationIdentity(id: "c1", title: "Design", action: details))
        XCTAssertThrowsError(try unhandled.inspect().find(button: "Design"), "no onAction, no control")
        let disabled = ConversationHeaderView(
            identity: ConversationIdentity(id: "c1", title: "Design",
                                           action: ConversationHeaderAction(id: "details", label: "Details", enabled: false)),
            onAction: { _ in })
        XCTAssertThrowsError(try disabled.inspect().find(button: "Design"))
        XCTAssertNoThrow(try disabled.inspect().find(text: "Design"), "the identity still shows")
    }
}
