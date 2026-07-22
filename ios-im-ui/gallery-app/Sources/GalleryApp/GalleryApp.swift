import SwiftUI
import FlareIMUI

/// A tiny gallery app that renders the FlareIMUI Aurora components on a simulator
/// — real-device verification beyond `swift build`. Defaults to dark so the
/// Aurora surfaces (glowing bubble, glowing unread badge) are visible on launch.
@main
struct FlareIMUIGalleryApp: App {
    // Follows the simulator's system appearance so both themes can be captured
    // via `xcrun simctl ui booted appearance light|dark`.
    @State private var dark = true
    var body: some Scene {
        WindowGroup {
            GalleryView(dark: $dark)
        }
    }
}

private func demoMsg(_ id: String, _ name: String, _ text: String, self isSelf: Bool = false) -> FlareMessageData {
    FlareMessageData(id: id, senderId: isSelf ? "me" : id, senderName: name,
                     content: FlareTextContent(text), timeLabel: "14:30", status: .read)
}

struct GalleryView: View {
    @Binding var dark: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    section("MessageBubble — Aurora 发光气泡") {
                        MessageBubbleView(message: demoMsg("2", "Ivy Chen", "新版设计稿已经上传啦，帮忙看下～"),
                                          currentUserId: "me", conversationKind: .group)
                        MessageBubbleView(message: demoMsg("3", "Me", "收到，我下午过一遍给你反馈 👍", self: true),
                                          currentUserId: "me", conversationKind: .group)
                    }
                    section("ConversationRow — 发光未读徽标 / 置顶淡底") {
                        ConversationRowView(item: ConversationRowData(
                            id: "c1", title: "Ivy Chen", preview: "好的，那明天上午同步一下 👍",
                            timestampLabel: "14:32", unreadCount: 3, pinned: true))
                        ConversationRowView(item: ConversationRowData(
                            id: "c2", title: "设计评审组", preview: "Kai: 新稿已上传", timestampLabel: "13:05"))
                    }
                    section("ChatHeader — 透明栏 / 返回在头像左") {
                        ChatHeaderView(title: "Ivy Chen", subtitle: "在线 · 设计评审组",
                                       presence: .online, avatarUserId: "u2", onBack: {})
                    }
                    section("SettingsList — 分组浮层卡") {
                        SettingsListView(sections: [
                            FlareSettingsSection(title: "通用", items: [
                                FlareSettingsItem(key: "notify", label: "新消息通知", kind: .toggle, value: true),
                                FlareSettingsItem(key: "lang", label: "语言", detail: "简体中文"),
                            ]),
                        ])
                        .frame(height: 140)
                    }
                    section("ProfilePanel — 极光头部") {
                        ProfilePanelView(user: UserProfile(id: "me", name: "Ivy Chen",
                                                           signature: "设计即沟通", flareId: "ivy_chen"))
                        .frame(height: 220)
                    }
                }
                .padding(16)
            }
            .navigationTitle("FlareIMUI Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(dark ? "浅色" : "深色") { dark.toggle() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundColor(.secondary)
            content()
        }
    }
}
