import SwiftUI
import XCTest
@testable import FlareIMUI

/// The wrapping row several kit bars use: subviews keep their width and move to the next line when it is full.
final class FlareFlowLayoutTests: XCTestCase {
    func testSubviewsStayOnOneLineWhileTheyFit() {
        XCTAssertEqual(FlareFlowLayout.lines([60, 90, 90], maxWidth: 256, spacing: 8), [[0, 1, 2]])
    }

    func testASubviewThatDoesNotFitStartsTheNextLine() {
        XCTAssertEqual(FlareFlowLayout.lines([60, 90, 90, 60, 44], maxWidth: 260, spacing: 8), [[0, 1, 2], [3, 4]])
        // The spacing counts: 60 + 8 + 90 + 8 + 90 is 256.
        XCTAssertEqual(FlareFlowLayout.lines([60, 90, 90], maxWidth: 255, spacing: 8), [[0, 1], [2]])
    }

    func testASubviewWiderThanTheLineStillGetsALineOfItsOwn() {
        XCTAssertEqual(FlareFlowLayout.lines([40, 300, 40], maxWidth: 200, spacing: 8), [[0], [1], [2]])
        XCTAssertEqual(FlareFlowLayout.lines([], maxWidth: 200, spacing: 8), [])
    }
}

#if os(macOS)
import AppKit

/// The batch toolbar on a phone: its keys wrap instead of squeezing their labels into clipped columns, or running
/// past the bar's edge where nobody can reach them.
final class MessageBatchToolbarLayoutTests: XCTestCase {
    /// The size the toolbar asks for when a container `width` wide offers it that width and any height.
    @MainActor
    private func size(at width: CGFloat) -> CGSize {
        _ = NSApplication.shared
        let view = MessageBatchToolbarView(
            selectedIds: ["a", "b"], total: 5,
            capabilities: MessageBatchCapabilities(forwardEach: true, forwardMerged: true, delete: true),
            onAction: { _, _ in }, onSelectAll: {}, onClearSelection: {}, onExit: {})
            .environment(\.locale, Locale(identifier: "zh-Hans"))
        return NSHostingController(rootView: view).sizeThatFits(in: CGSize(width: width, height: 10_000))
    }

    @MainActor
    func testTheKeysWrapOnAPhoneAndStayOnOneLineOnATablet() {
        let tablet = size(at: 700)
        let phone = size(at: 393)
        XCTAssertLessThan(tablet.height, 70, "one line of keys beside the count: \(tablet)")
        // Keys that do not wrap ask for more than the bar has; the last of them ends up past its edge.
        XCTAssertLessThanOrEqual(phone.width, 393, "every key inside the bar: \(phone)")
        XCTAssertGreaterThan(phone.height, tablet.height + 30, "a second line of keys, not labels squeezed into the first: \(phone)")
    }
}
#endif
