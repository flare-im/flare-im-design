import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// A voice engine that records what the playback asks of it and lets a test report progress, the end
/// and failures — no audio, no network.
@MainActor
final class FakeVoiceEngine: FlareVoiceEngine {
    var onProgress: ((TimeInterval) -> Void)?
    var onFinish: (() -> Void)?
    var onFailure: (() -> Void)?
    private(set) var played: [URL] = []
    private(set) var pauses = 0
    private(set) var resumes = 0
    private(set) var stops = 0
    func play(_ url: URL) { played.append(url) }
    func pause() { pauses += 1 }
    func resume() { resumes += 1 }
    func stop() { stops += 1 }
}

/// FR-078: received media can be consumed without a host media handler — an image opens the kit
/// preview, a video the kit player, a voice message plays in its bubble one at a time — while a host
/// handler keeps full control, and files, locations and links stay host actions.
final class MediaDefaultsTests: XCTestCase {
    private let s = FlareStrings()
    private let image = FlareImageContent(url: "https://cdn.example.com/full.jpg",
                                          thumbnailURL: "https://cdn.example.com/thumb.jpg", alt: "海边")
    private let video = FlareVideoContent(url: "https://cdn.example.com/clip.mp4",
                                          poster: "https://cdn.example.com/poster.jpg", durationSec: 42)

    @MainActor
    private func session(_ engine: FakeVoiceEngine? = nil) -> FlareMediaSession {
        FlareMediaSession(voice: FlareVoicePlayback(engine: engine ?? FakeVoiceEngine()))
    }

