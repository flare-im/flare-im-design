import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

final class PluginComponentsTests: XCTestCase {
    func testPublicCompositionModelsRoundTripWithoutSDKDependencies() throws {
        let model = PluginViewModel(available: true, title: "Wallet", fields: [PluginViewField(label: "CNY", value: "900")])
        let decoded = try JSONDecoder().decode(PluginViewModel.self, from: JSONEncoder().encode(model))
        XCTAssertEqual(decoded.fields.first?.value, "900")
        XCTAssertTrue(decoded.actions.isEmpty)
        XCTAssertEqual(PluginViewAction(id: "history", label: "History").id, "history")
    }
    @MainActor
    func testPacketDispatchesOnlyWhenInteractive() throws {
        var calls = 0
        let active = RedPacketCardView(blessing: "Hello", onOpen: { calls += 1 })
        try active.inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(calls, 1)
        // A finished packet still opens: the viewer goes on to its details.
        try RedPacketCardView(blessing: "Hello", state: .finished, onOpen: { calls += 1 })
            .inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(calls, 2)
        for card in [
            RedPacketCardView(blessing: "Hello", disabled: true, onOpen: { calls += 1 }),
            RedPacketCardView(blessing: "Hello", busy: true, onOpen: { calls += 1 }),
            RedPacketCardView(blessing: "Hello")
        ] {
            let button = try card.inspect().find(ViewType.Button.self)
            XCTAssertTrue(button.isDisabled())
            XCTAssertThrowsError(try button.tap())
        }
        XCTAssertEqual(calls, 2)
    }

    @MainActor
    func testPacketStatusAndEnglishPresetAndHostOverride() throws {
        let english = FlareStrings.english
        XCTAssertEqual(english.packetBusy, "Processing…")
        XCTAssertEqual(english.packetUnavailable, "Unavailable")
        // ViewInspector reads an unhosted value's default @Environment. Actual
        // environment propagation is exercised by the rendered specimen below.
        let busy = RedPacketCardView(blessing: "Hello", busy: true)
        XCTAssertNoThrow(try busy.inspect().find(text: FlareStrings().packetBusy))
        let unavailable = RedPacketCardView(blessing: "Hello", disabled: true)
        XCTAssertNoThrow(try unavailable.inspect().find(text: FlareStrings().packetUnavailable))
        let created = RedPacketCardView(blessing: "Hello", disabled: true, statusLabel: "Created")
        XCTAssertNoThrow(try created.inspect().find(text: "Created"))
    }

    @MainActor
    func testUnavailablePluginHidesFieldsAndActions() throws {
        let data = Data(#"{"available":false,"title":"History summary","fields":[{"label":"Private","value":"secret"}],"actions":[{"id":"claim","label":"Claim"}]}"#.utf8)
        let view = PluginView(view: try JSONDecoder().decode(PluginViewModel.self, from: data))
        XCTAssertNoThrow(try view.inspect().find(text: "History summary"))
        XCTAssertThrowsError(try view.inspect().find(text: "secret"))
        XCTAssertThrowsError(try view.inspect().find(ButtonView.self))
    }

    @MainActor
    func testPluginActionForwardsOnlyOpaqueIDAndBusyBlocksIt() throws {
        let data = Data(#"{"available":true,"title":"AI","fields":[],"actions":[{"id":"draft","label":"Generate"}]}"#.utf8)
        let model = try JSONDecoder().decode(PluginViewModel.self, from: data)
        var calls: [String] = []
        let view = PluginView(view: model, onAction: { calls.append($0) })
        try view.inspect().find(ButtonView.self).find(ViewType.Button.self).tap()
        XCTAssertEqual(calls, ["draft"])
        let busy = PluginView(view: model, busy: true, onAction: { calls.append($0) })
        XCTAssertTrue(try busy.inspect().find(ButtonView.self).find(ViewType.Button.self).isDisabled())
    }

    #if os(macOS)
    @MainActor
    func testPacketRendersInsideNarrowAndDesktopConstraints() throws {
        for width: CGFloat in [180, 390, 1024] {
            for scheme in [ColorScheme.light, .dark] {
                let view = RedPacketCardView(blessing: String(repeating: "长祝福 Hello ", count: 8), disabled: true)
                    .frame(maxWidth: width).environment(\.colorScheme, scheme)
                let renderer = ImageRenderer(content: view)
                renderer.proposedSize = ProposedViewSize(width: width, height: nil)
                let image = try XCTUnwrap(renderer.cgImage)
                XCTAssertLessThanOrEqual(image.width, Int(width))
                XCTAssertGreaterThanOrEqual(image.height, 48)
            }
        }
    }

    @MainActor
    func testHostedPacketUsesTheEnglishEnvironment() throws {
        let card = RedPacketCardView(blessing: "Hello", busy: true)
        let chinese = try XCTUnwrap(ImageRenderer(content: card).cgImage)
        let english = try XCTUnwrap(ImageRenderer(content: card.flareStrings(.english)).cgImage)
        let first = try XCTUnwrap(chinese.dataProvider?.data) as Data
        let second = try XCTUnwrap(english.dataProvider?.data) as Data
        XCTAssertNotEqual(first, second, "The host's locale must reach rendered packet status and brand")
    }
    #endif
}
