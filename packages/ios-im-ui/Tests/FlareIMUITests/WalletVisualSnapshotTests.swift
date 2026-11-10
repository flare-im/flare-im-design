#if os(macOS)
import AppKit
import SwiftUI
import XCTest
@testable import FlareIMUI

/// Opt-in visual evidence over real resolved contract fixtures; no account or financial operation is invoked.
final class WalletVisualSnapshotTests: XCTestCase {
    @MainActor func testResolvedWalletPagesAtPhoneAndDesktopWidths() throws {
        guard let output = ProcessInfo.processInfo.environment["FLARE_WALLET_SNAPSHOT_DIR"] else {
            throw XCTSkip("Set FLARE_WALLET_SNAPSHOT_DIR to capture wallet layout evidence")
        }
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let table = try JSONDecoder().decode(PluginJSONValue.self, from: Data(contentsOf: root.appendingPathComponent("spec/wallet-flow-vectors.json")))
        let cards = try JSONDecoder().decode(PluginJSONValue.self, from: Data(contentsOf: root.appendingPathComponent("spec/wallet-card-vectors.json")))
        let fixtures = (table["cases"]?.arrayValue ?? []) + (cards["cases"]?.arrayValue ?? [])
        let directory = URL(fileURLWithPath: output)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for (id, width, scheme, name) in [
            ("home", CGFloat(390), ColorScheme.light, "swiftui-wallet-phone-light"),
            ("home", CGFloat(1360), ColorScheme.dark, "swiftui-wallet-desktop-dark"),
            ("withdrawal", CGFloat(390), ColorScheme.light, "swiftui-withdrawal-phone-light"),
            ("withdrawal", CGFloat(1360), ColorScheme.dark, "swiftui-withdrawal-desktop-dark"),
            ("recharge", CGFloat(390), ColorScheme.light, "swiftui-recharge-inline-phone-light"),
            ("payout_profiles", CGFloat(390), ColorScheme.light, "swiftui-payout-inline-phone-light"),
            ("multipleWallets", CGFloat(390), ColorScheme.light, "swiftui-multi-wallet-phone-light"),
            ("multipleWallets", CGFloat(1360), ColorScheme.dark, "swiftui-multi-wallet-desktop-dark")
        ] {
            let fixture = try XCTUnwrap(fixtures.first { $0["id"]?.stringValue == id && $0["locale"]?.stringValue == "zh-CN" })
            let model = try PluginVectors.decode(PluginViewModel.self, fixture["view"])
            let page = PluginPageRef(pluginId: "flare.wallet", page: try XCTUnwrap(fixture["page"]?.stringValue))
            let content = FlarePluginPage(page: page, view: .init(view: model), onBack: {}, onRefresh: {}, onAction: { _, _ in })
                .environment(\.colorScheme, scheme).environment(\.locale, Locale(identifier: "zh-CN"))
            let size = NSSize(width: width, height: 950)
            _ = NSApplication.shared
            let host = NSHostingView(rootView: content)
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless, backing: .buffered, defer: false)
            window.colorSpace = .sRGB; window.contentView = host
            host.setFrameSize(size); host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
            host.layoutSubtreeIfNeeded()
            let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: bitmap)
            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            try png.write(to: directory.appendingPathComponent("\(name).png"))
            XCTAssertGreaterThan(png.count, 200)
        }
    }
}
#endif
