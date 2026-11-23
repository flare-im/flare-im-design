import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// docs/plugin-experience.md §4, §11: the red packet page renderers (`redPacket.compose`, `redPacket.detail`) are
/// chosen by the manifest's renderer name, read the resolved view alone and fall back to the generic document when
/// anything is off; plus the §12 rows of the composer, the open sheet and the details.
final class RedPacketPageTests: XCTestCase {
    private let zh = FlareStrings()

    private func view(_ json: String) throws -> PluginViewModel {
        try JSONDecoder().decode(PluginViewModel.self, from: Data(json.utf8))
    }

    private func compose(actions: String = #"{"submit":"prepare","submitDirect":"prepareDirect"}"#,
                         props: String = #"{"maxRecipients":4}"#,
                         viewActions: String = #"[{"id":"prepare","label":"塞钱进红包","form":["kind","amount","shareCount","greeting","designatedUserIds"]}]"#,
                         kindChoices: String = #"[{"value":"normal","label":"普通"},{"value":"lucky","label":"拼手气"},{"value":"exclusive","label":"专属"}]"#,
                         currency: String = #""CNY""#,
                         renderer: String = "redPacket.compose",
                         extra: String = "") throws -> PluginViewModel {
        try view("""
        {"available":true,"title":"发红包","actions":\(viewActions),
         "presentation":{"renderer":"\(renderer)","props":\(props),"actions":\(actions)},
         "inputs":[
          {"id":"kind","kind":"select","label":"类型","required":true,"default":"normal","choices":\(kindChoices)},
          {"id":"amount","kind":"money","label":"金额","required":true,"money":{"currency":\(currency),"scale":2,"min":"0.01","max":"10.00"}},
          {"id":"shareCount","kind":"number","label":"份数","required":true,"min":1,"max":100,"default":1},
          {"id":"greeting","kind":"text","label":"祝福语","required":true,"maxLength":128,"default":"恭喜发财，大吉大利"},
          {"id":"designatedUserIds","kind":"members","label":"收件人","required":true,"min":1,"max":1,"showWhen":{"field":"kind","anyOf":["exclusive"]}}
         ]\(extra)}
        """)
    }

    private func detail(details: String = #"{"viewerRole":"claimer","status":"completed","kind":"lucky","greeting":"祝福","currency":"CNY","currencyExponent":2,"claimedCount":2,"shareCount":2,"createdAtMs":1000,"expiresAtMs":100000,"claimsListed":true,"myAmountMinor":"230","completedInMs":5000,"designatedUserIds":["u9"]}"#,
                        journal: String = "null") throws -> PluginViewModel {
        try view("""
        {"available":true,"title":"红包详情",
         "actions":[{"id":"claim","label":"领取红包"},{"id":"wallet","label":"查看钱包","target":{"kind":"page"}},
                    {"id":"cancel","label":"取消","style":"danger","confirm":"确定？"},{"id":"recovery","label":"待确认操作"}],
         "presentation":{"renderer":"redPacket.detail","actions":{"claim":"claim","wallet":"wallet"},"props":{
           "senderId":"s1","journal":\(journal),"details":\(details),
           "claims":[{"id":"u1","amountMinor":"230","claimedAtMs":2000,"best":true},{"id":"u2","amountMinor":"x","claimedAtMs":3000},
                     {"id":7,"amountMinor":"1","claimedAtMs":1}]}}}
        """)
    }

    // MARK: renderer mapping

    func testComposeRendererMapsTheBoundFormAndKinds() throws {
        let plan = try XCTUnwrap(FlareRedPacketPagePlan.compose(try compose()))
        XCTAssertEqual(plan.action.id, "prepare")
        XCTAssertEqual(plan.inputs.map(\.id), ["kind", "amount", "shareCount", "greeting", "designatedUserIds"])
        XCTAssertEqual(plan.kinds, [.normal, .lucky, .exclusive])
        XCTAssertEqual(plan.currency, "CNY")
        XCTAssertEqual(plan.scale, 2)
        XCTAssertEqual(plan.maxRecipients, 4)
        XCTAssertEqual(FlareRedPacketPagePlan.of(try compose())?.ownedActionIds, ["prepare"])
    }

