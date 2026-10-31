import XCTest
@testable import FlareIMUI

final class MemberRoleSheetTests: XCTestCase {
    private let every = FlareMemberActions(canRemove: true, canMute: true, canChangeRole: true, canTransferOwner: true)

    private func member(_ role: FlareGroupMemberRole, muted: Bool = false) -> FlareGroupMemberSnapshot {
        FlareGroupMemberSnapshot(id: "u-\(role.rawValue)", name: role.rawValue, role: role, muted: muted)
    }

    private func ids(_ role: FlareGroupMemberRole, _ actions: FlareMemberActions?, muted: Bool = false) -> [FlareMemberRoleAction] {
        memberRoleActions(role: role, muted: muted, actions: actions).map(\.action)
    }

    func testNothingTheHostDidNotAnswerForThisMember() {
        XCTAssertEqual(ids(.member, nil), [])
        XCTAssertEqual(ids(.member, .none), [])
        XCTAssertEqual(ids(.admin, FlareMemberActions(canRemove: false, canMute: false)), [])
    }

    func testNoRankRuleWhatTheHostAllowsIsWhatTheSheetOffers() {
        // The owner's protection and admins not managing each other come from the host's answer.
        XCTAssertEqual(ids(.admin, every), [.demote, .mute, .transferOwner, .remove])
        XCTAssertEqual(ids(.member, every), [.promote, .mute, .transferOwner, .remove])
    }

    func testPromoteForMemberDemoteForAdminNeitherForTheOwner() {
        let role = FlareMemberActions(canChangeRole: true)
        XCTAssertEqual(ids(.member, role), [.promote])
        XCTAssertEqual(ids(.admin, role), [.demote])
        XCTAssertEqual(ids(.owner, role), [])
    }

    func testMuteAndUnmuteAreExclusive() {
        let mute = FlareMemberActions(canMute: true)
        XCTAssertEqual(ids(.member, mute), [.mute])
        XCTAssertEqual(ids(.member, mute, muted: true), [.unmute])
    }

    func testEachAnswerRevealsExactlyItsAction() {
        XCTAssertEqual(ids(.member, FlareMemberActions(canRemove: true)), [.remove])
        XCTAssertEqual(ids(.member, FlareMemberActions(canTransferOwner: true)), [.transferOwner])
    }

    func testDangerGroupIsTransferThenRemoveAtTheEnd() {
        let entries = memberRoleActions(role: .member, muted: false, actions: every)
        XCTAssertEqual(entries.filter(\.danger).map(\.action), [.transferOwner, .remove])
        XCTAssertEqual(entries.last?.action, .remove)
    }

    func testMuteHiddenWithoutHostDurations() {
        let noDurations = MemberRoleSheetView(member: member(.member), actions: every, onAction: { _, _, _ in })
        XCTAssertFalse(noDurations.visibleEntries.map(\.action).contains(.mute))
        let withDurations = MemberRoleSheetView(member: member(.member), actions: every,
                                                muteDurations: [.init(id: "1h", label: "1 小时")],
                                                onAction: { _, _, _ in })
        XCTAssertTrue(withDurations.visibleEntries.map(\.action).contains(.mute))
    }

    func testEmptyReasonDistinguishesTheOwnerFromMissingRights() {
        XCTAssertEqual(MemberRoleSheetView(member: member(.owner)).emptyReason, "群主不可被管理")
        XCTAssertEqual(MemberRoleSheetView(member: member(.member)).emptyReason, "你没有管理权限")
        XCTAssertTrue(MemberRoleSheetView(member: member(.member)).visibleEntries.isEmpty)
    }

    func testLabelsFollowTextProps() {
        let view = MemberRoleSheetView(member: member(.member), actions: every, promoteText: "Make admin")
        XCTAssertEqual(view.labelFor(.promote), "Make admin")
        XCTAssertEqual(view.labelFor(.remove), "移出群聊")
        XCTAssertEqual(view.labelFor(.transferOwner), "转让群主")
    }
}
