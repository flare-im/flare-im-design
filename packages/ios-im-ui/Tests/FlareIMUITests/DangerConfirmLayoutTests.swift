import AppKit
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// ``DangerConfirmView`` as ``FlareFeedback/confirm(_:)`` shows it: in a fitted kit sheet (a ScrollView around
/// ``BottomSheetView`` with the title hidden). Its content spans the sheet from the leading inset — a ScrollView
/// centres content narrower than itself, which pushed the title, text and keys a quarter of the screen to the right —
/// and its keys are the kit's ``ButtonView``s, not bare system buttons.
final class DangerConfirmLayoutTests: XCTestCase {
    private func confirm(busy: Bool = false, onConfirm: @escaping () -> Void = {},
                         onCancel: @escaping () -> Void = {}) -> DangerConfirmView {
        DangerConfirmView(title: "删除好友", description: "对方会从你的好友列表中移除。", target: "Lab Carol", busy: busy,
                          confirmText: "删除", onConfirm: onConfirm, onCancel: onCancel)
    }

    @MainActor
    func testTheKeysAreKitButtonsAndCancelComesFirst() throws {
        var calls: [String] = []
        let tree = try confirm(onConfirm: { calls.append("confirm") }, onCancel: { calls.append("cancel") }).inspect()
        XCTAssertEqual(try tree.findAll(ButtonView.self).count, 2, "both keys are kit buttons")
        XCTAssertEqual(try tree.findAll(ViewType.Button.self).count, 2, "no bare system button besides them")
        try tree.find(button: "取消").tap()
        try tree.find(button: "删除").tap()
        XCTAssertEqual(calls, ["cancel", "confirm"])
        let stack = try tree.find(ViewType.VStack.self, where: { (try? $0.find(text: "删除好友")) != nil })
        XCTAssertEqual(try stack.flexFrame().maxWidth, .infinity, "the content takes the sheet's width")
        XCTAssertEqual(try stack.flexFrame().alignment, .leading)
    }

    @MainActor
    func testBusyDisablesCancelAndSpinsTheConfirmKey() throws {
        let tree = try confirm(busy: true).inspect()
        XCTAssertTrue(try tree.find(button: "取消").isDisabled())
        XCTAssertNoThrow(try tree.find(ViewType.ProgressView.self), "the destructive key spins")
    }

    /// The drawn sheet: ink starts at the leading inset and the full-width keys reach the trailing one.
    @MainActor
    func testTheDrawnConfirmationSpansTheSheet() throws {
        let width: CGFloat = 390
        let sheet = ScrollView {
            BottomSheetView(title: "删除好友", titleHidden: true) { confirm() }
                .environment(\.flareBottomSheetHosted, true)
        }
        let pixels = try render(sheet, size: NSSize(width: width, height: 560))
        let ink = try XCTUnwrap(pixels.inkColumns(), "something is drawn")
        let inset = DangerConfirmView.insets
        XCTAssertLessThanOrEqual(pixels.points(ink.lowerBound), inset.leading + 4,
                                 "the content starts at the leading inset, not centred")
        XCTAssertGreaterThanOrEqual(pixels.points(ink.upperBound), width - inset.trailing - 4,
                                    "the full-width keys reach the trailing inset")
    }

    // MARK: Pixels

    private struct Pixels {
        let width: Int
        let height: Int
        let scale: CGFloat
        let bytes: [UInt8]

        /// Columns holding ink (anything clearly darker or more saturated than the white sheet ground).
        func inkColumns() -> ClosedRange<Int>? {
            var first: Int?
            var last: Int?
            for x in 0..<width {
                for y in 0..<height {
                    let i = (y * width + x) * 4
                    let r = Int(bytes[i]), g = Int(bytes[i + 1]), b = Int(bytes[i + 2])
                    if min(r, g, b) < 150 {
                        if first == nil { first = x }
                        last = x
                        break
                    }
                }
            }
            guard let first, let last else { return nil }
            return first...last
        }

        func points(_ px: Int) -> CGFloat { CGFloat(px) / scale }
    }

    @MainActor
    private func render(_ view: some View, size: NSSize) throws -> Pixels {
        _ = NSApplication.shared
        let root = view.frame(width: size.width, height: size.height, alignment: .topLeading)
            .background(Color.white).environment(\.colorScheme, .light)
        let host = NSHostingView(rootView: root)
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.colorSpace = .sRGB
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
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
}
