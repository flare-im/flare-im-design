import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The composer's tool row and "+" panel as the composer menu drives them: the host picks the toolbar keys
/// (`availableToolIDs`), the built-in items come in one order with one set of icons and the kit's copy, the format
/// key is the kit's own "T", a tile with a name the registry does not know draws the plugin glyph, and the voice
/// tile opens the composer's own recorder.
final class ComposerToolsTests: XCTestCase {
    private let s = FlareStrings()
    private let tools = ["emoji", "mention", "voice", "image", "richText", "attachments"]

    private func keyLabel(_ tool: String) -> String {
        switch tool {
        case "emoji": return s.composerEmoji
        case "mention": return s.composerMention
        case "voice": return s.composerVoice
        case "image": return s.composerImage
        case "richText": return s.composerRichText
        default: return s.composerMore
        }
    }

    private func composer(tools: Set<String>?) -> ComposerView {
        ComposerView(onSend: { _ in }, onImage: {}, capabilities: FlareComposerCapabilities(availableToolIDs: tools),
                     onAction: { _ in }, enableVoice: true, onVoiceSend: { _, _ in true })
    }

    @MainActor
    private func keyNames(_ view: ComposerView) throws -> Set<String> {
        Set(try view.inspect().findAll(ViewType.Button.self).compactMap { try? $0.accessibilityLabel().string() })
    }

    // MARK: Toolbar keys

    func testCapabilitiesOfferEveryToolUntilTheHostNamesTheirOwn() {
        let all = FlareComposerCapabilities()
        XCTAssertNil(all.availableToolIDs)
        for tool in tools { XCTAssertTrue(all.allowsTool(tool), tool) }
        let some = FlareComposerCapabilities(availableToolIDs: ["emoji", "attachments"])
        XCTAssertEqual(tools.filter(some.allowsTool), ["emoji", "attachments"])
        XCTAssertFalse(FlareComposerCapabilities(availableToolIDs: []).allowsTool("emoji"))
    }

    @MainActor
    func testEachToolCanBeHiddenOnItsOwn() throws {
        let everything = try keyNames(composer(tools: nil))
        for tool in tools { XCTAssertTrue(everything.contains(keyLabel(tool)), "\(tool) is offered by default") }
        for tool in tools {
            let names = try keyNames(composer(tools: Set(tools).subtracting([tool])))
            XCTAssertFalse(names.contains(keyLabel(tool)), "\(tool) is hidden")
            for other in tools where other != tool {
                XCTAssertTrue(names.contains(keyLabel(other)), "hiding \(tool) keeps \(other)")
            }
            XCTAssertTrue(names.contains(s.send), "the send key is not a tool")
        }
    }

    @MainActor
    func testAnEmptyToolSetLeavesOnlyTheInputKeys() throws {
        let names = try keyNames(composer(tools: []))
        for tool in tools { XCTAssertFalse(names.contains(keyLabel(tool)), tool) }
        XCTAssertTrue(names.contains(s.send))
        XCTAssertTrue(names.contains(s.composerExpandInput))
    }

    @MainActor
    func testARichComposerWithoutTheRichTextToolHasNoFormatStrip() throws {
        let names = try keyNames(ComposerView(rich: true, onSend: { _ in },
                                              capabilities: FlareComposerCapabilities(availableToolIDs: ["emoji"])))
        XCTAssertFalse(names.contains(s.composerFormatBold), "the format strip follows the rich-text tool")
        XCTAssertTrue(try keyNames(ComposerView(rich: true, onSend: { _ in })).contains(s.composerFormatBold))
    }

    // MARK: The format key

    @MainActor
    func testTheFormatKeyIsTheKitsTNotASystemSymbol() throws {
        let key = try composer(tools: nil).inspect().find(ViewType.Button.self, where: {
            try $0.accessibilityLabel().string() == self.s.composerRichText
        })
        XCTAssertNoThrow(try key.labelView().find(FlareRichTextIcon.self), "the kit draws the T")
        XCTAssertThrowsError(try key.labelView().find(ViewType.Image.self), "no SF Symbol: textformat reads 格式 in Chinese")
        XCTAssertTrue(flareKitGlyphNames.contains("rich-text"))
        XCTAssertNotEqual(flareIconMap["rich-text"], "textformat")
        XCTAssertNoThrow(try IconView("rich-text").inspect().find(FlareRichTextIcon.self))
    }

    /// Lucide `Type` on the 24 grid: the bar spans 4 to 20, the stem 4 to 20, the foot 9 to 15.
    func testTheTFollowsLucideTypeOnThe24Grid() {
        typealias G = FlareRichTextIcon.Grid
        XCTAssertEqual([G.left, G.right, G.top, G.bottom, G.drop, G.corner, G.footLeft, G.footRight],
                       [4, 20, 4, 20, 7, 1, 9, 15])
        // The stroked outline covers the bar's turned-down ends, the stem and the foot, and nothing beside them.
        let lines = FlareRichTextIconLines().path(in: CGRect(x: 0, y: 0, width: 24, height: 24))
        XCTAssertTrue(lines.contains(CGPoint(x: 4, y: 6)), "the bar's left end turns down")
        XCTAssertTrue(lines.contains(CGPoint(x: 20, y: 6)), "the bar's right end turns down")
        XCTAssertTrue(lines.contains(CGPoint(x: 12, y: 12)), "the stem")
        XCTAssertTrue(lines.contains(CGPoint(x: 10, y: 20)), "the foot")
        XCTAssertFalse(lines.contains(CGPoint(x: 6, y: 12)), "the counter beside the stem is empty")
        XCTAssertFalse(lines.contains(CGPoint(x: 4, y: 12)), "the bar's ends stop at 7")
    }

