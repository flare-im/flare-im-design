import XCTest
@testable import FlareIMUI

final class PermissionPromptTests: XCTestCase {
    func testActionVisibilityForEveryKindAndState() {
        for kind in FlarePermissionKind.allCases {
            for state in FlarePermissionState.allCases {
                let a = permissionActions(state, hasRequest: true, hasOpenSettings: true, hasDismiss: true)
                XCTAssertEqual(a.request, state == .undetermined, "\(kind)/\(state) request")
                XCTAssertEqual(a.openSettings, state == .denied, "\(kind)/\(state) openSettings")
                XCTAssertEqual(a.dismiss, state != .granted, "\(kind)/\(state) dismiss")
                XCTAssertTrue(a.enabled)
                let copy = defaultPermissionCopy(kind, state)
                XCTAssertFalse(copy.title.isEmpty)
                XCTAssertEqual(!copy.description.isEmpty, state != .granted, "\(kind)/\(state) description")
                XCTAssertEqual(!copy.primaryLabel.isEmpty, state == .undetermined || state == .denied, "\(kind)/\(state) primaryLabel")
                XCTAssertFalse(defaultPermissionStateLabel(state).isEmpty)
                XCTAssertNotNil(flareIconMap[permissionIconName(kind)], "\(kind) icon must resolve")
                XCTAssertNotNil(flareIconMap[permissionStateIconName(state)], "\(state) icon must resolve")
            }
        }
    }

    func testIconNamesMatchTheSharedContract() {
        XCTAssertEqual(FlarePermissionKind.allCases.map(permissionIconName),
                       ["mic", "camera", "notification", "storage", "image", "people", "location", "screen-share"])
        XCTAssertEqual(FlarePermissionState.allCases.map(permissionStateIconName), ["info", "error", "lock", "warning", "success"])
    }

    func testUnsuppliedHandlersHiddenAndBusyDisables() {
        let none = permissionActions(.undetermined, hasRequest: false, hasOpenSettings: true, hasDismiss: false)
        XCTAssertEqual(none, FlarePermissionActions(request: false, openSettings: false, dismiss: false, enabled: true))
        let busy = permissionActions(.denied, hasRequest: true, hasOpenSettings: true, hasDismiss: true, busy: true)
        XCTAssertEqual(busy, FlarePermissionActions(request: false, openSettings: true, dismiss: true, enabled: false))
    }

    func testFeatureLabelEmbeddedWithFallback() {
        XCTAssertTrue(defaultPermissionCopy(.microphone, .undetermined, featureLabel: "发送语音消息").description.contains("发送语音消息"))
        XCTAssertTrue(defaultPermissionCopy(.microphone, .denied, featureLabel: "  ").description.contains("此功能"))
        XCTAssertEqual(defaultPermissionCopy(.notifications, .denied).primaryLabel, "前往设置")
        XCTAssertEqual(defaultPermissionCopy(.camera, .undetermined).primaryLabel, "允许")
    }

    func testGrantedDrawsNothingAndASoftAskOnlyWhatThePersonCanActOn() {
        XCTAssertEqual(FlarePermissionState.allCases.filter { permissionPromptShows($0) },
                       [.undetermined, .denied, .restricted, .unavailable])
        XCTAssertEqual(FlarePermissionState.allCases.filter { permissionPromptShows($0, softAsk: true) },
                       [.undetermined, .denied])
    }

    func testNotificationSoftAskHasItsOwnCopy() {
        let ask = defaultPermissionSoftAskCopy(.notifications, .undetermined)
        XCTAssertEqual(ask.title, "及时收到新消息")
        XCTAssertEqual(ask.description, "开启通知后，应用不在前台时也能收到新消息提醒。")
        XCTAssertEqual(ask.primaryLabel, "开启通知")
        let denied = defaultPermissionSoftAskCopy(.notifications, .denied, strings: .english)
        XCTAssertEqual(denied.primaryLabel, "Open Settings")
        XCTAssertTrue(denied.description.contains("Settings"))
        // Any other kind keeps its own copy in a soft-ask.
        XCTAssertEqual(defaultPermissionSoftAskCopy(.camera, .undetermined), defaultPermissionCopy(.camera, .undetermined))
    }
}
