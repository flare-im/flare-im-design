#if os(macOS)
import AppKit
import SwiftUI
import XCTest
@testable import FlareIMUI

final class VisualSnapshotTests: XCTestCase {
    private func assertPixelsEqual(_ baseline: Data, _ observed: Data, _ message: String,
                                   file: StaticString = #filePath, line: UInt = #line) throws {
        func pixels(_ png: Data) throws -> (Int, Int, Data) {
            let image = try XCTUnwrap(NSBitmapImageRep(data: png)?.cgImage)
            let colorSpace = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
            var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
            try bytes.withUnsafeMutableBytes { buffer in
                let context = try XCTUnwrap(CGContext(data: buffer.baseAddress,
                    width: image.width, height: image.height, bitsPerComponent: 8,
                    bytesPerRow: image.width * 4, space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            return (image.width, image.height, Data(bytes))
        }
        // PNG compression and metadata are not visual differences; RGBA pixels are.
        let expected = try pixels(baseline)
        let actual = try pixels(observed)
        XCTAssertEqual(expected.0, actual.0, message, file: file, line: line)
        XCTAssertEqual(expected.1, actual.1, message, file: file, line: line)
        XCTAssertEqual(expected.2, actual.2, message, file: file, line: line)
    }

    /// Device pixels per point in every snapshot. The baselines are drawn at 2x; a window's own caching
    /// bitmap takes the scale of whatever display the machine has (1x on a CI runner or an external
    /// monitor, 2x on a laptop panel), so the same view came out at two sizes on two machines.
    static let snapshotScale: CGFloat = 2

    // ImageRenderer does not render AppKit-backed TextEditor controls.
    @MainActor
    private func nativeSnapshot<Content: View>(_ view: Content, size: NSSize, name: String) throws -> Data {
        _ = NSApplication.shared
        // Two host settings change the drawing, so the snapshot fixes both. Reduce Motion turns the sending
        // spinner into a clock (CI runners have it on). The system's preferred language picks the glyph of
        // East Asian ambiguous punctuation: a zh-Hans system draws the meta row's "·" from the CJK font, wider
        // than an en-US system's. The baselines are drawn with motion on, typeset as zh-Hans.
        let host = NSHostingView(rootView: view
            .environment(\._accessibilityReduceMotion, false)
            .typesettingLanguage(Locale.Language(identifier: "zh-Hans")))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                              styleMask: .borderless, backing: .buffered, defer: false)
        window.colorSpace = .sRGB
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        let display = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        let bitmap = try XCTUnwrap(NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int((size.width * Self.snapshotScale).rounded()),
            pixelsHigh: Int((size.height * Self.snapshotScale).rounded()),
            bitsPerSample: display.bitsPerSample, samplesPerPixel: display.samplesPerPixel,
            hasAlpha: display.hasAlpha, isPlanar: false, colorSpaceName: display.colorSpaceName,
            bytesPerRow: 0, bitsPerPixel: 0)?.retagging(with: display.colorSpace))
        bitmap.size = host.bounds.size
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        // What this machine drew, next to the build (CI uploads it when a snapshot differs).
        var observed = URL(fileURLWithPath: #filePath)
        for _ in 0..<3 { observed.deleteLastPathComponent() }
        observed.appendPathComponent(".build/flare-snapshots")
        try FileManager.default.createDirectory(at: observed, withIntermediateDirectories: true)
        try png.write(to: observed.appendingPathComponent("\(name).png"))
        return png
    }

    @MainActor
    func testMessageMetadataSnapshot() throws {
        let states = FlareMessageDeliveryStatus.allCases
        let view = HStack(spacing: 20) {
            ForEach(Array(states.enumerated()), id: \.offset) { _, state in
                MessageStatusView(status: state)
            }
            MessageMetaView(timestamp: "15:42", edited: true, status: .read)
        }
        .padding(20)
        .frame(width: 420, height: 80)
        .background(Color.white)
        .environment(\.colorScheme, .light)

        let png = try nativeSnapshot(view, size: NSSize(width: 420, height: 80), name: "swiftui-message-meta")

        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let baseline = root.appendingPathComponent("tests/visual/ios/baselines/swiftui-message-meta.png")
        if ProcessInfo.processInfo.environment["UPDATE_GOLDENS"] == "1" {
            try FileManager.default.createDirectory(at: baseline.deletingLastPathComponent(), withIntermediateDirectories: true)
            try png.write(to: baseline)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: baseline.path), "Missing SwiftUI snapshot baseline")
        try assertPixelsEqual(Data(contentsOf: baseline), png, "SwiftUI snapshot changed; inspect before UPDATE_GOLDENS=1")
    }

    @MainActor
    func testAccessibilityExtraExtraExtraLargeSnapshot() throws {
        let conversation = ConversationRowData(
            id: "release", title: "Long localized conversation title",
            preview: "The latest message remains understandable at large text sizes",
            timestampLabel: "23:59", unreadCount: 12
        )
        let message = FlareMessageData(
            id: "message", senderId: "self", senderName: "You",
            content: FlareTextContent("A stable outgoing message with a readable delivery state."),
            timeLabel: "23:59", status: .read, edited: true
        )
        let view = VStack(spacing: 16) {
            ConversationRowView(item: conversation, active: true)
            MessageBubbleView(message: message, currentUserId: "self")
            ComposerView(placeholder: "Write a message", onSend: { _ in })
        }
        .padding(16)
        .frame(width: 320, height: 900, alignment: .top)
        .background(Color.white)
        .environment(\.colorScheme, .light)
        .environment(\.dynamicTypeSize, .accessibility3)

        let png = try nativeSnapshot(view, size: NSSize(width: 320, height: 900), name: "swiftui-large-text")

        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let baseline = root.appendingPathComponent("tests/visual/ios/baselines/swiftui-large-text.png")
        if ProcessInfo.processInfo.environment["UPDATE_GOLDENS"] == "1" {
            try FileManager.default.createDirectory(at: baseline.deletingLastPathComponent(), withIntermediateDirectories: true)
            try png.write(to: baseline)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: baseline.path), "Missing SwiftUI large-text baseline")
        try assertPixelsEqual(Data(contentsOf: baseline), png, "SwiftUI large-text snapshot changed; inspect before UPDATE_GOLDENS=1")
    }
}
#endif
