#if os(macOS)
import AppKit
import SwiftUI
import XCTest
@testable import FlareIMUI

final class WalletRecordVisualTests: XCTestCase {
    @MainActor func testResolvedRecordPages() throws {
        guard let output = ProcessInfo.processInfo.environment["FLARE_RECORD_SNAPSHOT_DIR"] else { throw XCTSkip("Set FLARE_RECORD_SNAPSHOT_DIR to capture records") }
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let table = try JSONDecoder().decode(PluginJSONValue.self, from: Data(contentsOf: root.appendingPathComponent("spec/wallet-record-vectors.json")))
        let fixtures = table["cases"]?.arrayValue ?? []
        let directory = URL(fileURLWithPath: output)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for (id, variant, locale, width, scheme, name) in [
            ("history", "all", "zh-CN", CGFloat(390), ColorScheme.light, "swiftui-history-phone-light"),
            ("cashflow_history", "all_statuses", "zh-CN", CGFloat(1360), ColorScheme.dark, "swiftui-cashflow-desktop-dark"),
            ("recharge_history", "records", "zh-CN", CGFloat(390), ColorScheme.light, "swiftui-recharge-records-phone-light"),
            ("withdrawal_history", "records", "en-US", CGFloat(390), ColorScheme.light, "swiftui-withdrawal-records-phone-en"),
            ("history_detail", "internal", "zh-CN", CGFloat(1360), ColorScheme.dark, "swiftui-history-detail-desktop-dark"),
            ("cashflow_detail", "succeeded_withdrawal", "zh-CN", CGFloat(390), ColorScheme.light, "swiftui-cashflow-detail-phone-light")
        ] {
            let fixture = try XCTUnwrap(fixtures.first { $0["id"]?.stringValue == id && $0["variant"]?.stringValue == variant && $0["locale"]?.stringValue == locale })
            let model = try PluginVectors.decode(PluginViewModel.self, fixture["view"])
            let page = PluginPageRef(pluginId: "flare.wallet", page: try XCTUnwrap(fixture["page"]?.stringValue))
            let content = FlarePluginPage(page: page, view: .init(view: model), filters: fixture["filters"]?.objectValue ?? [:],
                                         onBack: {}, onRefresh: {}, onLoadMore: { _ in }, onFilter: { _ in }, onAction: { _, _ in })
                .environment(\.colorScheme, scheme).environment(\.locale, Locale(identifier: locale))
                .environment(\.flareStrings, locale == "en-US" ? .english : FlareStrings())
            _ = NSApplication.shared
            let size = NSSize(width: width, height: 1100)
            let host = NSHostingView(rootView: content)
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless, backing: .buffered, defer: false)
            window.colorSpace = .sRGB; window.contentView = host
            host.setFrameSize(size); host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)); host.layoutSubtreeIfNeeded()
            let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: bitmap)
            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            try png.write(to: directory.appendingPathComponent("\(name).png"))
            XCTAssertGreaterThan(png.count, 200)
        }
    }
}
#endif
