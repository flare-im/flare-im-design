import SwiftUI
import XCTest
@testable import FlareIMUI

/// Toast queue and confirmation contract of ``FlareFeedback`` (Vue `createFlareFeedback` parity),
/// plus the hand-off to the kit's layers (bottom sheets, Modals, Drawers).
final class FlareFeedbackTests: XCTestCase {
    @MainActor
    private func waitForRequest(_ feedback: FlareFeedback, titled title: String? = nil) async {
        for _ in 0..<1_000 where feedback.confirmRequest == nil || (title != nil && feedback.confirmRequest?.options.title != title) {
            await Task.yield()
        }
    }

    // MARK: Toasts

    @MainActor
    func testToastQueueKeepsTheNewestThree() {
        let feedback = FlareFeedback(announce: { _ in })
        for index in 1...4 { feedback.toast("t\(index)", duration: 0) }
        XCTAssertEqual(FlareFeedback.toastLimit, 3)
        XCTAssertEqual(feedback.toasts.map(\.message), ["t2", "t3", "t4"])
    }

    func testToastDurationsFollowTheTone() {
        XCTAssertEqual(FlareFeedback.toastDuration(variant: .info, tone: nil, duration: nil), 4)
        XCTAssertEqual(FlareFeedback.toastDuration(variant: .success, tone: nil, duration: nil), 4)
        XCTAssertEqual(FlareFeedback.toastDuration(variant: .error, tone: nil, duration: nil), 6)
        XCTAssertEqual(FlareFeedback.toastDuration(variant: .info, tone: .danger, duration: nil), 6)
        // The tone wins over the variant, as it does for the toast's look; loading never reads as danger.
        XCTAssertEqual(FlareFeedback.toastDuration(variant: .error, tone: .success, duration: nil), 4)
        XCTAssertEqual(FlareFeedback.toastDuration(variant: .loading, tone: .danger, duration: nil), 4)
        XCTAssertEqual(FlareFeedback.toastDuration(variant: .error, tone: nil, duration: 0), 0)
        XCTAssertEqual(FlareFeedback.toastDuration(variant: .info, tone: nil, duration: 1.5), 1.5)
    }

    @MainActor
    func testTimedToastDismissesItselfAndZeroDurationStays() async throws {
        let feedback = FlareFeedback(announce: { _ in })
        feedback.toast("brief", duration: 0.05)
        feedback.toast("sticky", duration: 0)
        try await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(feedback.toasts.map(\.message), ["sticky"])
    }

    @MainActor
    func testDismissHandleRemovesOnlyItsToast() {
        let feedback = FlareFeedback(announce: { _ in })
        let dismissFirst = feedback.toast("a", duration: 0)
        feedback.toast("b", duration: 0)
        dismissFirst()
        XCTAssertEqual(feedback.toasts.map(\.message), ["b"])
        dismissFirst()
        XCTAssertEqual(feedback.toasts.map(\.message), ["b"])
        if let close = feedback.toasts.first?.id { feedback.dismissToast(close) }
        XCTAssertTrue(feedback.toasts.isEmpty)
    }

    @MainActor
    func testToastActionRunsOnceAndDismisses() throws {
        let feedback = FlareFeedback(announce: { _ in })
        var runs = 0
        feedback.toast("Deleted", actionLabel: "Undo", action: { runs += 1 }, duration: 0)
        let entry = try XCTUnwrap(feedback.toasts.first)
        XCTAssertEqual(entry.actionLabel, "Undo")
        feedback.runToastAction(entry.id)
        feedback.runToastAction(entry.id)
        XCTAssertEqual(runs, 1)
        XCTAssertTrue(feedback.toasts.isEmpty)
        // A label without an action draws no action button.
        feedback.toast("Saved", actionLabel: "Undo", duration: 0)
        XCTAssertNil(feedback.toasts.first?.actionLabel)
    }

    @MainActor
    func testToastMessageIsAnnounced() {
        var announced: [String] = []
        let feedback = FlareFeedback(announce: { announced.append($0) })
        feedback.toast("Report sent", variant: .success)
        XCTAssertEqual(announced, ["Report sent"])
    }

