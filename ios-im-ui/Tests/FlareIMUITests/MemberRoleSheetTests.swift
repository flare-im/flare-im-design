import XCTest
@testable import FlareIMUI

final class MemberRoleSheetTests: XCTestCase {
    private let all = FlareMemberRoleCapabilities(promote: true, demote: true, mute: true,
                                                  unmute: true, remove: true, transferOwner: true)

    private func member(_ role: FlareGroupMemberRole, muted: Bool = false) -> FlareGroupMemberSnapshot {
        FlareGroupMemberSnapshot(id: "u-\(role.rawValue)", name: role.rawValue, role: role, muted: muted)
    }

    private func ids(_ m: FlareGroupMemberSnapshot, _ viewer: FlareGroupMemberRole,
                     _ caps: FlareMemberRoleCapabilities? = nil) -> [FlareMemberRoleAction] {
        memberRoleActions(m, viewerRole: viewer, capabilities: caps ?? all).map(\.action)
    }

    func testOwnerIsUntouchableForEveryViewer() {
        for viewer in FlareGroupMemberRole.allCases {
            XCTAssertEqual(ids(member(.owner), viewer), [])
            XCTAssertEqual(ids(member(.owner, muted: true), viewer), [])
        }
    }

    func testPlainMemberSeesNothing() {
        XCTAssertEqual(ids(member(.member), .member), [])
        XCTAssertEqual(ids(member(.admin), .member), [])
    }

    func testAdminStopsAtPeerAdminAndCannotTransfer() {
        XCTAssertEqual(ids(member(.admin), .admin), [])
        XCTAssertEqual(ids(member(.member), .admin), [.promote, .mute, .remove])
        XCTAssertFalse(ids(member(.member), .admin).contains(.transferOwner))
    }

    func testOwnerManagesMembersAndAdmins() {
        XCTAssertEqual(ids(member(.member), .owner), [.promote, .mute, .transferOwner, .remove])
        XCTAssertEqual(ids(member(.admin), .owner), [.demote, .mute, .transferOwner, .remove])
    }

    func testPromoteForMemberDemoteForAdmin() {
        let caps = FlareMemberRoleCapabilities(promote: true, demote: true)
        XCTAssertEqual(ids(member(.member), .owner, caps), [.promote])
        XCTAssertEqual(ids(member(.admin), .owner, caps), [.demote])
    }

    func testMuteAndUnmuteAreExclusive() {
        let caps = FlareMemberRoleCapabilities(mute: true, unmute: true)
        XCTAssertEqual(ids(member(.member), .owner, caps), [.mute])
        XCTAssertEqual(ids(member(.member, muted: true), .owner, caps), [.unmute])
    }

    func testNothingWithoutCapabilities() {
        XCTAssertEqual(ids(member(.member), .owner, .init()), [])
        XCTAssertEqual(ids(member(.member), .owner, .init(remove: true)), [.remove])
        XCTAssertEqual(ids(member(.member), .owner, .init(transferOwner: true)), [.transferOwner])
    }

    func testDangerGroupIsTransferThenRemoveAtTheEnd() {
        let entries = memberRoleActions(member(.member), viewerRole: .owner, capabilities: all)
        XCTAssertEqual(entries.filter(\.danger).map(\.action), [.transferOwner, .remove])
        XCTAssertEqual(entries.last?.action, .remove)
    }

    func testMuteHiddenWithoutHostDurations() {
        let noDurations = MemberRoleSheetView(member: member(.member), viewerRole: .owner,
                                              capabilities: all, onAction: { _, _, _ in })
        XCTAssertFalse(noDurations.visibleEntries.map(\.action).contains(.mute))
        let withDurations = MemberRoleSheetView(member: member(.member), viewerRole: .owner,
                                                capabilities: all,
                                                muteDurations: [.init(id: "1h", label: "1 小时")],
                                                onAction: { _, _, _ in })
        XCTAssertTrue(withDurations.visibleEntries.map(\.action).contains(.mute))
    }

    func testEmptyReasonDistinguishesRankFromPermission() {
        XCTAssertEqual(MemberRoleSheetView(member: member(.owner), viewerRole: .owner).emptyReason,
                       "群主不可被管理")
        XCTAssertEqual(MemberRoleSheetView(member: member(.member), viewerRole: .member).emptyReason,
                       "你没有管理权限")
    }

    func testLabelsFollowTextProps() {
        let view = MemberRoleSheetView(member: member(.member), viewerRole: .owner,
                                       capabilities: all, promoteText: "Make admin")
        XCTAssertEqual(view.labelFor(.promote), "Make admin")
        XCTAssertEqual(view.labelFor(.remove), "移出群聊")
        XCTAssertEqual(view.labelFor(.transferOwner), "转让群主")
    }
}
