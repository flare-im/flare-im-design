import XCTest
@testable import FlareIMUI

final class ConversationWorkspaceTests: XCTestCase {
    func testPaneRenderMapsEveryStatus() {
        XCTAssertEqual(FlareWorkspacePaneStatus.allCases.map { paneRender(FlareWorkspacePaneState(status: $0)) },
                       [.content, .skeleton, .empty, .failure])
    }

    func testPaneRenderDegradesMissingStateToContent() {
        XCTAssertEqual(paneRender(nil), .content)
        XCTAssertEqual(paneRender(FlareWorkspacePaneState()), .content)
        XCTAssertEqual(paneRender(FlareWorkspacePaneState(message: "只有文案")), .content)
    }

    func testLoadingNeverResolvesToEmpty() {
        XCTAssertNotEqual(paneRender(FlareWorkspacePaneState(status: .loading)), .empty)
        XCTAssertEqual(paneRender(FlareWorkspacePaneState(status: .loading)), .skeleton)
    }

    func testPaneRetryVisibleNeedsFailureLabelAndHandler() {
        for status in FlareWorkspacePaneStatus.allCases {
            for label in [nil, "", "   ", "重试"] as [String?] {
                for hasRetry in [false, true] {
                    let expected = status == .failure && label == "重试" && hasRetry
                    XCTAssertEqual(
                        paneRetryVisible(FlareWorkspacePaneState(status: status, actionLabel: label), hasRetry: hasRetry),
                        expected,
                        "status=\(status) label=\(String(describing: label)) hasRetry=\(hasRetry)")
                }
            }
        }
    }

    func testFailureWithoutHandlerOrLabelShowsReasonOnly() {
        let failed = FlareWorkspacePaneState(status: .failure, message: "网络中断", actionLabel: "重试")
        XCTAssertEqual(paneRender(failed), .failure)
        XCTAssertFalse(paneRetryVisible(failed, hasRetry: false))
        XCTAssertFalse(paneRetryVisible(FlareWorkspacePaneState(status: .failure, message: "网络中断"), hasRetry: true))
        XCTAssertFalse(paneRetryVisible(nil, hasRetry: true))
    }

    func testPanesAreIndependent() {
        let list = FlareWorkspacePaneState()
        let chat = FlareWorkspacePaneState(status: .failure, message: "消息加载失败", actionLabel: "重试")
        let detail = FlareWorkspacePaneState(status: .loading)
        XCTAssertEqual(paneRender(list), .content)
        XCTAssertEqual(paneRender(chat), .failure)
        XCTAssertEqual(paneRender(detail), .skeleton)
        XCTAssertFalse(paneRetryVisible(list, hasRetry: true))
        XCTAssertTrue(paneRetryVisible(chat, hasRetry: true))
        XCTAssertFalse(paneRetryVisible(detail, hasRetry: true))
    }

    func testWorkspaceBannerVisible() {
        XCTAssertFalse(workspaceBannerVisible(nil))
        XCTAssertFalse(workspaceBannerVisible(FlareWorkspaceBanner(message: "")))
        XCTAssertFalse(workspaceBannerVisible(FlareWorkspaceBanner(message: "   ")))
        XCTAssertFalse(workspaceBannerVisible(FlareWorkspaceBanner(message: "\n\t ")))
        XCTAssertTrue(workspaceBannerVisible(FlareWorkspaceBanner(message: "网络已断开")))
    }

    func testBannerCoexistsWithReadablePane() {
        let banner = FlareWorkspaceBanner(message: "离线，显示的是缓存内容", tone: .warning)
        XCTAssertTrue(workspaceBannerVisible(banner))
        XCTAssertEqual(paneRender(FlareWorkspacePaneState()), .content)
    }

    func testWorkspaceBannerActionVisible() {
        let withLabel = FlareWorkspaceBanner(message: "离线", actionLabel: "重连")
        XCTAssertTrue(workspaceBannerActionVisible(withLabel, hasAction: true))
        XCTAssertFalse(workspaceBannerActionVisible(withLabel, hasAction: false))
        XCTAssertFalse(workspaceBannerActionVisible(FlareWorkspaceBanner(message: "离线", actionLabel: "  "), hasAction: true))
        XCTAssertFalse(workspaceBannerActionVisible(FlareWorkspaceBanner(message: "离线"), hasAction: true))
        XCTAssertFalse(workspaceBannerActionVisible(FlareWorkspaceBanner(message: "  ", actionLabel: "重连"), hasAction: true))
        XCTAssertFalse(workspaceBannerActionVisible(nil, hasAction: true))
    }

    func testWorkspaceBannerToneMapsErrorToDanger() {
        XCTAssertEqual(FlareWorkspaceBannerTone.allCases.map { workspaceBannerTone($0) },
                       [.info, .warning, .danger, .success])
        XCTAssertEqual(workspaceBannerTone(nil), .info)
    }

    func testPaneSkeletonVariantPerPane() {
        XCTAssertEqual(FlareWorkspacePaneKey.allCases.map { paneSkeletonVariant($0) },
                       [.conversation, .message, .profile])
    }
}
