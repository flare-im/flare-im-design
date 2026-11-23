import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The plugin page details of docs/plugin-experience.md (§12 rulings): the status card's icon (6.1), the filter's
/// empty state (5.8), document slots (6.3), the inline form's busy key (R2.5), field labels (R6), the danger card
/// (R2.1), the step bar's reading (6.1) and the one Tag look (R3).
final class PluginPageDetailsTests: XCTestCase {
    private let s = FlareStrings()

    func testStatusCardIconFollowsTheStatus() {
        XCTAssertEqual(PluginExperienceRules.statusCardIcon(.neutral, unknown: false, hasKey: true), "admin")
        XCTAssertEqual(PluginExperienceRules.statusCardIcon(.info, unknown: false, hasKey: true), "edit", "a draft goes on")
        XCTAssertEqual(PluginExperienceRules.statusCardIcon(.info, unknown: false, hasKey: false), "clock", "under review")
        XCTAssertEqual(PluginExperienceRules.statusCardIcon(.success, unknown: false, hasKey: false), "success")
        XCTAssertEqual(PluginExperienceRules.statusCardIcon(.danger, unknown: false, hasKey: true), "error")
        XCTAssertEqual(PluginExperienceRules.statusCardIcon(.warning, unknown: false, hasKey: true), "warning")
        XCTAssertEqual(PluginExperienceRules.statusCardIcon(.success, unknown: true, hasKey: false), "info")
    }

    func testClearingFiltersDropsOnlyTheFilterValues() {
        let input = PluginInput(id: "kind", kind: .select, label: "类型",
                                choices: [.init(value: "in", label: "收入"), .init(value: "out", label: "支出")])
        let set = PluginPageFilter(input: input, tabs: [], selected: "in")
        let all = PluginPageFilter(input: input, tabs: [], selected: nil)
        let values: [String: PluginJSONValue] = ["kind": .string("in"), "walletId": .string("w1")]
        XCTAssertEqual(PluginPageRules.cleared([set], in: values), ["walletId": .string("w1")])
        XCTAssertNil(PluginPageRules.cleared([all], in: ["walletId": .string("w1")]), "nothing to clear")
    }

    func testConsecutiveDocumentInputsAreOneSlotGrid() {
        let name = PluginInput(id: "name", kind: .text, label: "姓名")
        let front = PluginInput(id: "front", kind: .document, label: "证件正面", side: .front)
        let back = PluginInput(id: "back", kind: .document, label: "证件反面", side: .back)
        let note = PluginInput(id: "note", kind: .textarea, label: "备注")
        XCTAssertEqual(PluginFormView.runs([name, front, back, note]).map { $0.map(\.id) },
                       [["name"], ["front", "back"], ["note"]])
        XCTAssertEqual(PluginFormView.slotState(nil), .empty)
        XCTAssertEqual(PluginFormView.slotState(PluginFileState(scope: "s", generation: 1, phase: .uploading, progress: 0.42)),
                       .uploading(42))
        XCTAssertEqual(PluginFormView.slotState(PluginFileState(scope: "s", generation: 1, phase: .uploaded)), .captured)
        XCTAssertEqual(PluginFormView.slotState(PluginFileState(scope: "s", generation: 1, phase: .failed)), .failed)
        XCTAssertEqual(PluginFormView.documentSide(.holding), .holding)
        XCTAssertEqual(PluginFormView.documentSide(nil), .front)
    }

    @MainActor
    func testDocumentInputsAreSlotsAndHoldTheSubmitUntilTaken() throws {
        let inputs = [PluginInput(id: "front", kind: .document, label: "证件正面", required: true, side: .front),
                      PluginInput(id: "back", kind: .document, label: "证件反面", required: true, side: .back)]
        let tree = try PluginFormView(inputs: inputs, submitLabel: "提交审核", onSubmit: { _ in }).inspect()
        XCTAssertEqual(tree.findAll(FlareDocumentSlot.self).count, 2)
        XCTAssertThrowsError(try tree.find(PluginFileUploadField.self), "no upload rows for documents")
        XCTAssertTrue(try tree.find(button: "提交审核").isDisabled())
        XCTAssertNoThrow(try tree.find(text: s.realnamePhotosNeeded.replacingOccurrences(of: "{count}", with: "2")))
    }

