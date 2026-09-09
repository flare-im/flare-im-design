import XCTest
@testable import FlareIMUI

final class PermissionPromptTests: XCTestCase {
    func testActionVisibilityForEveryKindAndState() {
        for kind in FlarePermissionKind.allCases {
            for state in FlarePermissionState.allCases {
                let a = permissionActions(state, hasRequest: true, hasOpenSettings: true, hasDismiss: true)
                XCTAssertEqual(a.request, state == .undetermined, "\(kind)/\(state) request")
                XCTAssertEqual(a.openSettings, state == .denied, "\(kind)/\(state) openSettings")
                XCTAssertTrue(a.dismiss)
                XCTAssertTrue(a.enabled)
                let copy = defaultPermissionCopy(kind, state)
                XCTAssertFalse(copy.title.isEmpty)
                XCTAssertFalse(copy.description.isEmpty)
                XCTAssertEqual(!copy.primaryLabel.isEmpty, state == .undetermined || state == .denied, "\(kind)/\(state) primaryLabel")
                XCTAssertFalse(defaultPermissionStateLabel(state).isEmpty)
                XCTAssertNotNil(flareIconMap[permissionIconName(kind)], "\(kind) icon must resolve")
                XCTAssertNotNil(flareIconMap[permissionStateIconName(state)], "\(state) icon must resolve")
            }
        }
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
}
