import Combine
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// A message's picture, video or file on this device: the file card's trailing key and the key of the image preview
/// and the video player follow the host's download state — a download, the save's progress, then a folder that asks
/// the host to show the saved file (`onMediaReveal`) — and an open viewer follows the state as it changes. Also the
/// timeline's display rules that came with it: no made-up 00:00 on a video, pictures at their own aspect.
final class MediaDownloadRevealTests: XCTestCase {
    private let s = FlareStrings()
    private let file = FlareFileContent(name: "连调测试.txt", url: "https://cdn.example/f.txt", sizeBytes: 8704)
    private let video = FlareVideoContent(url: "https://cdn.example/v.mp4", poster: "https://cdn.example/v.jpg")
    private let picture = FlareImageContent(url: "https://cdn.example/p.jpg", alt: "海边")

    private static let downloading = FlareMediaDownloadState(status: .downloading, progressPct: 42)
    private static let saved = FlareMediaDownloadState(status: .done)

    @MainActor
    private func session() -> FlareMediaSession {
        FlareMediaSession(voice: FlareVoicePlayback(engine: FakeVoiceEngine()))
    }

    @MainActor
    private func button(_ view: some View, _ name: String) throws -> InspectableView<ViewType.Button> {
        try view.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == name })
    }

    private func message(_ id: String, _ content: FlareMessageContent, from sender: String = "ivy") -> FlareMessageData {
        FlareMessageData(id: id, senderId: sender, senderName: sender, content: content, timeLabel: "00:11")
    }

    // MARK: File card key

    func testTheFileKeyIsADownloadThenProgressThenAFolder() {
        XCTAssertNil(FileMessageView.key(nil, canDownload: false, canReveal: true), "no key without a download handler")
        XCTAssertEqual(FileMessageView.key(nil, canDownload: true, canReveal: true), .download)
        XCTAssertEqual(FileMessageView.key(FlareMediaDownloadState(status: .failed), canDownload: true, canReveal: true),
                       .download, "a failed save is tried again")
        XCTAssertEqual(FileMessageView.key(Self.downloading, canDownload: true, canReveal: true), .progress(42))
        XCTAssertEqual(FileMessageView.key(FlareMediaDownloadState(status: .downloading, progressPct: 140),
                                           canDownload: true, canReveal: true), .progress(100))
        XCTAssertEqual(FileMessageView.key(Self.saved, canDownload: true, canReveal: true), .folder)
        XCTAssertEqual(FileMessageView.key(Self.saved, canDownload: true, canReveal: false), .download,
                       "a host that cannot show the file keeps the download")
    }

    func testTheSizeLineKeepsSizeAndTypeAndSaysWhereTheFileStands() {
        XCTAssertEqual(FileMessageView.subtitle(size: "8.5 KB", ext: "TXT", state: nil, strings: s), "8.5 KB · TXT")
        XCTAssertEqual(FileMessageView.subtitle(size: "8.5 KB", ext: nil, state: FlareMediaDownloadState(status: .failed),
                                                strings: s), "8.5 KB")
        XCTAssertEqual(FileMessageView.subtitle(size: "8.5 KB", ext: "TXT", state: Self.downloading, strings: s),
                       "8.5 KB · TXT · \(s.downloading) 42%")
        XCTAssertEqual(FileMessageView.subtitle(size: "8.5 KB", ext: "TXT",
                                                state: FlareMediaDownloadState(status: .downloading), strings: s),
                       "8.5 KB · TXT · \(s.downloading)")
        XCTAssertEqual(FileMessageView.subtitle(size: "8.5 KB", ext: "TXT", state: Self.saved, strings: s),
                       "8.5 KB · TXT · \(s.downloaded)")
    }

    @MainActor
    func testTheFileCardDrawsItsKeyWithTheKitIconsAndNames() throws {
        var calls: [String] = []
        func card(_ state: FlareMediaDownloadState?) -> FileMessageView {
            FileMessageView(name: file.name, size: "8.5 KB", ext: "TXT", onOpen: { calls.append("open") },
                            onDownload: { calls.append("download") }, downloadState: state,
                            onReveal: { calls.append("reveal") })
        }

        let idle = try button(card(nil), s.download)
        XCTAssertEqual(try idle.labelView().find(ViewType.Image.self).actualImage().name(), flareIconMap["download"])
        XCTAssertGreaterThanOrEqual(try idle.labelView().fixedFrame().width, FlareSizes.touchTargetMin,
                                    "the key's target is at least the touch target")
        try idle.tap()

        let busy = card(Self.downloading)
        XCTAssertThrowsError(try button(busy, s.download), "the progress takes the key's place")
        XCTAssertThrowsError(try button(busy, s.showInFolder))
        let progress = try busy.inspect().find(where: { try $0.accessibilityLabel().string() == self.s.downloading })
        XCTAssertEqual(try progress.accessibilityValue().string(), "42%")
        XCTAssertNoThrow(try busy.inspect().find(text: "8.5 KB · TXT · \(s.downloading) 42%"))

        let done = card(Self.saved)
        XCTAssertThrowsError(try button(done, s.download), "never a spent download key")
        let folder = try button(done, s.showInFolder)
        XCTAssertEqual(try folder.labelView().find(ViewType.Image.self).actualImage().name(), flareIconMap["folder"])
        try folder.tap()
        XCTAssertNoThrow(try done.inspect().find(text: "8.5 KB · TXT · \(s.downloaded)"))

        // The card itself still opens the file.
        try done.inspect().find(ViewType.Button.self, where: { (try? $0.find(text: self.file.name)) != nil }).tap()
        XCTAssertEqual(calls, ["download", "reveal", "open"])

        let named = FileMessageView(name: file.name, onDownload: {}, downloadLabel: "保存")
        XCTAssertNoThrow(try button(named, "保存"), "the host may name its download key")
        XCTAssertThrowsError(try FileMessageView(name: file.name).inspect().find(ViewType.Button.self),
                             "no handlers, no controls")
    }

    @MainActor
    func testATimelineFileCardDownloadsAndRevealsWithItsMessage() throws {
        var calls: [String] = []
        let incoming = message("f1", file)
        func bubble(_ state: FlareMediaDownloadState?) -> MessageBubbleView {
            MessageBubbleView(message: incoming, currentUserId: "me", mediaState: state,
                              onMediaDownload: { message, content in calls.append("download:\(message.id):\(content.type)") },
                              onMediaReveal: { message, content in calls.append("reveal:\(message.id):\(content.type)") },
                              onOpenFile: { message, _ in calls.append("open:\(message.id)") })
        }

        let idle = bubble(nil)
        XCTAssertNoThrow(try idle.inspect().find(text: "8.5 KB · TXT"), "the type comes from the file name")
        try button(idle, s.download).tap()
        XCTAssertThrowsError(try button(bubble(Self.downloading), s.download))
        try button(bubble(Self.saved), s.showInFolder).tap()
        // The host found the saved file gone and passed idle again: a download once more.
        try button(bubble(FlareMediaDownloadState(status: .idle)), s.download).tap()
        try idle.inspect().find(ViewType.Button.self, where: { (try? $0.find(text: self.file.name)) != nil }).tap()
        XCTAssertEqual(calls, ["download:f1:file", "reveal:f1:file", "download:f1:file", "open:f1"])

        let unwired = MessageBubbleView(message: incoming, currentUserId: "me", onOpenFile: { _, _ in })
        XCTAssertThrowsError(try button(unwired, s.download), "no key without the host's download handler")
    }

    // MARK: Viewers follow the live state

    @MainActor
    func testTheVideoPlayerKeyFollowsTheStateWhileItIsOpen() throws {
        var calls: [String] = []
        let media = session()
        let bubble = MessageBubbleView(message: message("v1", video), currentUserId: "me",
                                       onMediaDownload: { message, _ in calls.append("download:\(message.id)") },
                                       onMediaReveal: { message, _ in calls.append("reveal:\(message.id)") })
            .mediaDefaults(media)
        try button(bubble, s.messageVideo).tap()
        let presentation = try XCTUnwrap(media.viewer.presentation)
        XCTAssertEqual(presentation.downloadId, "v1")
        let viewer = FlareMediaViewer(presentation: presentation, onClose: {}, downloads: media.downloads)

        try button(viewer, s.download).tap()
        media.downloads.update(["v1": FlareMediaDownloadState(status: .downloading, progressPct: 30)])
        XCTAssertThrowsError(try button(viewer, s.download), "the progress takes the key's place")
        XCTAssertNoThrow(try viewer.inspect().find(FlareMediaDownloadRing.self).find(text: "30"))

        media.downloads.update(["v1": Self.saved])
        let folder = try button(viewer, s.showInFolder)
        XCTAssertEqual(try folder.labelView().find(ViewType.Image.self).actualImage().name(), flareIconMap["folder"])
        try folder.tap()

        media.downloads.update(["v1": FlareMediaDownloadState(status: .idle)])
        XCTAssertNoThrow(try button(viewer, s.download), "a saved file found gone is a download again")
        XCTAssertThrowsError(try button(viewer, s.showInFolder))
        XCTAssertEqual(calls, ["download:v1", "reveal:v1"])
    }

    @MainActor
    func testTheImagePreviewKeyFollowsTheStateWhileItIsOpen() throws {
        var calls: [String] = []
        let media = session()
        let bubble = MessageBubbleView(message: message("i1", picture), currentUserId: "me",
                                       onMediaDownload: { message, _ in calls.append("download:\(message.id)") },
                                       onMediaReveal: { message, _ in calls.append("reveal:\(message.id)") })
            .mediaDefaults(media)
        try button(bubble, "海边").tap()
        let viewer = FlareMediaViewer(presentation: try XCTUnwrap(media.viewer.presentation), onClose: {},
                                      downloads: media.downloads)
        try button(viewer, s.download).tap()
        media.downloads.update(["i1": Self.downloading])
        XCTAssertNoThrow(try viewer.inspect().find(FlareMediaDownloadRing.self).find(text: "42"))
        media.downloads.update(["i1": Self.saved])
        try button(viewer, s.showInFolder).tap()
        XCTAssertEqual(calls, ["download:i1", "reveal:i1"])

        // Another message's state is not this picture's.
        media.downloads.update(["other": Self.saved])
        XCTAssertNoThrow(try button(viewer, s.download))
    }

    @MainActor
    func testTheGalleryFollowsAnImageMessagesStateButNotAnAlbums() throws {
        var calls: [String] = []
        let album = FlareImageGroupContent(images: [FlareImageContent(url: "https://cdn.example/a0.jpg"),
                                                    FlareImageContent(url: "https://cdn.example/a1.jpg")])
        let messages = [message("m1", picture), message("m2", album)]
        let source = FlareImageGallerySource(messages: messages,
                                             download: { message, _ in calls.append("download:\(message.id)") },
                                             reveal: { message, _ in calls.append("reveal:\(message.id)") })
        let media = session()
        try button(MessageContentView(content: picture).mediaDefaults(media, messageId: "m1", gallery: source), "海边").tap()
        let presentation = try XCTUnwrap(media.viewer.presentation)
        guard case let .gallery(images, index) = presentation.kind else { return XCTFail("a gallery, not \(presentation.kind)") }
        XCTAssertEqual(index, 0)
        XCTAssertEqual(images.map(\.downloadId), ["m1", nil, nil], "an album's state would stand for all its pictures")
        XCTAssertEqual(images.map { $0.onReveal != nil }, [true, false, false])

        media.downloads.update(["m1": Self.saved, "m2": Self.saved])
        let viewer = FlareMediaViewer(presentation: presentation, onClose: {}, downloads: media.downloads)
        try button(viewer, s.showInFolder).tap()
        let albumPicture = FlareImageGalleryViewer(images: images, startIndex: 1, onClose: {}, states: media.downloads.states)
        try button(albumPicture, s.download).tap()
        XCTAssertEqual(calls, ["reveal:m1", "download:m2"])
    }

    @MainActor
    func testTheBoardPublishesOnlyAChange() {
        let board = FlareMediaDownloadBoard()
        var changes = 0
        let watch = board.objectWillChange.sink { changes += 1 }
        defer { watch.cancel() }
        board.update(["a": Self.saved])
        board.update(["a": Self.saved])
        XCTAssertEqual(changes, 1, "the same states do not redraw an open viewer")
        XCTAssertEqual(board.states, ["a": Self.saved])
    }

    // MARK: Keys of the preview and the player

    func testTheViewerKeyIsTheFolderOnlyForSavedMediaTheHostCanShow() {
        XCTAssertNil(FlareMediaKey.resolve(canDownload: false, downloading: false, saved: true, canReveal: true))
        XCTAssertEqual(FlareMediaKey.resolve(canDownload: true, downloading: false, saved: false, canReveal: true), .download)
        XCTAssertEqual(FlareMediaKey.resolve(canDownload: true, downloading: true, saved: false, canReveal: true), .progress)
        XCTAssertEqual(FlareMediaKey.resolve(canDownload: true, downloading: false, saved: true, canReveal: true), .folder)
        XCTAssertEqual(FlareMediaKey.resolve(canDownload: true, downloading: false, saved: true, canReveal: false), .download)
    }

    @MainActor
    func testTheStandaloneViewersTakeASavedStateAndARevealHandler() throws {
        var revealed = 0
        let preview = ImagePreviewView(show: true, imageSrc: picture.url, onClose: {}, onDownload: {}, saved: true,
                                       onReveal: { revealed += 1 })
        XCTAssertThrowsError(try button(preview, s.download))
        try button(preview, s.showInFolder).tap()
        let player = VideoPlayerView(show: true, videoSrc: video.url, onClose: {}, onDownload: {}, saved: true,
                                     onReveal: { revealed += 1 })
        XCTAssertThrowsError(try button(player, s.download))
        try button(player, s.showInFolder).tap()
        XCTAssertEqual(revealed, 2)
    }

    // MARK: Display rules

    @MainActor
    func testAVideoWithoutAKnownDurationDrawsNoBadge() throws {
        XCTAssertFalse(VideoMessageView.showsDuration(""))
        XCTAssertTrue(VideoMessageView.showsDuration("01:05"))
        let unknown = MessageContentView(content: FlareVideoContent(url: video.url, durationSec: 0), onMediaAction: { _ in })
        XCTAssertThrowsError(try unknown.inspect().find(text: "00:00"), "an unknown length is not 00:00")
        XCTAssertEqual(try button(unknown, s.messageVideo).accessibilityValue().string(), "")
        let known = MessageContentView(content: FlareVideoContent(url: video.url, durationSec: 65), onMediaAction: { _ in })
        XCTAssertNoThrow(try known.inspect().find(text: "01:05"))
        XCTAssertNoThrow(try VideoMessageView().inspect().find(FlareVideoPlayDisc.self), "the play disc, with or without a poster")
    }

    func testAPictureIsDrawnAtItsOwnAspectWhenTheHostKnowsIt() {
        func size(_ w: Double?, _ h: Double?) -> CGSize {
            MessageContentView.imageSize(FlareImageContent(url: "https://cdn.example/p.jpg", width: w, height: h))
        }
        XCTAssertEqual(size(nil, nil), CGSize(width: 240, height: 180), "4:3 while the size is unknown")
        XCTAssertEqual(size(1000, 500), CGSize(width: 240, height: 120))
        XCTAssertEqual(size(100, 1000), CGSize(width: 240, height: 240), "a tall picture stops at a square")
        XCTAssertEqual(size(1000, 10), CGSize(width: 240, height: 48), "a strip keeps a tappable height")
        XCTAssertEqual(size(0, 10), CGSize(width: 240, height: 180))
    }

    func testAFileCardNamesItsTypeFromTheFileName() {
        XCTAssertEqual(MessageContentView.fileExtension("连调测试.txt"), "TXT")
        XCTAssertEqual(MessageContentView.fileExtension("Q3 plan.final.pdf"), "PDF")
        XCTAssertNil(MessageContentView.fileExtension("README"))
        XCTAssertNil(MessageContentView.fileExtension("weird.averyveryverylongextension"))
    }
}

