import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// InviteCodeFieldView / MyInvitePanelView: what each state draws and what each control dispatches.
/// Timing (the debounced check) is asserted through the field's pure state and the shared table;
/// the debounce itself is a `Task.sleep` that an inspected tree cannot drive.
final class InviteViewsTests: XCTestCase {
    private let s = FlareStrings()
    private let invitees = [
        FlareInvitee(userId: "u1", displayName: "Ann", joinedAt: 1_790_000_000_000),
        FlareInvitee(userId: "u2", displayName: "Bob", joinedAt: 1_767_000_000_000),
    ]

    @MainActor
    func testOffModeRendersNothing() throws {
        let view = InviteCodeFieldView(text: .constant("AB12CD"), mode: .off)
        XCTAssertEqual(view.state, .off)
        XCTAssertThrowsError(try view.inspect().find(InputView.self))
        XCTAssertThrowsError(try view.inspect().find(text: s.inviteCodeLabel))
    }

    @MainActor
    func testOnlyRequiredModeShowsTheMark() throws {
        let optional = InviteCodeFieldView(text: .constant(""))
        XCTAssertNoThrow(try optional.inspect().find(text: s.inviteCodeLabel))
        XCTAssertThrowsError(try optional.inspect().find(text: s.inviteCodeOptional))
        XCTAssertThrowsError(try optional.inspect().find(text: "*"))
        let required = InviteCodeFieldView(text: .constant(""), mode: .required)
        XCTAssertThrowsError(try required.inspect().find(text: s.inviteCodeOptional))
        XCTAssertNoThrow(try required.inspect().find(text: "*"))
        XCTAssertEqual(required.state, .idle)
    }

    @MainActor
    func testWalksTheStateVector() throws {
        var view = InviteCodeFieldView(text: .constant("AB12CD"), checking: true)
        XCTAssertEqual(view.state, .checking)
        XCTAssertNoThrow(try view.inspect().find(text: s.inviteCodeChecking))

        view = InviteCodeFieldView(text: .constant("AB12CD"), checkResult: FlareInviteCodeCheckResult(valid: true, inviterDisplayName: "A**n"))
        XCTAssertEqual(view.state, .valid)
        XCTAssertNoThrow(try view.inspect().find(text: "邀请人：A**n"))

        view = InviteCodeFieldView(text: .constant("AB12CD"), checkResult: FlareInviteCodeCheckResult(valid: false))
        XCTAssertEqual(view.state, .invalid)
        XCTAssertNoThrow(try view.inspect().find(text: s.inviteCodeInvalid))

        view = InviteCodeFieldView(text: .constant("AB12CD"), checkResult: FlareInviteCodeCheckResult(valid: true, inviterDisplayName: "Ann"),
                                   error: "请填写邀请码后再提交")
        XCTAssertEqual(view.state, .invalid)
        XCTAssertNoThrow(try view.inspect().find(text: "请填写邀请码后再提交"))
        XCTAssertThrowsError(try view.inspect().find(text: "邀请人：Ann"))

        // A verdict for another code is not shown.
        view = InviteCodeFieldView(text: .constant("AB1"), checkResult: FlareInviteCodeCheckResult(valid: true, inviterDisplayName: "Ann"))
        XCTAssertThrowsError(try view.inspect().find(text: "邀请人：Ann"))
    }

    @MainActor
    func testPanelShowsQRAndCopiesOnlyTheCode() throws {
        let code = "ABCDEFGHJKMN"
        let link = "https://flare.example/r/123/\(code)"
        var events: [String] = []
        let view = MyInvitePanelView(code: code, shareURL: link, invitees: invitees,
                                     onCopy: { events.append("copy:\($0)") },
                                     onSelect: { events.append("select:\($0)") })
        XCTAssertNoThrow(try view.inspect().find(text: code))
        XCTAssertNoThrow(try view.inspect().find(viewWithAccessibilityLabel: s.myInviteQrHint))
        for label in [link, "邀请链接", "复制链接", s.myInviteShare, s.myInviteRegenerate] {
            XCTAssertThrowsError(try view.inspect().find(text: label), label)
        }
        try view.inspect().find(ViewType.Button.self, where: { (try? $0.find(text: s.myInviteCopy)) != nil }).tap()
        try view.inspect().find(ViewType.Button.self, where: { (try? $0.accessibilityLabel().string()) == "Bob" }).tap()
        XCTAssertEqual(events, ["copy:\(code)", "select:u2"])
    }

    @MainActor
    func testPanelCopiesTheCodeWithoutARegistrationQR() throws {
        var copied: [String] = []
        let view = MyInvitePanelView(code: "AB12CD", onCopy: { copied.append($0) })
        try view.inspect().find(ViewType.Button.self, where: { (try? $0.find(text: s.myInviteCopy)) != nil }).tap()
        XCTAssertEqual(copied, ["AB12CD"])
        XCTAssertThrowsError(try view.inspect().find(viewWithAccessibilityLabel: s.myInviteQrHint))
    }

