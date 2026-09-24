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
    func testOptionalShowsTheHintAndRequiredTheMark() throws {
        let optional = InviteCodeFieldView(text: .constant(""))
        XCTAssertNoThrow(try optional.inspect().find(text: s.inviteCodeOptional))
        let required = InviteCodeFieldView(text: .constant(""), mode: .required)
        XCTAssertThrowsError(try required.inspect().find(text: s.inviteCodeOptional))
        XCTAssertNoThrow(try required.inspect().find(text: s.inviteCodeLabel))
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
    func testPanelShowsCodeLinkAndDispatchesCopyShareSelect() throws {
        var events: [String] = []
        let view = MyInvitePanelView(code: "AB12CD", shareURL: "https://flare.example/r/t1/AB12CD", invitees: invitees,
                                     onCopy: { events.append("copy:\($0)") }, onShare: { events.append("share:\($0)") },
                                     onSelect: { events.append("select:\($0)") })
        XCTAssertNoThrow(try view.inspect().find(text: "AB12CD"))
        XCTAssertNoThrow(try view.inspect().find(text: "https://flare.example/r/t1/AB12CD"))
        try view.inspect().find(ViewType.Button.self, where: { (try? $0.find(text: s.myInviteCopy)) != nil }).tap()
        try view.inspect().find(ViewType.Button.self, where: { (try? $0.find(text: s.myInviteShare)) != nil }).tap()
        try view.inspect().find(ViewType.Button.self, where: { (try? $0.accessibilityLabel().string()) == "Bob" }).tap()
        XCTAssertEqual(events, ["copy:AB12CD", "share:https://flare.example/r/t1/AB12CD", "select:u2"])
    }

    @MainActor
    func testPanelSharesTheCodeWhenThereIsNoLink() throws {
        var shared: [String] = []
        let view = MyInvitePanelView(code: "AB12CD", onShare: { shared.append($0) })
        try view.inspect().find(ViewType.Button.self, where: { (try? $0.find(text: s.myInviteShare)) != nil }).tap()
        XCTAssertEqual(shared, ["AB12CD"])
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
        XCTAssertNoThrow(try countOnly.inspect().find(text: "9 人"))
        XCTAssertThrowsError(try countOnly.inspect().find(text: "Ann"))

        let loading = MyInvitePanelView(code: "", loading: true)
        XCTAssertThrowsError(try loading.inspect().find(text: s.myInviteEmpty))
        let empty = MyInvitePanelView(code: "AB12CD")
        XCTAssertNoThrow(try empty.inspect().find(text: s.myInviteEmpty))
    }

    @MainActor
    func testRegenerateOfferedOnlyWhenAllowedAndExplainedWhileCooling() throws {
        let hidden = MyInvitePanelView(code: "AB12CD")
        XCTAssertThrowsError(try hidden.inspect().find(text: s.myInviteRegenerate))
        let soon = Int64(Date().timeIntervalSince1970 * 1000) + 15 * 60 * 1000
        let cooling = MyInvitePanelView(code: "AB12CD", canRegenerate: true, regenerateAvailableAt: soon)
        XCTAssertNoThrow(try cooling.inspect().find(text: "15 分钟 后可重新生成"))
        var events: [String] = []
        let ready = MyInvitePanelView(code: "AB12CD", canRegenerate: true, onRegenerate: { events.append("regenerate") })
        XCTAssertThrowsError(try ready.inspect().find(text: "15 分钟 后可重新生成"))
        try ready.inspect().find(ViewType.Button.self, where: { (try? $0.find(text: s.myInviteRegenerate)) != nil }).tap()
        XCTAssertEqual(events, ["regenerate"])
        let busy = MyInvitePanelView(code: "AB12CD", canRegenerate: true, regenerating: true)
        XCTAssertNoThrow(try busy.inspect().find(text: s.myInviteRegenerating))
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