#if os(macOS)
import AppKit

/// On hosted views: the meta row (time and delivery) of an incoming message sits at the trailing edge — under a
/// picture at the picture's right edge, in a bubble at its bottom right — whether the body is wider or narrower than
/// it, and the body itself stays where it starts; and a list's open viewer follows the host's states end to end.
final class MediaDownloadRevealHostedTests: XCTestCase {
    private final class Log { var entries: [String] = [] }

    /// The rendered pixels of `view` on a dark green canvas (so a light bubble and grey text both stand out), and the
    /// pixels per point.
    private struct Pixels {
        let width: Int
        let height: Int
        let scale: CGFloat
        let bytes: [UInt8]

        func rgb(_ x: Int, _ y: Int) -> (Int, Int, Int) {
            let i = (y * width + x) * 4
            return (Int(bytes[i]), Int(bytes[i + 1]), Int(bytes[i + 2]))
        }

        func differs(_ a: (Int, Int, Int), _ b: (Int, Int, Int), by threshold: Int = 60) -> Bool {
            abs(a.0 - b.0) + abs(a.1 - b.1) + abs(a.2 - b.2) > threshold
        }

        func isProbe(_ x: Int, _ y: Int) -> Bool {
            let (r, g, b) = rgb(x, y)
            return r > 200 && g < 60 && b < 60
        }

