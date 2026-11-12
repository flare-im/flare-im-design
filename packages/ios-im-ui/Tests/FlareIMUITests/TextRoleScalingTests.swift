import SwiftUI
import XCTest
@testable import FlareIMUI

final class TextRoleScalingTests: XCTestCase {
    func testUnitScaleKeepsEverySemanticFont() {
        for role in [FlareTextRoles.title, FlareTextRoles.section, FlareTextRoles.body,
                     FlareTextRoles.caption, FlareTextRoles.message] {
            XCTAssertEqual(role.font(scaledBy: 1), role.font)
        }
    }

    func testScaledRolesKeepTheirSemanticWeight() {
        XCTAssertEqual(FlareTextRoles.body.font(scaledBy: 1.5),
                       Font.system(size: FlareTextRoles.body.fontSize * 1.5, weight: .regular))
        XCTAssertEqual(FlareTextRoles.section.font(scaledBy: 2),
                       Font.system(size: FlareTextRoles.section.fontSize * 2, weight: .semibold))
        XCTAssertEqual(FlareTextRoles.title.font(scaledBy: 1.25),
                       Font.system(size: FlareTextRoles.title.fontSize * 1.25, weight: .bold))
        for invalid in [CGFloat.zero, -1, .nan, .infinity] {
            XCTAssertEqual(FlareTextRoles.body.font(scaledBy: invalid), FlareTextRoles.body.font)
        }
    }
}
