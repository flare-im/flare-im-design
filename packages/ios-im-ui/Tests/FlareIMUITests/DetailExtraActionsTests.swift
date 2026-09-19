import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// FR-046: a report action lived outside the kit's detail pages. The host declares it now and the
/// kit draws it in place, reporting the id back.
final class DetailExtraActionsTests: XCTestCase {
    @MainActor
    func testAContactDetailDrawsHostActionsAndReportsTheId() throws {
        var reported: [String] = []
        let view = FlareContactDetail(
            contact: Contact(id: "u1", name: "Ada Chen"),
            extraActions: [
                FlareDetailExtraAction(id: "report", label: "举报", danger: true),
                FlareDetailExtraAction(id: "share", label: "分享名片"),
            ],
            onExtraAction: { reported.append($0) })

        try view.inspect().find(button: "举报").tap()
        XCTAssertNoThrow(try view.inspect().find(button: "分享名片"))
        XCTAssertEqual(reported, ["report"])
    }

    @MainActor
    func testAContactDetailWithoutThemDrawsNone() throws {
        let view = FlareContactDetail(contact: Contact(id: "u1", name: "Ada Chen"))
        XCTAssertThrowsError(try view.inspect().find(button: "举报"))
    }
}
