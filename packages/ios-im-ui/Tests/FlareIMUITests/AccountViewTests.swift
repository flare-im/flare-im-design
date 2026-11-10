import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

final class AccountViewTests: XCTestCase {
    func testLegacyNoLayoutRetainsOriginalNoteOnlyIncludingBlankNotes() {
        let note = PluginBlock.note(.init(text: "Original recovery note", tone: .warning))
        let blank = PluginBlock.note(.init(text: " \n ", tone: .warning))
        let status = PluginBlock.status(.init(text: "Original status stays in information", tone: .danger))
        let view = PluginViewModel(available: true, title: "Legacy", fields: [.init(label: "Balance", value: "1000.00")], blocks: [status, note, blank])
        XCTAssertEqual(flareAccountUrgentBlocks(view), [note, blank])
        XCTAssertEqual(view.blocks.filter { !flareAccountUrgentBlocks(view).contains($0) }, [status])
    }

    func testSharedLayoutFixturesKeepUrgentTextAndOpaqueRows() throws {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let table = try JSONDecoder().decode(PluginJSONValue.self, from: Data(contentsOf: root.appendingPathComponent("spec/account-layout-vectors.json")))
        let cases = try XCTUnwrap(table["cases"]?.arrayValue)
        XCTAssertEqual(cases.count, 6)
        func text(_ block: PluginBlock) -> String {
            switch block { case .status(let status): return status.text; case .note(let note): return note.text; default: return "" }
        }
        for fixture in cases {
            let view = try JSONDecoder().decode(PluginViewModel.self, from: JSONEncoder().encode(try XCTUnwrap(fixture["view"])))
            let expected = try XCTUnwrap(fixture["expected"])
            let expectedUrgent = expected["urgentTexts"]?.arrayValue?.compactMap(\.stringValue) ?? []
            if fixture["layout"]?.stringValue == "flow" {
                XCTAssertEqual(view.blocks.map(text).filter { expectedUrgent.contains($0) }, expectedUrgent)
            } else {
                let urgent = flareAccountUrgentBlocks(view)
                XCTAssertEqual(urgent.map(text), expectedUrgent)
                let information = view.blocks.filter { block in
                    if case .rows = block { return false }; return !urgent.contains(block)
                }.map(text).filter { !$0.isEmpty }
                XCTAssertTrue((expected["informationTexts"]?.arrayValue?.compactMap(\.stringValue) ?? []).allSatisfy { information.contains($0) })
                XCTAssertTrue(urgent.map(text).allSatisfy { !information.contains($0) })
            }
            let entries = FlareAccountEntry.entries(view)
            XCTAssertEqual(entries.map { $0.row.key }, expected["uniqueRowKeys"]?.arrayValue?.compactMap(\.stringValue))
            for entry in entries { XCTAssertEqual(entry.row.actions, entry.block.rows.first { $0.key == entry.row.key }?.actions) }
        }
    }
    func testResponsiveColumnsAndOptionalFiniteWidth() {
        for (width, count) in [(CGFloat(288),1),(358,1),(571,1),(572,2),(736,2),(848,2),(2000,2)] {
            XCTAssertEqual(flareAccountWalletColumnCount(width: width, count: 3), count)
            XCTAssertEqual(flareAccountWalletColumnCount(width: width, count: 1), 1)
        }
        for width in [CGFloat?]([nil,0,-1,.nan,.infinity]) { XCTAssertNil(flareContentMaxWidth(width)) }
        XCTAssertEqual(flareContentMaxWidth(880),880)
    }