    @MainActor
    func testPanelDepthRowsCountOnlyEmptyAndLoading() throws {
        let stats = FlareReferralStats(direct: 5, l2: 12, l3: 40, total: 57)
        let all = MyInvitePanelView(code: "AB12CD", stats: stats)
        for label in [s.myInviteDirect, s.myInviteLevel2, s.myInviteLevel3, s.myInviteTotal] {
            XCTAssertNoThrow(try all.inspect().find(text: label), label)
        }
        let one = MyInvitePanelView(code: "AB12CD", stats: stats, maxDepthShown: 1)
        XCTAssertThrowsError(try one.inspect().find(text: s.myInviteLevel2))
        XCTAssertNoThrow(try one.inspect().find(text: s.myInviteTotal))

        let countOnly = MyInvitePanelView(code: "AB12CD", stats: FlareReferralStats(direct: 9, l2: 0, l3: 0, total: 9),
                                          invitees: invitees, showProfiles: false)
        XCTAssertNoThrow(try countOnly.inspect().find(text: "9"))
        XCTAssertThrowsError(try countOnly.inspect().find(text: "Ann"))

        let loading = MyInvitePanelView(code: "", loading: true)
        XCTAssertThrowsError(try loading.inspect().find(text: s.myInviteEmpty))
        let empty = MyInvitePanelView(code: "AB12CD")
        XCTAssertNoThrow(try empty.inspect().find(text: s.myInviteEmpty))
    }

    @MainActor
    func testUnavailableCodeHidesActionsAndKeepsStatistics() throws {
        let view = MyInvitePanelView(code: "", shareURL: "https://flare.example/r/123/ABCDEFGHJKMN",
                                     stats: FlareReferralStats(direct: 7, l2: 0, l3: 0, total: 7),
                                     showProfiles: false, onCopy: { _ in })
        XCTAssertNoThrow(try view.inspect().find(text: s.myInviteCodeUnavailable))
        XCTAssertNoThrow(try view.inspect().find(text: s.myInviteStatsTitle))
        for label in [s.myInviteCopy, s.myInviteShare, s.myInviteRegenerate] {
            XCTAssertThrowsError(try view.inspect().find(text: label), label)
        }
        XCTAssertThrowsError(try view.inspect().find(viewWithAccessibilityLabel: s.myInviteQrHint))
    }

    @MainActor
    func testRelationshipTreeStartsCollapsedAndOnlyOffersAllowedBranches() throws {
        let parent = FlareInvitee(userId: "parent", displayName: "Ann", joinedAt: 0, hasChildren: true)
        let leaf = FlareInvitee(userId: "leaf", displayName: "Bob", joinedAt: 0)
        let load: (String, String?) async throws -> FlareInviteeBranchPage = { _, _ in
            XCTFail("The tree should not load a branch before it is expanded")
            return FlareInviteeBranchPage(invitees: [])
        }
        let view = MyInvitePanelView(code: "AB12CD", maxDepthShown: 2,
                                     invitees: [parent, leaf], onLoadChildren: load)
        XCTAssertNoThrow(try view.inspect().find(text: s.myInviteRelationships))
        for label in [s.myInviteInviterTitle, s.myInviteNoInviter, s.myInviteCurrentUser, s.myInviteInviteesTitle] {
            XCTAssertThrowsError(try view.inspect().find(text: label), label)
        }
        XCTAssertNoThrow(try view.inspect().find(viewWithAccessibilityLabel: "展开 Ann"))
        XCTAssertThrowsError(try view.inspect().find(viewWithAccessibilityLabel: "展开 Bob"))
        let oneLevel = MyInvitePanelView(code: "AB12CD", maxDepthShown: 1,
                                         invitees: [parent], onLoadChildren: load)
        XCTAssertThrowsError(try oneLevel.inspect().find(viewWithAccessibilityLabel: "展开 Ann"))
    }

    @MainActor
    func testLoadMoreOnlyWhileAnotherPageExists() throws {
        var events: [String] = []
        let none = MyInvitePanelView(code: "AB12CD", invitees: invitees, onLoadMore: { events.append("more") })
        XCTAssertThrowsError(try none.inspect().find(text: s.myInviteLoadMore))
        let more = MyInvitePanelView(code: "AB12CD", invitees: invitees, hasMore: true, onLoadMore: { events.append("more") })
        try more.inspect().find(ViewType.Button.self, where: { (try? $0.find(text: s.myInviteLoadMore)) != nil }).tap()
        XCTAssertEqual(events, ["more"])
    }

    /// ViewInspector cannot read `.environment` values, so the host override is asserted on the
    /// strings value the host applies, not on an inspected tree.
    func testHostOverrideCarriesTheInviteCopy() {
        let en = FlareStrings(inviteCodeLabel: "Invite code", myInviteTitle: "My invite")
        XCTAssertEqual(en.myInviteTitle, "My invite")
        XCTAssertEqual(en.inviteCodeLabel, "Invite code")
        XCTAssertEqual(en.myInviteEmpty, "还没有人通过你的邀请码加入", "untouched fields keep the kit default")
        XCTAssertEqual(FlareStrings().inviteCodeLabel, "邀请码")
    }
}
