import XCTest
@testable import FlareIMUI

private let hint = "当前版本无法显示这条消息"
private let unsupported = "不支持的消息类型"

final class UnknownMessageTests: XCTestCase {
    func testSummaryWinsAsBody() {
        let p = unknownMessagePresentation(contentType: "flare.poll.v2", summary: "[投票] 周会时间",
                                           hint: hint, unsupportedText: unsupported)
        XCTAssertEqual(p.body, "[投票] 周会时间")
        XCTAssertTrue(p.hasSummary)
    }

    func testBlankSummaryFallsBackToHint() {
        let p = unknownMessagePresentation(contentType: "flare.poll.v2", summary: "   ",
                                           hint: hint, unsupportedText: unsupported)
        XCTAssertEqual(p.body, hint)
        XCTAssertFalse(p.hasSummary)
    }

    func testTitleUsesLabelThenGenericWording() {
        XCTAssertEqual(unknownMessagePresentation(label: "投票", hint: hint, unsupportedText: unsupported).title, "投票")
        XCTAssertEqual(unknownMessagePresentation(label: "  ", hint: hint, unsupportedText: unsupported).title, unsupported)
    }

    func testRawTypeStaysDiagnosticNeverBody() {
        let p = unknownMessagePresentation(contentType: "flare.poll.v2", hint: hint, unsupportedText: unsupported)
        XCTAssertEqual(p.diagnostic, "flare.poll.v2")
        XCTAssertEqual(p.body, hint)
    }

    func testMissingOrBlankTypeYieldsNoDiagnostic() {
        XCTAssertEqual(unknownMessagePresentation(hint: hint, unsupportedText: unsupported).diagnostic, "")
        XCTAssertEqual(unknownMessagePresentation(contentType: "  ", hint: hint, unsupportedText: unsupported).diagnostic, "")
    }

    func testEveryInputIsTrimmed() {
        let p = unknownMessagePresentation(contentType: " x.y ", label: " 投票 ", summary: " hi ",
                                           hint: hint, unsupportedText: unsupported)
        XCTAssertEqual([p.title, p.body, p.diagnostic], ["投票", "hi", "x.y"])
    }

    func testViewConstructs() {
        _ = UnknownMessageView(contentType: "flare.poll.v2")
        _ = UnknownMessageView(contentType: "flare.poll.v2", label: "投票", summary: "s",
                               isSelf: true, actionText: "了解详情", onAction: {})
    }
}