    func testDirectChatSubmitsTheDirectActionWithOneOrdinaryKind() throws {
        let direct = try compose(actions: #"{"submitDirect":"prepareDirect"}"#,
                                 viewActions: #"[{"id":"prepareDirect","label":"塞钱进红包","form":["amount","greeting"]}]"#)
        let plan = try XCTUnwrap(FlareRedPacketPagePlan.compose(direct))
        XCTAssertEqual(plan.action.id, "prepareDirect")
        XCTAssertEqual(plan.kinds, [.normal])
    }

    func testComposeFallsBackToTheGenericDocument() throws {
        XCTAssertNil(FlareRedPacketPagePlan.of(try compose(renderer: "status.card")), "another renderer")
        XCTAssertNil(FlareRedPacketPagePlan.compose(try compose(actions: "{}")), "payments unavailable: no bound submit")
        XCTAssertNil(FlareRedPacketPagePlan.compose(try compose(props: #"{"journal":{"commandId":"c1","known":false}}"#)),
                     "an unknown outcome stays on the recovery path")
        XCTAssertNil(FlareRedPacketPagePlan.compose(try compose(
            viewActions: #"[{"id":"prepare","label":"x","confirm":"Sure?","form":["amount","greeting"]}]"#)), "a confirmation")
        XCTAssertNil(FlareRedPacketPagePlan.compose(try compose(
            viewActions: #"[{"id":"prepare","label":"x","form":["amount","greeting","missing"]}]"#)), "a form input the view lacks")
        XCTAssertNil(FlareRedPacketPagePlan.compose(try compose(
            kindChoices: #"[{"value":"normal","label":"普通"},{"value":"bonus","label":"?"}]"#)), "a kind the kit does not know")
        XCTAssertNil(FlareRedPacketPagePlan.compose(try compose(currency: #""""#)), "no currency")
        XCTAssertNil(FlareRedPacketPagePlan.compose(try compose(extra: #","unavailableReason":"unbound_copy""#)))
    }

    func testDetailRendererMapsDetailsClaimsAndBoundActions() throws {
        let plan = try XCTUnwrap(FlareRedPacketPagePlan.detail(try detail()))
        XCTAssertEqual(plan.details.viewerRole, .claimer)
        XCTAssertEqual(plan.details.myAmountMinor, "230")
        XCTAssertEqual(plan.details.completedAtMs, 6000)
        XCTAssertEqual(plan.claims.map(\.id), ["u1"], "rows without a string id or digit amount go")
        XCTAssertTrue(plan.claims[0].best)
        XCTAssertEqual(plan.senderId, "s1")
        XCTAssertEqual(plan.designatedUserIds, ["u9"])
        XCTAssertEqual(plan.claimAction?.id, "claim")
        XCTAssertEqual(plan.walletAction?.id, "wallet")
        XCTAssertFalse(plan.paidClaimPending)
        XCTAssertEqual(FlareRedPacketPagePlan.of(try detail())?.ownedActionIds, ["claim", "wallet"],
                       "cancel and recovery stay generic")
        let pending = try XCTUnwrap(FlareRedPacketPagePlan.detail(try detail(
            journal: #"{"known":false,"commandId":"c1","capabilityId":"flare.redpacket.ui.claim"}"#)))
        XCTAssertTrue(pending.paidClaimPending)
    }

    func testDetailFallsBackOnAnyWrongField() throws {
        XCTAssertNil(FlareRedPacketPagePlan.detail(try detail(details:
            #"{"viewerRole":"claimer","status":"open","kind":"normal","greeting":"g","currency":"CNY","currencyExponent":2,"claimedCount":0,"shareCount":1,"createdAtMs":1,"expiresAtMs":2,"claimsListed":false,"myAmountMinor":"not-money"}"#)))
        XCTAssertNil(FlareRedPacketPagePlan.detail(try detail(details:
            #"{"viewerRole":"boss","status":"open","kind":"normal","greeting":"g","currency":"CNY","currencyExponent":2,"claimedCount":0,"shareCount":1,"createdAtMs":1,"expiresAtMs":2,"claimsListed":false}"#)))
        XCTAssertNil(FlareRedPacketPagePlan.detail(try detail(details:
            #"{"viewerRole":"eligible","status":"open","kind":"normal","greeting":"g","currency":"CNY","currencyExponent":13,"claimedCount":0,"shareCount":1,"createdAtMs":1,"expiresAtMs":2,"claimsListed":false}"#)))
        XCTAssertNil(FlareRedPacketPagePlan.detail(try detail(details:
            #"{"viewerRole":"eligible","status":"open","kind":"normal","greeting":"g","currency":"CNY","currencyExponent":2,"claimedCount":0,"shareCount":1,"createdAtMs":1,"expiresAtMs":2}"#)),
                     "claimsListed missing")
    }

    @MainActor
    func testThePluginPageDrawsTheRedPacketPageOnlyForAResolvingRenderer() throws {
        let ref = PluginPageRef(pluginId: "any.plugin", page: "any.page")
        let page = try FlarePluginPage(page: ref, view: PluginPageViewModel(view: try compose()), onAction: { _, _ in }).inspect()
        XCTAssertNoThrow(try page.find(RedPacketPageView.self))
        let generic = try FlarePluginPage(page: ref, view: PluginPageViewModel(view: try compose(actions: "{}")),
                                          onAction: { _, _ in }).inspect()
        XCTAssertThrowsError(try generic.find(RedPacketPageView.self))
    }

    // MARK: compose page rules

    func testTotalsAndDraftFollowTheKind() throws {
        let plan = try XCTUnwrap(FlareRedPacketPagePlan.compose(try compose()))
        XCTAssertEqual(RedPacketPageView.totalMinor(plan, kind: .normal, amount: "6.00", count: 2), "1200")
        XCTAssertEqual(RedPacketPageView.totalMinor(plan, kind: .lucky, amount: "6.00", count: 2), "600")
        XCTAssertEqual(RedPacketPageView.totalMinor(plan, kind: .normal, amount: "6.00", count: 0), "0")
        XCTAssertEqual(RedPacketPageView.times("999999999999999999", 999), "998999999999999999001")
        let exclusive = RedPacketPageView.draft(plan, kind: .exclusive, amount: "1", count: 5, greeting: "  ", recipient: "u1")
        XCTAssertEqual(exclusive["shareCount"], .number(1))
        XCTAssertEqual(exclusive["greeting"], .string("恭喜发财，大吉大利"), "an empty greeting is the default")
    }

    func testSubmitHandsOverTheVisibleFormValues() throws {
        let plan = try XCTUnwrap(FlareRedPacketPagePlan.compose(try compose()))
        let draft = RedPacketPageView.draft(plan, kind: .normal, amount: "0.01", count: 2, greeting: "", recipient: nil)
        XCTAssertNil(RedPacketPageView.validate(plan, draft: draft, totalMinor: "2", strings: zh))
        XCTAssertEqual(PluginFormRules.values(plan.inputs, draft), [
            "kind": "normal", "amount": ["amount": "0.01", "currency": "CNY"], "shareCount": 2,
            "greeting": "恭喜发财，大吉大利",
        ])
    }

    func testValidationNamesTheWrongField() throws {
        let plan = try XCTUnwrap(FlareRedPacketPagePlan.compose(try compose()))
        func issue(kind: FlareRedPacketKind = .normal, amount: String = "0.01", count: Int = 2,
                   recipient: String? = nil) -> RedPacketPageView.Issue? {
            let draft = RedPacketPageView.draft(plan, kind: kind, amount: amount, count: count, greeting: "", recipient: recipient)
            return RedPacketPageView.validate(plan, draft: draft,
                                              totalMinor: RedPacketPageView.totalMinor(plan, kind: kind, amount: amount, count: count),
                                              strings: zh)
        }
        let limited = try XCTUnwrap(issue(count: 8))
        XCTAssertEqual(limited.field, .count, "over the plugin's live limit of 4")
        XCTAssertEqual(limited.text, "最多可发 4 个红包")
        XCTAssertEqual(issue(count: 0)?.field, .count)
        XCTAssertEqual(issue(kind: .exclusive)?.field, .recipient)
        XCTAssertEqual(issue(kind: .exclusive)?.text, "请选择发给谁", "§4.2, not the generic 收件人: 必填")
        XCTAssertNil(issue(kind: .exclusive, recipient: "u1"))
        XCTAssertEqual(issue(amount: "6.00", count: 2)?.field, .amount, "the total ¥12.00 is over ¥10.00")
        XCTAssertEqual(issue(amount: "6.00", count: 2)?.text, "总金额: 金额范围：0.01–10.00 CNY")
    }

    func testAGroupComposerShowsTheGroupSizeTheHostPassed() throws {
        let group = try XCTUnwrap(FlareRedPacketPagePlan.compose(try compose()))
        XCTAssertEqual(RedPacketPageView.memberCount(group, 12), 12, "the host's size, viewer included")
        XCTAssertNil(RedPacketPageView.memberCount(group, nil), "no size, no line")
        XCTAssertNil(RedPacketPageView.memberCount(group, 0), "no size, no line")
        let direct = try XCTUnwrap(FlareRedPacketPagePlan.compose(try compose(
            actions: #"{"submitDirect":"prepareDirect"}"#,
            viewActions: #"[{"id":"prepareDirect","label":"塞钱进红包","form":["amount","greeting"]}]"#)))
        XCTAssertNil(RedPacketPageView.memberCount(direct, 2), "a direct chat has no group size")
    }

    // MARK: review (the confirm page, §4.3)

    private func review(actions: String = #"{"submit":"commit"}"#,
                        props: String = #"{"amount":"8.88","currency":"CNY","kind":"lucky","shareCount":3,"blessing":"恭喜发财"}"#,
                        viewActions: String = #"[{"id":"commit","label":"发送红包"},{"id":"recovery","label":"查看待确认操作"}]"#,
                        renderer: String = "redPacket.review") throws -> PluginViewModel {
        try view("""
        {"available":true,"title":"发送已授权红包","actions":\(viewActions),
         "blocks":[{"kind":"note","text":"发送结果未知时请处理原操作，勿新建红包重复扣款。","tone":"warning"}],
         "presentation":{"renderer":"\(renderer)","props":\(props),"actions":\(actions)}}
        """)
    }

    func testReviewRendererMapsTheSendActionAndThePacket() throws {
        let plan = try XCTUnwrap(FlareRedPacketPagePlan.review(try review()))
        XCTAssertEqual(plan.action.id, "commit")
        XCTAssertEqual(plan.amount, "8.88")
        XCTAssertEqual(plan.currency, "CNY")
        XCTAssertEqual(plan.kind, .lucky)
        XCTAssertEqual(plan.shareCount, 3)
        XCTAssertEqual(plan.blessing, "恭喜发财")
        XCTAssertEqual(FlareRedPacketPagePlan.of(try review())?.ownedActionIds, ["commit"], "recovery stays generic")
        XCTAssertEqual(RedPacketPageView.reviewKindLabel(plan, zh), "拼手气红包 · 3 个")
        XCTAssertEqual(RedPacketPageView.notes(try review()).count, 1, "the warning stays above the review")
        let written = try XCTUnwrap(FlareRedPacketPagePlan.review(try review(
            props: #"{"amount":"¥8.88","kindLabel":"拼手气红包 · 3 个"}"#)))
        XCTAssertEqual(RedPacketPageView.reviewKindLabel(written, zh), "拼手气红包 · 3 个")
        XCTAssertNil(written.currency)
    }

    func testReviewFallsBackToTheGenericDocument() throws {
        XCTAssertNil(FlareRedPacketPagePlan.review(try review(actions: "{}")), "already sent: no bound send action")
        XCTAssertNil(FlareRedPacketPagePlan.review(try review(
            props: #"{"amount":"8.88","journal":{"commandId":"c1","known":false}}"#)), "an unknown outcome keeps recovery")
        XCTAssertNil(FlareRedPacketPagePlan.review(try review(
            viewActions: #"[{"id":"commit","label":"发送红包","confirm":"确定？"}]"#)), "a confirmation")
        XCTAssertNil(FlareRedPacketPagePlan.of(try review(renderer: "redPacket.card")))
    }

    @MainActor
    func testThePluginPageDrawsTheReviewAndRunsTheBoundSend() throws {
        var sent: [String] = []
        let ref = PluginPageRef(pluginId: "any.plugin", page: "any.page")
        let page = try FlarePluginPage(page: ref, view: PluginPageViewModel(view: try review()),
                                       onAction: { id, _ in sent.append(id) }).inspect()
        let shown = try page.find(RedPacketReviewView.self)
        try shown.find(ButtonView.self).find(ViewType.Button.self).tap()
        XCTAssertEqual(sent, ["commit"])
    }

    // MARK: component rows

    func testComposerPrimaryWaitsForAnAmountAndAFieldWithoutError() {
        typealias Composer = RedPacketComposerView<EmptyView>
        XCTAssertTrue(Composer.blocksSubmit(amount: "", exponent: 2, error: nil, errorField: nil))
        XCTAssertTrue(Composer.blocksSubmit(amount: "0.00", exponent: 2, error: nil, errorField: nil))
        XCTAssertFalse(Composer.blocksSubmit(amount: "0.01", exponent: 2, error: nil, errorField: nil))
        XCTAssertTrue(Composer.blocksSubmit(amount: "1", exponent: 2, error: "At most 100", errorField: .count))
        XCTAssertFalse(Composer.blocksSubmit(amount: "1", exponent: 2, error: "Network", errorField: .form),
                       "a service failure leaves the key for another try")
        XCTAssertEqual(Composer.greetingMaxLength, 24)
    }

    func testOpeningCannotBeDismissedAndTheBlessingKeepsToTwoLines() {
        XCTAssertFalse(RedPacketOpenSheet(senderName: "A", blessing: "b", state: .opening, onClose: {}).dismissible)
        XCTAssertTrue(RedPacketOpenSheet(senderName: "A", blessing: "b", state: .error, onClose: {}).dismissible)
        XCTAssertEqual(RedPacketOpenSheet.headlineLines(.ready), 2)
        XCTAssertEqual(RedPacketOpenSheet.headlineLines(.notEligible), 3)
        XCTAssertEqual(RedPacketMetrics.flipPeriod, 0.8)
    }
}
