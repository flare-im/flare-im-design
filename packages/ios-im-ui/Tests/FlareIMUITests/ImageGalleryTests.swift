import Foundation
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The shared gallery table (`spec/image-gallery-vectors.json`) and the paging preview a timeline opens.
final class ImageGalleryTests: XCTestCase {
    private struct Table: Decodable {
        let cases: [Case]
        struct Case: Decodable {
            let id: String
            let messages: [Message]
            let items: [String]
            let opens: [Open]
        }
        struct Message: Decodable {
            let id: String
            let kind: String
            let images: [String]?
            let recalled: Bool?
        }
        struct Open: Decodable {
            let message: String
            let index: Int
            let start: Int?
        }
    }

    private let s = FlareStrings()

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: root.appendingPathComponent("spec/image-gallery-vectors.json")))
    }

    private func message(_ raw: Table.Message) -> FlareMessageData {
        let refs = raw.images ?? []
        let content: FlareMessageContent
        switch raw.kind {
        case "image": content = FlareImageContent(url: refs[0])
        case "imageGroup": content = FlareImageGroupContent(images: refs.map { FlareImageContent(url: $0) })
        case "sticker": content = FlareStickerContent(url: "https://cdn.example/s.webp")
        case "video": content = FlareVideoContent(url: "https://cdn.example/v.mp4")
        default: content = FlareTextContent("明天见")
        }
        return FlareMessageData(id: raw.id, senderId: "u", senderName: "U", content: content,
                                lifecycle: raw.recalled == true ? FlareMessageLifecycle(mutation: .recalled) : nil)
    }

    @MainActor
    private func button(_ view: some View, _ name: String) throws -> InspectableView<ViewType.Button> {
        try view.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == name })
    }

    private func pictures(_ count: Int, from first: Int = 0) -> [FlareImageContent] {
        (first..<(first + count)).map { FlareImageContent(url: "https://cdn.example/\($0).jpg", alt: "图 \($0)") }
    }

    // MARK: The rule

    func testEveryTimelineBuildsTheGalleryTheTableSays() throws {
        let table = try table()
        XCTAssertGreaterThanOrEqual(table.cases.count, 4)
        for c in table.cases {
            let items = flareImageGalleryItems(c.messages.map(message))
            XCTAssertEqual(items.map { "\($0.messageId)#\($0.index)" }, c.items, c.id)
            for open in c.opens {
                XCTAssertEqual(flareImageGalleryStart(items, messageId: open.message, index: open.index), open.start,
                               "\(c.id): \(open.message)#\(open.index)")
            }
        }
    }

    func testAPictureWithoutAFullSizeAddressIsLoadedFromItsThumbnail() {
        let message = FlareMessageData(id: "t", senderId: "u", senderName: "U",
                                       content: FlareImageContent(url: " ", thumbnailURL: "https://cdn.example/t.jpg"))
        XCTAssertEqual(flareImageGalleryItems([message]).map(\.source), ["https://cdn.example/t.jpg"])
    }

    // MARK: The preview

    func testASidewaysSwipePagesAndAnythingElseDoesNot() {
        XCTAssertEqual(ImagePreviewView.page(horizontal: -80, vertical: 10), .next)
        XCTAssertEqual(ImagePreviewView.page(horizontal: 90, vertical: -20), .previous)
        XCTAssertNil(ImagePreviewView.page(horizontal: -40, vertical: 0), "not far enough")
        XCTAssertNil(ImagePreviewView.page(horizontal: 80, vertical: 120), "a downward swipe closes instead")
    }

    @MainActor
    func testTheGalleryPreviewSaysWhereItIsAndPagesWithItsSideKeys() throws {
        var moves: [String] = []
        let middle = ImagePreviewView(show: true, imageSrc: "https://cdn.example/1.jpg", onClose: {},
                                      galleryIndex: 1, galleryCount: 3,
                                      onPrevious: { moves.append("previous") }, onNext: { moves.append("next") })
        let position = try middle.inspect().find(text: "2 / 3")
        XCTAssertEqual(try position.accessibilityLabel().string(), s.imagePreviewPosition(2, 3))
        try button(middle, s.imagePreviewNext).tap()
        try button(middle, s.imagePreviewPrevious).tap()
        XCTAssertEqual(moves, ["next", "previous"])

        let last = ImagePreviewView(show: true, imageSrc: "https://cdn.example/2.jpg", galleryIndex: 2, galleryCount: 3,
                                    onPrevious: {}, onNext: nil)
        XCTAssertTrue(try button(last, s.imagePreviewNext).isDisabled(), "nothing after the last image")
        XCTAssertFalse(try button(last, s.imagePreviewPrevious).isDisabled())

        let single = ImagePreviewView(show: true, imageSrc: "https://cdn.example/a.jpg", onClose: {})
        XCTAssertThrowsError(try button(single, s.imagePreviewNext), "a single image has no paging keys")
        XCTAssertThrowsError(try single.inspect().find(ViewType.Text.self, where: { try $0.string().contains(" / ") }))
    }

    @MainActor
    func testTheViewerStartsInsideTheGalleryAndOffersTheDownloadOfTheImageItShows() throws {
        var downloaded: [Int] = []
        let images = (0..<3).map { i in
            FlareGalleryImage(url: "https://cdn.example/\(i).jpg", alt: nil, onDownload: i == 0 ? nil : { downloaded.append(i) })
        }
        let first = FlareImageGalleryViewer(images: images, startIndex: 0, onClose: {})
        XCTAssertNoThrow(try first.inspect().find(text: "1 / 3"))
        XCTAssertTrue(try button(first, s.imagePreviewPrevious).isDisabled())
        XCTAssertFalse(try button(first, s.imagePreviewNext).isDisabled())
        XCTAssertThrowsError(try button(first, s.download), "this image has no download handler")

        try button(FlareImageGalleryViewer(images: images, startIndex: 1, onClose: {}), s.download).tap()
        XCTAssertEqual(downloaded, [1])

        let past = FlareImageGalleryViewer(images: images, startIndex: 9, onClose: {})
        XCTAssertNoThrow(try past.inspect().find(text: "3 / 3"), "a start past the end is the last image")
        XCTAssertTrue(try button(past, s.imagePreviewNext).isDisabled())
    }

    // MARK: Opening from a timeline

    @MainActor
    func testATimelinePictureOpensTheGalleryAtItAndDownloadsWithTheMessageItBelongsTo() throws {
        let messages = [
            FlareMessageData(id: "m1", senderId: "u", senderName: "U", content: pictures(1)[0]),
            FlareMessageData(id: "m2", senderId: "u", senderName: "U", content: FlareTextContent("明天见")),
            FlareMessageData(id: "m3", senderId: "u", senderName: "U", content: FlareImageGroupContent(images: pictures(2, from: 1))),
        ]
        var downloads: [String] = []
        let source = FlareImageGallerySource(messages: messages) { message, content in
            downloads.append("\(message.id):\((content as? FlareImageContent)?.url ?? "-")")
        }
        let media = FlareMediaSession(voice: FlareVoicePlayback(engine: FakeVoiceEngine()))
        let album = MessageContentView(content: messages[2].content)
            .mediaDefaults(media, messageId: "m3", gallery: source)
        try album.inspect().find(ImageGroupMessageView.self).findAll(ViewType.Button.self)[1].tap()

        let presentation = try XCTUnwrap(media.viewer.presentation)
        guard case let .gallery(images, index) = presentation.kind else { return XCTFail("a gallery, not \(presentation.kind)") }
        XCTAssertEqual(images.map(\.url), ["https://cdn.example/0.jpg", "https://cdn.example/1.jpg", "https://cdn.example/2.jpg"])
        XCTAssertEqual(images.map(\.alt), ["图 0", "图 1", "图 2"])
        XCTAssertEqual(index, 2, "the second picture of the album is the third of the gallery")
        images.forEach { $0.onDownload?() }
        XCTAssertEqual(downloads, ["m1:https://cdn.example/0.jpg", "m3:https://cdn.example/1.jpg", "m3:https://cdn.example/2.jpg"])
    }

    @MainActor
    func testAPictureOutsideTheGalleryOrOutsideATimelineOpensAlone() throws {
        let media = FlareMediaSession(voice: FlareVoicePlayback(engine: FakeVoiceEngine()))
        let picture = pictures(1)[0]
        let recalled = FlareMessageData(id: "r", senderId: "u", senderName: "U", content: picture,
                                        lifecycle: FlareMessageLifecycle(mutation: .recalled))
        try button(MessageContentView(content: picture)
            .mediaDefaults(media, messageId: "r", gallery: FlareImageGallerySource(messages: [recalled], download: nil)), "图 0").tap()
        XCTAssertEqual(media.viewer.presentation?.kind, .image(url: picture.url, alt: "图 0"))

        media.dismiss()
        try button(MessageContentView(content: picture).mediaDefaults(media, messageId: "m1"), "图 0").tap()
        XCTAssertEqual(media.viewer.presentation?.kind, .image(url: picture.url, alt: "图 0"))
    }
}

