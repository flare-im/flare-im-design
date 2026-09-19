import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// K2 (FR-092): ``FlareFeedback/prompt(_:)`` asks for one value next to the confirmation — busy while the
/// host's submit runs, an inline error that keeps the draft, retry by confirming again.
final class FlarePromptTests: XCTestCase {
    private struct SaveFailed: LocalizedError { var errorDescription: String? { "保存失败，请重试" } }

    @MainActor
    private func waitForPrompt(_ feedback: FlareFeedback, titled title: String? = nil) async {
        for _ in 0..<1_000 where feedback.promptRequest == nil || (title != nil && feedback.promptRequest?.options.title != title) {
            await Task.yield()
        }
    }

    @MainActor
    func testConfirmRunsTheSubmitBusyWithTheTrimmedValueAndResolvesIt() async {
        let feedback = FlareFeedback(announce: { _ in })
        var submitted: [String] = []
        var busyDuringSubmit: Bool?
        let answer = Task {
            await feedback.prompt(FlarePromptOptions(title: "修改备注", initialValue: "老王", submit: { value in
                busyDuringSubmit = feedback.promptRequest?.busy
                submitted.append(value)
            }))
        }
        await waitForPrompt(feedback)
        XCTAssertEqual(feedback.promptRequest?.value, "老王", "the input starts with the current value")
        feedback.updatePromptValue("  王工  ")
        await feedback.acceptPrompt()
        let value = await answer.value
        XCTAssertEqual(value, "王工")
        XCTAssertEqual(submitted, ["王工"])
        XCTAssertEqual(busyDuringSubmit, true)
        XCTAssertNil(feedback.promptRequest)
    }

    @MainActor
    func testAFailedSubmitKeepsTheDraftAndTheErrorAndConfirmingAgainRetries() async {
        let feedback = FlareFeedback(announce: { _ in })
        var attempts = 0
        let answer = Task {
            await feedback.prompt(FlarePromptOptions(title: "群名称", submit: { _ in
                attempts += 1
                if attempts == 1 { throw SaveFailed() }
            }))
        }
        await waitForPrompt(feedback)
        feedback.updatePromptValue("设计部")
        await feedback.acceptPrompt()
        XCTAssertEqual(feedback.promptRequest?.error, "保存失败，请重试")
        XCTAssertEqual(feedback.promptRequest?.value, "设计部", "the draft stays")
        XCTAssertEqual(feedback.promptRequest?.busy, false)
        await feedback.acceptPrompt()
        let value = await answer.value
        XCTAssertEqual(value, "设计部")
        XCTAssertEqual(attempts, 2)
        XCTAssertNil(feedback.promptRequest)
    }

    @MainActor
    func testCancelResolvesNilWithoutSubmitting() async {
        let feedback = FlareFeedback(announce: { _ in })
        var ran = false
        let answer = Task { await feedback.prompt(FlarePromptOptions(title: "申请理由", submit: { _ in ran = true })) }
        await waitForPrompt(feedback)
        feedback.updatePromptValue("你好")
        feedback.cancelPrompt()
        let value = await answer.value
        XCTAssertNil(value)
        XCTAssertFalse(ran)
        XCTAssertNil(feedback.promptRequest)
    }

    @MainActor
    func testABlankValueWaitsForTextUnlessEmptyIsAllowedAndTheDraftKeepsTheLimit() async {
        let feedback = FlareFeedback(announce: { _ in })
        var runs = 0
        let blocked = Task { await feedback.prompt(FlarePromptOptions(title: "群名称", maxLength: 4, submit: { _ in runs += 1 })) }
        await waitForPrompt(feedback, titled: "群名称")
        feedback.updatePromptValue("   ")
        XCTAssertEqual(feedback.promptRequest?.canConfirm, false)
        await feedback.acceptPrompt()
        XCTAssertEqual(runs, 0, "a blank value is not confirmed")
        feedback.updatePromptValue("产品设计中心")
        XCTAssertEqual(feedback.promptRequest?.value, "产品设计", "the draft never exceeds maxLength")
        feedback.cancelPrompt()
        _ = await blocked.value

        let clearing = Task { await feedback.prompt(FlarePromptOptions(title: "备注", initialValue: "老王", allowsEmpty: true)) }
        await waitForPrompt(feedback, titled: "备注")
        feedback.updatePromptValue("")
        XCTAssertEqual(feedback.promptRequest?.canConfirm, true)
        await feedback.acceptPrompt()
        let cleared = await clearing.value
        XCTAssertEqual(cleared, "", "clearing is a value")
    }

    @MainActor
    func testANewerPromptReplacesAnIdleOneAndWaitsOutABusyOne() async {
        let feedback = FlareFeedback(announce: { _ in })
        let first = Task { await feedback.prompt(FlarePromptOptions(title: "first")) }
        await waitForPrompt(feedback, titled: "first")
        let second = Task { await feedback.prompt(FlarePromptOptions(title: "second", submit: { _ in
            try await Task.sleep(nanoseconds: 50_000_000)
        })) }
        let replaced = await first.value
        XCTAssertNil(replaced, "an idle prompt resolves nil when replaced")
        await waitForPrompt(feedback, titled: "second")
        feedback.updatePromptValue("x")
        let accepting = Task { await feedback.acceptPrompt() }
        for _ in 0..<1_000 where feedback.promptRequest?.busy != true { await Task.yield() }
        let refused = await feedback.prompt(FlarePromptOptions(title: "third"))
        XCTAssertNil(refused, "while a submit runs a newer prompt resolves nil at once")
        await accepting.value
        let secondValue = await second.value
        XCTAssertEqual(secondValue, "x")
    }

    @MainActor
    func testTheFormShowsTheCopyTheErrorAndAConfirmThatWaitsForText() throws {
        let strings = FlareStrings()
        var request = FlarePromptRequest(id: 1, options: FlarePromptOptions(title: "修改备注", message: "只有你能看到备注。",
                                                                           placeholder: "备注名", maxLength: 20),
                                         value: "")
        var confirmed = 0, cancelled = 0
        func form() -> FlarePromptForm {
            FlarePromptForm(request: request, onChange: { _ in }, onConfirm: { confirmed += 1 }, onCancel: { cancelled += 1 })
        }
        let view = try form().inspect()
        XCTAssertNoThrow(try view.find(text: "修改备注"))
        XCTAssertNoThrow(try view.find(text: "只有你能看到备注。"))
        XCTAssertNoThrow(try view.find(text: "0/20"), "the input shows its count")
        XCTAssertTrue(try view.find(button: strings.confirm).isDisabled(), "confirm waits for text")
        try view.find(button: strings.cancel).tap()
        XCTAssertEqual(cancelled, 1)

        request.value = "王工"
        request.error = "保存失败，请重试"
        let failed = try form().inspect()
        XCTAssertNoThrow(try failed.find(text: "保存失败，请重试"), "the error shows inline")
        let confirm = try failed.find(button: strings.confirm)
        XCTAssertFalse(confirm.isDisabled())
        try confirm.tap()
        XCTAssertEqual(confirmed, 1)
    }
}