    // MARK: Confirmations

    @MainActor
    func testConfirmRunsTheActionBusyAndResolvesTrue() async {
        let feedback = FlareFeedback(announce: { _ in })
        var busyDuringAction: Bool?
        let answer = Task {
            await feedback.confirm(FlareConfirmOptions(title: "Recall", description: "Recall this message?",
                                                       action: { busyDuringAction = feedback.confirmRequest?.busy }))
        }
        await waitForRequest(feedback)
        XCTAssertEqual(feedback.confirmRequest?.busy, false)
        await feedback.accept()
        let confirmed = await answer.value
        XCTAssertTrue(confirmed)
        XCTAssertEqual(busyDuringAction, true)
        XCTAssertNil(feedback.confirmRequest)
    }

    @MainActor
    func testFailedActionKeepsTheDialogOpenForRetry() async {
        struct RecallFailed: LocalizedError { var errorDescription: String? { "Recall failed" } }
        let feedback = FlareFeedback(announce: { _ in })
        var attempts = 0
        let answer = Task {
            await feedback.confirm(FlareConfirmOptions(title: "Recall", description: "", action: {
                attempts += 1
                if attempts == 1 { throw RecallFailed() }
            }))
        }
        await waitForRequest(feedback)
        await feedback.accept()
        XCTAssertEqual(feedback.confirmRequest?.error, "Recall failed")
        XCTAssertEqual(feedback.confirmRequest?.busy, false)
        await feedback.accept()
        let confirmed = await answer.value
        XCTAssertTrue(confirmed)
        XCTAssertEqual(attempts, 2)
        XCTAssertNil(feedback.confirmRequest)
    }

    @MainActor
    func testCancelResolvesFalseWithoutRunningTheAction() async {
        let feedback = FlareFeedback(announce: { _ in })
        var ran = false
        let answer = Task {
            await feedback.confirm(FlareConfirmOptions(title: "Delete", description: "", action: { ran = true }))
        }
        await waitForRequest(feedback)
        feedback.cancel()
        let confirmed = await answer.value
        XCTAssertFalse(confirmed)
        XCTAssertFalse(ran)
        XCTAssertNil(feedback.confirmRequest)
    }

    @MainActor
    func testNewerRequestReplacesAnIdleOne() async {
        let feedback = FlareFeedback(announce: { _ in })
        let first = Task { await feedback.confirm(FlareConfirmOptions(title: "First", description: "")) }
        await waitForRequest(feedback, titled: "First")
        let second = Task { await feedback.confirm(FlareConfirmOptions(title: "Second", description: "")) }
        await waitForRequest(feedback, titled: "Second")
        let firstAnswer = await first.value
        XCTAssertFalse(firstAnswer)
        // Without an action, confirming resolves true at once.
        await feedback.accept()
        let secondAnswer = await second.value
        XCTAssertTrue(secondAnswer)
    }

    @MainActor
    func testRequestWhileBusyResolvesFalseAtOnce() async {
        let feedback = FlareFeedback(announce: { _ in })
        var release: CheckedContinuation<Void, Never>?
        let first = Task {
            await feedback.confirm(FlareConfirmOptions(title: "Leave", description: "", action: {
                await withCheckedContinuation { release = $0 }
            }))
        }
        await waitForRequest(feedback)
        let accepting = Task { await feedback.accept() }
        for _ in 0..<1_000 where release == nil { await Task.yield() }
        XCTAssertEqual(feedback.confirmRequest?.busy, true)
        let overlapping = await feedback.confirm(FlareConfirmOptions(title: "Other", description: ""))
        XCTAssertFalse(overlapping)
        feedback.cancel()
        XCTAssertEqual(feedback.confirmRequest?.options.title, "Leave", "cancel is ignored while the action runs")
        release?.resume()
        await accepting.value
        let confirmed = await first.value
        XCTAssertTrue(confirmed)
    }

    // MARK: Kit bottom sheets

