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
        for status: FlareMessageDeliveryStatus in [.pending, .sent, .read] {
            XCTAssertFalse(MessageStatusView.resendEnabled(status, handler), "\(status) must not offer resend")
        }
        XCTAssertEqual(FlareStrings().resend, "重新发送")
        _ = MessageStatusView(status: .failed, onResend: {}).body
        _ = MessageStatusView(status: .failed, variant: .compact).body
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

    func testActionSheetDefaultsMatchUnifiedCoreSet() {
        let ids = MessageActionSheetView.defaultActions.map(\.id)
        XCTAssertEqual(ids, ["image", "camera", "file", "location", "card", "vote", "task", "schedule"])
        XCTAssertEqual(MessageActionSheetView.actions(for: FlareStrings()).map(\.id), ids)
        XCTAssertEqual(Set(ids).count, ids.count, "ids are unique")
        XCTAssertTrue(MessageActionSheetView.defaultActions.allSatisfy { !$0.label.isEmpty && !$0.systemImage.isEmpty })
    }

    func testDeprecatedContactDetailViewStillConstructs() {
        // `ContactDetailView` is deprecated in favour of `FlareContactDetail` but must remain source-compatible.
        _ = FlareContactDetail(contact: Contact(id: "u1", name: "Ada")).body
        _ = legacyContactDetail(Contact(id: "u1", name: "Ada"))
    }

    @available(*, deprecated)
    private func legacyContactDetail(_ contact: Contact) -> some View { ContactDetailView(contact: contact) }
}
