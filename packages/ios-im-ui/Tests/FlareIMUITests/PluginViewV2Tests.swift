import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// Plugin view v2 on the card and in the page host: the ⋯ menu, grouped entries with the me tag, the unavailable
/// reasons and the read-only copy (`spec/plugin-view-vectors.json` unavailableReasons, entryGroupHeaders,
/// poll-v2-menu, poll-v2-detail-grouped, unbound-copy), and ``FlarePluginPage``.
final class PluginViewV2Tests: XCTestCase {
    private let s = FlareStrings()

    private func table() throws -> PluginJSONValue {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/plugin-view-vectors.json"))
        return try JSONDecoder().decode(PluginJSONValue.self, from: data)
    }

    private func view(_ id: String) throws -> PluginViewModel {
        let entry = try XCTUnwrap((try table()["views"]?.arrayValue ?? []).first { $0["id"]?.stringValue == id }, id)
        return try JSONDecoder().decode(PluginViewModel.self, from: JSONEncoder().encode(try XCTUnwrap(entry["view"])))
    }

    func testEveryUnavailableReasonHasItsCopy() throws {
        let rows = try table()["unavailableReasons"]?.arrayValue ?? []
        XCTAssertEqual(rows.count, PluginUnavailableReason.allCases.count)
        for row in rows {
            let reason = try XCTUnwrap(PluginUnavailableReason(rawValue: row["reason"]?.stringValue ?? ""))
            XCTAssertEqual(PluginViewFormat.reasonText(reason, s), row["zh"]?.stringValue, reason.rawValue)
        }
        let disabled = PluginViewModel(available: false, title: "t", unavailableReason: .disabled)
        XCTAssertEqual(PluginViewFormat.reasonLine(disabled, displayName: "投票", s), "投票 · 插件已停用")
        XCTAssertEqual(PluginViewFormat.reasonLine(disabled, displayName: "  ", s), "插件已停用")
        XCTAssertNil(PluginViewFormat.reasonLine(PluginViewModel(available: false, title: "t"), displayName: "投票", s),
                     "no reason, no line")
    }

    func testGroupHeadersFollowTheTable() throws {
        for row in try table()["entryGroupHeaders"]?.arrayValue ?? [] {
            let group = try JSONDecoder().decode(PluginEntryGroup.self, from: JSONEncoder().encode(try XCTUnwrap(row["group"])))
            XCTAssertEqual(PluginViewFormat.groupHeader(group, s), row["zh"]?.stringValue)
        }
    }

    @MainActor
    func testTheMenuKeyOpensTheMenuActionsAndWaitsWhileBusy() throws {
        let poll = try view("poll-v2-menu")
        XCTAssertEqual(PluginView.menuItems(poll).map(\.label), ["结束投票", "取消投票"])
        XCTAssertTrue(PluginView.menuItems(poll).allSatisfy(\.danger))
        let card = try PluginView(view: poll, icon: "poll", onAction: { _, _ in }).inspect()
        let key = try card.find(ViewType.Button.self, where: { (try? $0.accessibilityLabel().string()) == self.s.pluginViewMore })
        XCTAssertFalse(key.isDisabled())
        XCTAssertThrowsError(try card.find(button: "结束投票"), "menu actions are not keys on a card")
        let busy = try PluginView(view: poll, busyActionId: "vote", onAction: { _, _ in }).inspect()
        XCTAssertTrue(try busy.find(ViewType.Button.self, where: {
            (try? $0.accessibilityLabel().string()) == self.s.pluginViewMore
        }).isDisabled(), "busy holds the menu")
        // Embedded (the detail sheet, the page): the menu actions are keys after the footer actions.
        var calls: [String] = []
        let embedded = try PluginView(view: try view("poll-v2-detail-grouped"), embedded: true,
                                      onAction: { id, _ in calls.append(id) }).inspect()
        XCTAssertThrowsError(try embedded.find(ViewType.Button.self, where: {
            (try? $0.accessibilityLabel().string()) == self.s.pluginViewMore
        }))
        XCTAssertNoThrow(try embedded.find(button: "结束投票"))
    }

    @MainActor
    func testGroupedEntriesDrawTheirHeadersAndTheViewersMeTag() throws {
        let detail = try view("poll-v2-detail-grouped")
        let users = try JSONDecoder().decode([String: PluginUser].self,
                                             from: JSONEncoder().encode(try XCTUnwrap(try table()["users"])))
        let tree = try PluginView(view: detail, icon: nil, viewerId: "u_bob0002", busy: false, busyActionId: nil,
                                  error: nil, embedded: true, resolveUser: nil, members: [], formErrors: [],
                                  onAction: { _, _ in }, onOpenDetail: nil, clock: .system, users: users).inspect()
        XCTAssertNoThrow(try tree.find(text: "火锅 · 3 票 · 60%"))
        XCTAssertNoThrow(try tree.find(text: "烧烤 · 2 票 · 40%"))
        XCTAssertEqual(tree.findAll(ViewType.Text.self, where: { try $0.string() == self.s.pluginViewMe }).count, 1,
                       "only the viewer's entry is tagged")
        XCTAssertThrowsError(try tree.find(text: "1."), "a grouped poll list is not numbered")
    }