    @MainActor
    func testToastsShowAboveTheNewestOpenSheetAndWaitWhileItCloses() {
        let feedback = FlareFeedback(announce: { _ in })
        let outer = UUID(), inner = UUID()
        XCTAssertEqual(feedback.toastPresenter, .host)
        feedback.layerPresented(outer, kind: .sheet)
        XCTAssertEqual(feedback.toastPresenter, .layer(outer))
        feedback.layerPresented(inner, kind: .sheet)
        XCTAssertEqual(feedback.toastPresenter, .layer(inner))
        feedback.layerClosing(inner)
        XCTAssertEqual(feedback.toastPresenter, .waiting)
        feedback.layerDismissed(inner)
        XCTAssertEqual(feedback.toastPresenter, .layer(outer))
        feedback.layerClosing(outer)
        feedback.layerDismissed(outer)
        XCTAssertEqual(feedback.toastPresenter, .host)
    }

    @MainActor
    func testConfirmationWaitsUntilNoKitSheetIsOnScreenAndASwipeCancelsIt() async {
        let feedback = FlareFeedback(announce: { _ in })
        let sheet = UUID()
        // A host closes its sheet and asks in the same turn: the sheet has not reported closing yet.
        feedback.layerPresented(sheet, kind: .sheet)
        let answer = Task { await feedback.confirm(FlareConfirmOptions(title: "Recall", description: "")) }
        await waitForRequest(feedback)
        XCTAssertEqual(feedback.confirmPresenter, .waiting)
        XCTAssertFalse(feedback.hostConfirmPresented.wrappedValue)
        feedback.layerClosing(sheet)
        XCTAssertFalse(feedback.hostConfirmPresented.wrappedValue)
        // Dropping a presentation the host does not own does not cancel the request.
        feedback.hostConfirmPresented.wrappedValue = false
        XCTAssertNotNil(feedback.confirmRequest)
        feedback.layerDismissed(sheet)
        XCTAssertEqual(feedback.confirmPresenter, .host)
        XCTAssertTrue(feedback.hostConfirmPresented.wrappedValue)
        // A swipe down on the shown dialog cancels.
        feedback.hostConfirmPresented.wrappedValue = false
        let confirmed = await answer.value
        XCTAssertFalse(confirmed)
    }

    // MARK: Layer stack (sheets, Modals, Drawers)

    @MainActor
    private func waitForPrompt(_ feedback: FlareFeedback) async {
        for _ in 0..<1_000 where feedback.promptRequest == nil { await Task.yield() }
    }

    @MainActor
    func testToastsGoToTheTopmostLayerOfAnyKind() {
        let feedback = FlareFeedback(announce: { _ in })
        let sheet = UUID(), drawer = UUID(), modal = UUID()
        feedback.layerPresented(sheet, kind: .sheet)
        feedback.layerPresented(drawer, kind: .drawer)
        XCTAssertEqual(feedback.toastPresenter, .layer(drawer))
        feedback.layerPresented(modal, kind: .modal)
        XCTAssertEqual(feedback.toastPresenter, .layer(modal))
        feedback.layerClosing(modal)
        XCTAssertEqual(feedback.toastPresenter, .waiting, "nothing draws toasts on a layer on its way out")
        feedback.layerDismissed(modal)
        XCTAssertEqual(feedback.toastPresenter, .layer(drawer))
        feedback.layerClosing(drawer)
        XCTAssertEqual(feedback.toastPresenter, .waiting)
        feedback.layerDismissed(drawer)
        XCTAssertEqual(feedback.toastPresenter, .layer(sheet))
        feedback.layerDismissed(sheet)
        XCTAssertEqual(feedback.toastPresenter, .host)
    }

