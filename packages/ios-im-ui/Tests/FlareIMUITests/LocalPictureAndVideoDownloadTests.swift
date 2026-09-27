import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// A picture draws the copy the host resolved through the SDK media cache (`FlareImageContent.localPath`) for anyone's
/// message — bubble, album, preview and gallery — while a file address in the message's own `url` is never drawn; and
/// the kit's video player offers the host's download (VideoPlayerModal `download`, `downloading`, `progressPct`).
final class LocalPictureAndVideoDownloadTests: XCTestCase {
    private let s = FlareStrings()
    private let cachedPath = "/tmp/cache/a.png"
    private var cached: FlareImageContent {
        FlareImageContent(url: "https://cdn.example/a.png?sig=1", thumbnailURL: "https://cdn.example/a-thumb.png",
                          localPath: cachedPath)
    }
    private let video = FlareVideoContent(url: "https://cdn.example/v.mp4", poster: "https://cdn.example/v.jpg",
                                          durationSec: 42)

    @MainActor
    private func session() -> FlareMediaSession {
        FlareMediaSession(voice: FlareVoicePlayback(engine: FakeVoiceEngine()))
    }

    @MainActor
    private func button(_ view: some View, _ name: String) throws -> InspectableView<ViewType.Button> {
        try view.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == name })
    }

    /// The addresses the view hands to its image loaders.
    @MainActor
    private func loaded(_ view: some View) throws -> [URL?] {
        try view.inspect().findAll(ViewType.AsyncImage.self).map { try $0.url() }
    }

    private func message(_ content: FlareMessageContent, from sender: String = "ivy") -> FlareMessageData {
        FlareMessageData(id: "m-\(sender)", senderId: sender, senderName: sender, content: content)
    }

    // MARK: Picture source

    func testAPictureSourcePrefersTheLocalCopyThenThumbnailOrFullSize() {
        let remote = FlareImageContent(url: "https://cdn.example/full.png", thumbnailURL: "https://cdn.example/thumb.png")
        XCTAssertEqual(flarePictureSource(remote), FlarePictureSource(src: "https://cdn.example/thumb.png", local: false))
        XCTAssertEqual(flarePictureSource(remote, preferThumbnail: false),
                       FlarePictureSource(src: "https://cdn.example/full.png", local: false))
        XCTAssertEqual(flarePictureSource(FlareImageContent(url: " https://cdn.example/full.png ", thumbnailURL: " ")),
                       FlarePictureSource(src: "https://cdn.example/full.png", local: false), "a blank thumbnail falls back")
        XCTAssertEqual(flarePictureSource(FlareImageContent(url: "", thumbnailURL: "https://cdn.example/thumb.png"),
                                          preferThumbnail: false),
                       FlarePictureSource(src: "https://cdn.example/thumb.png", local: false))
        XCTAssertEqual(flarePictureSource(FlareImageContent(url: "", localPath: "/c/p.png")),
                       FlarePictureSource(src: "/c/p.png", local: true))
        XCTAssertEqual(flarePictureSource(cached, preferThumbnail: false), FlarePictureSource(src: cachedPath, local: true))
        XCTAssertEqual(flarePictureSource(FlareImageContent(url: "https://cdn.example/full.png", localPath: "  ")),
                       FlarePictureSource(src: "https://cdn.example/full.png", local: false), "a blank local path is none")
        XCTAssertEqual(flarePictureSource(FlareImageContent(url: "")), FlarePictureSource(src: "", local: false))
    }

    func testOnlyTheLocalCopyOpensAFileOnThisDevice() {
        XCTAssertEqual(flarePictureURL("https://cdn.example/a.png"), URL(string: "https://cdn.example/a.png"))
        XCTAssertEqual(flarePictureURL("https://cdn.example/a.png", local: true), URL(string: "https://cdn.example/a.png"))
        XCTAssertNil(flarePictureURL("/tmp/picked.png"), "an absolute path in message content")
        XCTAssertNil(flarePictureURL("file:///tmp/picked.png"), "a file URL in message content")
        XCTAssertNil(flarePictureURL("FILE:///tmp/picked.png"))
        XCTAssertNil(flarePictureURL(""))
        XCTAssertNil(flarePictureURL(nil))
        XCTAssertEqual(flarePictureURL("/tmp/picked.png", local: true), URL(fileURLWithPath: "/tmp/picked.png"))
        XCTAssertEqual(flarePictureURL(" file:///tmp/picked.png ", local: true), URL(string: "file:///tmp/picked.png"))
    }

    // MARK: The local copy is drawn

    @MainActor
    func testTheLocalCopyIsDrawnForAnyonesPictureInTheBubbleAndThePreview() throws {
        let file = URL(fileURLWithPath: cachedPath)
        let media = session()
        let bubble = MessageBubbleView(message: message(cached), currentUserId: "me").mediaDefaults(media)
        XCTAssertEqual(Set(try loaded(bubble)), [file], "a received picture draws the host's local copy, not the web address")

        try button(bubble, s.messageImage).tap()
        let presentation = try XCTUnwrap(media.viewer.presentation)
        XCTAssertEqual(presentation.kind, .image(url: cachedPath, alt: nil, local: true))
        let viewer = FlareMediaViewer(presentation: presentation, onClose: {})
        XCTAssertNoThrow(try viewer.inspect().find(ImagePreviewView.self))
        XCTAssertEqual(try loaded(viewer), [file], "the preview draws the local copy too")

        // My own picture is drawn from it the same way.
        let mine = MessageBubbleView(message: message(cached, from: "me"), currentUserId: "me").mediaDefaults(session())
        XCTAssertEqual(Set(try loaded(mine)), [file])
    }

    @MainActor
    func testAnAlbumAndTheGalleryDrawTheLocalCopies() throws {
        let album = FlareImageGroupContent(images: [
            FlareImageContent(url: "https://cdn.example/0.jpg", localPath: "/tmp/cache/0.jpg"),
            FlareImageContent(url: "https://cdn.example/1.jpg", thumbnailURL: "https://cdn.example/1-thumb.jpg"),
        ])
        XCTAssertEqual(try loaded(ImageGroupMessageView(images: album.images)),
                       [URL(fileURLWithPath: "/tmp/cache/0.jpg"), URL(string: "https://cdn.example/1-thumb.jpg")])

        let messages = [message(cached, from: "ann"), FlareMessageData(id: "album", senderId: "ivy", senderName: "ivy",
                                                                       content: album)]
        let media = session()
        let body = MessageContentView(content: album)
            .mediaDefaults(media, messageId: "album", gallery: FlareImageGallerySource(messages: messages, download: nil))
        try body.inspect().find(ImageGroupMessageView.self).findAll(ViewType.Button.self)[0].tap()
        let presentation = try XCTUnwrap(media.viewer.presentation)
        guard case let .gallery(images, index) = presentation.kind else { return XCTFail("a gallery, not \(presentation.kind)") }
        XCTAssertEqual(index, 1)
        XCTAssertEqual(images.map(\.url), [cachedPath, "/tmp/cache/0.jpg", "https://cdn.example/1.jpg"])
        XCTAssertEqual(images.map(\.local), [true, true, false])

        let first = FlareImageGalleryViewer(images: images, startIndex: 0, onClose: {})
        XCTAssertEqual(try loaded(first), [URL(fileURLWithPath: cachedPath)])
        let last = FlareImageGalleryViewer(images: images, startIndex: 2, onClose: {})
        XCTAssertEqual(try loaded(last), [URL(string: "https://cdn.example/1.jpg")])
    }

    // MARK: A file address in message content is not

    @MainActor
    func testAFileAddressInTheMessageUrlAloneIsStillNotDrawn() throws {
        for address in ["/tmp/picked.png", "file:///tmp/picked.png"] {
            let picked = FlareImageContent(url: address)
            let media = session()
            let bubble = MessageBubbleView(message: message(picked), currentUserId: "me").mediaDefaults(media)
            XCTAssertEqual(try loaded(bubble), [], "\(address): the bubble shows its placeholder")

            try button(bubble, s.messageImage).tap()
            let presentation = try XCTUnwrap(media.viewer.presentation)
            XCTAssertEqual(presentation.kind, .image(url: address, alt: nil, local: false))
            let viewer = FlareMediaViewer(presentation: presentation, onClose: {})
            XCTAssertEqual(try loaded(viewer), [], "\(address): the preview loads nothing")
            XCTAssertNoThrow(try viewer.inspect().find(text: s.imageLoadFailed))

            XCTAssertEqual(try loaded(ImageGroupMessageView(images: [picked])), [], "\(address): nor does an album tile")
            XCTAssertEqual(try loaded(ImagePreviewView(show: true, imageSrc: address)), [])
        }
        // The same address is drawn once the host says it is the local copy.
        XCTAssertEqual(try loaded(ImagePreviewView(show: true, imageSrc: "/tmp/picked.png", allowLocalFile: true)),
                       [URL(fileURLWithPath: "/tmp/picked.png")])
        XCTAssertEqual(try loaded(ImageMessageView(src: "file:///tmp/picked.png", allowLocalFile: true)),
                       [URL(string: "file:///tmp/picked.png")])
    }

    // MARK: Video download

    @MainActor
    func testTheVideoPlayerOffersADownloadKeyOnlyWithAHandlerAndCallsBackWithTheVideo() throws {
        let media = session()
        var saved: [FlareMessageContent] = []
        let body = MessageContentView(content: video, onMediaDownload: { saved.append($0) }).mediaDefaults(media, messageId: "v1")
        try button(body, s.messageVideo).tap()
        let presentation = try XCTUnwrap(media.viewer.presentation)
        XCTAssertEqual(presentation.kind, .video(url: video.url, poster: video.poster))
        let viewer = FlareMediaViewer(presentation: presentation, onClose: {})
        try button(viewer, s.download).tap()
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual((saved.first as? FlareVideoContent)?.url, video.url, "the key saves the video on screen")

        let plain = session()
        try button(MessageContentView(content: video).mediaDefaults(plain, messageId: "v2"), s.messageVideo).tap()
        let unwired = FlareMediaViewer(presentation: try XCTUnwrap(plain.viewer.presentation), onClose: {})
        XCTAssertNoThrow(try button(unwired, s.close))
        XCTAssertThrowsError(try button(unwired, s.download), "no download key without a host download handler")
    }

    @MainActor
    func testATimelineVideoDownloadsWithTheMessageItBelongsTo() throws {
        let media = session()
        var downloads: [String] = []
        let bubble = MessageBubbleView(message: message(video), currentUserId: "me",
                                       onMediaDownload: { message, content in downloads.append("\(message.id):\(content.type)") })
            .mediaDefaults(media)
        try button(bubble, s.messageVideo).tap()
        try XCTUnwrap(media.viewer.presentation?.onDownload)()
        XCTAssertEqual(downloads, ["m-ivy:video"])
    }

    @MainActor
    func testTheDownloadKeyLooksLikeThePreviewsAndShowsProgressWhileDownloading() throws {
        var downloads = 0
        let player = VideoPlayerView(show: true, videoSrc: video.url, onClose: {}, onDownload: { downloads += 1 })
        let key = try button(player, s.download)
        XCTAssertEqual(try key.labelView().find(ViewType.Image.self).actualImage().name(), flareIconMap["download"])
        let close = try button(player, s.close)
        XCTAssertEqual(try key.labelView().find(ViewType.Image.self).fixedFrame().width,
                       try close.labelView().find(ViewType.Image.self).fixedFrame().width, "the close key's size")
        XCTAssertEqual(try key.labelView().find(ViewType.Image.self).fixedFrame().width, FlareSizes.touchTarget)
        try key.tap()
        XCTAssertEqual(downloads, 1)

        let busy = VideoPlayerView(show: true, videoSrc: video.url, onDownload: {}, downloading: true, progressPct: 37)
        XCTAssertThrowsError(try button(busy, s.download), "the ring takes the key's place")
        let ring = try busy.inspect().find(FlareMediaDownloadRing.self)
        XCTAssertNoThrow(try ring.find(text: "37"))
        XCTAssertEqual(try ring.zStack().accessibilityLabel().string(), s.download, "read as the download key, with its percent")
        XCTAssertEqual(try ring.zStack().accessibilityValue().string(), "37%")
        XCTAssertNoThrow(try VideoPlayerView(show: true, videoSrc: video.url, onDownload: {}, downloading: true, progressPct: 140)
            .inspect().find(text: "100"), "progress stops at 100")

        let none = VideoPlayerView(show: true, videoSrc: video.url, downloading: true, progressPct: 37)
        XCTAssertThrowsError(try button(none, s.download))
        XCTAssertThrowsError(try none.inspect().find(FlareMediaDownloadRing.self), "nothing to download without a handler")
    }
}

