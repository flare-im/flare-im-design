import XCTest
@testable import FlareIMUI

final class ReauthPromptTests: XCTestCase {
    func testActionsPerReasonAndBusy() {
        for reason in FlareReauthReason.allCases {
            for busy in [false, true] {
                let reauthAllowed = reason != .accountDisabled
                let both = reauthActions(reason, hasReauth: true, hasLogout: true, busy: busy)
                XCTAssertEqual(both.reauthenticate, FlareReauthActionState(visible: reauthAllowed, enabled: reauthAllowed && !busy), "\(reason) busy=\(busy)")
                XCTAssertEqual(both.logout, FlareReauthActionState(visible: true, enabled: !busy), "\(reason) busy=\(busy)")
                XCTAssertEqual(both.primary, reauthAllowed, "\(reason) busy=\(busy)")
                let none = reauthActions(reason, hasReauth: false, hasLogout: false, busy: busy)
                XCTAssertEqual(none.reauthenticate, FlareReauthActionState(visible: false, enabled: false))
                XCTAssertEqual(none.logout, FlareReauthActionState(visible: false, enabled: false))
                XCTAssertFalse(none.primary)
            }
        }
    }
    func testBusyDefaultsToFalse() {
        XCTAssertTrue(reauthActions(.sessionExpired, hasReauth: true, hasLogout: false).reauthenticate.enabled)
    }
    func testToneAndIconPerReason() {
        XCTAssertEqual(FlareReauthReason.allCases.map(reauthTone), [.info, .warning, .warning, .danger])
        XCTAssertEqual(FlareReauthReason.allCases.map(reauthIcon), ["clock", "devices", "lock", "block"])
    }
}
