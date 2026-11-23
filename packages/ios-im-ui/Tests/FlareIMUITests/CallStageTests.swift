import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// docs/plugin-experience.md §3: the group grid's rows, the ended line, hang up's own row on a crowded phone bar, the
/// failed state's keys, the disabled bar and the call window's size.
final class CallStageTests: XCTestCase {
    private let s = FlareStrings()

    func testTheGroupGridRowsFollowTheHeadCount() {
        XCTAssertEqual(GroupCallView.gridRows(count: 0, compact: true), [])
        XCTAssertEqual(GroupCallView.gridRows(count: 1, compact: true), [1])
        XCTAssertEqual(GroupCallView.gridRows(count: 2, compact: true), [2])
        XCTAssertEqual(GroupCallView.gridRows(count: 3, compact: true), [2, 1], "two over one, never a 2×2 with a hole")
        XCTAssertEqual(GroupCallView.gridRows(count: 4, compact: false), [2, 2])
        XCTAssertEqual(GroupCallView.gridRows(count: 5, compact: true), [2, 2, 1])
        XCTAssertEqual(GroupCallView.gridRows(count: 6, compact: true), [2, 2, 2], "2×3 on a phone")
        XCTAssertEqual(GroupCallView.gridRows(count: 6, compact: false), [3, 3], "3×2 elsewhere")
        XCTAssertEqual(GroupCallView.gridRows(count: 7, compact: true), [3, 3, 1])
        XCTAssertEqual(GroupCallView.gridRows(count: 9, compact: false), [3, 3, 3])
        XCTAssertEqual(GroupCallView.gridRows(count: 9, compact: true), [3, 3, 3])
        // §12.16: up to 12 — 4×3 elsewhere, 3×4 on a phone.
        XCTAssertEqual(GroupCallView.gridRows(count: 10, compact: false), [4, 4, 2])
        XCTAssertEqual(GroupCallView.gridRows(count: 12, compact: false), [4, 4, 4])
        XCTAssertEqual(GroupCallView.gridRows(count: 10, compact: true), [3, 3, 3, 1])
        XCTAssertEqual(GroupCallView.gridRows(count: 12, compact: true), [3, 3, 3, 3])
    }

    /// §12.16: 「N 人已加入」 counts only the people already on the call.
    @MainActor
    func testTheHeadCountLeavesOutThoseStillBeingCalled() throws {
        let people = [CallParticipant(id: "me", name: "Me", isSelf: true), CallParticipant(id: "a", name: "A"),
                      CallParticipant(id: "b", name: "B", calling: true)]
        XCTAssertEqual(GroupCallView.joinedCount(people), 2)
        let group = GroupCallView(participants: people, mode: .audio, state: .connected, durationLabel: "08:41")
        XCTAssertNoThrow(try group.inspect().find(text: s.joinedCount(2, "08:41")))
    }

