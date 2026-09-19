import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// FR-104: every call device toggle is named by the device and says whether the device is on
/// (已开启 / 已关闭 from the strings table, never "selected" meaning muted); the dock's main button is
/// named 返回通话 and hang up is 挂断.
final class CallDeviceToggleTests: XCTestCase {
    private let s = FlareStrings()

    @MainActor
    private func button(_ view: some View, _ name: String) throws -> InspectableView<ViewType.Button> {
        try view.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == name })
    }

    func testTheStringsTableNamesTheStates() {
        XCTAssertEqual(s.callDeviceOn, "已开启")
        XCTAssertEqual(s.callDeviceOff, "已关闭")
        XCTAssertEqual(s.callReturn, "返回通话")
        XCTAssertEqual(s.microphone, "麦克风")
        XCTAssertEqual(s.camera, "摄像头")
        XCTAssertEqual(s.speaker, "扬声器")
        XCTAssertEqual(s.hangUp, "挂断")
        XCTAssertEqual(CallControlsView.deviceState(on: true, s), s.callDeviceOn)
        XCTAssertEqual(CallControlsView.deviceState(on: false, s), s.callDeviceOff)
    }

    @MainActor
    func testCallControlsValueEachDeviceByWhetherItIsOn() throws {
        let unmutedVideo = CallControlsView(muted: false, cameraOn: true, mode: .video, onToggleMute: {}, onToggleCamera: {})
        XCTAssertEqual(try button(unmutedVideo, s.microphone).accessibilityValue().string(), s.callDeviceOn)
        XCTAssertEqual(try button(unmutedVideo, s.camera).accessibilityValue().string(), s.callDeviceOn)

        let mutedCameraOff = CallControlsView(muted: true, cameraOn: false, mode: .video, onToggleMute: {}, onToggleCamera: {})
        XCTAssertEqual(try button(mutedCameraOff, s.microphone).accessibilityValue().string(), s.callDeviceOff,
                       "a muted microphone is off")
        XCTAssertEqual(try button(mutedCameraOff, s.camera).accessibilityValue().string(), s.callDeviceOff)

        let speakerOff = CallControlsView(speakerOn: false, mode: .audio, onToggleSpeaker: {})
        XCTAssertEqual(try button(speakerOff, s.speaker).accessibilityValue().string(), s.callDeviceOff)
        let speakerOn = CallControlsView(speakerOn: true, mode: .audio, onToggleSpeaker: {})
        XCTAssertEqual(try button(speakerOn, s.speaker).accessibilityValue().string(), s.callDeviceOn)
        XCTAssertNoThrow(try button(speakerOn, s.hangUp))
    }

    @MainActor
    func testTheDockNamesTheMicrophoneAndItsMainButtonReturnsToTheCall() throws {
        var expanded = 0, toggled = 0
        let muted = CallDockView(title: "Ada", muted: true, onExpand: { expanded += 1 }, onToggleMute: { toggled += 1 },
                                 onHangup: {})
        let microphone = try button(muted, s.microphone)
        XCTAssertEqual(try microphone.accessibilityValue().string(), s.callDeviceOff)
        XCTAssertThrowsError(try muted.inspect().find(ViewType.Button.self, where: {
            try $0.accessibilityLabel().string() == "静音"
        }), "the toggle is no longer named after one of its states")
        let main = try button(muted, s.callReturn)
        XCTAssertEqual(try main.accessibilityValue().string(), "Ada")
        try main.tap()
        try microphone.tap()
        XCTAssertEqual(expanded, 1)
        XCTAssertEqual(toggled, 1)
        XCTAssertNoThrow(try button(muted, s.hangUp))

        let live = CallDockView(title: "Ada", muted: false, onToggleMute: {})
        XCTAssertEqual(try button(live, s.microphone).accessibilityValue().string(), s.callDeviceOn)
    }

    @MainActor
    func testTheRecoveryButtonTakesItsTargetOnTheLabel() throws {
        let call = CallView(peerName: "Ada", mode: .audio, state: .failed, recoveryText: "重新连接", onRecover: {})
        let recover = try call.inspect().find(button: "重新连接")
        let frame = try recover.labelView().find(ViewType.Text.self).flexFrame()
        XCTAssertEqual(frame.minHeight, FlareSizes.touchTargetMin)
        XCTAssertEqual(frame.minWidth, FlareSizes.touchTargetMin)
    }
}
