import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// docs/plugin-experience.md §5 on the account appearance: the derived wallet (R12), offline (R8), no account (5.2),
/// record rows (5.8) and unmapped values (R3).
final class AccountExperienceTests: XCTestCase {
    private let page = PluginActionTarget(kind: "page")

    func testLedgerSignTellsMoneyInAndOutOnly() {
        XCTAssertEqual(FlareAccountView.ledgerKind("+¥88.88"), .income)
        XCTAssertEqual(FlareAccountView.ledgerKind(" -25.00"), .spend)
        XCTAssertEqual(FlareAccountView.ledgerKind("\u{2212}1.00"), .spend)
        XCTAssertEqual(FlareAccountView.ledgerKind("100.00"), .other)
        XCTAssertEqual(FlareAccountView.signedAmount("-¥52.00"), "\u{2212}¥52.00")
        XCTAssertEqual(FlareAccountView.signedAmount(" -1"), " \u{2212}1")
        XCTAssertEqual(FlareAccountView.signedAmount("+¥3.00"), "+¥3.00")
        XCTAssertEqual(FlareAccountView.signedAmount(""), "")
        XCTAssertEqual(FlareAccountView.signedAmount("2026-11-19"), "2026-11-19")
        XCTAssertEqual(FlareAccountView.signedAmount("-¥1.00 tx-01"), "\u{2212}¥1.00 tx-01")
    }

    func testStructuralWalletReadsAsTheWalletLayout() {
        let hero = PluginBlock.hero(.init(label: "可用余额", value: "¥1,000.00", amount: true, maskable: true))
        let stats = PluginBlock.stats(.init(items: [.init(label: "资金类型与币种", value: "CNY · cash")]))
        let note = PluginBlock.note(.init(text: "说明", tone: .info))
        let rows = PluginBlock.rows(.init(columns: [.init(label: "余额"), .init(label: "钱包")], rows: [],
                                          actions: [.init(id: "wallet", label: "查看明细", target: page)]))
        let create = PluginViewAction(id: "create", label: "开户", style: .primary, form: ["name"], target: .init(kind: "operation"))
        let actions = [create, PluginViewAction(id: "recharge", label: "充值", style: .primary, target: page),
                       PluginViewAction(id: "withdrawal", label: "提现", style: .primary, target: page)]
        let view = PluginViewModel(available: true, title: "钱包", actions: actions,
                                   blocks: [.section(.init(label: "余额钱包", blocks: [hero, stats, note])), rows])
        let account = flareAccountDocument(view)
        XCTAssertEqual(account.presentation?.props["layout"], .string("wallet"))
        XCTAssertEqual(account.presentation?.props["summaryTitle"], .string("余额钱包"))
        XCTAssertEqual(account.presentation?.props["rowEntryAction"], .string("wallet"))
        XCTAssertEqual(account.presentation?.actions, ["primary": "recharge", "secondary": "withdrawal"])
        XCTAssertEqual(account.fields.map(\.value), ["¥1,000.00", "CNY · cash"])
        XCTAssertEqual(account.blocks, [note, rows])
        XCTAssertEqual(flareAccountDocument(account), account)
        XCTAssertNil(flareAccountDocument(PluginViewModel(available: true, title: "", blocks: view.blocks + [rows])).presentation)
        XCTAssertEqual(FlareAccountView.setupAction(account.actions)?.id, "create")
        let openings = PluginViewAction(id: "openings", label: "开户进度", target: page)
        let payout = PluginViewAction(id: "payoutProfiles", label: "收款方式", target: page)
        XCTAssertEqual(FlareAccountView.setupProgress([payout, openings, create], create: create)?.id, "openings")
        XCTAssertEqual(FlareAccountView.setupProgress([create, openings], create: create)?.id, "openings")
        XCTAssertNil(FlareAccountView.setupProgress([openings, actions[1], create], create: create))
    }