    /// §3.4: no host minimize (and no surface's), no minimize key.
    @MainActor
    func testTheGroupMinimizeKeyNeedsSomethingToCall() throws {
        let bare = GroupCallView(participants: [CallParticipant(id: "a", name: "A")], mode: .audio, state: .connected)
        XCTAssertThrowsError(try bare.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.callMinimize }))
        var minimized = 0
        let wired = GroupCallView(participants: [CallParticipant(id: "a", name: "A")], mode: .audio, state: .connected,
                                  onMinimize: { minimized += 1 })
        try wired.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.callMinimize }).tap()
        XCTAssertEqual(minimized, 1)
    }

    /// §3.3: the flip key is a phone's; §3.1: only the window's top band drags it, and never while expanded.
    func testTheFlipKeyIsAPhonesAndTheTopBandDragsTheWindow() {
        XCTAssertTrue(CallControlsView.showsFlip(mode: .video, compact: true))
        XCTAssertFalse(CallControlsView.showsFlip(mode: .video, compact: false), "not in an iPad or Mac window")
        XCTAssertFalse(CallControlsView.showsFlip(mode: .audio, compact: true))
        XCTAssertTrue(CallSurfaceView<EmptyView>.drags(from: CGPoint(x: 100, y: FlareSizes.touchTarget), expanded: false))
        XCTAssertFalse(CallSurfaceView<EmptyView>.drags(from: CGPoint(x: 100, y: FlareSizes.touchTarget + 1), expanded: false))
        XCTAssertFalse(CallSurfaceView<EmptyView>.drags(from: CGPoint(x: 100, y: 10), expanded: true))
    }

    /// §12.17: the dock speaks in short phrases, a failure in the call error colour's words; hang up is labelled.
    @MainActor
    func testTheDockUsesShortPhrasesAndHangUpIsLabelled() throws {
        XCTAssertNoThrow(try CallDockView(title: "Ada", state: .calling).inspect().find(text: s.callDockWaiting))
        XCTAssertNoThrow(try CallDockView(title: "Ada", state: .reconnecting).inspect().find(text: s.callReconnectingShort))
        XCTAssertNoThrow(try CallDockView(title: "Ada", state: .failed).inspect().find(text: s.callInterrupted))
        XCTAssertNoThrow(try CallControlsView(mode: .audio, onHangup: {}).inspect().find(text: s.hangUp))
    }

    func testTheEndedLineCarriesTheLength() {
        XCTAssertEqual(CallView.endedText(durationLabel: "03:24", s), "通话已结束 · 03:24")
        XCTAssertEqual(CallView.endedText(durationLabel: FlareCallRecordRules.durationLabel(3725), s), "通话已结束 · 1:02:05")
        XCTAssertEqual(CallView.endedText(durationLabel: nil, s), "通话已结束")
        XCTAssertEqual(CallView.endedText(durationLabel: "", FlareStrings.english), "Call ended")
    }

    func testHangUpTakesItsOwnRowOnlyOnACrowdedPhoneBar() {
        XCTAssertFalse(CallControlsView.hangupOnOwnRow(otherKeys: 4, compact: true))
        XCTAssertTrue(CallControlsView.hangupOnOwnRow(otherKeys: 5, compact: true))
        XCTAssertFalse(CallControlsView.hangupOnOwnRow(otherKeys: 5, compact: false), "a desktop bar stays one row")
    }

    func testTheWindowTakesTheModeSizeAndFitsItsContainer() {
        let room = CGSize(width: 1024, height: 768)
        XCTAssertEqual(CallSurfaceView<EmptyView>.windowSize(mode: .audio, expanded: false, in: room),
                       CGSize(width: FlareSizes.componentCallWindowAudioWidth, height: FlareSizes.componentCallWindowAudioHeight))
        XCTAssertEqual(CallSurfaceView<EmptyView>.windowSize(mode: .video, expanded: false, in: room),
                       CGSize(width: FlareSizes.componentCallWindowVideoWidth, height: FlareSizes.componentCallWindowVideoHeight))
        XCTAssertEqual(CallSurfaceView<EmptyView>.windowSize(mode: .video, expanded: true, in: room),
                       CGSize(width: 1024 - FlareSizes.spacingXl * 2, height: 768 * 0.9))
        let small = CGSize(width: 600, height: 500)
        XCTAssertEqual(CallSurfaceView<EmptyView>.windowSize(mode: .video, expanded: false, in: small),
                       CGSize(width: 600 - FlareSizes.spacingXl * 2, height: 500 - FlareSizes.spacingXl * 2))
    }

    func testTheWindowDragStaysInsideTheContainer() {
        let room = CGSize(width: 1000, height: 800), window = CGSize(width: 400, height: 560)
        let edge = CGSize(width: (1000 - 400) / 2 - FlareSizes.spacingXl, height: (800 - 560) / 2 - FlareSizes.spacingXl)
        XCTAssertEqual(CallSurfaceView<EmptyView>.clampedOffset(CGSize(width: 50, height: -20), window: window, in: room),
                       CGSize(width: 50, height: -20))
        XCTAssertEqual(CallSurfaceView<EmptyView>.clampedOffset(CGSize(width: 900, height: -900), window: window, in: room),
                       CGSize(width: edge.width, height: -edge.height))
        XCTAssertEqual(CallSurfaceView<EmptyView>.clampedOffset(CGSize(width: 30, height: 30), window: room, in: room), .zero,
                       "a window as large as its room does not move")
    }

    func testADraggedPreviewSettlesInTheNearestCorner() {
        let stage = CGSize(width: 390, height: 600)
        XCTAssertEqual(CallView.previewCorner(center: CGPoint(x: 40, y: 40), in: stage), .topLeading)
        XCTAssertEqual(CallView.previewCorner(center: CGPoint(x: 350, y: 40), in: stage), .topTrailing)
        XCTAssertEqual(CallView.previewCorner(center: CGPoint(x: 40, y: 560), in: stage), .bottomLeading)
        XCTAssertEqual(CallView.previewCorner(center: CGPoint(x: 350, y: 560), in: stage), .bottomTrailing)
    }

    @MainActor
    func testCloseGoesToOnCloseAndFallsBackToHangUp() throws {
        var closed = 0, hungUp = 0
        let call = CallView(peerName: "Ada", mode: .audio, state: .failed, onHangup: { hungUp += 1 },
                            onClose: { closed += 1 })
        try call.inspect().find(button: s.close).tap()
        let group = GroupCallView(participants: [CallParticipant(id: "a", name: "A")], mode: .audio, state: .failed,
                                  onHangup: { hungUp += 1 })
        try group.inspect().find(button: s.close).tap()
        XCTAssertEqual(closed, 1)
        XCTAssertEqual(hungUp, 1, "a host without onClose still closes through hang up")
    }

    @MainActor
    func testACallingParticipantIsAskedForNoVideoAndReadsCalling() throws {
        var asked = 0
        let ringing = CallParticipant(id: "b", name: "Bo", calling: true)
        XCTAssertNil(GroupCallView.tileVideo(for: ringing, mode: .video, tile: { _ in asked += 1; return AnyView(Text("v")) }))
        XCTAssertEqual(asked, 0)
        let group = GroupCallView(participants: [CallParticipant(id: "a", name: "Ada"), ringing], mode: .video,
                                  state: .connected)
        XCTAssertNoThrow(try group.inspect().find(text: s.callCalling))
        let tile = try group.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == "Bo" })
        XCTAssertEqual(try tile.accessibilityValue().string(), s.callCalling)
    }

    @MainActor
    func testTheSpeakerKeyIsInBothModesAndThePreviewIsNineBySixteen() throws {
        let video = CallControlsView(mode: .video, onToggleSpeaker: {})
        XCTAssertNoThrow(try video.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.speaker }))
        XCTAssertEqual(CallView.previewHeight, FlareSizes.componentCallPreviewWidth * 16 / 9)
        #if os(macOS)
        XCTAssertEqual(CallControlsView.hangupShortcutLabel, "⌘⇧H")
        #else
        XCTAssertEqual(CallControlsView.hangupShortcutLabel, "⌃⇧H", "iPadOS keeps ⌘⇧H for Home")
        #endif
    }

    @MainActor
    func testTheLocalTileIsCalledYou() throws {
        let group = GroupCallView(participants: [CallParticipant(id: "me", name: "Ada", isSelf: true)], mode: .audio,
                                  state: .connected)
        XCTAssertNoThrow(try group.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.callYou }))
        XCTAssertNoThrow(try group.inspect().find(text: s.callYou))
    }

    @MainActor
    func testAFailedCallSwapsTheBarForCloseAndRedial() throws {
        var closed = 0, redialled = 0
        let call = CallView(peerName: "Ada", mode: .audio, state: .failed, onHangup: { closed += 1 },
                            onRecover: { redialled += 1 })
        let tree = try call.inspect()
        XCTAssertThrowsError(try tree.find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.microphone }),
                             "the control bar is gone")
        try tree.find(button: s.close).tap()
        try tree.find(button: s.callRedial).tap()
        XCTAssertEqual(closed, 1)
        XCTAssertEqual(redialled, 1)
        XCTAssertNoThrow(try tree.find(text: s.callFailed), "no host reason: the default status line")
    }

    @MainActor
    func testADisabledBarKeepsOnlyHangUpAndAnEndedCallKeepsNothing() throws {
        func key(_ view: some View, _ name: String) throws -> InspectableView<ViewType.Button> {
            try view.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == name })
        }
        let waiting = CallView(peerName: "Ada", mode: .audio, state: .calling, onHangup: {}, onToggleMute: {},
                               controlsDisabled: true)
        XCTAssertTrue(try key(waiting, s.microphone).isDisabled())
        XCTAssertFalse(try key(waiting, s.hangUp).isDisabled())

        let ended = CallView(peerName: "Ada", mode: .audio, state: .ended, durationLabel: "03:24", onHangup: {},
                             onToggleMute: {})
        XCTAssertTrue(try key(ended, s.microphone).isDisabled())
        XCTAssertTrue(try key(ended, s.hangUp).isDisabled())
        XCTAssertNoThrow(try ended.inspect().find(text: "通话已结束 · 03:24"))

        let groupEnded = GroupCallView(participants: [CallParticipant(id: "a", name: "A")], mode: .audio, state: .ended,
                                       durationLabel: "08:41", onHangup: {}, onToggleMute: {})
        XCTAssertTrue(try key(groupEnded, s.microphone).isDisabled())
        XCTAssertTrue(try key(groupEnded, s.hangUp).isDisabled())
        XCTAssertNoThrow(try groupEnded.inspect().find(text: "通话已结束 · 08:41"), "the end line alone, no head-count")
    }
}
