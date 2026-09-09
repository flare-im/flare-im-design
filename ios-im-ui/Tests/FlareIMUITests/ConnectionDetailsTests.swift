import XCTest
@testable import FlareIMUI

final class ConnectionDetailsTests: XCTestCase {
    private func actions(_ state: FlareConnectionState, busy: Bool = false, all: Bool = true) -> [FlareConnectionAction] {
        availableConnectionActions(state, hasReconnect: all, hasReauth: all, hasDiagnostics: all, busy: busy)
    }

    func testEveryStateExposesOnlyStateAppropriateActions() {
        XCTAssertEqual(actions(.connected), [.copyDiagnostics])
        XCTAssertEqual(actions(.connecting), [.copyDiagnostics])
        XCTAssertEqual(actions(.reconnecting), [.reconnect, .copyDiagnostics])
        XCTAssertEqual(actions(.offline), [.reconnect, .copyDiagnostics])
        XCTAssertEqual(actions(.sessionExpired), [.reauth, .copyDiagnostics])
        XCTAssertEqual(actions(.kicked), [.reauth, .copyDiagnostics])
        XCTAssertEqual(actions(.sdkUnready), [])
    }

    func testBusyOrMissingCapabilitiesExposeNothing() {
        for state in FlareConnectionState.allCases {
            XCTAssertEqual(actions(state, busy: true), [], "\(state) busy")
            XCTAssertEqual(actions(state, all: false), [], "\(state) no capabilities")
        }
    }

    func testReconnectAndReauthNeverCross() {
        XCTAssertFalse(actions(.connected).contains(.reconnect))
        XCTAssertFalse(actions(.connecting).contains(.reconnect))
        XCTAssertFalse(actions(.offline).contains(.reauth))
        XCTAssertFalse(actions(.reconnecting).contains(.reauth))
    }

    func testToneAndProgressPerState() {
        XCTAssertEqual(connectionTone(.connected), .success)
        XCTAssertEqual(connectionTone(.connecting), .warning)
        XCTAssertEqual(connectionTone(.reconnecting), .warning)
        XCTAssertEqual(connectionTone(.offline), .danger)
        XCTAssertEqual(connectionTone(.sessionExpired), .danger)
        XCTAssertEqual(connectionTone(.kicked), .danger)
        XCTAssertEqual(connectionTone(.sdkUnready), .neutral)
        XCTAssertEqual(FlareConnectionState.allCases.filter(connectionInProgress), [.connecting, .reconnecting])
    }

    func testViewBuildsForEveryState() {
        for state in FlareConnectionState.allCases {
            let view = ConnectionDetailsView(state: state, transport: "QUIC", endpoint: "quic://gw.example.com:60443/x",
                                             lastSyncAt: "刚刚", reason: "r", diagnostics: "d", busy: false,
                                             onReconnect: {}, onReauth: {}, onCopyDiagnostics: {})
            _ = view.body
        }
    }
}