    @MainActor
    func testConfirmationWaitsWhileTheTopmostIsASheetOrModalAndShowsFromAnOpenDrawer() {
        let feedback = FlareFeedback(announce: { _ in })
        for kind in [FlareLayerKind.sheet, .modalFromBottomSheet, .modal] {
            let layer = UUID()
            feedback.layerPresented(layer, kind: kind)
            XCTAssertEqual(feedback.confirmPresenter, .waiting, "\(kind) on top: wait until it is gone")
            feedback.layerDismissed(layer)
            XCTAssertEqual(feedback.confirmPresenter, .host)
        }
        let drawer = UUID(), sheet = UUID()
        feedback.layerPresented(drawer, kind: .drawer)
        XCTAssertEqual(feedback.confirmPresenter, .layer(drawer), "an open Drawer presents it itself")
        // A sheet opened from the drawer: wait for it, then the drawer asks again.
        feedback.layerPresented(sheet, kind: .sheet)
        XCTAssertEqual(feedback.confirmPresenter, .waiting)
        feedback.layerClosing(sheet)
        XCTAssertEqual(feedback.confirmPresenter, .waiting)
        feedback.layerDismissed(sheet)
        XCTAssertEqual(feedback.confirmPresenter, .layer(drawer))
        // A closing drawer never presents.
        feedback.layerClosing(drawer)
        XCTAssertEqual(feedback.confirmPresenter, .waiting)
        feedback.layerDismissed(drawer)
        XCTAssertEqual(feedback.confirmPresenter, .host)
    }

    @MainActor
    func testADrawerShowsTheConfirmationAndDismissingItCancels() async {
        let feedback = FlareFeedback(announce: { _ in })
        let drawer = UUID()
        feedback.layerPresented(drawer, kind: .drawer)
        let answer = Task { await feedback.confirm(FlareConfirmOptions(title: "Leave", description: "")) }
        await waitForRequest(feedback)
        XCTAssertTrue(feedback.confirmPresented(by: .layer(drawer)).wrappedValue)
        XCTAssertFalse(feedback.hostConfirmPresented.wrappedValue, "the host stays out while the drawer asks")
        // Another layer's presenter dropping it changes nothing.
        feedback.confirmPresented(by: .layer(UUID())).wrappedValue = false
        XCTAssertNotNil(feedback.confirmRequest)
        // The scrim or a swipe on the drawer's confirmation cancels it.
        feedback.confirmPresented(by: .layer(drawer)).wrappedValue = false
        let confirmed = await answer.value
        XCTAssertFalse(confirmed)
    }

    @MainActor
    func testAConfirmationAskedFromAClosingDrawerMovesToTheHost() async {
        let feedback = FlareFeedback(announce: { _ in })
        let drawer = UUID()
        feedback.layerPresented(drawer, kind: .drawer)
        let answer = Task { await feedback.confirm(FlareConfirmOptions(title: "Block", description: "")) }
        await waitForRequest(feedback)
        feedback.layerClosing(drawer)
        XCTAssertFalse(feedback.confirmPresented(by: .layer(drawer)).wrappedValue)
        // The drawer dropping its presentation on the way out leaves the request waiting.
        feedback.confirmPresented(by: .layer(drawer)).wrappedValue = false
        XCTAssertNotNil(feedback.confirmRequest)
        feedback.layerDismissed(drawer)
        XCTAssertTrue(feedback.hostConfirmPresented.wrappedValue)
        await feedback.accept()
        let confirmed = await answer.value
        XCTAssertTrue(confirmed)
    }

    @MainActor
    func testPromptsFollowTheSameRouting() async {
        let feedback = FlareFeedback(announce: { _ in })
        let modal = UUID(), drawer = UUID()
        feedback.layerPresented(drawer, kind: .drawer)
        feedback.layerPresented(modal, kind: .modalFromBottomSheet)
        let answer = Task { await feedback.prompt(FlarePromptOptions(title: "Remark", initialValue: "Ann")) }
        await waitForPrompt(feedback)
        XCTAssertFalse(feedback.promptPresented(by: .layer(drawer)).wrappedValue, "waits for the Modal above")
        XCTAssertFalse(feedback.hostPromptPresented.wrappedValue)
        feedback.layerClosing(modal)
        feedback.layerDismissed(modal)
        XCTAssertTrue(feedback.promptPresented(by: .layer(drawer)).wrappedValue)
        feedback.promptPresented(by: .layer(drawer)).wrappedValue = false
        let value = await answer.value
        XCTAssertNil(value)
    }