    @MainActor
    private func button(_ view: some View, _ name: String) throws -> InspectableView<ViewType.Button> {
        try view.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == name })
    }

    // MARK: Image

    @MainActor
    func testTappingAnImagePresentsTheKitPreviewOnTheFullSizeImage() throws {
        let media = session()
        let body = MessageContentView(content: image).mediaDefaults(media, messageId: "m1")
        try button(body, "海边").tap()
        let presentation = try XCTUnwrap(media.viewer.presentation)
        XCTAssertEqual(presentation.kind, .image(url: image.url, alt: "海边"))
        XCTAssertNil(presentation.onDownload)

        var closed = 0
        let viewer = FlareMediaViewer(presentation: presentation, onClose: { closed += 1 })
        XCTAssertNoThrow(try viewer.inspect().find(ImagePreviewView.self))
        XCTAssertEqual(try viewer.inspect().find(ViewType.AsyncImage.self).url(), URL(string: image.url))
        try button(viewer, s.imagePreviewClose).tap()
        XCTAssertEqual(closed, 1)
        XCTAssertThrowsError(try button(viewer, s.download), "no download key without a host download handler")

        // Without a full-size URL the preview shows the thumbnail.
        let thumbOnly = session()
        try button(MessageContentView(content: FlareImageContent(url: "", thumbnailURL: image.thumbnailURL))
            .mediaDefaults(thumbOnly, messageId: "m2"), s.messageImage).tap()
        XCTAssertEqual(thumbOnly.viewer.presentation?.kind, .image(url: image.thumbnailURL!, alt: nil))
    }

    @MainActor
    func testTheDownloadKeyAppearsOnlyWithAHostDownloadHandler() throws {
        let media = session()
        var downloaded: [String] = []
        let body = MessageContentView(content: image, onMediaDownload: { downloaded.append($0.type) })
            .mediaDefaults(media, messageId: "m1")
        try button(body, "海边").tap()
        let presentation = try XCTUnwrap(media.viewer.presentation)
        let viewer = FlareMediaViewer(presentation: presentation, onClose: {})
        try button(viewer, s.download).tap()
        XCTAssertEqual(downloaded, ["image"])
    }

    @MainActor
    func testThePreviewClosesOnASwipeDownAndShowsAnImageThatCannotLoad() throws {
        XCTAssertTrue(ImagePreviewView.closesOnDrag(translation: 130, predicted: 150))
        XCTAssertTrue(ImagePreviewView.closesOnDrag(translation: 40, predicted: 260), "a fling closes")
        XCTAssertFalse(ImagePreviewView.closesOnDrag(translation: 40, predicted: 90))

        var closed = 0
        let broken = ImagePreviewView(show: true, imageSrc: "", onClose: { closed += 1 })
        XCTAssertNoThrow(try broken.inspect().find(text: s.imageLoadFailed), "never a blank screen or an endless spinner")
        try button(broken, s.imagePreviewClose).tap()
        XCTAssertEqual(closed, 1)
    }

    // MARK: Video

    @MainActor
    func testTappingAVideoPresentsTheKitPlayerAndStopsAPlayingVoice() throws {
        let engine = FakeVoiceEngine()
        let media = session(engine)
        media.voice.toggle(id: "voice", url: "https://cdn.example.com/a.m4a")
        let body = MessageContentView(content: video).mediaDefaults(media, messageId: "v1")
        let play = try button(body, s.messageVideo)
        XCTAssertEqual(try play.accessibilityValue().string(), "00:42")
        try play.tap()
        let presentation = try XCTUnwrap(media.viewer.presentation)
        XCTAssertEqual(presentation.kind, .video(url: video.url, poster: video.poster))
        XCTAssertNil(media.voice.activeId, "the voice message stops before the video plays")

        var closed = 0
        let viewer = FlareMediaViewer(presentation: presentation, onClose: { closed += 1 })
        XCTAssertNoThrow(try viewer.inspect().find(VideoPlayerView.self))
        try button(viewer, s.close).tap()
        XCTAssertEqual(closed, 1)
        media.dismiss()
        XCTAssertNil(media.viewer.presentation)
    }

    @MainActor
    func testAVideoThatCannotLoadShowsRetryAndClose() throws {
        let playback = FlareVideoPlayback()
        playback.load("not a playable url")
        XCTAssertEqual(playback.phase, .failed)
        var closed = 0
        let surface = FlareVideoSurface(playback: playback, onClose: { closed += 1 })
        XCTAssertNoThrow(try surface.inspect().find(text: s.videoLoadFailed))
        let retry = try button(surface, s.retry)
        XCTAssertEqual(try retry.labelView().find(ViewType.Text.self).flexFrame().minHeight, FlareSizes.touchTargetMin)
        try retry.tap()
        XCTAssertEqual(playback.phase, .failed, "nothing loadable to retry")
        try button(surface, s.close).tap()
        XCTAssertEqual(closed, 1)
        XCTAssertEqual(s.retry, "重试")
        XCTAssertEqual(s.close, "关闭")
    }

    func testOnlyLoadableURLsReachThePlatformPlayer() {
        XCTAssertEqual(FlareVoicePlayback.playableURL("https://cdn.example.com/a.m4a"), URL(string: "https://cdn.example.com/a.m4a"))
        XCTAssertEqual(FlareVoicePlayback.playableURL(" file:///tmp/a.m4a "), URL(string: "file:///tmp/a.m4a"))
        XCTAssertEqual(FlareVoicePlayback.playableURL("/tmp/a.m4a"), URL(fileURLWithPath: "/tmp/a.m4a"))
        XCTAssertNil(FlareVoicePlayback.playableURL(""))
        XCTAssertNil(FlareVoicePlayback.playableURL("javascript:alert(1)"))
        XCTAssertNil(FlareVoicePlayback.playableURL("file-id-123"))
    }

    // MARK: Voice

    @MainActor
    func testVoiceTogglesAndASecondVoiceStopsTheFirst() throws {
        let engine = FakeVoiceEngine()
        let playback = FlareVoicePlayback(engine: engine)
        let first = FlareVoiceMessageBody(content: FlareAudioContent(url: "https://cdn.example.com/a.m4a", durationSec: 12),
                                          id: "a", playback: playback)
        let second = FlareVoiceMessageBody(content: FlareAudioContent(url: "https://cdn.example.com/b.m4a", durationSec: 5),
                                           id: "b", playback: playback)

        try button(first, s.play).tap()
        XCTAssertEqual(playback.activeId, "a")
        XCTAssertEqual(playback.phase, .playing)
        XCTAssertEqual(engine.played, [URL(string: "https://cdn.example.com/a.m4a")!])
        XCTAssertNoThrow(try button(first, s.pause), "the playing voice offers pause")
        XCTAssertEqual(try button(first, s.pause).labelView().find(ViewType.Image.self).actualImage().name(), flareIconMap["pause"])

        try button(second, s.play).tap()
        XCTAssertEqual(playback.activeId, "b")
        XCTAssertEqual(engine.played.last, URL(string: "https://cdn.example.com/b.m4a"))
        XCTAssertGreaterThanOrEqual(engine.stops, 1, "the first voice stopped")
        XCTAssertNoThrow(try button(first, s.play), "the first voice is back to play")

        try button(second, s.pause).tap()
        XCTAssertEqual(playback.phase, .paused)
        XCTAssertEqual(engine.pauses, 1)
        try button(second, s.play).tap()
        XCTAssertEqual(playback.phase, .playing)
        XCTAssertEqual(engine.resumes, 1)
    }

    @MainActor
    func testThePlayingVoiceCountsDownAndResetsAtTheEnd() throws {
        let engine = FakeVoiceEngine()
        let playback = FlareVoicePlayback(engine: engine)
        let body = FlareVoiceMessageBody(content: FlareAudioContent(url: "https://cdn.example.com/a.m4a", durationSec: 12),
                                         id: "a", playback: playback)
        XCTAssertEqual(try button(body, s.play).accessibilityValue().string(), s.voiceSeconds(12))
        try button(body, s.play).tap()
        engine.onProgress?(5.4)
        XCTAssertEqual(playback.elapsed, 5.4)
        XCTAssertEqual(try button(body, s.pause).accessibilityValue().string(), s.voiceSeconds(7))
        XCTAssertNoThrow(try body.inspect().find(text: "7\""), "the time left is visible")
        XCTAssertEqual(VoiceMessageView.playedBars(12, elapsed: 6), 5)
        XCTAssertEqual(VoiceMessageView.playedBars(12, elapsed: nil), 9, "all bars full before playback")
        XCTAssertEqual(VoiceMessageView.shownSeconds(0, elapsed: 4), 4, "an unknown length counts the seconds played")
        XCTAssertEqual(VoiceMessageView.playedBars(0, elapsed: 4), 9)

        engine.onFinish?()
        XCTAssertNil(playback.activeId)
        XCTAssertEqual(playback.phase, .idle)
        XCTAssertEqual(try button(body, s.play).accessibilityValue().string(), s.voiceSeconds(12))
    }

    @MainActor
    func testAFailedVoiceShowsTheFailureAndATapTriesAgain() throws {
        let engine = FakeVoiceEngine()
        let playback = FlareVoicePlayback(engine: engine)
        let body = FlareVoiceMessageBody(content: FlareAudioContent(url: "https://cdn.example.com/a.m4a", durationSec: 3),
                                         id: "a", playback: playback)
        try button(body, s.play).tap()
        engine.onFailure?()
        XCTAssertEqual(playback.phase, .failed)
        let retry = try button(body, s.retry)
        XCTAssertEqual(try retry.accessibilityValue().string(), s.voicePlaybackFailed)
        XCTAssertNoThrow(try body.inspect().find(text: s.voicePlaybackFailed))
        XCTAssertEqual(try retry.labelView().find(ViewType.Image.self).actualImage().name(), flareIconMap["refresh"])
        try retry.tap()
        XCTAssertEqual(playback.phase, .playing)
        XCTAssertEqual(engine.played.count, 2)

        // A voice message without a loadable URL fails at once, without reaching the engine.
        let unresolved = FlareVoiceMessageBody(content: FlareAudioContent(url: "", durationSec: 3), id: "c", playback: playback)
        try button(unresolved, s.play).tap()
        XCTAssertEqual(playback.activeId, "c")
        XCTAssertEqual(playback.phase, .failed)
        XCTAssertEqual(engine.played.count, 2)
    }

    @MainActor
    func testOneVoicePlaysAtATimeAcrossTimelinesAndStopEndsIt() {
        let firstEngine = FakeVoiceEngine(), secondEngine = FakeVoiceEngine()
        let first = FlareVoicePlayback(engine: firstEngine)
        let second = FlareVoicePlayback(engine: secondEngine)
        first.toggle(id: "a", url: "https://cdn.example.com/a.m4a")
        second.toggle(id: "b", url: "https://cdn.example.com/b.m4a")
        XCTAssertNil(first.activeId, "starting a voice in another timeline stops this one")
        XCTAssertEqual(second.activeId, "b")
        let stopsBefore = secondEngine.stops
        second.stop()
        XCTAssertNil(second.activeId)
        XCTAssertEqual(second.phase, .idle)
        XCTAssertEqual(secondEngine.stops, stopsBefore + 1)
    }

    @MainActor
    func testTheContentViewPlaysVoiceInTheTimelinePlaybackUnderTheMessageId() throws {
        let engine = FakeVoiceEngine()
        let media = session(engine)
        let body = MessageContentView(content: FlareAudioContent(url: "https://cdn.example.com/a.m4a", durationSec: 8))
            .mediaDefaults(media, messageId: "m7")
        try button(body, s.play).tap()
        XCTAssertEqual(media.voice.activeId, "m7")
        XCTAssertEqual(engine.played, [URL(string: "https://cdn.example.com/a.m4a")!])
    }

    // MARK: Host control

    @MainActor
    func testAHostMediaHandlerTakesPrecedenceOverTheDefaults() throws {
        let engine = FakeVoiceEngine()
        let media = session(engine)
        var handled: [String] = []
        for content in [image, video, FlareAudioContent(url: "https://cdn.example.com/a.m4a", durationSec: 3)] as [FlareMessageContent] {
            let body = MessageContentView(content: content, onMediaAction: { handled.append($0.type) })
                .mediaDefaults(media, messageId: content.type)
            try body.inspect().find(ViewType.Button.self).tap()
        }
        XCTAssertEqual(handled, ["image", "video", "audio"])
        XCTAssertNil(media.viewer.presentation)
        XCTAssertNil(media.voice.activeId)
        XCTAssertEqual(engine.played, [])
        XCTAssertFalse(MessageContentView.usesMediaDefaults(image, hostHandles: true))
        XCTAssertTrue(MessageContentView.usesMediaDefaults(image, hostHandles: false))
    }

    @MainActor
    func testFilesAndLocationsStayHostActions() throws {
        let media = session()
        // Links are no longer in this list: a link card with a web address opens through the kit's link
        // intent (K4, `TextLinkAndInlineEmojiTests`). A file and a location still have no kit default.
        let host: [FlareMessageContent] = [
            FlareFileContent(name: "report.pdf", url: "https://cdn.example.com/report.pdf", sizeBytes: 2048),
            FlareLocationContent(name: "西湖", address: "杭州"),
        ]
        for content in host {
            XCTAssertFalse(MessageContentView.usesMediaDefaults(content, hostHandles: false))
            let inert = MessageContentView(content: content).mediaDefaults(media, messageId: "x")
            XCTAssertThrowsError(try inert.inspect().find(ViewType.Button.self), "\(content.type): no kit default")
            var opened = 0
            let wired = MessageContentView(content: content, onMediaAction: { _ in opened += 1 }).mediaDefaults(media, messageId: "x")
            try wired.inspect().find(ViewType.Button.self).tap()
            XCTAssertEqual(opened, 1, content.type)
        }
        // A host media handler still takes every link-card tap.
        var cardTaps = 0
        let card = MessageContentView(content: FlareLinkCardContent(url: "https://flare.im", title: "Flare"),
                                      onMediaAction: { _ in cardTaps += 1 }).mediaDefaults(media, messageId: "x")
        try card.inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(cardTaps, 1)
        XCTAssertFalse(MessageContentView.usesMediaDefaults(FlareLinkCardContent(url: "https://flare.im", title: "Flare"),
                                                            hostHandles: false), "a link card is not media")
        XCTAssertNil(media.viewer.presentation)
    }

    @MainActor
    func testAFileTapGoesToTheHostFileOpenerWithoutTurningTheMediaDefaultsOff() throws {
        let media = session()
        let file = FlareFileContent(name: "report.pdf", url: "https://cdn.example.com/report.pdf", sizeBytes: 2048)
        var opened: [String] = []
        let message = FlareMessageData(id: "f1", senderId: "peer", senderName: "Ann", content: file)
        let bubble = MessageBubbleView(message: message, currentUserId: "me",
                                       onOpenFile: { message, file in opened.append("\(message.id):\(file.url)") })
            .mediaDefaults(media)
        try bubble.inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(opened, ["f1:https://cdn.example.com/report.pdf"])

        // The same host still gets the kit image preview.
        let photo = MessageBubbleView(message: FlareMessageData(id: "p1", senderId: "peer", senderName: "Ann", content: image),
                                      currentUserId: "me", onOpenFile: { _, _ in opened.append("never") })
            .mediaDefaults(media)
        try button(photo, "海边").tap()
        XCTAssertNotNil(media.viewer.presentation)

        // A media handler keeps full control of files too.
        var handled = 0
        let controlled = MessageContentView(content: file, onMediaAction: { _ in handled += 1 },
                                            onOpenFile: { _ in opened.append("never") })
        try controlled.inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(handled, 1)
        XCTAssertEqual(opened, ["f1:https://cdn.example.com/report.pdf"])
    }

    @MainActor
    func testTheBubbleGivesItsBodyTheTimelineMediaDefaultsAndItsMessageId() throws {
        let engine = FakeVoiceEngine()
        let media = session(engine)
        let message = FlareMessageData(id: "msg-1", senderId: "peer", senderName: "Ann",
                                       content: FlareAudioContent(url: "https://cdn.example.com/a.m4a", durationSec: 4))
        let bubble = MessageBubbleView(message: message, currentUserId: "me").mediaDefaults(media)
        try button(bubble, s.play).tap()
        XCTAssertEqual(media.voice.activeId, "msg-1")

        var downloads: [String] = []
        let photo = FlareMessageData(id: "msg-2", senderId: "peer", senderName: "Ann", content: image)
        let photoBubble = MessageBubbleView(message: photo, currentUserId: "me",
                                            onMediaDownload: { message, _ in downloads.append(message.id) }).mediaDefaults(media)
        try button(photoBubble, "海边").tap()
        try XCTUnwrap(media.viewer.presentation?.onDownload)()
        XCTAssertEqual(downloads, ["msg-2"])
    }
}