    func testPayoutKindFixturesKeepDynamicChoicesAndHistoricalManagement() throws {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let table = try JSONDecoder().decode(PluginJSONValue.self, from: Data(contentsOf: root.appendingPathComponent("spec/wallet-payout-kind-vectors.json")))
        let fixtures = try XCTUnwrap(table["cases"]?.arrayValue)
        XCTAssertEqual(fixtures.count, 6)
        for fixture in fixtures {
            let raw = try XCTUnwrap(fixture["view"])
            let view = try JSONDecoder().decode(PluginViewModel.self, from: JSONEncoder().encode(raw))
            let kind = try XCTUnwrap(view.inputs.first { $0.id == "kind" })
            let variant = fixture["variant"]?.stringValue
            let expected = variant == "all4" ? ["bankCard", "alipay", "wechat", "address"] : variant == "alipay_only" ? ["alipay"] : []
            XCTAssertEqual(kind.choices?.map(\.value) ?? [], expected)
            XCTAssertNil(kind.defaultValue)
            XCTAssertEqual(PluginFormRules.draft(view.inputs, values: nil)["kind"], .string(""))
            let english = fixture["locale"]?.stringValue == "en-US"
            let labels = english ? ["bankCard":"Bank card", "alipay":"Alipay", "wechat":"WeChat", "address":"Payout address"] : ["bankCard":"银行卡", "alipay":"支付宝", "wechat":"微信", "address":"收款地址"]
            XCTAssertEqual(kind.choices?.map(\.label) ?? [], expected.map { labels[$0]! })
            let row = try XCTUnwrap(FlareAccountEntry.entries(view).first?.row)
            XCTAssertEqual(row.key, "fixture-existing-bank")
            XCTAssertEqual(Set(row.actions.map(\.id)), Set(["default", "remove"]))
            for action in row.actions {
                XCTAssertEqual(action.input["id"], .string("fixture-existing-bank"))
                XCTAssertEqual(action.input["expectedRevision"], .string("1"))
            }
            if variant == "empty" {
                XCTAssertTrue(FlareAccountPresentation(view).primary.isEmpty)
                XCTAssertTrue(view.blocks.contains { if case .status(let status) = $0 { return status.tone == .warning && !status.text.isEmpty }; return false })
                XCTAssertNil(FlareAccountFlowResult(view), "declared warning suppresses duplicate unavailable notice")
            } else {
                XCTAssertEqual(FlareAccountPresentation(view).primary.map(\.id), ["save"])
            }
        }
    }
    func testUnavailableFormNoticeRequiresDeclaredFormAndNoVisiblePrimaryOrResult() {
        let props: [String: PluginJSONValue] = ["layout": .string("flow"), "formTitle": .string("Apply"), "formUnavailableDescription": .string("Applications are unavailable; existing records remain available."), "resultTone": .string("success")]
        func model(_ props: [String: PluginJSONValue], actions: [PluginViewAction] = [], slots: [String: String] = [:], blocks: [PluginBlock] = []) -> PluginViewModel {
            .init(available: true, title: "Flow", actions: actions, blocks: blocks, presentation: .init(renderer: "account", props: props, actions: slots))
        }
        XCTAssertEqual(FlareAccountFlowResult(model(props))?.text, props["formUnavailableDescription"]?.stringValue)
        XCTAssertEqual(FlareAccountFlowResult(model(props))?.tone, .neutral)
        var wallet = props; wallet["layout"] = .string("wallet")
        var blank = props; blank["formTitle"] = .string(" \n ")
        var missing = props; missing.removeValue(forKey: "formTitle")
        var noMessage = props; noMessage.removeValue(forKey: "formUnavailableDescription")
        for candidate in [wallet, blank, missing, noMessage] { XCTAssertNil(FlareAccountFlowResult(model(candidate))) }
        var result = props; result["resultDescription"] = .string("Review the original request."); result["resultTone"] = .string("warning")
        XCTAssertEqual(FlareAccountFlowResult(model(result))?.text, "Review the original request.")
        XCTAssertEqual(FlareAccountFlowResult(model(result))?.tone, .warning)
        result.removeValue(forKey: "formTitle")
        XCTAssertEqual(FlareAccountFlowResult(model(result))?.text, "Review the original request.")
        for action in [PluginViewAction(id: "protected", label: "Verify", style: .primary, form: ["password"]), PluginViewAction(id: "protected", label: "Confirm", style: .primary, confirm: "Confirm original request")] {
            XCTAssertNil(FlareAccountFlowResult(model(props, actions: [action])))
        }
        XCTAssertNil(FlareAccountFlowResult(model(props, actions: [.init(id: "continue", label: "Continue")], slots: ["submit": "continue"])))
        for tone in [PluginTone.warning, .danger] {
            let blocks: [PluginBlock] = [.status(.init(text: "Review the channel", tone: tone))]
            XCTAssertNil(FlareAccountFlowResult(model(props, blocks: blocks)))
            XCTAssertEqual(FlareAccountFlowResult(model(result, blocks: blocks))?.text, "Review the original request.")
        }
        let nonsuppressing: [PluginBlock] = [
            .status(.init(label: "Status", text: " \n ", tone: .warning)),
            .status(.init(text: "For information", tone: .info)),
            .status(.init(text: "Account information", tone: .neutral)),
            .status(.init(text: "Recorded", tone: .success)),
            .note(.init(text: "Informational note", tone: .info)),
            .note(.init(text: "Warning note", tone: .warning)),
            .note(.init(text: "Danger note", tone: .danger)),
        ]
        for block in nonsuppressing {
            XCTAssertEqual(FlareAccountFlowResult(model(props, blocks: [block]))?.text, props["formUnavailableDescription"]?.stringValue)
        }
    }
    func testInlineFormMetadataIsOptionalAndBlankKeepsTheExistingLayout() {
        XCTAssertNil(PluginView.inlineHeading(nil))
        XCTAssertNil(PluginView.inlineHeading(""))
        XCTAssertNil(PluginView.inlineHeading(" \n\t "))
        XCTAssertEqual(PluginView.inlineHeading(" Add account\n"), "Add account")
    }
    func testFlowResultUsesOnlyDeclaredTextAndSemanticTone() {
        let base = PluginViewModel(available: true, title: "Receipt", fields: [.init(label: "Status", value: "completed")])
        XCTAssertNil(FlareAccountFlowResult(base))
        for tone in ["success", "warning", "danger", "info", "neutral"] {
            let view = PluginViewModel(available: true, title: "Receipt", presentation: .init(renderer: "account", props: [
                "resultTitle": .string("Review pending"), "resultDescription": .string("Submission does not mean funds arrived."), "resultTone": .string(tone)], actions: [:]))
            XCTAssertEqual(FlareAccountFlowResult(view)?.text, "Review pending\nSubmission does not mean funds arrived.")
            XCTAssertEqual(FlareAccountFlowResult(view)?.tone.rawValue, tone)
        }
        let titleOnly = PluginViewModel(available: true, title: "Receipt", presentation: .init(renderer: "account", props: [
            "resultTitle": .string("Original request"), "resultDescription": .string(""), "resultTone": .string("invalid")], actions: [:]))
        XCTAssertEqual(FlareAccountFlowResult(titleOnly)?.text, "Original request")
        XCTAssertEqual(FlareAccountFlowResult(titleOnly)?.tone, .neutral)
        let descriptionOnly = PluginViewModel(available: true, title: "Receipt", presentation: .init(renderer: "account", props: [
            "resultTitle": .string(""), "resultDescription": .string("Use the original request.")], actions: [:]))
        XCTAssertEqual(FlareAccountFlowResult(descriptionOnly)?.text, "Use the original request.")
        XCTAssertEqual(FlareAccountFlowResult(descriptionOnly)?.tone, .neutral)
        let toneOnly = PluginViewModel(available: true, title: "Receipt", presentation: .init(renderer: "account", props: ["resultTone": .string("success")], actions: [:]))
        XCTAssertNil(FlareAccountFlowResult(toneOnly))
    }
    @MainActor func testFlowInlineHeadingFollowsRowsAndKeepsOriginalPayload() throws {
        let amount = "12345678901234567890.4500"
        let action = PluginViewAction(id: "save", label: "Save account", form: ["amount"])
        let row = PluginRow(key: "profile", cells: [.init(text: "Existing account")])
        let block = PluginRowsBlock(columns: [.init(label: "Account")], rows: [row])
        let model = PluginViewModel(available: true, title: "Accounts", fields: [.init(label: "Receipt", value: "Unchanged")], actions: [action], blocks: [.rows(block)],
            inputs: [.init(id: "amount", kind: .text, label: "Exact amount", defaultValue: .string(amount))],
            presentation: .init(renderer: "account", props: ["layout": .string("flow"), "sectionTitle": .string("Existing accounts"), "formTitle": .string("Add an account"), "formDescription": .string("Enter the original details.")], actions: ["submit":"save"]))
        var sent: [PluginActionPayload] = []
        let tree = try FlareAccountView(view: model, onAction: { _, payload in sent.append(payload) }).inspect()
        let text = tree.findAll(ViewType.Text.self).compactMap { try? $0.string() }
        XCTAssertLessThan(try XCTUnwrap(text.firstIndex(of: "Existing account")), try XCTUnwrap(text.firstIndex(of: "Add an account")))
        XCTAssertLessThan(try XCTUnwrap(text.firstIndex(of: "Add an account")), try XCTUnwrap(text.firstIndex(of: "Exact amount")))
        XCTAssertEqual(text.filter { $0 == "Existing accounts" }.count, 1)
        XCTAssertEqual(text.filter { $0 == "Add an account" }.count, 1)
        XCTAssertTrue(sent.isEmpty)
        try tree.find(button: "Save account").tap()
        XCTAssertEqual(sent.first?.formValues, ["amount": .string(amount)])
        let protected = PluginViewModel(available: true, title: "", actions: [.init(id: "save", label: "Save account", confirm: "Confirm", form: ["amount"])], inputs: model.inputs)
        let protectedTree = try PluginView(view: protected, embedded: true, inlineFormActionId: "save", inlineFormTitle: "Add an account", inlineFormDescription: "Enter the original details.", onAction: { _, _ in }).inspect()
        XCTAssertThrowsError(try protectedTree.find(text: "Add an account"))
    }
    func testScopedHistoryKeepsServerWalletContextAndDetailBinding() throws {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let table = try JSONDecoder().decode(PluginJSONValue.self, from: Data(contentsOf: root.appendingPathComponent("spec/wallet-scoped-history-vectors.json")))
        let fixtures = try XCTUnwrap(table["cases"]?.arrayValue)
        XCTAssertEqual(fixtures.count, 4)
        for fixture in fixtures {
            let view = try PluginVectors.decode(PluginViewModel.self, fixture["view"])
            XCTAssertEqual(view.presentation?.props["contextLabel"], fixture["sourceData"]?["walletContext"])
            XCTAssertTrue(view.fields.isEmpty)
            for entry in FlareAccountEntry.entries(view) {
                let action = try XCTUnwrap(FlareAccountView.entryAction(view, entry: entry, busy: false, handled: true))
                XCTAssertEqual(action.input["walletId"], fixture["arguments"]?["walletId"])
                XCTAssertEqual(action.input, entry.row.actions.first?.input)
            }
        }
    }
    func testWalletShortcutSlotsKeepDeclaredActionsWithoutDuplicatingServices() {
        let primary = PluginViewAction(id: "send", label: "Continue")
        let history = PluginViewAction(id: "ledger", label: "All entries")
        let deposits = PluginViewAction(id: "credits", label: "Incoming")
        let withdrawals = PluginViewAction(id: "debits", label: "Outgoing")
        let security = PluginViewAction(id: "security", label: "Security")
        let slots = ["primary": "send", "shortcutPrimary": "ledger", "shortcutSecondary": "credits", "shortcutTertiary": "debits"]
        let view = PluginViewModel(available: true, title: "Account", actions: [primary, history, deposits, security], menuActions: [withdrawals], presentation: .init(renderer: "account", props: ["layout": .string("wallet")], actions: slots))
        XCTAssertEqual(FlareAccountPresentation(view).primary, [primary])
        XCTAssertEqual(FlareAccountPresentation(view).shortcuts, [history, deposits, withdrawals])
        XCTAssertEqual(FlareAccountPresentation(view).services, [security])
        let unresolved = PluginViewModel(available: true, title: "Account", actions: view.actions, menuActions: view.menuActions, presentation: .init(renderer: "account", props: ["layout": .string("wallet")], actions: ["primary": "send", "shortcutPrimary": "send", "shortcutSecondary": "missing", "shortcutTertiary": "ledger"]))
        XCTAssertEqual(FlareAccountPresentation(unresolved).shortcuts, [history])
        XCTAssertEqual(FlareAccountPresentation(unresolved).services, [deposits, security, withdrawals])
        let readOnly = PluginViewModel(available: true, title: "Account", actions: view.actions, menuActions: view.menuActions, unavailableReason: .unboundCopy, presentation: view.presentation)
        XCTAssertTrue(FlareAccountPresentation(readOnly).shortcuts.isEmpty)
    }
    @MainActor func testWalletCardDirectNavigationKeepsOpaqueWalletInputAndBusyFooter() throws {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let table = try JSONDecoder().decode(PluginJSONValue.self, from: Data(contentsOf: root.appendingPathComponent("spec/wallet-card-vectors.json")))
        let original = try PluginVectors.decode(PluginViewModel.self, table["cases"]?[0]?["view"])
        let id = try XCTUnwrap(FlareAccountEntry.entries(original).first?.row.actions.first?.id)
        let model = PluginViewModel(available: true, title: original.title, fields: original.fields, blocks: original.blocks,
            presentation: .init(renderer: "account", props: ["layout": .string("wallet"), "rowEntryAction": .string(id)], actions: [:]))
        let entries = FlareAccountEntry.entries(model)
        XCTAssertEqual(entries.map { FlareAccountView.entryAction(model, entry: $0, busy: false, handled: true)?.input["walletId"]?.stringValue }, ["wallet-cny-fixture", "wallet-usd-fixture"])
        let entry = try XCTUnwrap(entries.last)
        XCTAssertNil(FlareAccountView.entryAction(model, entry: entry, busy: true, handled: true))
        XCTAssertNil(FlareAccountView.entryAction(model, entry: entry, busy: false, handled: false))
        let unavailable = PluginViewModel(available: false, title: "Account", blocks: original.blocks, presentation: model.presentation)
        XCTAssertNil(FlareAccountView.entryAction(unavailable, entry: entry, busy: false, handled: true))
        let readOnly = PluginViewModel(available: true, title: "Account", blocks: original.blocks, unavailableReason: .unboundCopy, presentation: model.presentation)
        XCTAssertNil(FlareAccountView.entryAction(readOnly, entry: entry, busy: false, handled: true))
        let unbound = FlareAccountEntry(id: entry.id, block: entry.block, row: .init(key: entry.row.key, cells: entry.row.cells))
        XCTAssertNil(FlareAccountView.entryAction(model, entry: unbound, busy: false, handled: true))
        let undeclared = FlareAccountEntry(id: entry.id, block: .init(columns: entry.block.columns, rows: [entry.row]), row: entry.row)
        XCTAssertNil(FlareAccountView.entryAction(model, entry: undeclared, busy: false, handled: true))
        let guarded = FlareAccountEntry(id: entry.id, block: .init(columns: entry.block.columns, rows: [entry.row], actions: [.init(id: id, label: "Guarded", confirm: "Confirm")]), row: entry.row)
        XCTAssertNil(FlareAccountView.entryAction(model, entry: guarded, busy: false, handled: true))
        let form = FlareAccountEntry(id: entry.id, block: .init(columns: entry.block.columns, rows: [entry.row], actions: [.init(id: id, label: "Guarded", form: ["amount"])]), row: entry.row)
        XCTAssertNil(FlareAccountView.entryAction(model, entry: form, busy: false, handled: true))
        var sent: [PluginActionPayload] = []
        let tree = try FlareAccountView(view: model, onAction: { _, payload in sent.append(payload) }).inspect()
        try tree.find(ViewType.Button.self, where: { try $0.labelView().find(text: "旅行钱包").string() == "旅行钱包" }).tap()
        XCTAssertEqual(sent.first?.row, PluginRowRef(key: "wallet-usd-fixture", input: ["walletId": .string("wallet-usd-fixture")]))
        let busy = try FlareAccountView(view: model, busyActionId: "other", onAction: { _, _ in }).inspect()
        XCTAssertTrue(try busy.find(ViewType.Button.self, where: { try $0.labelView().find(text: "旅行钱包").string() == "旅行钱包" }).isDisabled())
        let label = try XCTUnwrap(FlareAccountView.entryAction(model, entry: entry, busy: false, handled: true)?.action.label)
        let idleLabels = tree.findAll(ViewType.Text.self).compactMap { try? $0.string() }.filter { $0 == label }.count
        let busyLabels = busy.findAll(ViewType.Text.self).compactMap { try? $0.string() }.filter { $0 == label }.count
        XCTAssertGreaterThanOrEqual(idleLabels, entries.count)
        XCTAssertEqual(busyLabels, idleLabels)
        let fallback = PluginViewModel(available: true, title: "Account", blocks: original.blocks, presentation: .init(renderer: "account", props: ["layout": .string("wallet")], actions: [:]))
        XCTAssertNil(FlareAccountView.entryAction(fallback, entry: entry, busy: false, handled: true))
    }
    @MainActor func testLedgerContextIsSecondaryContentRatherThanABalanceField() throws {
        let model = PluginViewModel(available: true, title: "Entries", presentation: .init(renderer: "account", props: ["layout": .string("ledger"), "contextLabel": .string("Travel · USD · cash")], actions: [:]))
        let tree = try FlareAccountView(view: model).inspect()
        XCTAssertNoThrow(try tree.find(text: "Travel · USD · cash"))
        XCTAssertTrue(model.fields.isEmpty)
    }
    func testResolvedRecordFixturesKeepTitlesStatusesAmountsAndDetailBindings() throws {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let table = try JSONDecoder().decode(PluginJSONValue.self, from: Data(contentsOf: root.appendingPathComponent("spec/wallet-record-vectors.json")))
        let fixtures = table["cases"]?.arrayValue ?? []
        XCTAssertEqual(fixtures.count, 22)
        for fixture in fixtures {
            let view = try PluginVectors.decode(PluginViewModel.self, fixture["view"])
            if view.presentation?.props["layout"]?.stringValue == "ledger" {
                for entry in FlareAccountEntry.entries(view) {
                    XCTAssertTrue(entry.separateBadge)
                    XCTAssertEqual(entry.title, entry.row.cells[1].text)
                    XCTAssertEqual(entry.amount, entry.row.cells[0].text)
                    let action = try XCTUnwrap(FlareAccountView.entryAction(view, entry: entry, busy: false, handled: true))
                    XCTAssertEqual(action.action.id, "detail")
                    XCTAssertEqual(action.input, entry.row.actions.first { $0.id == "detail" }?.input)
                }
            }
        }
    }
    @MainActor func testSeparateStatusKeepsTitleAmountAndBoundDetailAction() throws {
        let amount = "CNY 12345678901234567890.123456789"
        let row = PluginRow(key: "request-1", cells: [.init(text: amount), .init(text: "提现"), .init(text: "零钱钱包")],
                            actions: [.init(id: "details", input: ["requestId": .string("opaque-request")])], badge: .init(text: "待审核", tone: .warning))
        let block = PluginRowsBlock(columns: [.init(label: "申请金额"), .init(label: "类型"), .init(label: "钱包")], rows: [row], actions: [.init(id: "details", label: "详情")])
        let model = PluginViewModel(available: true, title: "记录", blocks: [.rows(block)],
            presentation: .init(renderer: "account", props: ["layout": .string("ledger"), "rowBadgePlacement": .string("separate"), "rowBadgeLabel": .string("状态"), "rowEntryAction": .string("details")], actions: [:]))
        let entry = try XCTUnwrap(FlareAccountEntry.entries(model).first)
        XCTAssertEqual(entry.title, "提现"); XCTAssertEqual(entry.subtitle, "零钱钱包"); XCTAssertEqual(entry.amount, amount)
        XCTAssertEqual(entry.row.badge?.tone, .warning)
        XCTAssertNil(FlareAccountView.entryAction(model, entry: entry, busy: true, handled: true))
        XCTAssertNil(FlareAccountView.entryAction(model, entry: entry, busy: false, handled: false))
        var sent: [PluginActionPayload] = []
        let tree = try FlareAccountView(view: model, onAction: { _, payload in sent.append(payload) }).inspect()
        try tree.find(ViewType.Button.self, where: { try $0.labelView().find(text: "提现").string() == "提现" }).tap()
        XCTAssertEqual(sent.count, 1)
        XCTAssertEqual(sent.first?.row, PluginRowRef(key: "request-1", input: ["requestId": .string("opaque-request")]))
        let guarded = FlareAccountEntry(id: entry.id, block: .init(columns: block.columns, rows: [row], actions: [.init(id: "details", label: "详情", confirm: "确认")]), row: row)
        XCTAssertNil(FlareAccountView.entryAction(model, entry: guarded, busy: false, handled: true))
        let legacy = PluginViewModel(available: true, title: "", blocks: [.rows(block)])
        XCTAssertEqual(FlareAccountEntry.entries(legacy).first?.title, "待审核")
    }
    private func view() throws -> PluginViewModel {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("spec/account-view-vectors.json")
        let json = try JSONDecoder().decode(PluginJSONValue.self, from: Data(contentsOf: url))
        return try PluginVectors.decode(PluginViewModel.self, json["view"])
    }
    func testExactAmountsAndBindings() throws {
        let entries = FlareAccountEntry.entries(try view())
        XCTAssertEqual(entries.map(\.amount), ["+¥88.88", "-¥52.00", "+¥3.00", "+¥200.00", "+$0.88"])
        XCTAssertEqual(entries.first?.subtitle, "周五快乐")
        XCTAssertEqual(entries.first?.row.actions.first?.input["packetId"], .string("packet-01"))
        XCTAssertTrue(entries[3].row.actions.isEmpty)
    }
    func testDeduplicatesAndKeepsUnknownDatesUnknown() throws {
        let view = try view()
        guard case .rows(let block) = view.blocks.first else { return XCTFail("missing ledger") }
        let duplicate = PluginViewModel(available: true, title: "", blocks: [.rows(PluginRowsBlock(columns: block.columns, rows: block.rows + [block.rows[0]]))])
        XCTAssertEqual(FlareAccountEntry.entries(duplicate).count, block.rows.count)
        let unknown = PluginViewModel(available: true, title: "", blocks: [.rows(PluginRowsBlock(columns: [], rows: [PluginRow(key: "unknown", cells: [])]))])
        XCTAssertNil(FlareAccountEntry.entries(unknown).first?.timeMs)
    }
    @MainActor func testAccountPresentationShowsOriginalBalance() throws {
        let account = FlareAccountView(view: try view())
        XCTAssertNoThrow(try account.inspect().find(text: "¥1,288.66"))
        XCTAssertNoThrow(try account.inspect().find(text: "交易记录"))
    }
    func testSlotsOnlyOrderVisibleActionsAndKeepGuards() {
        let guarded = PluginViewAction(id: "submit", label: "提现", style: .primary, confirm: "确认提现", form: ["amount", "password"])
        let service = PluginViewAction(id: "history", label: "查看记录")
        let presentation = PluginPresentation(renderer: "account", props: ["layout": .string("wallet")],
            actions: ["primary": "submit", "secondary": "missing", "tertiary": "submit"])
        let view = PluginViewModel(available: true, title: "钱包", actions: [service, guarded], presentation: presentation)
        let projected = FlareAccountPresentation(view)
        XCTAssertEqual(projected.layout, .wallet)
        XCTAssertEqual(projected.primary, [guarded])
        XCTAssertEqual(projected.services, [service])
        XCTAssertFalse(projected.groupByDate)
        let grouped = PluginViewModel(available: true, title: "钱包", presentation: .init(renderer: "account", props: ["layout": .string("wallet"), "groupByDate": .bool(true)], actions: [:]))
        XCTAssertTrue(FlareAccountPresentation(grouped).groupByDate)
        let readOnly = PluginViewModel(available: true, title: "钱包", actions: [guarded], unavailableReason: .unboundCopy, presentation: presentation)
        XCTAssertTrue(FlareAccountPresentation(readOnly).primary.isEmpty)
        XCTAssertTrue(FlareAccountPresentation(readOnly).services.isEmpty)
        let authorized = PluginViewModel(available: true, title: "提现", actions: [service, guarded],
            presentation: .init(renderer: "account", props: ["layout": .string("flow")], actions: ["submit": "previously-visible"]))
        XCTAssertEqual(FlareAccountPresentation(authorized).primary, [guarded])
        XCTAssertEqual(FlareAccountPresentation(authorized).services, [service])
    }
    @MainActor func testFlowShowsReceiptAndRecoveryWithoutAnEmptyLedger() throws {
        let flow = PluginViewModel(available: true, title: "提现", fields: [.init(label: "申请金额", value: "¥123.45")],
            actions: [.init(id: "recover", label: "查看待确认操作")],
            presentation: .init(renderer: "account", props: ["layout": .string("flow"), "stepLabel": .string("确认提现")], actions: ["submit": "recover"]))
        let tree = try FlareAccountView(view: flow, error: "结果待确认").inspect()
        XCTAssertNoThrow(try tree.find(text: "¥123.45"))
        XCTAssertNoThrow(try tree.find(text: "确认提现"))
        XCTAssertNoThrow(try tree.find(button: "查看待确认操作"))
        XCTAssertThrowsError(try tree.find(EmptyStateView.self))
        XCTAssertEqual(tree.findAll(StatusBannerView.self).count, 1)
    }
    func testRustWalletFixturesKeepTheDeclaredSubmitAndVisibleActions() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("spec/wallet-flow-vectors.json")
        let fixtures = try JSONDecoder().decode(PluginJSONValue.self, from: Data(contentsOf: url))["cases"]?.arrayValue ?? []
        XCTAssertEqual(fixtures.count, 44)
        var recoveries = 0
        for fixture in fixtures {
            let view = try PluginVectors.decode(PluginViewModel.self, fixture["view"])
            let projected = FlareAccountPresentation(view)
            let grouped = projected.primary + projected.shortcuts + projected.services
            XCTAssertEqual(Set(grouped.map(\.id)), Set((view.actions + view.menuActions).map(\.id)))
            XCTAssertEqual(grouped.count, Set(grouped.map(\.id)).count)
            if projected.layout == .wallet { XCTAssertFalse(projected.groupByDate) }
            if fixture["id"]?.stringValue == "openings", fixture["locale"]?.stringValue == "zh-CN" {
                let rows = try XCTUnwrap(view.rowsBlock)
                let fields = PluginViewFormat.rowFields(rows, try XCTUnwrap(rows.rows.first), nowMs: 0, FlareStrings(), utcOffsetMinutes: 0)
                XCTAssertEqual(fields.map(\.label), ["模板", "状态", "原因"])
                XCTAssertEqual(fields.last?.value, "等待审核")
            }
            if fixture["id"]?.stringValue == "recovery" {
                recoveries += 1
                XCTAssertEqual(view.presentation?.actions["submit"], "retry")
                XCTAssertEqual(projected.primary.first?.id, "retry")
                XCTAssertNil(projected.primary.first?.style)
            }
        }
        XCTAssertEqual(recoveries, 2)
    }
    @MainActor func testFlowRowsShowColumnLabels() throws {
        let block = PluginRowsBlock(columns: [.init(label: "实例名称"), .init(label: "模板"), .init(label: "状态"), .init(label: "原因")], rows: [
            .init(key: "opening", cells: [.init(text: "工资钱包"), .init(text: "definition-fixture"), .init(text: "pending"), .init(text: "等待审核")])])
        let view = PluginViewModel(available: true, title: "开户进度", blocks: [.rows(block)],
            presentation: .init(renderer: "account", props: ["layout": .string("flow")], actions: [:]))
        let tree = try FlareAccountView(view: view).inspect()
        for label in ["实例名称", "工资钱包", "模板", "状态", "原因", "等待审核"] { XCTAssertNoThrow(try tree.find(text: label)) }
    }
    func testDefaultStyleRecoveryActionUsesSubmitSlot() {
        let retry = PluginViewAction(id: "retry", label: "重试原操作")
        let back = PluginViewAction(id: "back", label: "返回钱包")
        let view = PluginViewModel(available: true, title: "待确认操作", actions: [back, retry],
            presentation: .init(renderer: "account", props: ["layout": .string("flow")], actions: ["submit": "retry"]))
        XCTAssertEqual(FlareAccountPresentation(view).primary, [retry])
        XCTAssertEqual(FlareAccountPresentation(view).services, [back])
    }
    @MainActor func testCompactAndListActionsUseTheSameConfirmationAndFormGuard() throws {
        for layout in [PluginViewActionLayout.compact, .list] {
            var emitted: [String] = []
            let guarded = PluginViewModel(available: true, title: "", actions: [
                .init(id: "confirm", label: "确认", confirm: "请确认"),
                .init(id: "form", label: "填写金额", form: ["amount"]),
                .init(id: "recover", label: "恢复状态")], inputs: [.init(id: "amount", kind: .text, label: "金额")])
            let tree = try PluginView(view: guarded, embedded: true, actionLayout: layout, onAction: { id, _ in emitted.append(id) }).inspect()
            try tree.find(button: "确认").tap()
            try tree.find(button: "填写金额").tap()
            XCTAssertTrue(emitted.isEmpty)
            try tree.find(button: "恢复状态").tap()
            XCTAssertEqual(emitted, ["recover"])
        }
    }
    func testInlineEligibilityAndSynchronousSettlement() {
        let action = PluginViewAction(id: "submit", label: "核对", form: ["amount"])
        let input = PluginInput(id: "amount", kind: .text, label: "金额")
        let view = PluginViewModel(available: true, title: "", actions: [action], inputs: [input])
        XCTAssertEqual(PluginView.inlineAction(view, id: "submit", hasAction: true), action)
        XCTAssertNil(PluginView.inlineAction(view, id: "submit", hasAction: false))
        for blocked in [
            PluginViewModel(available: false, title: "", actions: [action], inputs: [input]),
            PluginViewModel(available: true, title: "", actions: [action], inputs: [input], unavailableReason: .unboundCopy),
            PluginViewModel(available: true, title: "", menuActions: [action]),
            PluginViewModel(available: true, title: "", actions: [action]),
            PluginViewModel(available: true, title: "", actions: [.init(id: "submit", label: "核对", confirm: "请确认", form: ["amount"])], inputs: [input]),
            PluginViewModel(available: true, title: "", actions: [action], inputs: [.init(id: "amount", kind: .password, label: "密码")])
        ] { XCTAssertNil(PluginView.inlineAction(blocked, id: "submit", hasAction: true)) }
        var state = PluginInlineFormState()
        XCTAssertTrue(state.begin("submit")); XCTAssertFalse(state.begin("submit"))
        state.settle(from: .init(), to: .init(error: "结果待确认", settleToken: 1), actionId: "submit")
        XCTAssertFalse(state.pending); XCTAssertTrue(state.submitted); XCTAssertEqual(state.revision, 0)
        XCTAssertTrue(state.begin("submit"))
        state.settle(from: .init(settleToken: 1), to: .init(settleToken: 2), actionId: "submit")
        XCTAssertFalse(state.submitted); XCTAssertEqual(state.revision, 1)
    }
    @MainActor func testMultipleWalletRowsPreserveIndependentAmountsAndBindings() throws {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        let table = try JSONDecoder().decode(PluginJSONValue.self, from: Data(contentsOf: url.appendingPathComponent("spec/wallet-card-vectors.json")))
        let model = try PluginVectors.decode(PluginViewModel.self, table["cases"]?[0]?["view"])
        let entries = FlareAccountEntry.entries(model)
        XCTAssertEqual(entries.map(\.walletTitle), ["零钱钱包", "旅行钱包"])
        XCTAssertEqual(entries.map(\.amount), ["1000.00", "88.50"])
        XCTAssertEqual(entries.map(\.walletCaption), ["余额", "余额"])
        XCTAssertEqual(model.fields.first?.value, "900.00")
        XCTAssertEqual(entries.map { $0.row.actions.first?.input["walletId"]?.stringValue }, ["wallet-cny-fixture", "wallet-usd-fixture"])
        let tree = try FlareAccountView(view: model, onAction: { _, _ in }).inspect()
        XCTAssertNoThrow(try tree.find(text: "1000.00")); XCTAssertNoThrow(try tree.find(text: "88.50"))
        let titles = tree.findAll(ViewType.Text.self).compactMap { try? $0.string() }
        XCTAssertEqual(titles.filter { $0 == "我的钱包" }.count, 1)
    }
    @MainActor func testInlineFormIsVisibleWithoutExecutingAndSubmitsOriginalText() throws {
        let action = PluginViewAction(id: "review", label: "核对充值", form: ["amount"])
        let model = PluginViewModel(available: true, title: "充值", actions: [action], inputs: [
            .init(id: "amount", kind: .text, label: "金额", required: true, defaultValue: .string("123.4500"))])
        var sent: [(String, PluginActionPayload)] = []
        let tree = try PluginView(view: model, embedded: true, inlineFormActionId: "review", onAction: { sent.append(($0, $1)) }).inspect()
        XCTAssertTrue(sent.isEmpty)
        XCTAssertNoThrow(try tree.find(PluginFormView.self))
        XCTAssertThrowsError(try tree.find(button: "取消"))
        try tree.find(button: "核对充值").tap()
        XCTAssertEqual(sent.first?.0, "review")
        XCTAssertEqual(sent.first?.1.formValues, ["amount": .string("123.4500")])
        let busy = try PluginView(view: model, busyActionId: "other", embedded: true, inlineFormActionId: "review", onAction: { _, _ in }).inspect()
        XCTAssertTrue(try busy.find(button: "核对充值").isDisabled())
        let error = try PluginView(view: model, error: "结果待确认", embedded: true, inlineFormActionId: "review", onAction: { _, _ in }).inspect()
        XCTAssertEqual(error.findAll(StatusBannerView.self).count, 1)
    }
}