    @MainActor
    func testAReopenedLayerStopsClosingKeepsItsPlaceAndTakesItsNewKind() {
        let feedback = FlareFeedback(announce: { _ in })
        let lower = UUID(), upper = UUID()
        feedback.layerPresented(lower, kind: .sheet)
        feedback.layerPresented(upper, kind: .modal)
        feedback.layerClosing(lower)
        feedback.layerPresented(lower, kind: .modalFromBottomSheet)
        XCTAssertEqual(feedback.layers.map(\.id), [lower, upper])
        XCTAssertEqual(feedback.layers.first?.closing, false)
        XCTAssertEqual(feedback.layers.first?.kind, .modalFromBottomSheet)
        // Presenting twice registers once.
        feedback.layerPresented(upper, kind: .modal)
        XCTAssertEqual(feedback.layers.count, 2)
        // Unknown ids are ignored.
        feedback.layerClosing(UUID())
        feedback.layerDismissed(UUID())
        XCTAssertEqual(feedback.layers.count, 2)
    }

    #if os(macOS)
    @MainActor
    func testTheHostPublishesItsLiveFormFactor() {
        final class Seen { var compact: [Bool] = [] }
        struct Probe: View {
            @Environment(\.flareCompactOverlays) private var compact
            let seen: Seen
            var body: some View {
                seen.compact.append(compact)
                return Color.clear
            }
        }
        func render(width: CGFloat) -> Bool? {
            let seen = Seen()
            let size = CGSize(width: width, height: 700)
            let host = NSHostingView(rootView: Probe(seen: seen).flareFeedbackHost(FlareFeedback(announce: { _ in }))
                .frame(width: size.width, height: size.height))
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                                  backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            defer { window.close() }
            window.contentView = host
            host.setFrameSize(size)
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.2))
            host.layoutSubtreeIfNeeded()
            return seen.compact.last
        }
        XCTAssertEqual(render(width: 390), true)
        XCTAssertEqual(render(width: 1024), false)
    }
    #endif

    func testSheetDetentFitsTheMeasuredContent() {
        XCTAssertEqual(FlareBottomSheetFrame<EmptyView>.detents(forHeight: 0), [.medium])
        XCTAssertEqual(FlareBottomSheetFrame<EmptyView>.detents(forHeight: 320), [.height(320)])
    }

    #if os(macOS)
    @MainActor
    func testSheetContentIsHostedSoFormSheetsLeaveDetentsToThePresenter() {
        final class Seen { var hosted: [Bool] = [] }
        struct Probe: View {
            @Environment(\.flareBottomSheetHosted) private var hosted
            let seen: Seen
            var body: some View {
                seen.hosted.append(hosted)
                return Color.clear.frame(height: 120)
            }
        }
        func render<Content: View>(_ view: Content) {
            let host = NSHostingView(rootView: view.frame(width: 390, height: 844))
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 390, height: 844),
                                  styleMask: .borderless, backing: .buffered, defer: false)
            window.contentView = host
            host.layoutSubtreeIfNeeded()
        }
        let inSheet = Seen(), outside = Seen()
        render(FlareBottomSheetFrame(title: "Report", presence: UUID()) { Probe(seen: inSheet) })
        render(Probe(seen: outside))
        XCTAssertEqual(inSheet.hosted.last, true)
        XCTAssertEqual(outside.hosted.last, false)
    }
    #endif

    @MainActor
    func testHostSheetAndEnvironmentBuild() {
        let feedback = FlareFeedback()
        var environment = EnvironmentValues()
        XCTAssertNil(environment.flareFeedback)
        environment.flareFeedback = feedback
        XCTAssertTrue(environment.flareFeedback === feedback)
        _ = Text("root").flareFeedbackHost(feedback)
        _ = Text("chat").flareBottomSheet(item: .constant(Contact?.none), title: "Actions") { contact in Text(contact.name) }
        _ = BottomSheetView(title: "Actions") { Text("Copy") }.body
        _ = BottomSheetView { Text("Copy") }.body
        _ = BottomSheetView(title: "Actions", titleHidden: true, maxHeight: 400) { Text("Copy") }.body
    }
}
