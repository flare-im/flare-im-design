import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The host's settle signal (`settleToken`), the embedded view's sheet insets and what the detail sheet hands its
/// embedded view for the actions run from it (`spec/plugin-view-vectors.json` rules: settle, inset, detail).
final class PluginSettleTests: XCTestCase {
    private func poll(multiple: Bool = false) -> PluginChoicesBlock {
        PluginChoicesBlock(options: [PluginChoice(index: 0, label: "A"), PluginChoice(index: 1, label: "B")],
                           multiple: multiple, action: PluginViewAction(id: "vote", label: "Vote"))
    }

    /// A choice submitted and waiting for the host.
    private func submitted() -> PluginChoicesInteraction {
        var state = PluginChoicesInteraction()
        state.submitted(block: 0, actionId: "vote", selection: [1])
        return state
    }

    // MARK: Choices

    func testACleanSettleKeepsTheMarkAndThePauseUntilTheNewView() {
        var state = submitted()
        state.hostChanged(from: PluginHostSignal(), to: PluginHostSignal(settleToken: 1))
        XCTAssertEqual(state.shown(poll(), at: 0), [1], "the mark stays")
        XCTAssertFalse(state.isInteractive(poll(), at: 0, locked: false), "the options wait for the new view")
        state.viewChanged()
        XCTAssertTrue(state.isInteractive(poll(), at: 0, locked: false))
    }

    func testASettleWithAnErrorRevertsEvenWhenTheTextDidNotChange() {
        var state = submitted()
        let failed = PluginHostSignal(error: "网络异常", settleToken: 1)
        state.hostChanged(from: PluginHostSignal(error: "网络异常"), to: failed)
        XCTAssertEqual(state.shown(poll(), at: 0), [], "read at the change, the same text reverts")
        XCTAssertTrue(state.isInteractive(poll(), at: 0, locked: false))
    }

    func testASettleWithFormErrorsRevertsTheChoiceTheFormCarried() {
        var state = submitted()
        let invalid = PluginHostSignal(formErrors: [PluginFormError(input: "note", issue: .required)], settleToken: 1)
        state.hostChanged(from: PluginHostSignal(), to: invalid)
        XCTAssertEqual(state.shown(poll(), at: 0), [])
    }

    func testBusyActionIdLeavingTheActionStillSettlesAndTogetherTheySettleOnce() {
        var fallback = submitted()
        fallback.hostChanged(from: PluginHostSignal(busyActionId: "vote"),
                             to: PluginHostSignal(busyActionId: nil, formErrors: [PluginFormError(input: "x", issue: .tooLong)]))
        XCTAssertEqual(fallback.shown(poll(), at: 0), [], "the fallback reads form errors too")

        var both = submitted()
        both.hostChanged(from: PluginHostSignal(busyActionId: "vote"), to: PluginHostSignal(settleToken: 1))
        XCTAssertEqual(both.shown(poll(), at: 0), [1], "a clean result, however many signals")

        // Set and cleared within one update: busyActionId never changes, the token alone settles.
        var sameFrame = submitted()
        sameFrame.hostChanged(from: PluginHostSignal(), to: PluginHostSignal(error: "失败", settleToken: 1))
        XCTAssertEqual(sameFrame.shown(poll(), at: 0), [])
        var unsettled = submitted()
        unsettled.hostChanged(from: PluginHostSignal(), to: PluginHostSignal())
        XCTAssertEqual(unsettled.shown(poll(), at: 0), [1], "no signal, no settle")
    }

    // MARK: Forms

    func testTheSubmittedFormClosesOnACleanSettleAndStaysWithErrors() {
        let idle = PluginHostSignal()
        XCTAssertEqual(PluginSettleRules.form(from: idle, to: PluginHostSignal(settleToken: 1), actionId: "create"), .close)
        XCTAssertEqual(PluginSettleRules.form(from: idle, to: PluginHostSignal(error: "保存失败", settleToken: 1),
                                              actionId: "create"), .keep)
        XCTAssertEqual(PluginSettleRules.form(from: idle, to: PluginHostSignal(
            formErrors: [PluginFormError(input: "title", issue: .required)], settleToken: 1), actionId: "create"), .keep)
        XCTAssertEqual(PluginSettleRules.form(from: idle, to: PluginHostSignal(error: "x"), actionId: "create"), .wait,
                       "an error alone does not settle the form")
        // The fallback: the form's action (or the whole card) stops being busy.
        XCTAssertEqual(PluginSettleRules.form(from: PluginHostSignal(busyActionId: "create"), to: idle, actionId: "create"),
                       .close)
        XCTAssertEqual(PluginSettleRules.form(from: PluginHostSignal(busy: true), to: PluginHostSignal(error: "x"),
                                              actionId: "create"), .keep)
        XCTAssertEqual(PluginSettleRules.form(from: PluginHostSignal(busyActionId: "other"), to: idle, actionId: "create"),
                       .wait, "another action finishing leaves this form alone")
        XCTAssertEqual(PluginSettleRules.form(from: PluginHostSignal(busyActionId: "create"),
                                              to: PluginHostSignal(settleToken: 1), actionId: "create"), .close,
                       "both signals at once settle once")
    }

