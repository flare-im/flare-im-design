import XCTest
@testable import FlareIMUI

final class ConversationBatchToolbarTests: XCTestCase {
    private let caps = ConversationBatchCapabilities(markRead: true, mute: true, delete: true)

    func testAvailableActionsFollowCapabilitiesInCanonicalOrder() {
        XCTAssertEqual(batchActionsAvailable(["a", "b"], caps, false), [.markRead, .mute, .delete])
        XCTAssertEqual(batchActionsAvailable(["a"], ConversationBatchCapabilities(archive: true, delete: true), false), [.archive, .delete])
    }

    func testAvailableActionsEmptyWhenIdleBusyUncapableOrOverLimit() {
        XCTAssertEqual(batchActionsAvailable([], caps, false), [])
        XCTAssertEqual(batchActionsAvailable(["a"], caps, true), [])
        XCTAssertEqual(batchActionsAvailable(["a"], ConversationBatchCapabilities(), false), [])
        XCTAssertEqual(batchActionsAvailable(["a"], nil, false), [])
        XCTAssertEqual(batchActionsAvailable(["a", "b", "c"], caps, false, 2), [])
        XCTAssertEqual(batchActionsAvailable(["a", "b"], caps, false, 2).count, 3)
        XCTAssertEqual(batchActionsAvailable(["a", "b", "c"], caps, false, 0).count, 3)
        XCTAssertTrue(batchSelectionExceeded(3, 2))
        XCTAssertFalse(batchSelectionExceeded(2, 2))
        XCTAssertFalse(batchSelectionExceeded(3, nil))
    }

    func testSummaryKeepsSuccessesAndDeduplicatesRetryIds() {
        let result = ConversationBatchResult(succeeded: ["a", "b"], failed: [
            ConversationBatchFailure(id: "d", title: "设计群", reason: "无权限"),
            ConversationBatchFailure(id: "d", title: "设计群", reason: "再次失败"),
            ConversationBatchFailure(id: "", title: "未知", reason: "无 ID"),
            ConversationBatchFailure(id: "e", title: "客服", reason: "网络中断"),
        ])
        XCTAssertEqual(summarizeBatchResult(result), ConversationBatchSummary(succeededCount: 2, failedCount: 4, retryIds: ["d", "e"]))
        XCTAssertEqual(summarizeBatchResult(nil), ConversationBatchSummary(succeededCount: 0, failedCount: 0, retryIds: []))
    }

    func testViewConstructsWithAllStates() {
        let result = ConversationBatchResult(succeeded: ["a"], failed: [ConversationBatchFailure(id: "b", title: "b", reason: "r")])
        _ = ConversationBatchToolbarView(selectedIds: [], capabilities: caps).body
        _ = ConversationBatchToolbarView(selectedIds: ["a", "b"], capabilities: caps, busy: true, result: result, maxSelection: 1,
                                         onAction: { _, _ in }, onRetryFailed: { _ in }, onClearSelection: {}, onDismissResult: {}).body
    }
}
