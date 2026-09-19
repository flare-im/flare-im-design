import XCTest
@testable import FlareIMUI

final class ConversationHeaderGroupingTests: XCTestCase {
    private let group = ConversationIdentity(id: "g1", title: "Product room", kind: .group)

    func testHeaderActionsResolveDefaultsCapabilitiesAndHostConfiguration() {
        let resolved = resolveConversationHeaderActions(
            identity: group,
            capabilities: ConversationHeaderCapabilities(availableActionIds: ["search", "addMember", "share", "task", "pin"]),
            configuration: ConversationHeaderConfiguration(
                removeActionIds: ["share"],
                actionOverrides: [
                    ConversationHeaderAction(
                        id: "addMember", label: "Invite people", icon: "person.badge.plus",
                        placement: .add, order: 30, enabled: false, disabledReason: "Read only"
                    ),
                ]
            ),
            actions: [
                ConversationHeaderAction(id: "pin", label: "Pin", order: 5),
                ConversationHeaderAction(id: "task", label: "Create task", placement: .add, order: 40),
            ]
        )
        XCTAssertEqual(resolved.map(\.id), ["pin", "search", "addMember", "task"])
        XCTAssertFalse(resolved[2].enabled)
        XCTAssertEqual(resolved[2].label, "Invite people")
    }

    func testGroupingCoversSenderTimeAndSystemBoundaries() {
        let messages = [
            message("1", "ivy", 1_000), message("2", "ivy", 2_000),
            message("3", "ivy", 400_000), message("4", "system", 401_000, system: true),
            message("5", "ivy", 402_000), message("6", "me", 403_000),
        ]
        XCTAssertEqual(messageGroupPosition(messages, index: 0), .first)
        XCTAssertEqual(messageGroupPosition(messages, index: 1), .last)
        XCTAssertEqual(messageGroupPosition(messages, index: 2), .single)
        XCTAssertEqual(messageGroupPosition(messages, index: 3), .single)
        XCTAssertEqual(messageGroupPosition(messages, index: 4), .single)

        // A recalled message is a notice: it stands alone and ends the sender's run.
        let recalledRun = [
            message("r1", "ivy", 1_000), message("r2", "ivy", 2_000),
            FlareMessageData(id: "r3", senderId: "ivy", senderName: "ivy", content: FlareTextContent("gone"), sentAtMs: 3_000,
                             lifecycle: FlareMessageLifecycle(mutation: .recalled)),
            message("r4", "ivy", 4_000),
        ]
        XCTAssertEqual(recalledRun.indices.map { messageGroupPosition(recalledRun, index: $0) }, [.first, .last, .single, .single])

        let incoming = messageRowPresentation(
            message: messages[0], position: .first, currentUserId: "me", groupConversation: true)
        let outgoing = messageRowPresentation(
            message: messages[5], position: .single, currentUserId: "me", groupConversation: true)
        XCTAssertTrue(incoming.showAvatar)
        XCTAssertTrue(incoming.showSenderName)
        XCTAssertTrue(incoming.reserveAvatarSpace)
        XCTAssertFalse(outgoing.showAvatar)
        XCTAssertFalse(outgoing.showSenderName)
    }

    private func message(_ id: String, _ sender: String, _ time: Int64, system: Bool = false) -> FlareMessageData {
        FlareMessageData(
            id: id,
            senderId: sender,
            senderName: sender,
            content: system ? FlareNotificationContent("boundary") : FlareTextContent("hello"),
            sentAtMs: time
        )
    }
}
