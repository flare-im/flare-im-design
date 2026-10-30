import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI
#if os(macOS)
import AppKit
#endif

final class PluginTextActionsTests: XCTestCase {
    private func model() throws -> PluginViewModel {
        try JSONDecoder().decode(PluginViewModel.self, from: Data(#"{"available":true,"title":"接龙","detail":true,"blocks":[{"kind":"text","text":"周五下午茶，一起点点心"}],"actions":[{"id":"join","label":"参与接龙","style":"primary"},{"id":"end","label":"结束接龙","style":"danger"}]}"#.utf8))
    }
    @MainActor func testFooterStillDispatchesOpaqueActionAndDetailsSeparately() throws {
        var sent: [String] = []; var opened = 0
        let view = PluginView(view: try model(), onAction: { id, _ in sent.append(id) }, onOpenDetail: { opened += 1 })
        let tree = try view.inspect()
        try tree.find(button: "参与接龙").tap()
        XCTAssertEqual(sent, ["join"])
        try tree.find(button: FlareStrings().pluginViewDetail).tap()
        XCTAssertEqual(opened, 1)
        XCTAssertEqual(sent, ["join"])
    }
    #if os(macOS)
    @MainActor func testCompactCardRendersAtNarrowAndPhoneWidthsInBothThemes() throws {
        _ = NSApplication.shared
        for width: CGFloat in [220, 390] {
            for scheme in [ColorScheme.light, .dark] {
                let content = PluginView(view: try model(), onAction: { _, _ in }, onOpenDetail: {})
                    .frame(width: width).padding(20).environment(\.colorScheme, scheme)
                let renderer = ImageRenderer(content: content)
                let image = try XCTUnwrap(renderer.cgImage)
                XCTAssertEqual(image.width, Int(width + 40))
                XCTAssertLessThan(image.height, 420, "text actions must stay compact even when they wrap")
                if let output = ProcessInfo.processInfo.environment["FLARE_CARD_SCREENSHOTS"] {
                    let png = try XCTUnwrap(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
                    try png.write(to: URL(fileURLWithPath: output).appendingPathComponent("swift-card-\(Int(width))-\(scheme == .dark ? "dark" : "light").png"))
                }
            }
        }
    }
    #endif
}
