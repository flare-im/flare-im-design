import SwiftUI
import XCTest
@testable import FlareIMUI

final class FlareIMUITests: XCTestCase {
    func testInitialsFallback() {
        XCTAssertEqual(AvatarView.initials("Henry Ford"), "HF")
        XCTAssertEqual(AvatarView.initials("Ivy"), "I")
        XCTAssertEqual(AvatarView.initials("   "), "?")
    }

    func testSeedTintIsDeterministic() {
        XCTAssertEqual(AvatarView.seedTint("u1").bg, AvatarView.seedTint("u1").bg)
        XCTAssertEqual(AvatarView.seedTint("u1").fg, AvatarView.seedTint("u1").fg)
    }

    func testTokensThemeDiffers() {
        XCTAssertNotEqual(FlareColors.light.bgPrimary, FlareColors.dark.bgPrimary)
    }

    func testSizeTokens() {
        XCTAssertEqual(FlareSizes.avatarSize, 42)
        XCTAssertEqual(FlareSizes.spacingMd, 12)
    }

    func testViewsConstruct() {
        _ = AvatarView(userId: "u1", displayName: "Ann", presence: .online)
        _ = TimeStampView(label: "14:32")
        _ = MessageStatusView(status: .read, variant: .compact)
    }

    func testConversationRowDataFlags() {
        let unread = ConversationRowData(id: "c1", title: "A", unreadCount: 3)
        XCTAssertTrue(unread.hasUnread)
        let draft = ConversationRowData(id: "c1", title: "A", draftPreview: "wip")
        XCTAssertTrue(draft.hasDraft)
        let plain = ConversationRowData(id: "c1", title: "A")
        XCTAssertFalse(plain.hasUnread)
        XCTAssertFalse(plain.hasDraft)
    }

    func testConversationViewsConstruct() {
        let rows = [ConversationRowData(id: "c1", title: "One"),
                    ConversationRowData(id: "c2", title: "Two", unreadCount: 5)]
        _ = ConversationListView(items: rows, activeId: "c1")
        _ = ConversationRowView(item: rows[0], active: true)
        _ = ConversationDetailsView(
            conversation: FlareConversationSummary(id: "c1", title: "Team", kind: .group, memberCount: 4),
            connectionText: "已连接")
        _ = StartConversationView(contacts: [FlareContactOption(id: "u1", name: "Ann")])
    }

    func testMessageDataIsSystem() {
        let sys = FlareMessageData(id: "m1", senderId: "s", senderName: "s",
                                   content: FlareNotificationContent("joined"))
        XCTAssertTrue(sys.isSystem)
        let text = FlareMessageData(id: "m2", senderId: "s", senderName: "s",
                                    content: FlareTextContent("hi"))
        XCTAssertFalse(text.isSystem)
    }

    func testContentTypeKeysAndBareMedia() {
        XCTAssertEqual(FlareTextContent("x").type, "text")
        XCTAssertEqual(FlareImageContent(url: "u").type, "image")
        XCTAssertEqual(FlareGenericContent(contentType: "vote", label: "l").type, "vote")
        XCTAssertTrue(MessageBubbleView.isBareMedia(FlareImageContent(url: "u")))
        XCTAssertFalse(MessageBubbleView.isBareMedia(FlareTextContent("x")))
    }

    func testContentHelpers() {
        XCTAssertEqual(MessageContentView.duration(75), "01:15")
        XCTAssertEqual(MessageContentView.bytes(2048), "2.0 KB")
    }

    func testRegistryRegisterUnregister() {
        FlareContentRegistry.register("vote") { _, _ in AnyView(EmptyView()) }
        XCTAssertNotNil(FlareContentRegistry.lookup("vote"))
        FlareContentRegistry.unregister("vote")
        XCTAssertNil(FlareContentRegistry.lookup("vote"))
    }

    func testPhaseCViewsConstruct() {
        var q = ""
        let qb = Binding(get: { q }, set: { q = $0 })
        _ = SearchBarView(text: qb)
        _ = InputView(text: qb, maxLength: 20, clearable: true)
        _ = EmptyStateView(title: "空", description: "d", actionText: "a")

        let contacts = [Contact(id: "u1", name: "Henry"), Contact(id: "u2", name: "Ivy", signature: "PM")]
        _ = ContactItemView(item: contacts[0])
        _ = ContactListView(items: contacts)
        _ = ContactDetailView(contact: contacts[0])
        _ = NewFriendRequestsView(items: [FriendRequest(id: "r1", name: "Bob", message: "hi")])
        _ = GroupListView(items: [GroupSummary(id: "g1", name: "Team", memberCount: 4)])

        let user = UserProfile(id: "me", name: "我", flareId: "flare_me")
        _ = ProfilePanelView(user: user)
        _ = ProfileEditorView(user: user)
        _ = SettingsListView(sections: [FlareSettingsSection(title: "通用", items: [
            FlareSettingsItem(key: "mute", label: "免打扰", kind: .toggle, value: true),
        ])])

        _ = CallControlsView(mode: .video)
        _ = CallView(peerName: "Henry", mode: .video, state: .connected, durationLabel: "02:14")
        _ = IncomingCallView(callerName: "Ivy", mode: .audio)

        let nav = [FlareNavItem(key: "chat", label: "消息", systemImage: "message", badge: 3)]
        _ = AppShellView(items: nav, activeKey: "chat") { Text("content") }
        _ = ResponsiveLayoutView(list: AnyView(Text("l")), chat: AnyView(Text("c")), detail: AnyView(Text("d")))
    }

    func testMessageAndComposerViewsConstruct() {
        let msgs = [FlareMessageData(id: "m1", senderId: "me", senderName: "me", content: FlareTextContent("hi"))]
        _ = MessageListView(messages: msgs, currentUserId: "me")
        _ = MessageBubbleView(message: msgs[0], currentUserId: "me")
        _ = MessageContentView(content: FlareTextContent("hi"), isSelf: true)
        _ = ChatHeaderView(title: "Team", subtitle: "在线", presence: .online)
        _ = PinnedMessageBarView(items: [FlarePinnedMessage(id: "p1", summary: "s")])
        _ = ComposerView(rich: false)
        _ = MessageActionSheetView()
        _ = MarkdownPreviewView(content: "# H\n\n- a\n\n**b**", showStats: true)
        _ = ImagePreviewView(show: true, imageSrc: "https://x/y.png")
        _ = VideoPlayerView(show: true, videoSrc: "https://x/y.mp4", title: "Clip")
    }

    func testStandaloneMessageBodiesConstruct() {
        _ = TextMessageView(text: "hello", isSelf: false)
        _ = ImageMessageView()
        _ = VideoMessageView(duration: "00:42")
        _ = VoiceMessageView(seconds: 7)
        _ = FileMessageView(name: "spec.pdf", size: "2.4 MB", ext: "PDF")
        _ = LocationMessageView(title: "HQ", address: "Beijing")
        _ = ContactMessageView(name: "Ivy Chen", subtitle: "Product Designer")
        _ = LinkCardMessageView(title: "Flare", domain: "flare.im")
        _ = VoteMessageView(title: "When?", options: [FlareVoteOption("Thu", 62), FlareVoteOption("Fri", 38)])
        _ = TaskMessageView(title: "Sync", meta: "done", done: true)
        _ = StickerMessageView(emoji: "🐱")
        _ = EmojiMessageView(emoji: "🎉")
        _ = SystemMessageView(text: "recalled")
    }
}
