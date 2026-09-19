import XCTest
@testable import FlareIMUI

/// DoD 18 — the state matrix `WorkspaceFrameView` and `ConversationWorkspaceView`
/// now share. SwiftUI cannot be mounted in this test target, so this pins the
/// resolution both surfaces feed into `WorkspacePaneView`.
final class WorkspaceStateMatrixTests: XCTestCase {
    private let statuses: [FlareWorkspacePaneStatus] = [.ready, .loading, .empty, .failure]

    func testEveryStatusResolvesToOneRender() {
        XCTAssertEqual(statuses.map { paneRender(FlareWorkspacePaneState(status: $0)) },
                       [.content, .skeleton, .empty, .failure])
        // A pane with no state at all is the host's content, never a blank.
        XCTAssertEqual(paneRender(nil), .content)
    }

    func testOnlyAFailureOffersRetryAndOnlyAnEmptyOffersTheNextStep() {
        for status in statuses {
            let state = FlareWorkspacePaneState(status: status, actionLabel: "Do it")
            XCTAssertEqual(paneRetryVisible(state, hasRetry: true), status == .failure, "retry for \(status)")
            XCTAssertEqual(paneEmptyActionVisible(state, hasAction: true), status == .empty, "empty action for \(status)")
        }
    }

    func testAnActionNeedsBothALabelAndAHandler() {
        let failure = FlareWorkspacePaneState(status: .failure, actionLabel: "Retry")
        XCTAssertFalse(paneRetryVisible(failure, hasRetry: false), "no handler, no button")
        XCTAssertFalse(paneRetryVisible(FlareWorkspacePaneState(status: .failure, actionLabel: "  "), hasRetry: true),
                       "blank label, no button")
        XCTAssertTrue(paneRetryVisible(failure, hasRetry: true))

        let empty = FlareWorkspacePaneState(status: .empty, actionLabel: "Add a device")
        XCTAssertFalse(paneEmptyActionVisible(empty, hasAction: false))
        XCTAssertTrue(paneEmptyActionVisible(empty, hasAction: true))
    }

    func testTheBannerIsIndependentOfEveryPane() {
        XCTAssertFalse(workspaceBannerVisible(nil))
        XCTAssertFalse(workspaceBannerVisible(FlareWorkspaceBanner(message: "   ")))
        XCTAssertTrue(workspaceBannerVisible(FlareWorkspaceBanner(message: "Offline")))
        XCTAssertEqual(workspaceBannerTone(.warning), .warning)
        XCTAssertEqual(workspaceBannerTone(.error), .danger)
    }

    func testTheFrameCarriesGenericCopy() {
        // A frame that also hosts contacts and settings must not say "conversation".
        let strings = FlareStrings()
        for text in [strings.workspaceFrameLoading, strings.workspaceFrameEmpty, strings.workspaceFrameFailure] {
            XCTAssertFalse(text.trimmingCharacters(in: .whitespaces).isEmpty, "frame copy is set")
            XCTAssertFalse(text.contains("会话"), "frame copy stays generic: \(text)")
        }
    }

    func testTheFrameKeepsOneStatePerPane() {
        let state = FlareWorkspaceState(
            primary: FlareWorkspacePaneState(status: .loading),
            content: FlareWorkspacePaneState(status: .failure, message: "Network down"),
            detail: FlareWorkspacePaneState(status: .empty)
        )
        // Panes are independent: a failing content pane never degrades the others.
        XCTAssertEqual(paneRender(state.pane(.primary)), .skeleton)
        XCTAssertEqual(paneRender(state.pane(.content)), .failure)
        XCTAssertEqual(paneRender(state.pane(.detail)), .empty)
    }
}
