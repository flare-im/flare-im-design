import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// FlareGroupDetail member intents carry the target state; transferring ownership confirms through
/// the app's FlareFeedback when a host is installed (FR-028), while removing a member and leaving /
/// dissolving are emitted as tapped for the host to confirm.
final class GroupDetailIntentTests: XCTestCase {
    private let ann = Contact(id: "u2", name: "Ann")
    private let bob = Contact(id: "u3", name: "Bob")

    private func model(isOwner: Bool = true) -> FlareGroupDetailModel {
        FlareGroupDetailModel(groupId: "g1", name: "Design", memberCount: 3,
                              members: [Contact(id: "me", name: "Me"), ann, bob], ownerId: isOwner ? "me" : "u9",
                              adminIds: ["u2"], mutedIds: ["u3"], canManage: true, isOwner: isOwner)
    }

    func testMemberIntentsOfferTheOppositeOfTheCurrentState() {
        let detail = model()
        // Ann is an admin who can talk: the buttons offer "unset admin" and "mute".
        XCTAssertEqual(FlareGroupDetail.memberIntentTargets("u2", in: detail).admin, false)
        XCTAssertEqual(FlareGroupDetail.memberIntentTargets("u2", in: detail).muted, true)
        // Bob is a muted member: "set admin" and "unmute".
        XCTAssertEqual(FlareGroupDetail.memberIntentTargets("u3", in: detail).admin, true)
        XCTAssertEqual(FlareGroupDetail.memberIntentTargets("u3", in: detail).muted, false)
    }

    func testDiscoverabilityDefaultsPrivateAndUsesTheSharedString() {
        XCTAssertFalse(model().discoverable)
        XCTAssertEqual(FlareGroupDetailLabels().resolve(FlareStrings()).discoverable,
                       FlareStrings().groupDetailDiscoverable)
    }

    func testTransferConfirmationCopyNamesTheStepAndTheMember() {
        let copy = FlareGroupDetailLabels().resolve(FlareStrings())
        let transfer = FlareGroupDetail.transferOptions(ann, copy: copy, onTransferOwner: nil)
        XCTAssertEqual(transfer.title, copy.transferOwner)
        XCTAssertEqual(transfer.confirmText, copy.transferOwner)
        XCTAssertTrue(transfer.description.contains("Ann"))
    }

    @MainActor
    func testTransferConfirmsThroughTheFeedbackHostBeforeEmitting() async {
        let copy = FlareGroupDetailLabels().resolve(FlareStrings())
        let feedback = FlareFeedback(announce: { _ in })
        var transferred: [String] = []
        let options = FlareGroupDetail.transferOptions(ann, copy: copy, onTransferOwner: { transferred.append($0) })
        XCTAssertTrue(FlareGroupDetail.confirm(options, through: feedback))
        for _ in 0..<1_000 where feedback.confirmRequest == nil { await Task.yield() }
        XCTAssertEqual(feedback.confirmRequest?.options.title, copy.transferOwner)
        XCTAssertTrue(transferred.isEmpty, "nothing is emitted before the user confirms")
        await feedback.accept()
        XCTAssertEqual(transferred, ["u2"])
        // Cancelling emits nothing.
        XCTAssertTrue(FlareGroupDetail.confirm(options, through: feedback))
        for _ in 0..<1_000 where feedback.confirmRequest == nil { await Task.yield() }
        feedback.cancel()
        XCTAssertEqual(transferred, ["u2"])
        // Without a host the view falls back to its system alert.
        XCTAssertFalse(FlareGroupDetail.confirm(options, through: nil))
    }

    @MainActor
    func testRemovingAMemberAndLeavingAreEmittedAsTapped() throws {
        let copy = FlareGroupDetailLabels().resolve(FlareStrings())
        var intents: [String] = []
        let detail = FlareGroupDetail(model: model(),
                                      onTransferOwner: { intents.append("transfer \($0)") },
                                      onRemoveMember: { intents.append("remove \($0)") },
                                      onLeave: { intents.append("leave") })
        let memberDialog = try AnyView(detail.memberActionButtons(for: bob)).inspect()
        // Transferring ownership asks first (no feedback host here: the view's own alert).
        try memberDialog.find(button: copy.transferOwner).tap()
        XCTAssertEqual(intents, [])
        // Removing is the host's to confirm: the tap is the intent.
        try memberDialog.find(button: copy.removeMember).tap()
        XCTAssertEqual(intents, ["remove u3"])
        // So is dissolving (the owner's footer action).
        try detail.inspect().find(button: copy.dissolve).tap()
        XCTAssertEqual(intents, ["remove u3", "leave"])
    }

    @MainActor
    func testGroupDetailBuildsWithTargetStateIntents() {
        var intents: [String] = []
        _ = FlareGroupDetail(model: model(),
                             onPromoteMember: { id, admin in intents.append("\(id) admin \(admin)") },
                             onMuteMember: { id, muted in intents.append("\(id) muted \(muted)") },
                             onRemoveMember: { intents.append("remove \($0)") }).body
        XCTAssertTrue(intents.isEmpty)
    }
}