        func points(_ px: Int) -> CGFloat { CGFloat(px) / scale }
    }

    private static let canvas = Color(red: 0, green: 0.4, blue: 0)

    @MainActor
    private func render(_ view: some View, size: NSSize) throws -> Pixels {
        _ = NSApplication.shared
        let root = view.frame(width: size.width, height: size.height, alignment: .topLeading)
            .background(Self.canvas).environment(\.colorScheme, .light)
        let host = NSHostingView(rootView: root)
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.colorSpace = .sRGB
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let image = try XCTUnwrap(bitmap.cgImage)
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                                                  bitsPerComponent: 8, bytesPerRow: image.width * 4, space: space,
                                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return Pixels(width: image.width, height: image.height, scale: CGFloat(image.width) / size.width, bytes: bytes)
    }

    /// Where an incoming bubble whose body is a red probe `bodyWidth` wide puts its parts, in points: the body, the
    /// bubble's inner edges on the row just under the body, and the meta row's ink.
    @MainActor
    private func incomingBubble(bodyWidth: CGFloat) throws
        -> (body: ClosedRange<CGFloat>, bubble: ClosedRange<CGFloat>, meta: ClosedRange<CGFloat>) {
        let type = "layout-probe-\(Int(bodyWidth))"
        FlareContentRegistry.register(type) { _, _ in
            AnyView(Color(red: 1, green: 0, blue: 0).frame(width: bodyWidth, height: 24))
        }
        defer { FlareContentRegistry.unregister(type) }
        let incoming = FlareMessageData(id: "p", senderId: "ivy", senderName: "ivy",
                                        content: FlareGenericContent(contentType: type, label: ""), timeLabel: "00:11")
        let px = try render(MessageBubbleView(message: incoming, currentUserId: "me"), size: NSSize(width: 420, height: 120))

        var probe = (minX: Int.max, maxX: Int.min, minY: Int.max, maxY: Int.min)
        for y in 0..<px.height { for x in 0..<px.width where px.isProbe(x, y) {
            probe = (min(probe.minX, x), max(probe.maxX, x), min(probe.minY, y), max(probe.maxY, y))
        } }
        XCTAssertLessThan(probe.minY, px.height / 2, "the bubble sits at the top of the canvas")

        // The row just under the body is the bubble's fill from its inner left edge to its inner right edge.
        let gap = probe.maxY + Int(1.5 * px.scale)
        let fill = px.rgb(probe.minX, gap)
        XCTAssertTrue(px.differs(fill, px.rgb(1, gap)), "the bubble stands out from the canvas")
        var left = probe.minX, right = probe.maxX
        while left > 0, !px.differs(px.rgb(left - 1, gap), fill, by: 24) { left -= 1 }
        while right < px.width - 1, !px.differs(px.rgb(right + 1, gap), fill, by: 24) { right += 1 }

        // The meta row: ink on the fill below the body, inside the bubble — clear of its rounded bottom corners, which
        // the canvas shows through.
        var ink = (minX: Int.max, maxX: Int.min)
        let top = probe.maxY + Int(3 * px.scale), bottom = probe.maxY + Int((3 + FlareSizes.iconSizeSm) * px.scale)
        let inset = Int(FlareSizes.spacingXs * px.scale)
        for y in top...bottom { for x in (left + inset)..<(right - inset) where px.differs(px.rgb(x, y), fill) {
            ink = (min(ink.minX, x), max(ink.maxX, x))
        } }
        XCTAssertLessThan(ink.minX, ink.maxX, "the meta row is drawn")
        return (px.points(probe.minX)...px.points(probe.maxX), px.points(left)...px.points(right),
                px.points(ink.minX)...px.points(ink.maxX))
    }

