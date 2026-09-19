import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// FR-077: an icon-only control is named by what it does (a kit string, so a host can translate it),
/// reports its on/off state as a value where it has one, and has a touch target of at least 44pt —
/// the frame itself or the target laid behind a glyph whose drawn size is part of the design.
final class IconOnlyControlAccessibilityTests: XCTestCase {
    private let s = FlareStrings()

    // MARK: Helpers

    @MainActor
    private func control(_ view: some View, _ name: String,
                         file: StaticString = #filePath, line: UInt = #line) throws -> InspectableView<ViewType.Button> {
        do {
            return try view.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == name })
        } catch {
            XCTFail("no button named \"\(name)\": \(error)", file: file, line: line)
            throw error
        }
    }

    /// The largest width and height the button's label reserves or declares as its target: fixed and
    /// minimum frames anywhere in the label, including the target laid behind the glyph.
    @MainActor
    private func target(_ button: InspectableView<ViewType.Button>) throws -> CGSize {
        let label = try button.labelView()
        var size = CGSize.zero
        for view in [label] + label.findAll(where: { _ in true }) {
            if let frame = try? view.flexFrame() {
                if !frame.minWidth.isNaN { size.width = max(size.width, frame.minWidth) }
                if !frame.minHeight.isNaN { size.height = max(size.height, frame.minHeight) }
            }
            if let width = try? view.fixedWidth(), !width.isNaN { size.width = max(size.width, width) }
            if let height = try? view.fixedHeight(), !height.isNaN { size.height = max(size.height, height) }
        }
        return size
    }

    @MainActor
    private func assertNamedTarget(_ view: some View, _ names: [String],
                                   file: StaticString = #filePath, line: UInt = #line) throws {
        for name in names {
            let button = try control(view, name, file: file, line: line)
            let size = try target(button)
            XCTAssertGreaterThanOrEqual(size.width, FlareSizes.touchTargetMin, "\(name) target width", file: file, line: line)
            XCTAssertGreaterThanOrEqual(size.height, FlareSizes.touchTargetMin, "\(name) target height", file: file, line: line)
        }
    }

    @MainActor
    private func symbol(_ button: InspectableView<ViewType.Button>) throws -> String {
        try button.labelView().find(ViewType.Image.self).actualImage().name()
    }

    // MARK: Composer

    @MainActor
    func testComposerToolbarKeysAreNamedAndDoWhatTheySay() throws {
        var emoji = 0, image = 0
        let composer = ComposerView(onSend: { _ in }, onImage: { image += 1 }, onEmoji: { emoji += 1 },
                                    enableVoice: true, onVoiceSend: { _, _ in true })
        try assertNamedTarget(composer, [s.composerExpandInput, s.composerEmoji, s.composerMention, s.composerVoice,
                                         s.composerImage, s.composerRichText, s.composerMore])
        XCTAssertEqual(try symbol(control(composer, s.composerEmoji)), flareIconMap["emoji"])
        XCTAssertEqual(try symbol(control(composer, s.composerMention)), flareIconMap["mention"])
        XCTAssertEqual(try symbol(control(composer, s.composerRichText)), flareIconMap["rich-text"])
        XCTAssertEqual(try symbol(control(composer, s.composerExpandInput)), flareIconMap["expand"])
        XCTAssertEqual(try symbol(control(composer, s.composerMore)), flareIconMap["add"])
        try control(composer, s.composerEmoji).tap()
        try control(composer, s.composerImage).tap()
        XCTAssertEqual(emoji, 1)
        XCTAssertEqual(image, 1)
        // No key is left to SF Symbols' generic names.
        for button in try composer.inspect().findAll(ViewType.Button.self) {
            XCTAssertFalse((try? button.accessibilityLabel().string())?.isEmpty ?? true, "every composer key has a name")
        }
    }

    @MainActor
    func testComposerVoiceKeyIsOfferedOnlyWithAVoiceHandler() throws {
        let composer = ComposerView(onSend: { _ in })
        XCTAssertThrowsError(try composer.inspect().find(ViewType.Button.self, where: {
            try $0.accessibilityLabel().string() == self.s.composerVoice
        }))
    }

    @MainActor
    func testComposerFormatKeysAndReplyCancelAreNamedFromTheStringsTable() throws {
        XCTAssertEqual(ComposerView.formatKeys(s).map(\.label),
                       [s.composerFormatBold, s.composerFormatItalic, s.composerFormatStrike, s.composerFormatCode,
                        s.composerFormatLink, s.composerFormatHeading, s.composerFormatQuote, s.composerFormatBullet,
                        s.composerFormatOrdered])
        XCTAssertFalse(ComposerView.formatKeys(s).map(\.label).contains("bold"), "never a raw format id")
        XCTAssertEqual(ComposerView.formatKeys(s).first { $0.id == "quote" }?.symbol, flareIconMap["quote"])
        let rich = ComposerView(rich: true, onSend: { _ in })
        try assertNamedTarget(rich, [s.composerFormatBold, s.composerFormatQuote, s.composerFormatOrdered])

        var cancelled = 0
        let replying = ComposerView(replyTo: FlareReplyTarget(senderName: "Ivy", summary: "Hi"), onSend: { _ in },
                                    onCancelReply: { cancelled += 1 })
        try assertNamedTarget(replying, [s.cancelReply])
        try control(replying, s.cancelReply).tap()
        XCTAssertEqual(cancelled, 1)
        try assertNamedTarget(FlareComposerReplyStrip(senderName: "Ivy", summary: "Hi", onCancel: {}), [s.cancelReply])
    }

    // MARK: Media

    @MainActor
    func testImagePreviewCloseAndDownloadAreNamed() throws {
        var closed = 0, downloaded = 0
        let preview = ImagePreviewView(show: true, imageSrc: "https://example.com/a.png",
                                       onClose: { closed += 1 }, onDownload: { downloaded += 1 })
        try assertNamedTarget(preview, [s.imagePreviewClose, s.download])
        XCTAssertEqual(try symbol(control(preview, s.imagePreviewClose)), flareIconMap["close"])
        XCTAssertEqual(try symbol(control(preview, s.download)), flareIconMap["download"])
        try control(preview, s.imagePreviewClose).tap()
        try control(preview, s.download).tap()
        XCTAssertEqual(closed, 1)
        XCTAssertEqual(downloaded, 1)
    }

    @MainActor
    func testVideoAndVoicePlaybackKeysSayWhatATapDoes() throws {
        let video = VideoPlayerView(show: true, videoSrc: "https://example.com/a.mp4", onPlay: {}, onClose: {})
        try assertNamedTarget(video, [s.play, s.close])
        XCTAssertEqual(try symbol(control(video, s.play)), flareIconMap["play"])
        let idle = VoicePlayerView(durationLabel: "0:12", playing: false, onToggle: {})
        try assertNamedTarget(idle, [s.play])
        XCTAssertEqual(try symbol(control(idle, s.play)), flareIconMap["play"])
        let playing = VoicePlayerView(durationLabel: "0:12", playing: true, onToggle: {})
        try assertNamedTarget(playing, [s.pause])
        XCTAssertEqual(try symbol(control(playing, s.pause)), flareIconMap["pause"])
    }

    @MainActor
    func testVoiceRecordingBarCancelAndSendAreNamed() throws {
        var cancelled = 0, sent = 0
        let bar = VoiceRecordingBarView(durationLabel: "0:05", onCancel: { cancelled += 1 }, onSend: { sent += 1 })
        try assertNamedTarget(bar, [s.cancelRecording, s.sendVoice])
        try control(bar, s.cancelRecording).tap()
        try control(bar, s.sendVoice).tap()
        XCTAssertEqual(cancelled, 1)
        XCTAssertEqual(sent, 1)
        let cancelling = VoiceRecordingBarView(durationLabel: "0:05", cancelling: true, onCancel: {}, onSend: {})
        XCTAssertThrowsError(try cancelling.inspect().find(ViewType.Button.self, where: {
            try $0.accessibilityLabel().string() == self.s.sendVoice
        }), "while cancelling there is nothing to send")
    }

    // MARK: Messages

    @MainActor
    func testMessageBatchToolbarExitIsNamed() throws {
        var exited = 0
        let bar = MessageBatchToolbarView(selectedIds: ["a", "b"], total: 5,
                                          capabilities: MessageBatchCapabilities(delete: true),
                                          onExit: { exited += 1 })
        try assertNamedTarget(bar, [s.exitMultiSelect])
        XCTAssertEqual(try symbol(control(bar, s.exitMultiSelect)), flareIconMap["close"])
        try control(bar, s.exitMultiSelect).tap()
        XCTAssertEqual(exited, 1)
    }

    @MainActor
    func testScrollToLatestIsNamedWithTheUnreadCountAsItsValue() throws {
        let pill = ScrollToLatestView(count: 3, onTap: {})
        try assertNamedTarget(pill, [s.scrollToLatest])
        XCTAssertEqual(try control(pill, s.scrollToLatest).accessibilityValue().string(), s.newMessages(3))
        try assertNamedTarget(ScrollToLatestView(onTap: {}), [s.scrollToLatest])
    }

    @MainActor
    func testSheetCloseKeysAreNamed() throws {
        try assertNamedTarget(AnnouncementBannerView(text: "Notice", dismissible: true, onClose: {}),
                              [s.announcementBannerDismiss])
        try assertNamedTarget(ForwardPickerView(targets: [ForwardTarget(id: "c1", name: "Ada")], onClose: {}), [s.close])
        try assertNamedTarget(ReadReceiptSheetView(readers: [], unread: [], dismissible: true, onClose: {}), [s.close])
        try assertNamedTarget(PollComposerView(onCancel: {}), [s.cancel])
    }

    // MARK: Calls

    @MainActor
    func testCallControlsAreNamedAndReportTheirState() throws {
        let video = CallControlsView(muted: true, cameraOn: false, mode: .video, onToggleMute: {},
                                     onToggleCamera: {}, onSwitchCamera: {}, onHangup: {})
        try assertNamedTarget(video, [s.microphone, s.camera, s.flipCamera, s.hangUp])
        XCTAssertEqual(try control(video, s.microphone).accessibilityValue().string(), s.callDeviceOff)
        XCTAssertEqual(try control(video, s.camera).accessibilityValue().string(), s.callDeviceOff)
        XCTAssertEqual(try symbol(control(video, s.microphone)), flareIconMap["mic-off"])
        XCTAssertEqual(try symbol(control(video, s.camera)), flareIconMap["camera-off"])
        XCTAssertEqual(try symbol(control(video, s.flipCamera)), flareIconMap["switch-camera"])
        XCTAssertEqual(try symbol(control(video, s.hangUp)), flareIconMap["end-call"])

        let audio = CallControlsView(muted: false, speakerOn: true, mode: .audio, onToggleMute: {}, onToggleSpeaker: {})
        XCTAssertEqual(try control(audio, s.microphone).accessibilityValue().string(), s.callDeviceOn)
        XCTAssertEqual(try control(audio, s.speaker).accessibilityValue().string(), s.callDeviceOn)
        XCTAssertEqual(try symbol(control(audio, s.speaker)), flareIconMap["speaker"])
        let quiet = CallControlsView(speakerOn: false, mode: .audio, onToggleSpeaker: {})
        XCTAssertEqual(try symbol(control(quiet, s.speaker)), flareIconMap["speaker-off"])
    }

    @MainActor
    func testCallDockIncomingAndGroupCallKeysAreNamed() throws {
        var muted = 0, hungUp = 0
        let dock = CallDockView(title: "Ada", muted: true, onToggleMute: { muted += 1 }, onHangup: { hungUp += 1 })
        try assertNamedTarget(dock, [s.microphone, s.hangUp])
        XCTAssertEqual(try symbol(control(dock, s.microphone)), flareIconMap["mic-off"])
        XCTAssertEqual(try symbol(control(dock, s.hangUp)), flareIconMap["end-call"], "hang up, not a rotated handset")
        try control(dock, s.microphone).tap()
        try control(dock, s.hangUp).tap()
        XCTAssertEqual(muted, 1)
        XCTAssertEqual(hungUp, 1)

        let incoming = IncomingCallView(callerName: "Ada", mode: .audio, onAccept: {}, onReject: {})
        try assertNamedTarget(incoming, [s.reject, s.accept])
        XCTAssertEqual(try symbol(control(incoming, s.reject)), flareIconMap["end-call"])

        let group = GroupCallView(participants: [CallParticipant(id: "u1", name: "Ada")], mode: .video,
                                  state: .connected, onMinimize: {})
        try assertNamedTarget(group, [s.callMinimize])
        XCTAssertEqual(try symbol(control(group, s.callMinimize)), flareIconMap["collapse"])
    }

    // MARK: Form controls

    @MainActor
    func testStepperKeysAreNamedAndKeepTheirBox() throws {
        var value = 2.0
        let binding = Binding(get: { value }, set: { value = $0 })
        let stepper = StepperView(value: binding, min: 0, max: 5, size: .sm)
        try assertNamedTarget(stepper, [s.decrease, s.increase])
        try control(stepper, s.increase).tap()
        XCTAssertEqual(value, 3)
        try control(stepper, s.decrease).tap()
        XCTAssertEqual(value, 2)
    }

    @MainActor
    func testRatingStarsAreNamedButtonsAndAReadOnlyRatingIsOneValue() throws {
        var rating = 3
        let binding = Binding(get: { rating }, set: { rating = $0 })
        let stars = RatingView(value: binding)
        try assertNamedTarget(stars, (1...5).map(s.ratingStar))
        try control(stars, s.ratingStar(5)).tap()
        XCTAssertEqual(rating, 5)
        let readOnly = RatingView(value: .constant(4), readonly: true)
        XCTAssertTrue(try readOnly.inspect().findAll(ViewType.Button.self).isEmpty, "a read-only star is not a control")
        XCTAssertEqual(try readOnly.inspect().find(ViewType.HStack.self).accessibilityValue().string(), "4/5")
    }

    @MainActor
    func testIconButtonViewHasTheMinimumTargetAtEverySize() throws {
        for size in [FlareControlSize.sm, .md, .lg] {
            var taps = 0
            let button = IconButtonView(icon: "close", accessibilityLabel: "Close", size: size) { taps += 1 }
            try assertNamedTarget(button, ["Close"])
            try control(button, "Close").tap()
            XCTAssertEqual(taps, 1)
        }
    }

    // MARK: Pickers, moments, profile

    @MainActor
    func testEmojiAndStickerTabsAreNamedByTheirCategory() throws {
        let picker = EmojiPickerView(categories: [
            EmojiCategory(key: "smileys", label: "Smileys", emojis: ["😀"]),
            EmojiCategory(key: "empty", label: "Empty"),
        ], recents: ["😀"])
        try assertNamedTarget(picker, [s.recent, "Smileys", "Empty"])
        XCTAssertNoThrow(try control(picker, "Empty").labelView().find(text: "Empty"),
                         "a category with nothing to show draws its label, not a stand-in glyph")
        let stickers = StickerPanelView(packs: [StickerPack(key: "cats", label: "Cats", coverEmoji: "🐱")],
                                        recents: [StickerItem(id: "r1")])
        try assertNamedTarget(stickers, [s.recent, "Cats"])
    }

    @MainActor
    func testMomentControlsAreNamed() throws {
        var removed: [Int] = []
        let composer = MomentComposerView(images: ["https://example.com/a.png"], onAddImage: {},
                                          onRemoveImage: { removed.append($0) })
        try assertNamedTarget(composer, [s.removeImage, s.addImage])
        try control(composer, s.removeImage).tap()
        XCTAssertEqual(removed, [0])
        let card = MomentCardView(moment: Moment(id: "m1", author: MomentAuthor(id: "u1", name: "Ada"), text: "Hi"))
        try assertNamedTarget(card, [s.momentActions])
        try assertNamedTarget(MomentsVisibilityRuleListView(kind: .hideFrom, members: [], onAdd: {}),
                              [s.momentsVisibilityRuleListAdd])
    }

    @MainActor
    func testProfileQrCodeKeyIsNamed() throws {
        var opened = 0
        let panel = ProfilePanelView(user: UserProfile(id: "u1", name: "Ada"), onQr: { opened += 1 })
        try assertNamedTarget(panel, [s.myQrCode])
        try control(panel, s.myQrCode).tap()
        XCTAssertEqual(opened, 1)
    }

    @MainActor
    func testStarredContactBadgeIsTheStarIconPlusItsLabel() throws {
        let detail = FlareContactDetail(contact: Contact(id: "u1", name: "Ada"), starred: true)
        let inspected = try detail.inspect()
        XCTAssertNoThrow(try inspected.find(text: s.contactDetailStar))
        XCTAssertThrowsError(try inspected.find(text: "★ \(s.contactDetailStar)"), "no text glyph")
        XCTAssertNoThrow(try inspected.find(ViewType.Image.self, where: { try $0.actualImage().name() == flareIconMap["star"] }))
    }
}