    func testRowStatusesLeaveCompletedOutAndNeverPrintUnmappedValues() {
        let block = PluginRowsBlock(columns: [.init(label: "金额"), .init(label: "业务"), .init(label: "状态")], rows: [])
        let row = PluginRow(key: "a", cells: [.init(text: "100.00"), .init(text: "提现"), .init(text: "已完成", tone: .success)],
                            badge: .init(text: "待审核", tone: .warning))
        let separate = FlareAccountEntry(id: "a", block: block, row: row, separateBadge: true)
        XCTAssertEqual(separate.statuses, [PluginBadge(text: "待审核", tone: .warning)])
        XCTAssertEqual(separate.subtitle, "")
        let odd = PluginRow(key: "b", cells: [.init(text: "1.00"), .init(text: "raw", unmapped: true), .init(text: "零钱钱包")],
                            badge: .init(text: "prepared", unmapped: true))
        let legacy = FlareAccountEntry(id: "b", block: block, row: odd)
        XCTAssertTrue(legacy.titleUnmapped)
        XCTAssertEqual(legacy.statuses.map(\.unmapped), [true])
        XCTAssertEqual(legacy.subtitle, "零钱钱包")
        let wallet = FlareAccountEntry(id: "w", block: block, row: .init(key: "w", cells: [.init(text: "1.00"), .init(text: "零钱"), .init(text: "正常", tone: .success)]))
        XCTAssertEqual(wallet.walletFields.first?.tone, .success)
    }

    func testOnlyUnguardedActionsRunFromTheAccountKeysAndBannersLeadThePage() {
        XCTAssertTrue(FlareAccountView.direct(.init(id: "a", label: "a", target: page)))
        XCTAssertFalse(FlareAccountView.direct(.init(id: "b", label: "b", confirm: "确定？")))
        XCTAssertFalse(FlareAccountView.direct(.init(id: "c", label: "c", form: ["x"])))
        XCTAssertFalse(FlareAccountView.direct(.init(id: "d", label: "d", target: .init(kind: "native"))))
        let banner = PluginBlock.banner(.init(tone: .warning, text: "有资金操作等待确认", action: .init(id: "review", label: "查看", target: page)))
        let blank = PluginBlock.banner(.init(text: " "))
        for layout in ["wallet", "ledger", "flow"] {
            let view = PluginViewModel(available: true, title: "", blocks: [banner, blank],
                                       presentation: .init(renderer: "account", props: ["layout": .string(layout)], actions: [:]))
            XCTAssertEqual(flareAccountUrgentBlocks(view), [banner])
        }
    }

    @MainActor func testOfflineKeepsKeysDrawnButDisabled() throws {
        let row = PluginRow(key: "w", cells: [.init(text: "1.00"), .init(text: "零钱")])
        let model = PluginViewModel(available: true, title: "钱包", actions: [.init(id: "recharge", label: "充值", style: .primary, target: page)],
                                    blocks: [.rows(.init(columns: [.init(label: "余额"), .init(label: "钱包")], rows: [row]))],
                                    presentation: .init(renderer: "account", props: ["layout": "wallet"], actions: ["primary": "recharge"]))
        let tree = try FlareAccountView(view: model, offline: true, onAction: { _, _ in }).inspect()
        XCTAssertNoThrow(try tree.find(text: FlareStrings().pluginViewAvailableOnline))
        XCTAssertTrue(try tree.find(button: "充值").isDisabled())
        XCTAssertTrue(try tree.find(ViewType.Button.self, where: { try $0.labelView().find(text: "零钱").string() == "零钱" }).isDisabled())
    }

    @MainActor func testNoAccountShowsTheSetupStateWithoutBalanceOrTopUp() throws {
        let model = PluginViewModel(available: true, title: "钱包", fields: [.init(label: "可用余额", value: "900.00")],
                                    actions: [.init(id: "recharge", label: "充值", style: .primary, target: page),
                                              .init(id: "openings", label: "开户进度", target: page),
                                              .init(id: "create", label: "开户", style: .primary, form: ["name"])],
                                    blocks: [.rows(.init(columns: [.init(label: "余额"), .init(label: "钱包")], rows: []))],
                                    inputs: [.init(id: "name", kind: .text, label: "名称")],
                                    presentation: .init(renderer: "account", props: ["layout": "wallet"], actions: ["primary": "recharge"]))
        let tree = try FlareAccountView(view: model, onAction: { _, _ in }).inspect()
        XCTAssertNoThrow(try tree.find(text: FlareStrings().walletSetupTitle))
        XCTAssertNoThrow(try tree.find(button: "开户"))
        XCTAssertNoThrow(try tree.find(button: "开户进度"))
        XCTAssertThrowsError(try tree.find(text: "900.00"))
        XCTAssertThrowsError(try tree.find(button: "充值"))
    }
}
