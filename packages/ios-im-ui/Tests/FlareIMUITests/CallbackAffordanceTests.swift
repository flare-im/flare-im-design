import SwiftUI
import XCTest
@testable import FlareIMUI

/// "No callback, no dead control" contract for the wave-0 additions:
/// Toast `onClose`, MessageStatus `onResend`, NewFriendRequests `onView`.
final class CallbackAffordanceTests: XCTestCase {
    func testToastCloseButtonOnlyWithHandler() {
        XCTAssertFalse(ToastView.showsClose(nil))
        XCTAssertTrue(ToastView.showsClose({}))
        _ = ToastView(message: "saved", variant: .success).body
        _ = ToastView(message: "offline", variant: .warning, actionLabel: "retry", onAction: {}, onClose: {}).body
    }

    func testMessageStatusResendOnlyForFailedWithHandler() {
        let handler: () -> Void = {}
        XCTAssertTrue(MessageStatusView.resendEnabled(.failed, handler))
        XCTAssertFalse(MessageStatusView.resendEnabled(.failed, nil))
        for status: FlareMessageDeliveryStatus in [.pending, .sending, .sent, .delivered, .read, .retrying] {
            XCTAssertFalse(MessageStatusView.resendEnabled(status, handler), "\(status) must not offer resend")
        }
        XCTAssertEqual(FlareStrings().resend, "重新发送")
        _ = MessageStatusView(status: .failed, onResend: {}).body
        _ = MessageStatusView(status: .failed, variant: .compact).body
        _ = MessageDoubleCheckShape().path(in: CGRect(x: 0, y: 0, width: 16, height: 16))
    }

    func testNewFriendRequestsRowTapOnlyWithOnView() {
        var viewed: [String] = []
        XCTAssertNil(NewFriendRequestsView.rowTap(id: "r1", onView: nil))
        let tap = NewFriendRequestsView.rowTap(id: "r1", onView: { viewed.append($0) })
        XCTAssertNotNil(tap)
        tap?()
        XCTAssertEqual(viewed, ["r1"], "onView receives the request id")
        let items = [FriendRequest(id: "r1", name: "Bob", message: "hi")]
        _ = NewFriendRequestsView(items: items).body
        _ = NewFriendRequestsView(items: items, onAccept: { _ in }, onReject: { _ in }, onView: { _ in }).body
    }

    func testActionSheetDefaultsMatchUnifiedSet() {
        let ids = FlareComposerActionPanel.defaultActions.map(\.id)
        XCTAssertEqual(ids, ["image", "file", "voice", "location", "contact"])
        XCTAssertEqual(FlareComposerActionPanel.actions(for: FlareStrings()).map(\.id), ids)
        XCTAssertEqual(Set(ids).count, ids.count, "ids are unique")
        XCTAssertTrue(FlareComposerActionPanel.defaultActions.allSatisfy { !$0.label.isEmpty && flareIconNames.contains($0.icon) })
    }

    func testComposerActionsResolveHostConfigurationAndCapabilities() {
        let actions = [
            FlareComposerAction(id: "file", label: "File", icon: "folder", order: 30),
            FlareComposerAction(id: "voice", label: "Voice", icon: "mic", visible: false),
            FlareComposerAction(id: "order", label: "Order", icon: "file", order: 20, intent: "open-order"),
            FlareComposerAction(id: "image", label: "Image", icon: "image", order: 10, enabled: false),
        ]
        let resolved = resolveComposerActions(
            defaults: FlareComposerActionPanel.defaultActions,
            capabilities: FlareComposerCapabilities(availableActionIDs: ["image", "order", "file"]),
            actions: actions
        )
        XCTAssertEqual(resolved.map(\.id), ["image", "order", "file"])
        XCTAssertFalse(resolved[0].enabled)
        XCTAssertEqual(resolved[1].intent, "open-order")
    }

    func testContactDetailConstructs() {
        _ = FlareContactDetail(contact: Contact(id: "u1", name: "Ada")).body
    }
}