    @MainActor
    func testAnIncomingBubbleEndsItsMetaRowAtTheBubblesRightEdge() throws {
        let padding = FlareSizes.componentBubblePaddingX
        let wide = try incomingBubble(bodyWidth: 200)
        // The time's last glyph keeps a point or two of side bearing inside its frame.
        XCTAssertEqual(wide.bubble.upperBound - wide.meta.upperBound, padding, accuracy: 3,
                       "a body wider than the meta: the meta ends at the bubble's right edge")
        XCTAssertGreaterThan(wide.meta.lowerBound, wide.body.lowerBound + 100, "not at the left")
        XCTAssertEqual(wide.body.lowerBound - wide.bubble.lowerBound, padding, accuracy: 2)

        let narrow = try incomingBubble(bodyWidth: 12)
        XCTAssertGreaterThan(narrow.meta.upperBound, narrow.body.upperBound, "the meta is the wider one here")
        XCTAssertEqual(narrow.bubble.upperBound - narrow.meta.upperBound, padding, accuracy: 3,
                       "a body narrower than the meta: the meta still ends at the bubble's right edge")
        XCTAssertEqual(narrow.body.lowerBound - narrow.bubble.lowerBound, padding, accuracy: 2,
                       "and the body stays where it starts, at the left")
    }