    /// R2.5 (P1): the inline form's key spins only while its own action runs; another action running only disables it.
    @MainActor
    func testInlineSubmitSpinsOnlyForItsOwnAction() throws {
        let action = PluginViewAction(id: "review", label: "核对充值", form: ["amount"])
        let model = PluginViewModel(available: true, title: "充值", actions: [action],
                                    inputs: [.init(id: "amount", kind: .text, label: "金额")])
        let other = try PluginView(view: model, busyActionId: "other", embedded: true, inlineFormActionId: "review",
                                   onAction: { _, _ in }).inspect()
        let waiting = try other.find(button: "核对充值")
        XCTAssertTrue(waiting.isDisabled())
        XCTAssertThrowsError(try waiting.labelView().find(ViewType.ProgressView.self), "no spinner for another action")
        let own = try PluginView(view: model, busyActionId: "review", embedded: true, inlineFormActionId: "review",
                                 onAction: { _, _ in }).inspect()
        XCTAssertNoThrow(try own.find(button: "核对充值").labelView().find(ViewType.ProgressView.self))
    }

    /// R6: the required mark reads "必填" with the label; the error is the field's hint.
    @MainActor
    func testRequiredLabelReadsRequired() throws {
        let field = FormFieldView(label: "金额", required: true, error: "必填") { Text("x") }
        XCTAssertNoThrow(try field.inspect().find(viewWithAccessibilityLabel: "金额, \(s.pluginFormRequired)"))
    }

    /// R2.1: a danger action is its own card and always asks first, also without a confirm of its own.
    @MainActor
    func testWalletDangerRowAsksFirst() throws {
        let close = PluginViewAction(id: "close", label: "关闭钱包", style: .danger, target: .init(kind: "operation"))
        let view = PluginViewModel(available: true, title: "钱包", actions: [close],
                                   presentation: .init(renderer: "account", props: ["layout": .string("ledger")], actions: [:]))
        var sent: [String] = []
        let tree = try FlareAccountView(view: view, onAction: { id, _ in sent.append(id) }).inspect()
        try tree.find(button: "关闭钱包").tap()
        XCTAssertTrue(sent.isEmpty, "the danger card confirms first")
    }

    /// R6: an input's help (already translated) is drawn under its field; an input without one draws nothing more.
    @MainActor
    func testAFieldDrawsItsHelpUnderTheInput() throws {
        let help = "英文、数字或 _ : - .，最多 128 个字符"
        let helped = try JSONDecoder().decode(PluginInput.self,
            from: Data(#"{"id":"key","kind":"text","label":"键","help":"\#(help)"}"#.utf8))
        XCTAssertEqual(helped.help, help)
        let plain = try JSONDecoder().decode(PluginInput.self, from: Data(#"{"id":"key","kind":"text","label":"键"}"#.utf8))
        XCTAssertNil(plain.help)
        XCTAssertNil(try JSONDecoder().decode(PluginInput.self,
            from: Data(#"{"id":"key","kind":"text","label":"键","help":""}"#.utf8)).help, "an empty help is none")
        let drawn = try PluginFormView(inputs: [helped]).inspect()
        XCTAssertNoThrow(try drawn.find(text: help))
        let bare = try PluginFormView(inputs: [plain]).inspect()
        XCTAssertEqual(drawn.findAll(ViewType.Text.self).count, bare.findAll(ViewType.Text.self).count + 1)
    }

    func testStepBarReadsItsPosition() {
        XCTAssertEqual(PluginStepsBlockView.position(1, of: 4, s), "第 2 步，共 4 步")
    }

    @MainActor
    func testStatusBlockIsTheKitTag() throws {
        let tree = try PluginStatusBlockView(block: .init(label: "状态", text: "已完成", tone: .success)).inspect()
        XCTAssertNoThrow(try tree.find(PluginBadgeView.self))
    }
}
