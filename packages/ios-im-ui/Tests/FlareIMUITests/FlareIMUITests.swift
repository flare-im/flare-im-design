import SwiftUI
import XCTest
@testable import FlareIMUI

final class FlareIMUITests: XCTestCase {
    func testRichMarkdownLabelsAreHumanReadableAndInjectable() {
        let labels = FlareRichMarkdownLabels(bold: "Bold", italic: "Italic", code: "Code", list: "List", link: "Link")
        XCTAssertEqual(labels.bold, "Bold")
        XCTAssertEqual(labels.link, "Link")
    }

    func testInitialsFallback() {
        XCTAssertEqual(AvatarView.initials("Henry Ford"), "HF")
        XCTAssertEqual(AvatarView.initials("Ivy"), "I")
        XCTAssertEqual(AvatarView.initials("   "), "?")
    }

    func testSeedTintIsDeterministic() {
        let light = FlareColors.of(.light)
        XCTAssertEqual(AvatarView.seedTint("u1", light).bg, AvatarView.seedTint("u1", light).bg)
        XCTAssertEqual(AvatarView.seedTint("u1", light).fg, AvatarView.seedTint("u1", light).fg)
        // 同一个人在亮/暗下是**不同**的一对色:暗色以前根本没有变体,头像在深色表面上
        // 当作一块浅色马卡龙。色板现在来自 token 真源,按模式解析。
        let dark = FlareColors.of(.dark)
        XCTAssertNotEqual(AvatarView.seedTint("u1", light).bg, AvatarView.seedTint("u1", dark).bg)
        // 但选中的是同一格:取模只看种子,不看模式。
        XCTAssertEqual(AvatarView.seedTint("u1", dark).bg, AvatarView.seedTint("u1", dark).bg)
    }

    func testTokensThemeDiffers() {
        XCTAssertNotEqual(FlareColors.light.bgPrimary, FlareColors.dark.bgPrimary)
    }

    func testAllBrandsHaveDistinctMessageSemanticsAndSupportCustomThemes() {
        let outgoing = Set(FlareBrandTheme.allCases.map { FlareColors.of(.light, brand: $0).messageOutgoingBackground })
        let read = Set(FlareBrandTheme.allCases.map { FlareColors.of(.light, brand: $0).messageStatusRead })
        XCTAssertEqual(outgoing.count, FlareBrandTheme.allCases.count)
        XCTAssertEqual(read.count, FlareBrandTheme.allCases.count)

        let customPrimary = Color(red: 0, green: 0.34, blue: 0.72)
        let light = FlareColors.forestLight.copy(primary: customPrimary)
        let custom = FlareBrandTheme(name: "custom", light: light, dark: .graphiteDark)
        XCTAssertEqual(FlareColors.of(.light, brand: custom).primary, customPrimary)
        XCTAssertEqual(FlareColors.of(.dark, brand: custom).messageStatusRead, FlareColors.graphiteDark.messageStatusRead)
    }

    func testSizeTokens() {
        XCTAssertEqual(FlareSizes.avatarSize, 44)
        XCTAssertEqual(FlareSizes.spacingMd, 12)
    }

    func testViewsConstruct() {
        _ = AvatarView(userId: "u1", displayName: "Ann", presence: .online)
        _ = DatePillView(label: "14:32")
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
        _ = FlareContactDetail(contact: contacts[0])
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

        _ = ResponsiveLayoutView(list: AnyView(Text("l")), chat: AnyView(Text("c")), detail: AnyView(Text("d")))
    }

    func testMessageAndComposerViewsConstruct() {
        let msgs = [FlareMessageData(id: "m1", senderId: "me", senderName: "me", content: FlareTextContent("hi"))]
        _ = MessageListView(messages: msgs, currentUserId: "me")
        _ = MessageBubbleView(message: msgs[0], currentUserId: "me")
        _ = MessageContentView(content: FlareTextContent("hi"), isSelf: true)
        _ = ConversationHeaderView(identity: ConversationIdentity(id: "team", title: "Team", subtitle: "在线", presence: .online))
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

    func testEmojiStickerCatalogLoadsFromCentralSource() {
        let catalog = FlareEmojiStickerCatalog.shared
        XCTAssertGreaterThan(catalog.loadedEmojiKeys().count, 100)
        XCTAssertTrue(catalog.hasEmojiKey("red_heart"))
        let packs = catalog.loadedStickerPacks()
        XCTAssertTrue(packs.contains { $0.id == "gifs" })
        XCTAssertTrue(packs.contains { $0.id == "classic" })
    }

    func testStickerSubdirGifsAlias() {
        XCTAssertEqual(FlareEmojiStickerCatalog.stickerSubdir(forPackageId: "gifs"), "default")
        XCTAssertEqual(FlareEmojiStickerCatalog.stickerSubdir(forPackageId: "classic"), "classic")
        XCTAssertEqual(FlareEmojiStickerCatalog.stickerSubdir(forPackageId: nil), "default")
    }

    // The webp binaries are fetched on demand (assets/emoji-sticker/fetch-assets.sh +
    // sync-resources.sh) and never tracked, so a clean checkout has the manifest but
    // no images. Skip rather than fail: the catalog test above already proves the
    // tracked contract loads; this one only makes sense once the images are present.
    func testBundledWebpDecodesToFrames() throws {
        guard let url = FlareEmojiStickerCatalog.shared.emojiImageURL("red_heart") else {
            throw XCTSkip("emoji webp not synced into Resources/emoji-sticker (run fetch-assets.sh + sync-resources.sh)")
        }
        let decoded = flareDecodeAnimatedWebp(url: url)
        XCTAssertNotNil(decoded)
        XCTAssertGreaterThanOrEqual(decoded?.frames.count ?? 0, 1)
    }
}