    @MainActor
    func testTheTokenIsAParameterOfTheCardAndTheSheet() throws {
        let view = PluginViewModel(available: true, title: "Card", blocks: [.note(PluginNoteBlock(text: "n"))])
        XCTAssertEqual(PluginView(view: view).settleToken, 0)
        XCTAssertEqual(PluginView(view: view, settleToken: 3).settleToken, 3)
    }

    // MARK: Inset

    func testAnEmbeddedViewTakesTheSheetInsetsOnlyWhenAsked() {
        let sheet = PluginView.insetPadding(.sheet)
        XCTAssertEqual(sheet.top, FlareSizes.spacingMd)
        XCTAssertEqual(sheet.leading, FlareSizes.spacingLg)
        XCTAssertEqual(sheet.trailing, FlareSizes.spacingLg)
        XCTAssertEqual(sheet.bottom, FlareSizes.spacingXl)
        XCTAssertEqual(PluginView.insetPadding(.none), EdgeInsets())
        let top = PluginView.insetPadding(.sheetTop)
        XCTAssertEqual(top, EdgeInsets(top: FlareSizes.spacingMd, leading: FlareSizes.spacingLg, bottom: 0,
                                       trailing: FlareSizes.spacingLg), "a preface leaves the gap to the form under it")
        XCTAssertEqual(PluginViewInset.allCases.map(\.rawValue), ["none", "sheet", "sheetTop"])
    }

    /// `spec/plugin-view-vectors.json` insets: every value's sides.
    func testTheInsetsFollowTheTable() throws {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/plugin-view-vectors.json"))
        let table = try JSONDecoder().decode(PluginJSONValue.self, from: data)
        let insets = try XCTUnwrap(table["insets"]?.objectValue)
        XCTAssertEqual(Set(insets.keys), Set(PluginViewInset.allCases.map(\.rawValue)))
        func side(_ token: PluginJSONValue?) -> CGFloat {
            switch token?.stringValue {
            case "md": return FlareSizes.spacingMd
            case "lg": return FlareSizes.spacingLg
            case "xl": return FlareSizes.spacingXl
            default: return 0
            }
        }
        for inset in PluginViewInset.allCases {
            let sides = insets[inset.rawValue]
            XCTAssertEqual(PluginView.insetPadding(inset),
                           EdgeInsets(top: side(sides?["top"]), leading: side(sides?["sides"]),
                                      bottom: side(sides?["bottom"]), trailing: side(sides?["sides"])), inset.rawValue)
        }
    }

    @MainActor
    func testAnUnavailableEmbeddedViewKeepsTheInsetAndSaysWhatItWas() throws {
        let gone = PluginViewModel(available: false, title: "投票（已失效）",
                                   actions: [PluginViewAction(id: "vote", label: "投票")])
        for inset in [PluginViewInset.sheet, .sheetTop] {
            let embedded = PluginView(view: gone, embedded: true, inset: inset)
            XCTAssertEqual(embedded.inset, inset)
            let tree = try embedded.inspect()
            XCTAssertNoThrow(try tree.find(text: "投票（已失效）"), "the title as a line")
            XCTAssertThrowsError(try tree.find(button: "投票"), "no actions")
            XCTAssertEqual(try tree.find(ViewType.Group.self).padding(), PluginView.insetPadding(inset),
                           "the unavailable state takes the inset")
            // A shell a host keeps for an unavailable view is padded the same, around the shell.
            let shell = try PluginView(view: gone, inset: inset).inspect()
            XCTAssertNoThrow(try shell.find(text: "投票（已失效）"))
            XCTAssertEqual(try shell.find(ViewType.Group.self).padding(), PluginView.insetPadding(inset))
        }
        let shown = PluginViewModel(available: true, title: "Card", blocks: [.note(PluginNoteBlock(text: "n"))])
        XCTAssertThrowsError(try PluginView(view: shown, embedded: true).inspect().find(text: "Card"),
                             "an available embedded view leaves the title to its host")
    }

    @MainActor
    func testTheInsetIsPassedThroughAndTheDefaultIsNone() throws {
        let view = PluginViewModel(available: true, title: "Card", blocks: [.note(PluginNoteBlock(text: "n"))])
        XCTAssertEqual(PluginView(view: view, embedded: true).inset, .none)
        let padded = PluginView(view: view, embedded: true, inset: .sheet)
        XCTAssertEqual(padded.inset, .sheet)
        XCTAssertNoThrow(try padded.inspect().find(text: "n"))
    }

    // MARK: Detail sheet

