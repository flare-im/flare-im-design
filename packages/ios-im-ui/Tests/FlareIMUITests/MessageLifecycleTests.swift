import XCTest
@testable import FlareIMUI

final class MessageLifecycleTests: XCTestCase {
    func testLifecycleProjectsToCompleteVisualStatus() {
        XCTAssertEqual(FlareMessageLifecycle().visualStatus, .sent)
        XCTAssertEqual(FlareMessageLifecycle(transfer: .failed).visualStatus, .failed)
        XCTAssertEqual(FlareMessageLifecycle(read: .read).visualStatus, .read)
        XCTAssertEqual(FlareMessageLifecycle(send: .sending).visualStatus, .sending)
        XCTAssertEqual(FlareMessageLifecycle(delivery: .delivered).visualStatus, .sent,
                       "delivery has no glyph of its own: a single check until it is read")
        XCTAssertEqual(FlareMessageLifecycle(delivery: .partiallyDelivered, read: .read).visualStatus, .read)
        _ = MessageMetaView(timestamp: "14:32", edited: true, status: .read, ephemeral: .burnAfterRead).body
    }
}