#if os(macOS)
import AppKit

/// End to end on hosted views: the gallery pages with its keys, and a picture clicked in a list opens the list's
/// gallery at it.
final class ImageGalleryHostedTests: XCTestCase {
    private final class Log { var entries: [String] = [] }

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

    /// The preview's keys in a window of `size`: the download key at the top trailing corner, the paging keys at the
    /// sides, halfway down.
    private static func download(_ size: CGSize) -> CGPoint { CGPoint(x: size.width - 35, y: 35) }
    private static func previous(_ size: CGSize) -> CGPoint { CGPoint(x: 35, y: size.height / 2) }
    private static func next(_ size: CGSize) -> CGPoint { CGPoint(x: size.width - 35, y: size.height / 2) }

    @MainActor
    private static func host(_ view: some View, size: NSSize) -> NSWindow {
        _ = NSApplication.shared
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        spin(0.3)
        return window
    }

    @MainActor
    func testTheGalleryPagesWithItsKeysAndStopsAtItsEnds() throws {
        let log = Log()
        let images = (0..<3).map { i in
            FlareGalleryImage(url: "https://invalid.invalid/\(i).jpg", alt: nil, onDownload: { log.entries.append("\(i)") })
        }
        let size = CGSize(width: 360, height: 480)
        let window = Self.host(FlareImageGalleryViewer(images: images, startIndex: 0, onClose: {}), size: size)
        defer { window.orderOut(nil) }

        try Self.click(window, Self.download(size))
        try Self.click(window, Self.previous(size))
        try Self.click(window, Self.download(size))
        try Self.click(window, Self.next(size))
        try Self.click(window, Self.download(size))
        try Self.click(window, Self.next(size))
        try Self.click(window, Self.next(size))
        try Self.click(window, Self.download(size))
        XCTAssertEqual(log.entries, ["0", "0", "1", "2"], "each image downloads itself; the keys stop at the ends")
    }

