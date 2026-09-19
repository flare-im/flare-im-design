import XCTest
@testable import FlareIMUI

final class MessageContentContractTests: XCTestCase {
    func testMessageContentProjectionCoversRCKinds() {
        XCTAssertEqual(FlareMessageContentKind.allCases.count, 26)
        XCTAssertEqual(resolveMessageContentContract(.multiImage).wireType, "image_group")
        XCTAssertNil(resolveMessageContentContract(.readOnce).wireType)
        XCTAssertTrue(FlareMessageContentKind.code.capabilities.contains(.horizontalScroll))
    }
}
