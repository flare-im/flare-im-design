import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The peer's state on the 1:1 call screen: a muted peer gets the mic-off badge, named 对方已静音 from the strings
/// table; a speaking peer gets the ring unless muted; the host's own camera is a picture-in-picture in video mode
/// only, at the component token's width and 3:4.
final class CallViewPeerStateTests: XCTestCase {
    private let s = FlareStrings()

    func testTheStringsTableNamesTheMutedPeer() {
        XCTAssertEqual(s.callPeerMuted, "对方已静音")
    }

    func testTheMutedBadgeIsNamedOnlyWhileThePeerIsMuted() throws {
        let muted = CallView(peerName: "Ada", mode: .audio, state: .connected, peerMuted: true)
        XCTAssertNoThrow(try muted.inspect().find(viewWithAccessibilityLabel: s.callPeerMuted))
        XCTAssertNoThrow(try muted.inspect().find(text: "Ada"), "the name stays beside the badge")

        let live = CallView(peerName: "Ada", mode: .audio, state: .connected)
        XCTAssertThrowsError(try live.inspect().find(viewWithAccessibilityLabel: s.callPeerMuted))

        let videoMuted = CallView(peerName: "Ada", mode: .video, state: .connected, video: AnyView(Color.black), peerMuted: true)
        XCTAssertNoThrow(try videoMuted.inspect().find(viewWithAccessibilityLabel: s.callPeerMuted),
                         "the badge sits by the name, which the peer's video does not hide")
    }

    func testTheSpeakingRingIsNotDrawnWhileThePeerIsMuted() {
        XCTAssertTrue(CallView.showsSpeakingRing(speaking: true, muted: false))
        XCTAssertFalse(CallView.showsSpeakingRing(speaking: true, muted: true))
        XCTAssertFalse(CallView.showsSpeakingRing(speaking: false, muted: false))
        XCTAssertFalse(CallView.showsSpeakingRing(speaking: false, muted: true))
    }

    func testTheLocalPreviewIsAPictureInPictureInVideoModeOnly() throws {
        let video = CallView(peerName: "Ada", mode: .video, state: .connected, localVideo: AnyView(Text("me")))
        let frame = try video.inspect().find(ViewType.AnyView.self, where: { try $0.text().string() == "me" }).fixedFrame()
        XCTAssertEqual(frame.width, FlareSizes.componentCallPreviewWidth)
        XCTAssertEqual(frame.height, FlareSizes.componentCallPreviewWidth * 4 / 3)

        let audio = CallView(peerName: "Ada", mode: .audio, state: .connected, localVideo: AnyView(Text("me")))
        XCTAssertThrowsError(try audio.inspect().find(text: "me"))
    }

    func testThePeerBlockStartsBelowThePreview() {
        // Both measure from the top of the safe area: the preview's bottom is its inset plus its 3:4 height, the
        // avatar's top is the peer block's inset.
        let previewBottom = FlareSizes.spacingLg + FlareSizes.componentCallPreviewWidth * 4 / 3
        let avatarTop = CallView.peerTopInset(localPreview: true)
        XCTAssertGreaterThan(avatarTop, previewBottom)
        XCTAssertEqual(avatarTop, FlareSizes.spacingLg * 2 + FlareSizes.componentCallPreviewWidth * 4 / 3)
        XCTAssertEqual(CallView.peerTopInset(localPreview: false), 72)
    }
}
