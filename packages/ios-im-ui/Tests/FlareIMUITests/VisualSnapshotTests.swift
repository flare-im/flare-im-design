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
        // than an en-US system's. Typeset as en-US, both systems draw the narrow one (a zh-Hans typesetting
        // language does not bring the CJK glyph back on an en-US system), so the baselines are drawn with
        // motion on, typeset as en-US.
        let host = NSHostingView(rootView: view
            .environment(\._accessibilityReduceMotion, false)
            .typesettingLanguage(Locale.Language(identifier: "en-US")))
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

    /// The vocabulary 2 plugin blocks and the upgrade notice (spec/plugin-view-vectors.json → blocks2,
    /// upgradeNotice), light and dark: the page the four kits' visual gates share.
    @MainActor
    func testPluginBlocks2Snapshot() throws {
        let fixture = #"""
        {"available":true,"title":"Task board","blocks":[
          {"kind":"hero","label":"Balance","value":"1,250.00","amount":true,"tone":"brand","maskable":true,"subtitle":"Updated just now",
           "actions":[{"id":"top-up","label":"Top up"},{"id":"withdraw","label":"Withdraw"}]},
          {"kind":"stats","items":[{"label":"Open tasks","value":"12","trend":{"text":"+3","direction":"up"}},
           {"label":"Members","value":"12345","format":{"kind":"count","count":12345}},
           {"label":"Avg. time","value":"7500000","format":{"kind":"duration","ms":7500000},"tone":"warning"}]},
          {"kind":"chart","chartKind":"bar","series":[{"label":"Done","points":[{"label":"Mon","value":3,"text":"3"},{"label":"Tue","value":5,"text":"5"},{"label":"Wed","value":2,"text":"2"}]},
           {"label":"Open","points":[{"label":"Mon","value":1,"text":"1"},{"label":"Tue","value":2,"text":"2"},{"label":"Wed","value":4,"text":"4"}]}]},
          {"kind":"chart","chartKind":"donut","series":[{"points":[{"label":"Done","value":6,"text":"6"},{"label":"Open","value":3,"text":"3"},{"label":"Late","value":1,"text":"1"}]}]},
          {"kind":"steps","items":[{"label":"Submitted","state":"done"},{"label":"Review","state":"current"},{"label":"Approved","state":"pending"}]},
          {"kind":"banner","tone":"warning","text":"Two tasks are overdue","action":{"id":"view","label":"View"}},
          {"kind":"section","label":"Details","collapsed":false,"blocks":[{"kind":"fields","fields":[{"label":"Owner","value":"Ann"}]}]},
          {"kind":"qr","value":"flare://task/42","label":"Share board","caption":"Scan to open"}
        ]}
        """#
        let view = try JSONDecoder().decode(PluginViewModel.self, from: Data(fixture.utf8))
        let placeholder = try JSONDecoder().decode(PluginViewModel.self, from: Data(
            #"{"available":false,"title":"Task board","unavailableReason":"upgrade_required","minBuild":41020}"#.utf8))
        for scheme in [ColorScheme.light, .dark] {
            let name = "swiftui-plugin-blocks2-\(scheme == .light ? "light" : "dark")"
            let colors = FlareColors.of(scheme, brand: .violet)
            let page = VStack(alignment: .leading, spacing: 12) {
                PluginView(view: view, embedded: true, onAction: { _, _ in })
                PluginView(view: placeholder, upgradeStatus: PluginUpgradeStatus(available: true, build: 41020), onUpdate: {})
                FlarePluginUpgradeNotice(variant: .page, title: "Task board", status: PluginUpgradeStatus(available: false))
            }
            .padding(16)
            .frame(width: 390, height: 1500, alignment: .top)
            .background(colors.bgPrimary)
            .environment(\.colorScheme, scheme)
            .environment(\.flareStrings, .english)
            let png = try nativeSnapshot(page, size: NSSize(width: 390, height: 1500), name: name)
            var root = URL(fileURLWithPath: #filePath)
            for _ in 0..<5 { root.deleteLastPathComponent() }
            let baseline = root.appendingPathComponent("tests/visual/ios/baselines/\(name).png")
            if ProcessInfo.processInfo.environment["UPDATE_GOLDENS"] == "1" {
                try FileManager.default.createDirectory(at: baseline.deletingLastPathComponent(), withIntermediateDirectories: true)
                try png.write(to: baseline)
            }
            XCTAssertTrue(FileManager.default.fileExists(atPath: baseline.path), "Missing SwiftUI snapshot baseline \(name)")
            try assertPixelsEqual(Data(contentsOf: baseline), png, "SwiftUI snapshot changed; inspect before UPDATE_GOLDENS=1")
        }
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
