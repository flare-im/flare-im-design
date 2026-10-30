#if os(macOS)
import AppKit
import SwiftUI
import XCTest
@testable import FlareIMUI

/// spec/plugin-view-vectors.json rules.menuActions: the card's title row takes the card's inner width and the ⋯ key
/// sits at its trailing edge whatever the title's length. Drawn for real: the key is what differs between a card
/// with menu actions and the same card without them.
final class PluginMenuKeyPlacementTests: XCTestCase {
    private let width = FlareSizes.componentRichCardWidth

    private func card(title: String, menu: Bool) -> PluginView {
        PluginView(view: PluginViewModel(available: true, title: title, actions: [], blocks: [], detail: false,
                                         menuActions: menu ? [PluginViewAction(id: "close", label: "结束")] : []),
                   onAction: { _, _ in })
    }

    /// The card drawn `width` wide, as a bitmap.
    @MainActor
    private func render(_ view: PluginView) throws -> NSBitmapImageRep {
        _ = NSApplication.shared
        let size = NSSize(width: width, height: 120)
        let host = NSHostingView(rootView: view.frame(width: width, height: 120, alignment: .topLeading)
            .background(Color.white).environment(\.colorScheme, .light))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        let rep = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: rep)
        return rep
    }

    /// The horizontal extent (in points) of the pixels that differ between two renders inside the card's padding, on
    /// the title row's first line.
    private func differingColumns(_ a: NSBitmapImageRep, _ b: NSBitmapImageRep) -> ClosedRange<CGFloat>? {
        let scale = CGFloat(a.pixelsWide) / width
        let inset = Int((FlareSizes.spacingMd - 2) * scale)
        let rows = inset..<Int((FlareSizes.spacingMd + FlareSizes.iconSizeMd + 4) * scale)
        var low: Int?
        var high: Int?
        for y in rows {
            for x in inset..<(min(a.pixelsWide, b.pixelsWide) - inset) {
                guard let p = a.colorAt(x: x, y: y), let q = b.colorAt(x: x, y: y) else { continue }
                let delta = abs(p.redComponent - q.redComponent) + abs(p.greenComponent - q.greenComponent)
                    + abs(p.blueComponent - q.blueComponent)
                if delta > 0.15 {
                    low = min(low ?? x, x)
                    high = max(high ?? x, x)
                }
            }
        }
        guard let low, let high else { return nil }
        return CGFloat(low) / scale...CGFloat(high) / scale
    }

    @MainActor
    func testTheMenuKeySitsAtTheTitleRowsTrailingEdge() throws {
        let inner = width - FlareSizes.spacingMd
        for title in ["", "投票", "周五团建去哪儿？这是一个相当长的标题，会把整行占满"] {
            let with = try render(card(title: title, menu: true))
            let without = try render(card(title: title, menu: false))
            let columns = try XCTUnwrap(differingColumns(with, without), "\"\(title)\": the key is drawn")
            let glyph = FlareSizes.iconSizeMd
            XCTAssertGreaterThanOrEqual(columns.upperBound, inner - glyph, "\"\(title)\": the key ends at the trailing edge")
            XCTAssertLessThanOrEqual(columns.upperBound, inner + 1, "\"\(title)\": inside the card's padding")
            if title.isEmpty {
                // Nothing else is on the row, so all that differs is the key: at the end, not after a blank title.
                XCTAssertGreaterThan(columns.lowerBound, inner - FlareSizes.touchTarget, "no title leaves the key at the end")
            }
        }
    }
}
#endif
