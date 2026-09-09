import XCTest
@testable import FlareIMUI
final class TransferProgressTests: XCTestCase {
    func testRecoveryAndCompletedActions() {
        XCTAssertEqual(FlareTransferState.failed.actions, [.retry])
        XCTAssertEqual(FlareTransferState.completed.actions, [.open])
        XCTAssertEqual(FlareTransferState.transferring.actions, [.pause, .cancel])
        XCTAssertEqual(FlareTransferState.paused.actions, [.resume, .cancel])
        XCTAssertEqual(FlareTransferState.queued.actions, [.cancel])
        XCTAssertEqual(FlareTransferState.cancelled.actions, [.retry])
    }
    func testMeasuredProgress() {
        XCTAssertNil(FlareTransferState.transferring.normalizedProgress(.nan))
        XCTAssertNil(FlareTransferState.transferring.normalizedProgress(nil))
        XCTAssertEqual(FlareTransferState.transferring.normalizedProgress(0), 0)
        XCTAssertEqual(FlareTransferState.transferring.normalizedProgress(2), 1)
        XCTAssertEqual(FlareTransferState.completed.normalizedProgress(nil), 1)
    }
}
