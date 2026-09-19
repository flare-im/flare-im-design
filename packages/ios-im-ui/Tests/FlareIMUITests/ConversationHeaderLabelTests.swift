import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// Batch 2b: the header's default actions and presence subtitle speak the strings table (K8), a More
/// menu that would hold one action becomes that action (K3), and the inbox keeps the host's order (K8).
final class ConversationHeaderLabelTests: XCTestCase {
    private let s = FlareStrings()

    func testDefaultActionsShowTheStringsTableWordsAndHostLabelsShowAsGiven() {
        let direct = resolveConversationHeaderActions(identity: ConversationIdentity(id: "u1", title: "Ada"))
        XCTAssertEqual(direct.map { ConversationHeaderView.localizedLabel($0, kind: .direct, strings: s) },
                       [s.conversationHeaderSearch, s.conversationHeaderAudioCall, s.conversationHeaderVideoCall,
                        s.conversationHeaderShare, s.conversationHeaderDetails])
        let group = resolveConversationHeaderActions(identity: ConversationIdentity(id: "g1", title: "Room", kind: .group))
        XCTAssertEqual(group.map { ConversationHeaderView.localizedLabel($0, kind: .group, strings: s) },
                       [s.conversationHeaderSearch, s.conversationHeaderAudioCall, s.conversationHeaderVideoCall,
                        s.conversationHeaderAddMember, s.conversationHeaderShare, s.conversationHeaderDetails])
        XCTAssertEqual([s.conversationHeaderSearch, s.conversationHeaderAudioCall, s.conversationHeaderVideoCall,
                        s.conversationHeaderAddMember, s.conversationHeaderShare, s.conversationHeaderDetails],
                       ["搜索消息", "发起语音通话", "发起视频通话", "添加成员", "分享会话", "会话详情"])

        // A host label, or a default id whose label the host changed, is never replaced.
        let renamed = ConversationHeaderAction(id: "search", label: "Find in chat")
        XCTAssertEqual(ConversationHeaderView.localizedLabel(renamed, kind: .direct, strings: s), "Find in chat")
        let groupShareOnDirect = ConversationHeaderAction(id: "share", label: "Share conversation")
        XCTAssertEqual(ConversationHeaderView.localizedLabel(groupShareOnDirect, kind: .direct, strings: s), "Share conversation",
                       "only the default of the conversation's own kind is translated")
        let english = FlareStrings(conversationHeaderSearch: "Search messages")
        XCTAssertEqual(ConversationHeaderView.localizedLabel(direct[0], kind: .direct, strings: english), "Search messages")
    }

    @MainActor
    func testTheRenderedHeaderCarriesNoEnglishDefaultNames() throws {
        let header = ConversationHeaderView(identity: ConversationIdentity(id: "g1", title: "Room", kind: .group), onAction: { _ in })
        let view = try header.inspect()
        let labels = view.findAll(ViewType.Button.self).compactMap { try? $0.accessibilityLabel().string() }
        XCTAssertTrue(labels.contains(s.conversationHeaderSearch), "\(labels)")
        for english in ["Search messages", "Start audio call", "Start video call", "Add member", "Share conversation", "Conversation details"] {
            XCTAssertFalse(labels.contains(english), "\(english) in \(labels)")
        }
    }

    func testThePresenceSubtitleIsWordsFromTheStringsTable() {
        func subtitle(_ identity: ConversationIdentity) -> String { ConversationHeaderView.subtitle(identity, strings: s) }
        XCTAssertEqual(subtitle(ConversationIdentity(id: "u1", title: "Ada", presence: .online)), "在线")
        XCTAssertEqual(subtitle(ConversationIdentity(id: "u1", title: "Ada", presence: .offline)), s.presenceOffline)
        XCTAssertEqual(subtitle(ConversationIdentity(id: "u1", title: "Ada", presence: .busy)), s.presenceBusy)
        XCTAssertEqual(subtitle(ConversationIdentity(id: "u1", title: "Ada", presence: .away)), s.presenceAway)
        XCTAssertEqual(subtitle(ConversationIdentity(id: "g1", title: "Room", kind: .group, presence: .online, memberCount: 8)),
                       s.memberCount(8), "a group's member count comes before a presence")
        XCTAssertEqual(subtitle(ConversationIdentity(id: "u1", title: "Ada", presence: .online, memberCount: 2)), s.presenceOnline,
                       "a direct conversation shows no member count (Vue)")
        XCTAssertEqual(subtitle(ConversationIdentity(id: "u1", title: "Ada", subtitle: " ", presence: .online, typingText: "Ada 正在输入")),
                       "Ada 正在输入")
        XCTAssertEqual(subtitle(ConversationIdentity(id: "u1", title: "Ada")), "")
    }