    // MARK: The "+" panel

    func testTheBuiltInItemsComeInOneOrderWithOneSetOfIcons() {
        let defaults = FlareComposerActionPanel.defaultActions
        XCTAssertEqual(defaults.map(\.id), ["image", "video", "file", "voice", "card", "poll"])
        XCTAssertEqual(defaults.map(\.id), FlareComposerActionPanel.defaultActionIDs)
        XCTAssertEqual(defaults.map(\.icon), ["image", "video", "file", "mic", "card", "poll"])
        XCTAssertTrue(defaults.allSatisfy { $0.kind == .feature })
        XCTAssertFalse(defaults.map(\.id).contains("location"), "no location source yet")
        for icon in defaults.map(\.icon) { XCTAssertNotNil(flareIconMap[icon], "\(icon) is a registry name") }
        XCTAssertEqual(resolveComposerActions(defaults: defaults).map(\.id), defaults.map(\.id))
    }

    func testTheKitSuppliesTheBuiltInLabelsInBothLanguages() {
        let ids = FlareComposerActionPanel.defaultActionIDs
        func labels(_ strings: FlareStrings) -> [String] {
            ids.map { FlareComposerAction(id: $0, icon: "image", kind: .feature).resolvedLabel(strings) }
        }
        XCTAssertEqual(labels(FlareStrings()), ["图片", "视频", "文件", "语音", "名片", "投票"])
        XCTAssertEqual(labels(.english), ["Photo", "Video", "File", "Voice", "Contact card", "Poll"])
        XCTAssertEqual(FlareComposerActionPanel.actions(for: .english).map(\.label), labels(.english))
        XCTAssertEqual(FlareComposerAction(id: "image", label: "Album", icon: "image").resolvedLabel(s), "Album",
                       "the host's label wins")
        XCTAssertEqual(FlareComposerAction(id: "order", icon: "file").resolvedLabel(s), "order",
                       "an id the kit has no copy for shows itself, never a blank tile")
    }

    func testATileWithAnUnknownIconDrawsThePluginGlyph() {
        func plugin(_ icon: String) -> FlareComposerAction {
            FlareComposerAction(id: "plugin:acme.order", label: "Order", icon: icon, kind: .plugin)
        }
        XCTAssertEqual(plugin("red-packet").resolvedIcon, "red-packet", "a known name is kept")
        XCTAssertEqual(plugin("shopping-cart").resolvedIcon, "plugin")
        XCTAssertEqual(plugin("").resolvedIcon, "plugin", "an old manifest declares no icon")
        XCTAssertEqual(FlareComposerAction(id: "card", icon: "contact", kind: .feature).resolvedIcon, "plugin",
                       "a built-in item with a name the registry lacks falls back too, never to the question mark")
        XCTAssertEqual(FlareComposerAction(id: "x", label: "X", icon: "shopping-cart").resolvedIcon, "plugin")
        for action in FlareComposerActionPanel.defaultActions {
            XCTAssertEqual(action.resolvedIcon, action.icon, "\(action.id) keeps its registry name")
        }
        XCTAssertNotNil(flareIconMap["plugin"], "plugin is a registry name")
        XCTAssertNotEqual(flareIconSymbol("plugin"), "questionmark")
    }

    /// The voice tile is the composer's own: it opens the recorder the voice key opens (as on Flutter), and the
    /// host gets the recording through `onVoiceSend`. Without a recorder, and for every other tile, the host decides.
    func testTheVoiceTileOpensTheComposersRecorder() {
        let voice = FlareComposerAction(id: "voice", icon: "mic", kind: .feature)
        XCTAssertTrue(ComposerView.panelTileOpensRecorder(voice, offersVoice: true))
        XCTAssertFalse(ComposerView.panelTileOpensRecorder(voice, offersVoice: false), "no recorder: the host handles it")
        for id in ["image", "video", "file", "card", "poll", "plugin:flare.redpacket.send"] {
            XCTAssertFalse(ComposerView.panelTileOpensRecorder(FlareComposerAction(id: id, icon: "image"), offersVoice: true), id)
        }
    }

    @MainActor
    func testAStandalonePanelHandsEveryTileToTheHost() throws {
        var picked: [String] = []
        let panel = FlareComposerActionPanel(onAction: { picked.append($0.id) })
        try panel.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.composerVoice }).tap()
        XCTAssertEqual(picked, ["voice"], "outside the composer there is no recorder to open")
    }

    @MainActor
    func testThePanelDrawsResolvedLabelsAndIcons() throws {
        let panel = FlareComposerActionPanel(actions: [
            FlareComposerAction(id: "video", icon: "video", kind: .feature),
            FlareComposerAction(id: "plugin:acme.order", label: "Order", icon: "shopping-cart", kind: .plugin),
        ])
        let names = Set(try panel.inspect().findAll(ViewType.Button.self).compactMap { try? $0.accessibilityLabel().string() })
        XCTAssertEqual(names, [s.actionVideo, "Order"], "a built-in tile without a label takes the kit's copy")
        let symbols = try panel.inspect().findAll(ViewType.Image.self).compactMap { try? $0.actualImage().name() }
        XCTAssertTrue(symbols.contains(flareIconSymbol("plugin")), "the plugin tile draws the plugin glyph")
        XCTAssertFalse(symbols.contains("questionmark"))
    }
}