    @MainActor
    func testAnUnboundCopyIsReadOnly() throws {
        let copy = try view("unbound-copy")
        XCTAssertTrue(copy.readOnly)
        // Even a copy that still carried keys draws none of them.
        let carried = PluginViewModel(available: true, title: copy.title, actions: [PluginViewAction(id: "x", label: "做点什么")],
                                      blocks: copy.blocks, detail: true,
                                      menuActions: [PluginViewAction(id: "close", label: "结束投票")],
                                      unavailableReason: .unboundCopy)
        var calls = 0
        let tree = try PluginView(view: carried, onAction: { _, _ in calls += 1 }, onOpenDetail: { calls += 1 }).inspect()
        XCTAssertNoThrow(try tree.find(text: s.pluginViewUnavailableUnboundCopy))
        XCTAssertThrowsError(try tree.find(button: "做点什么"))
        XCTAssertThrowsError(try tree.find(button: s.pluginViewDetail))
        XCTAssertThrowsError(try tree.find(ViewType.Button.self, where: {
            (try? $0.accessibilityLabel().string()) == self.s.pluginViewMore
        }))
        XCTAssertTrue(try tree.find(button: "桌游").isDisabled(), "the options are not controls")
        XCTAssertEqual(calls, 0)
    }

    @MainActor
    func testAnUnavailableCardSaysWhyAfterThePluginsName() throws {
        let card = try PluginView(view: try view("unavailable-disabled"), displayName: "投票").inspect()
        XCTAssertNoThrow(try card.find(text: "周五团建去哪儿？"))
        XCTAssertNoThrow(try card.find(text: "投票 · 插件已停用"))
    }

    @MainActor
    func testTheCardShellCarriesTheQuoteSlot() throws {
        let tree = try PluginView(view: PluginViewModel(available: true, title: "t")).inspect()
        XCTAssertNoThrow(try tree.find(FlareMessageCardQuoteSlot.self))
        XCTAssertThrowsError(try PluginView(view: PluginViewModel(available: true, title: "t"), embedded: true).inspect()
            .find(FlareMessageCardQuoteSlot.self), "an embedded view has no shell")
    }

    // MARK: Plugin page

    @MainActor
    func testThePluginPageLoadsFailsAndShowsTheEmbeddedView() throws {
        XCTAssertEqual(FlarePluginPage.phase(loading: true, error: nil, view: nil), .loading)
        XCTAssertEqual(FlarePluginPage.phase(loading: false, error: "x", view: nil), .error)
        XCTAssertEqual(FlarePluginPage.phase(loading: false, error: nil, view: nil), .loading)
        let wallet = PluginViewModel(available: true, title: "钱包",
                                     fields: [PluginViewField(label: "CNY", value: "¥12.00")], nextCursor: "c2")
        XCTAssertEqual(FlarePluginPage.phase(loading: true, error: "x", view: wallet), .loaded, "a view stays while refreshing")
        XCTAssertEqual(FlarePluginPage.heading(view: wallet, title: "页面"), "钱包")
        XCTAssertEqual(FlarePluginPage.heading(view: nil, title: "页面"), "页面")

        var retries = 0
        let failed = try FlarePluginPage(title: "钱包", error: "加载失败", onRetry: { retries += 1 }).inspect()
        XCTAssertNoThrow(try failed.find(text: "加载失败"))
        try failed.find(button: s.retry).tap()
        XCTAssertEqual(retries, 1)

        var asked: [String] = []
        var backs = 0
        let page = try FlarePluginPage(view: wallet, onBack: { backs += 1 }, onRefresh: {},
                                       onLoadMore: { asked.append($0) }).inspect()
        XCTAssertNoThrow(try page.find(text: "¥12.00"))
        XCTAssertNoThrow(try page.find(text: "钱包"), "the view's title heads the page")
        try page.find(button: s.myInviteLoadMore).tap()
        XCTAssertEqual(asked, ["c2"])
        try page.find(ViewType.Button.self, where: { (try? $0.accessibilityLabel().string()) == self.s.back }).tap()
        XCTAssertEqual(backs, 1)
        #if os(macOS)
        XCTAssertNoThrow(try page.find(ViewType.Button.self, where: {
            (try? $0.accessibilityLabel().string()) == self.s.pluginPageRefresh
        }), "a pointer refreshes from the header")
        #endif
    }
}
