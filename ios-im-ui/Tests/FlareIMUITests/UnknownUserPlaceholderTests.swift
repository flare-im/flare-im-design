import XCTest
@testable import FlareIMUI

final class UnknownUserPlaceholderTests: XCTestCase {
    func testEveryKindMapsToItself() {
        for kind in FlareUnknownUserKind.allCases {
            XCTAssertEqual(unknownUserPresentation(kind).kind, kind)
        }
    }

    func testToneAccompaniesTheIcon() {
        XCTAssertEqual(unknownUserPresentation(.unknown).tone, .neutral)
        XCTAssertEqual(unknownUserPresentation(.deactivated).tone, .neutral)
        XCTAssertEqual(unknownUserPresentation(.blocked).tone, .danger)
        XCTAssertEqual(unknownUserPresentation(.unreachable).tone, .warning)
    }

    func testAbsentKindDegradesToUnknown() {
        XCTAssertEqual(unknownUserPresentation(nil), FlareUnknownUserPresentation(.unknown, tone: .neutral))
    }

    func testEachKindHasItsOwnSymbol() {
        let symbols = Set(FlareUnknownUserKind.allCases.map(UnknownUserPlaceholderView.symbol(for:)))
        XCTAssertEqual(symbols.count, FlareUnknownUserKind.allCases.count)
    }

    func testShortIdsSurviveIntactAndAreTrimmed() {
        XCTAssertEqual(shortenUserId("u_42"), "u_42")
        XCTAssertEqual(shortenUserId("  u_42  "), "u_42")
        XCTAssertEqual(shortenUserId(""), "")
        XCTAssertEqual(shortenUserId(nil), "")
    }

    func testIdExactlyAtTheBudgetIsKept() {
        let exact = "0123456789abcdef01234567"
        XCTAssertEqual(exact.count, 24)
        XCTAssertEqual(shortenUserId(exact), exact)
    }

    func testLongIdIsMiddleElidedToTheBudget() {
        let out = shortenUserId("2AW1QQ2SKVWFEPJRXN0123456789abcdef")
        XCTAssertEqual(out.count, 24)
        XCTAssertEqual(out, "2AW1QQ2SKVWF…56789abcdef")
    }

    func testCustomBudgetIsHonouredAndFloored() {
        XCTAssertEqual(shortenUserId("abcdefghijklmnop", maxLength: 10).count, 10)
        XCTAssertEqual(shortenUserId("abcdefghijklmnop", maxLength: 2).count, 8)
    }

    func testTitleIsTheKindTextAndFollowsTextProps() {
        XCTAssertEqual(UnknownUserPlaceholderView(userId: "u1", kind: .unknown).title, "未知用户")
        XCTAssertEqual(UnknownUserPlaceholderView(userId: "u1", kind: .deactivated).title, "该账号已注销")
        XCTAssertEqual(UnknownUserPlaceholderView(userId: "u1", kind: .blocked).title, "该账号已被屏蔽")
        XCTAssertEqual(UnknownUserPlaceholderView(userId: "u1", kind: .unreachable).title, "暂时无法联系该账号")
        XCTAssertEqual(
            UnknownUserPlaceholderView(userId: "u1", kind: .unknown, unknownText: "Unknown user").title,
            "Unknown user"
        )
    }

    func testAccessibilityTextLeadsWithTheReasonAndTrailsWithTheId() {
        let view = UnknownUserPlaceholderView(userId: "  u_2AW1QQ2SKVWFEPJRXN  ",
                                              kind: .deactivated,
                                              detail: "来自群成员列表")
        XCTAssertEqual(view.accessibilityText, "该账号已注销 · 来自群成员列表 · ID u_2AW1QQ2SKVWFEPJRXN")
        XCTAssertTrue(view.accessibilityText.hasPrefix("该账号已注销"))
    }

    func testBlankIdLeavesTheDiagnosticSlotOut() {
        let view = UnknownUserPlaceholderView(userId: "   ", kind: .unknown)
        XCTAssertEqual(view.accessibilityText, "未知用户")
        XCTAssertEqual(shortenUserId("   "), "")
    }
}
