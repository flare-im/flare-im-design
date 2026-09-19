import XCTest
@testable import FlareIMUI

/// K1 (FR-096): one connection notice for every app — the wording, tone, pulse and way back per phase.
/// The host renders it with the existing status banner.
final class ConnectionNoticeTests: XCTestCase {
    private let s = FlareStrings()

    func testEachPhaseSaysWhatIsHappeningAndConnectedSaysNothing() {
        XCTAssertNil(FlareConnectionNotice.resolve(.connected, reason: "ignored", strings: s))
        XCTAssertEqual(FlareConnectionNotice.resolve(.connecting, strings: s),
                       FlareConnectionNotice(phase: .connecting, text: "正在连接…", tone: .warning, pulse: true))
        XCTAssertEqual(FlareConnectionNotice.resolve(.reconnecting, strings: s),
                       FlareConnectionNotice(phase: .reconnecting, text: "连接已断开，正在重连…", tone: .warning, pulse: true))
        XCTAssertEqual(FlareConnectionNotice.resolve(.offline, strings: s),
                       FlareConnectionNotice(phase: .offline, text: "网络不可用，恢复后会自动重连", tone: .warning, pulse: false))
        XCTAssertEqual(FlareConnectionNotice.resolve(.disconnected, strings: s),
                       FlareConnectionNotice(phase: .disconnected, text: "连接已断开", tone: .warning, pulse: false))
    }

    func testADisconnectionNamesItsReasonAndOffersReconnectOnlyWhenTheHostCan() {
        let withReason = FlareConnectionNotice.resolve(.disconnected, reason: "  网关超时 ", strings: s)
        XCTAssertEqual(withReason?.text, "连接已断开：网关超时")
        XCTAssertNil(withReason?.recovery)
        let reconnectable = FlareConnectionNotice.resolve(.disconnected, canReconnect: true, strings: s)
        XCTAssertEqual(reconnectable?.recovery, .reconnect)
        XCTAssertEqual(reconnectable?.recoveryText, "重新连接")
    }

    func testKickedAndExpiredAlwaysOfferSignInAndAReasonReplacesTheKickedText() {
        let kicked = FlareConnectionNotice.resolve(.kicked, strings: s)
        XCTAssertEqual(kicked, FlareConnectionNotice(phase: .kicked, text: "账号已在其他设备登录", tone: .danger, pulse: false,
                                                     recovery: .signIn, recoveryText: "重新登录"))
        XCTAssertEqual(FlareConnectionNotice.resolve(.kicked, reason: "管理员已将你移出", canReconnect: true, strings: s)?.text,
                       "管理员已将你移出")
        XCTAssertEqual(FlareConnectionNotice.resolve(.kicked, canReconnect: true, strings: s)?.recovery, .signIn,
                       "the core does not reconnect after a kick")
        let expired = FlareConnectionNotice.resolve(.expired, reason: "token expired", canReconnect: true, strings: s)
        XCTAssertEqual(expired, FlareConnectionNotice(phase: .expired, text: "登录已过期", tone: .danger, pulse: false,
                                                      recovery: .signIn, recoveryText: "重新登录"))
    }

    func testEveryNoticeIsChineseByDefaultAndOverridable() {
        let english = FlareStrings(connectionKicked: "Your account signed in on another device", connectionSignIn: "Sign in again")
        XCTAssertEqual(FlareConnectionNotice.resolve(.kicked, strings: english)?.recoveryText, "Sign in again")
        for phase in FlareConnectionPhase.allCases {
            guard let notice = FlareConnectionNotice.resolve(phase, strings: s) else { continue }
            XCTAssertNotNil(notice.text.range(of: "\\p{Han}", options: .regularExpression), "\(phase): \(notice.text)")
        }
    }
}