    @MainActor
    func testTheDetailSheetHandsItsActionStateToTheEmbeddedView() throws {
        let detail = PluginViewModel(available: true, title: "接龙", actions: [PluginViewAction(id: "join", label: "参与")],
                                     blocks: [.note(PluginNoteBlock(text: "n"))])
        let members = [PluginMember(userId: "u1", name: "Ann")]
        let errors = [PluginFormError(input: "text", issue: .required)]
        let sheet = PluginDetailSheetView(view: detail, error: nil, busyActionId: "join", actionError: "提交失败",
                                          formErrors: errors, members: members, settleToken: 4)
        let embedded = try sheet.inspect().find(PluginView.self).actualView()
        XCTAssertEqual(embedded.error, "提交失败", "actionError is the embedded view's error")
        XCTAssertEqual(embedded.formErrors, errors)
        XCTAssertEqual(embedded.members, members)
        XCTAssertEqual(embedded.settleToken, 4)
        XCTAssertEqual(embedded.busyActionId, "join")
        XCTAssertNoThrow(try sheet.inspect().find(text: "提交失败"), "the failure shows inside the sheet")

        let quiet = try PluginDetailSheetView(view: detail).inspect().find(PluginView.self).actualView()
        XCTAssertNil(quiet.error)
        XCTAssertTrue(quiet.formErrors.isEmpty)
        XCTAssertTrue(quiet.members.isEmpty)
        XCTAssertEqual(quiet.settleToken, 0)
        // The loading failure stays `error`, with retry, and never reaches the embedded view.
        XCTAssertEqual(PluginDetailSheetView.phase(loading: false, error: "加载失败", view: detail), .error)
    }

    // MARK: Detail pages

    func testTheDetailViewReadsItsNextCursor() throws {
        func decode(_ json: String) throws -> PluginViewModel {
            try JSONDecoder().decode(PluginViewModel.self, from: Data(json.utf8))
        }
        let paged = try decode(#"{"available":true,"title":"接龙","nextCursor":"c2"}"#)
        XCTAssertEqual(paged.nextCursor, "c2")
        XCTAssertNil(try decode(#"{"available":true,"title":"接龙","nextCursor":""}"#).nextCursor, "empty: the last page")
        XCTAssertNil(try decode(#"{"available":true,"title":"接龙","nextCursor":"  "}"#).nextCursor, "blank: the last page")
        XCTAssertNil(try decode(#"{"available":true,"title":"接龙"}"#).nextCursor)
        XCTAssertNil(try decode(#"{"available":true,"title":"接龙","nextCursor":7}"#).nextCursor, "lenient")
        let again = try JSONDecoder().decode(PluginViewModel.self, from: JSONEncoder().encode(paged))
        XCTAssertEqual(again, paged)
    }

    func testLoadMoreShowsWithACursorAndSpinsUntilThePageMovesItOn() {
        XCTAssertEqual(PluginDetailSheetView.loadMore(cursor: nil, requested: nil, loadingMore: false), .hidden)
        XCTAssertEqual(PluginDetailSheetView.loadMore(cursor: "", requested: nil, loadingMore: false), .hidden)
        XCTAssertEqual(PluginDetailSheetView.loadMore(cursor: " \n", requested: nil, loadingMore: false), .hidden)
        XCTAssertEqual(PluginDetailSheetView.loadMore(cursor: "c2", requested: nil, loadingMore: false), .ready("c2"))
        XCTAssertEqual(PluginDetailSheetView.loadMore(cursor: "c2", requested: nil, loadingMore: true), .loading,
                       "the host is loading")
        XCTAssertEqual(PluginDetailSheetView.loadMore(cursor: "c2", requested: "c2", loadingMore: false), .loading,
                       "asked for and not answered: the same page is never asked for twice")
        XCTAssertEqual(PluginDetailSheetView.loadMore(cursor: "c3", requested: "c2", loadingMore: false), .ready("c3"),
                       "the merged page moved the cursor on")
        XCTAssertEqual(PluginDetailSheetView.loadMore(cursor: nil, requested: "c2", loadingMore: false), .hidden,
                       "the last page")
    }

    @MainActor
    func testLoadMoreHandsTheCursorToTheHost() throws {
        let s = FlareStrings()
        let paged = PluginViewModel(available: true, title: "接龙", blocks: [.note(PluginNoteBlock(text: "n"))],
                                    nextCursor: "c2")
        var asked: [String] = []
        try PluginDetailSheetView(view: paged, onLoadMore: { asked.append($0) }).inspect()
            .find(button: s.myInviteLoadMore).tap()
        XCTAssertEqual(asked, ["c2"])

        let loading = try PluginDetailSheetView(view: paged, loadingMore: true, onLoadMore: { asked.append($0) })
            .inspect().find(button: s.myInviteLoadMore)
        XCTAssertTrue(loading.isDisabled())
        XCTAssertNoThrow(try loading.labelView().find(ViewType.ProgressView.self), "it spins")

        let last = PluginViewModel(available: true, title: "接龙", blocks: [.note(PluginNoteBlock(text: "n"))])
        XCTAssertThrowsError(try PluginDetailSheetView(view: last, onLoadMore: { asked.append($0) }).inspect()
            .find(button: s.myInviteLoadMore), "no cursor, no key")
    }
}
