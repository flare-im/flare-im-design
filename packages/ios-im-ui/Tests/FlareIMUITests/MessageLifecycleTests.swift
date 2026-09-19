import XCTest
@testable import FlareIMUI

final class MessageLifecycleTests: XCTestCase {
    func testLifecycleProjectsToCompleteVisualStatus() {
        XCTAssertEqual(FlareMessageLifecycle().visualStatus, .sent)
        XCTAssertEqual(FlareMessageLifecycle(transfer: .failed).visualStatus, .failed)
        XCTAssertEqual(FlareMessageLifecycle(read: .read).visualStatus, .read)
        XCTAssertEqual(FlareMessageLifecycle(send: .sending).visualStatus, .sending)
        XCTAssertEqual(FlareMessageLifecycle(delivery: .delivered).visualStatus, .delivered)
        _ = MessageMetaView(timestamp: "14:32", edited: true, status: .read, ephemeral: .burnAfterRead).body
    }
}