    @MainActor
    func testAPictureClickedInAListOpensTheListsGalleryAtIt() throws {
        let log = Log()
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let messages = (1...2).map { i in
            FlareMessageData(id: "m\(i)", senderId: "me", senderName: "Me",
                             content: FlareImageContent(url: "https://invalid.invalid/\(i).jpg", alt: "海边 \(i)"),
                             sentAtMs: now + Int64(i))
        }
        let list = MessageListView(messages: messages, currentUserId: "me",
                                   onMediaDownload: { message, _ in log.entries.append(message.id) })
        // The newest image sits at the bottom of the viewport, where the timeline opens (see
        // MediaPresentationHostedTests).
        let window = Self.host(list, size: NSSize(width: 320, height: 600))
        defer {
            window.sheets.forEach { window.endSheet($0) }
            window.orderOut(nil)
        }
        try Self.click(window, CGPoint(x: 188, y: 480))
        let deadline = Date().addingTimeInterval(1.5)
        while window.sheets.isEmpty && Date() < deadline { Self.spin(0.05) }
        let sheet = try XCTUnwrap(window.sheets.first, "the kit viewer is presented")
        // The macOS test host presents the viewer as a sheet sized to its content; give it room for its keys.
        let size = CGSize(width: 360, height: 480)
        sheet.setContentSize(size)
        sheet.contentView?.layoutSubtreeIfNeeded()
        Self.spin(0.3)

        try Self.click(sheet, Self.download(size))
        try Self.click(sheet, Self.previous(size))
        try Self.click(sheet, Self.download(size))
        try Self.click(sheet, Self.previous(size))
        try Self.click(sheet, Self.download(size))
        XCTAssertEqual(log.entries, ["m2", "m1", "m1"],
                       "the gallery opens at the clicked picture, pages to the one before it and stops at the first")
    }
}
#endif
