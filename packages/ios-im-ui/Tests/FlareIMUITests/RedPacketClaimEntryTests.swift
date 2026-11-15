import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

final class RedPacketClaimEntryTests: XCTestCase {
    @MainActor
    func testOpenLabelStaysOnOneLineInsideTheCoinAndKeepsItsAction() throws {
        var requests = 0
        // ViewInspector expands an unmounted body with default Environment values.
        // English rendering needs a simulator visual check; this test covers sizing and tap semantics.
        let strings = FlareStrings()
        let view = try RedPacketOpenSheet(senderName: "Ann", blessing: "A red packet",
            onOpen: { requests += 1 }, onClose: {}).inspect()
        let label = try view.find(text: strings.packetOpenAction)
        XCTAssertEqual(try label.lineLimit(), 1)
        XCTAssertLessThan(try label.minimumScaleFactor(), 1)
        XCTAssertEqual(try label.fixedWidth(), FlareSizes.componentRedPacketOpenButtonSize)
        let button = try view.find(button: strings.packetOpenAction)
        try button.tap()
        XCTAssertEqual(requests, 1)
    }
}