    @MainActor
    func testAnIncomingPictureEndsItsMetaRowAtThePicturesRightEdge() throws {
        // No address: the picture's placeholder surface, 240 x 180.
        let incoming = FlareMessageData(id: "i", senderId: "ivy", senderName: "ivy",
                                        content: FlareImageContent(url: ""), timeLabel: "00:08")
        let px = try render(MessageBubbleView(message: incoming, currentUserId: "me"), size: NSSize(width: 420, height: 260))
        let canvas = px.rgb(px.width - 2, 2)
        // The picture: the first and last non-canvas columns on its middle row, and its last row on a column near its left.
        let middle = Int(100 * px.scale)
        var left = 0
        while left < px.width - 1, !px.differs(px.rgb(left, middle), canvas) { left += 1 }
        var right = left
        while right < px.width - 1, px.differs(px.rgb(right + 1, middle), canvas) { right += 1 }
        let column = left + Int(20 * px.scale)
        var bottom = middle
        while bottom < px.height - 1, px.differs(px.rgb(column, bottom + 1), canvas) { bottom += 1 }
        XCTAssertEqual(px.points(right - left), 240, accuracy: 2, "the picture's width")

        var ink = (minX: Int.max, maxX: Int.min)
        for y in (bottom + 2)..<min(px.height, bottom + Int(24 * px.scale)) {
            for x in 0..<px.width where px.differs(px.rgb(x, y), canvas) { ink = (min(ink.minX, x), max(ink.maxX, x)) }
        }
        XCTAssertLessThan(ink.minX, ink.maxX, "the meta row is drawn under the picture")
        XCTAssertEqual(px.points(ink.maxX), px.points(right), accuracy: 2, "the meta ends at the picture's right edge")
        XCTAssertGreaterThan(px.points(ink.minX), px.points(left) + 120, "not under its left edge")
    }