    // MARK: K3 — a sole overflow action

    private func header(overflow: [ConversationHeaderAction], dispatched: @escaping (String) -> Void) -> ConversationHeaderView {
        ConversationHeaderView(
            identity: ConversationIdentity(id: "u1", title: "Ada"),
            configuration: ConversationHeaderConfiguration(replaceDefaults: true),
            actions: overflow,
            onAction: { dispatched($0.id) })
    }

    func testOnlyASingleOverflowActionTakesTheMoreButton() {
        let details = ConversationHeaderAction(id: "details", label: "Conversation details", placement: .overflow)
        let report = ConversationHeaderAction(id: "report", label: "举报", placement: .overflow)
        XCTAssertEqual(ConversationHeaderView.soleOverflowAction([details])?.id, "details")
        XCTAssertNil(ConversationHeaderView.soleOverflowAction([details, report]))
        XCTAssertNil(ConversationHeaderView.soleOverflowAction([]))
    }

    @MainActor
    func testTheMoreButtonPerformsASoleOverflowActionUnderItsOwnName() throws {
        var dispatched: [String] = []
        let details = ConversationHeaderAction(id: "details", label: "Conversation details", placement: .overflow)
        let view = try header(overflow: [details], dispatched: { dispatched.append($0) }).inspect()
        XCTAssertThrowsError(try view.find(ViewType.Menu.self), "no menu for one action")
        let more = try view.find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.conversationHeaderDetails })
        XCTAssertEqual(try more.labelView().find(ViewType.Image.self).actualImage().name(), flareIconMap["more"],
                       "the glyph stays more")
        try more.tap()
        XCTAssertEqual(dispatched, ["details"])

        let report = ConversationHeaderAction(id: "report", label: "举报", placement: .overflow)
        let two = try header(overflow: [details, report], dispatched: { _ in }).inspect()
        XCTAssertNoThrow(try two.find(ViewType.Menu.self, where: { try $0.accessibilityLabel().string() == self.s.conversationHeaderMoreActions }))
    }

    @MainActor
    func testADisabledSoleOverflowActionIsADisabledButton() throws {
        let locked = ConversationHeaderAction(id: "export", label: "导出", placement: .overflow, enabled: false, disabledReason: "仅群主")
        let view = try header(overflow: [locked], dispatched: { _ in }).inspect()
        let more = try view.find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == "导出" })
        XCTAssertTrue(more.isDisabled())
    }

    // MARK: K8 — host order

    @MainActor
    func testTheListRendersRowsInTheHostOrderAndKeepsThePinMark() throws {
        let items = [
            ConversationRowData(id: "c1", title: "Latest", pinned: false),
            ConversationRowData(id: "c2", title: "Pinned later", pinned: true),
            ConversationRowData(id: "c3", title: "Older", pinned: false),
        ]
        let texts = try ConversationListView(items: items).inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
        let order = ["Latest", "Pinned later", "Older"].map { texts.firstIndex(of: $0) }
        XCTAssertFalse(order.contains(nil), "\(texts)")
        XCTAssertEqual(order.compactMap { $0 }, order.compactMap { $0 }.sorted(), "rows are not re-sorted pinned first: \(texts)")
        let pins = try ConversationListView(items: items).inspect().findAll(ViewType.Image.self)
            .compactMap { try? $0.actualImage().name() }.filter { $0 == "pin" }
        XCTAssertEqual(pins.count, 1, "the pinned row keeps its pin mark")
    }
}