#if os(macOS)
import AppKit

/// On a hosted view the platform image loader really loads the address the kit hands it for a local copy — a
/// ViewInspector test only sees the address, not the load.
final class LocalPictureHostedTests: XCTestCase {
    private final class Log { var phase = "empty" }

    /// A solid red PNG in the temporary directory.
    private func picture() throws -> URL {
        let side = 16
        let rep = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
                                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                                 colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        for x in 0..<side { for y in 0..<side { rep.setColor(.red, atX: x, y: y) } }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("flare-local-\(UUID().uuidString).png")
        try XCTUnwrap(rep.representation(using: .png, properties: [:])).write(to: file)
        addTeardownBlock { try? FileManager.default.removeItem(at: file) }
        return file
    }

    /// Where `AsyncImage` — what ``ImageMessageView``, the album tiles and ``ImagePreviewView`` draw with — ends up for
    /// `url` in a hosted window: `success`, `failure`, or still `empty` after `seconds`.
    @MainActor
    private func phase(_ url: URL?, waiting seconds: TimeInterval = 3) -> String {
        _ = NSApplication.shared
        let log = Log()
        let view = AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image): image.resizable().onAppear { log.phase = "success" }
            case .failure: Color.clear.onAppear { log.phase = "failure" }
            default: Color.clear
            }
        }
        let size = NSSize(width: 120, height: 90)
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        let deadline = Date().addingTimeInterval(seconds)
        while log.phase == "empty" && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        return log.phase
    }

    @MainActor
    func testTheLocalCopyLoadsAndAFileAddressInContentIsNeverHandedToTheLoader() throws {
        let file = try picture()
        XCTAssertEqual(phase(flarePictureURL(file.path, local: true)), "success", "an absolute path, as the SDK cache gives it")
        XCTAssertEqual(phase(flarePictureURL(file.absoluteString, local: true)), "success", "a file URL")
        // Parsed as a web address the path does not load at all; a file URL does — which is why the kit resolves
        // the local copy itself and never hands the loader a file address from message content.
        XCTAssertEqual(phase(URL(string: file.path)), "failure")
        XCTAssertEqual(phase(URL(string: file.absoluteString)), "success")
        XCTAssertNil(flarePictureURL(file.absoluteString))
        XCTAssertNil(flarePictureURL(file.path))
    }
}
#endif
