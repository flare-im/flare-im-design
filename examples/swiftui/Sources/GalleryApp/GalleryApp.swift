import SwiftUI
import FlareIMUI

/// A small consumer app that renders FlareIMUI on a simulator and exercises the
/// same brand and appearance matrix as the other platform examples.
@main
struct FlareIMUIGalleryApp: App {
    @State private var dark = false
    @State private var brand: FlareBrandTheme = .violet

    var body: some Scene {
        WindowGroup {
            GalleryView(dark: $dark, brand: $brand)
                .flareTheme(brand: brand)
                .preferredColorScheme(dark ? .dark : .light)
        }
    }
}

private func demoMsg(_ id: String, _ name: String, _ text: String, self isSelf: Bool = false) -> FlareMessageData {
    FlareMessageData(id: id, senderId: isSelf ? "me" : id, senderName: name,
                     content: FlareTextContent(text), timeLabel: "14:30", status: .read)
}

struct GalleryView: View {
    @Binding var dark: Bool
    @Binding var brand: FlareBrandTheme
    @State private var commandPaletteOpen = false
    @State private var commandQuery = ""
    @State private var selectedCommand: String? = "new-message"

    private let commandGroups = [
        FlareCommandPaletteGroup(id: "workspace", label: "Workspace", commands: [
            FlareCommandPaletteCommand(id: "new-message", label: "New conversation",
                                       description: "Choose a contact or group", shortcut: "⌘N"),
            FlareCommandPaletteCommand(id: "search", label: "Search messages",
                                       description: "Find content in this workspace", shortcut: "⌘F"),
            FlareCommandPaletteCommand(id: "settings", label: "Open settings", shortcut: "⌘,"),
        ]),
    ]

    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                    section("MessageBubble") {
                        MessageBubbleView(message: demoMsg("2", "Ivy Chen", "新版设计稿已经上传啦，帮忙看下～"),
                                          currentUserId: "me", conversationKind: .group)
                        MessageBubbleView(message: demoMsg("3", "Me", "收到，我下午过一遍给你反馈 👍", self: true),
                                          currentUserId: "me", conversationKind: .group)
                    }
                    section("ConversationRow") {
                        ConversationRowView(item: ConversationRowData(
                            id: "c1", title: "Ivy Chen", preview: "好的，那明天上午同步一下 👍",
                            timestampLabel: "14:32", unreadCount: 3, pinned: true))
                        ConversationRowView(item: ConversationRowData(
                            id: "c2", title: "设计评审组", preview: "Kai: 新稿已上传", timestampLabel: "13:05"))
                    }
                    section("ConversationHeader") {
                        ConversationHeaderView(identity: ConversationIdentity(id: "u2", title: "Ivy Chen", subtitle: "在线 · 设计评审组", presence: .online),
                                               showBack: true, onBack: {})
                    }
                    section("SettingsList") {
                        SettingsListView(sections: [
                            FlareSettingsSection(title: "通用", items: [
                                FlareSettingsItem(key: "notify", label: "新消息通知", kind: .toggle, value: true),
                                FlareSettingsItem(key: "lang", label: "语言", detail: "简体中文"),
                            ]),
                        ])
                        .frame(height: 140)
                    }
                    section("ProfilePanel") {
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
                    ToolbarItem(placement: .navigationBarLeading) {
                        Picker("Theme", selection: $brand) {
                            ForEach(FlareBrandTheme.allCases, id: \.self) { item in
                                Text(item.name.capitalized).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Commands") { commandPaletteOpen = true }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(dark ? "Light" : "Dark") { dark.toggle() }
                    }
                }
            }
            .navigationViewStyle(.stack)

            CommandPaletteView(
                open: commandPaletteOpen,
                query: commandQuery,
                groups: commandGroups,
                label: "Workspace commands",
                placeholder: "Search commands",
                emptyText: "No matching commands",
                onQueryChange: { commandQuery = $0 },
                onInvoke: { _ in commandPaletteOpen = false },
                onClose: { commandPaletteOpen = false },
                selectedId: selectedCommand,
                onSelectedIdChange: { selectedCommand = $0 }
            )
        }
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundColor(.secondary)
            content()
        }
    }
}