    // MARK: A list's viewer follows the host end to end

    @MainActor
    private final class States: ObservableObject {
        @Published var states: [String: FlareMediaDownloadState] = [:]
    }

    private struct Chat: View {
        @ObservedObject var model: States
        let messages: [FlareMessageData]
        let log: Log

        var body: some View {
            MessageListView(messages: messages, currentUserId: "me", mediaDownloadStates: model.states,
                            onMediaDownload: { message, _ in log.entries.append("download:\(message.id)") },
                            onMediaReveal: { message, _ in log.entries.append("reveal:\(message.id)") })
        }
    }

    private static func spin(_ seconds: TimeInterval) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    /// Clicks `window` at `point`, measured from its top left.
    private static func click(_ window: NSWindow, _ point: CGPoint) throws {
        let height = window.contentView?.bounds.height ?? window.frame.height
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = try XCTUnwrap(NSEvent.mouseEvent(with: type, location: NSPoint(x: point.x, y: height - point.y),
                                                         modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                                                         windowNumber: window.windowNumber, context: nil,
                                                         eventNumber: 0, clickCount: 1, pressure: 1))
            window.sendEvent(event)
            spin(0.05)
        }
        spin(0.2)
    }

    @MainActor
    func testAnOpenPreviewTurnsItsKeyIntoTheFolderWhenTheHostSaysTheFileIsSaved() throws {
        let log = Log()
        let model = States()
        let message = FlareMessageData(id: "m1", senderId: "me", senderName: "Me",
                                       content: FlareImageContent(url: "https://invalid.invalid/1.jpg", alt: "海边"),
                                       sentAtMs: Int64(Date().timeIntervalSince1970 * 1000))
        _ = NSApplication.shared
        let size = NSSize(width: 320, height: 600)
        let host = NSHostingView(rootView: Chat(model: model, messages: [message], log: log).frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        defer {
            window.sheets.forEach { window.endSheet($0) }
            window.orderOut(nil)
        }
        Self.spin(0.3)
        // The outgoing picture at the bottom of the viewport, where the timeline opens (MediaPresentationHostedTests).
        try Self.click(window, CGPoint(x: 188, y: 480))
        let deadline = Date().addingTimeInterval(1.5)
        while window.sheets.isEmpty && Date() < deadline { Self.spin(0.05) }
        let sheet = try XCTUnwrap(window.sheets.first, "the kit viewer is presented")
        let viewer = CGSize(width: 360, height: 480)
        sheet.setContentSize(viewer)
        sheet.contentView?.layoutSubtreeIfNeeded()
        Self.spin(0.3)
        let key = CGPoint(x: viewer.width - 35, y: 35)

        try Self.click(sheet, key)
        model.states = ["m1": FlareMediaDownloadState(status: .done)]
        Self.spin(0.3)
        try Self.click(sheet, key)
        model.states = ["m1": FlareMediaDownloadState(status: .idle)]
        Self.spin(0.3)
        try Self.click(sheet, key)
        XCTAssertEqual(log.entries, ["download:m1", "reveal:m1", "download:m1"],
                       "the key downloads, shows the saved picture, and downloads again once the host finds it gone")
    }
}
#endif
