import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// An audio call can be switched to video: the control bar draws a "switch to video" key (切换到视频 from the strings
/// table, the kit's video glyph) after the speaker when the host passes `onStartVideo`, never in a video call; the
/// one-to-one and the group call screens forward it. A group tile asks the host for video only while it shows video,
/// and keeps the avatar when the host has none.
final class CallStartVideoTests: XCTestCase {
    private let s = FlareStrings()

    @MainActor
    private func names(_ view: some View) throws -> [String] {
        try view.inspect().findAll(ViewType.Button.self).map { try $0.accessibilityLabel().string() }
    }

    @MainActor
    private func button(_ view: some View, _ name: String) throws -> InspectableView<ViewType.Button> {
        try view.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == name })
    }

    func testTheStringsTableNamesTheKey() {
        XCTAssertEqual(s.callSwitchToVideo, "切换到视频")
        XCTAssertEqual(FlareStrings.english.callSwitchToVideo, "Switch to video")
    }

    @MainActor
    func testTheKeySitsAfterTheSpeakerInAnAudioCallAndAsksTheHost() throws {
        var asked = 0
        let voice = CallControlsView(mode: .audio, onToggleMute: {}, onToggleSpeaker: {}, onHangup: {},
                                     onAddMember: {}, onStartVideo: { asked += 1 })
        XCTAssertEqual(try names(voice), [s.microphone, s.speaker, s.callSwitchToVideo, s.addMember, s.hangUp])
        let key = try button(voice, s.callSwitchToVideo)
        XCTAssertEqual(try key.labelView().find(ViewType.Image.self).actualImage().name(), flareIconMap["video"])
        XCTAssertEqual(try key.accessibilityValue().string(), "", "an action, not a device toggle")
        try key.tap()
        XCTAssertEqual(asked, 1)
    }

    @MainActor
    func testTheKeyIsNotDrawnInAVideoCallNorWithoutTheCallback() throws {
        let video = CallControlsView(mode: .video, onStartVideo: {})
        XCTAssertFalse(try names(video).contains(s.callSwitchToVideo))
        let plain = CallControlsView(mode: .audio)
        XCTAssertEqual(try names(plain), [s.microphone, s.speaker, s.hangUp])
    }

    @MainActor
    func testTheCallScreensForwardItInAudioCallsOnly() throws {
        var asked = 0
        let oneToOne = CallView(peerName: "Ada", mode: .audio, state: .connected, onStartVideo: { asked += 1 })
        try button(oneToOne, s.callSwitchToVideo).tap()
        let group = GroupCallView(participants: [CallParticipant(id: "a", name: "A")], mode: .audio, state: .connected,
                                  onStartVideo: { asked += 1 })
        try button(group, s.callSwitchToVideo).tap()
        XCTAssertEqual(asked, 2)

        let videoOneToOne = CallView(peerName: "Ada", mode: .video, state: .connected, onStartVideo: {})
        XCTAssertFalse(try names(videoOneToOne).contains(s.callSwitchToVideo))
        let videoGroup = GroupCallView(participants: [CallParticipant(id: "a", name: "A")], mode: .video,
                                       state: .connected, onStartVideo: {})
        XCTAssertFalse(try names(videoGroup).contains(s.callSwitchToVideo))
    }

    // MARK: Group tiles

    func testATileIsAskedForVideoOnlyWhileItShowsVideo() {
        var asked: [String] = []
        let tile: (CallParticipant) -> AnyView? = { p in
            asked.append(p.id)
            // No stream for c yet: the kit keeps the avatar.
            return p.id == "a" ? AnyView(Text("stream-a")) : nil
        }
        let on = CallParticipant(id: "a", name: "A"), off = CallParticipant(id: "b", name: "B", cameraOff: true)
        let waiting = CallParticipant(id: "c", name: "C")
        XCTAssertNotNil(GroupCallView.tileVideo(for: on, mode: .video, tile: tile))
        XCTAssertNil(GroupCallView.tileVideo(for: off, mode: .video, tile: tile))
        XCTAssertNil(GroupCallView.tileVideo(for: waiting, mode: .video, tile: tile))
        XCTAssertNil(GroupCallView.tileVideo(for: on, mode: .audio, tile: tile))
        XCTAssertNil(GroupCallView.tileVideo(for: on, mode: .video, tile: nil))
        XCTAssertEqual(asked, ["a", "c"], "never asked for a camera that is off, nor in an audio call")
    }

    @MainActor
    func testAVideoTileDrawsTheStreamUnderItsChromeAndTheOthersTheAvatar() throws {
        let group = GroupCallView(
            participants: [CallParticipant(id: "a", name: "Ada", muted: true, speaking: true),
                           CallParticipant(id: "b", name: "Bo", cameraOff: true),
                           CallParticipant(id: "c", name: "Cy")],
            mode: .video, state: .connected,
            tile: { p in p.id == "a" ? AnyView(Text("stream-a")) : nil })
        let tree = try group.inspect()
        XCTAssertNoThrow(try tree.find(text: "stream-a"))
        XCTAssertEqual(tree.findAll(AvatarView.self).count, 2, "the stream replaces only its own tile's avatar")
        XCTAssertNoThrow(try tree.find(text: "Ada"), "the name stays over the stream")
    }
}
