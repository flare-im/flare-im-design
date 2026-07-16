#if DEBUG
import SwiftUI

// Xcode-canvas demos for every FlareIMUI component — the iOS equivalent of the web
// docs demos. Each renders the REAL component with mock data (no mockups). Target is
// iOS 16, so these use `PreviewProvider` rather than the iOS-17 `#Preview` macro.

private func demoRow(_ id: String, _ name: String, _ text: String, self isSelf: Bool = false,
                     _ status: FlareMessageDeliveryStatus = .read) -> FlareMessageData {
    FlareMessageData(id: id, senderId: isSelf ? "me" : id, senderName: name,
                     content: FlareTextContent(text), timeLabel: "14:30", status: status)
}

// MARK: General

struct FlareAvatar_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 12) {
            AvatarView(userId: "u1", displayName: "Ivy Chen", presence: .online)
            AvatarView(userId: "u2", displayName: "Henry Ford", presence: .busy)
            AvatarView(userId: "u3", displayName: "Kai")
        }.padding()
    }
}

struct FlareTimeStamp_Previews: PreviewProvider {
    static var previews: some View {
        HStack { TimeStampView(label: "刚刚"); TimeStampView(label: "14:32"); TimeStampView(label: "昨天") }.padding()
    }
}

struct FlareMessageStatus_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            MessageStatusView(status: .pending)
            MessageStatusView(status: .sent)
            MessageStatusView(status: .read)
            MessageStatusView(status: .failed)
        }.padding()
    }
}

struct FlareEmptyState_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(title: "还没有会话", description: "发起一个聊天，或从通讯录里找人开始对话。", actionText: "发起聊天").padding()
    }
}

struct FlareSearchBar_Previews: PreviewProvider {
    static var previews: some View { SearchBarView(text: .constant(""), placeholder: "搜索联系人、群组、消息").padding() }
}

struct FlareInput_Previews: PreviewProvider {
    static var previews: some View { InputView(text: .constant("Flare IM 组件库"), placeholder: "请输入…", maxLength: 40, clearable: true).padding() }
}

struct FlareMarkdownPreview_Previews: PreviewProvider {
    static var previews: some View { MarkdownPreviewView(content: "## 新版设计稿\n\n- **加粗** / *斜体* / `代码`\n- [链接](https://flare.im)", showStats: true).padding() }
}

// MARK: Conversation

struct FlareConversationRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ConversationRowView(item: ConversationRowData(id: "c1", title: "Ivy Chen", preview: "好的，那明天上午同步一下 👍", timestampLabel: "14:32", unreadCount: 3, pinned: true, tags: [ConversationRowTag(text: "Official", tone: .warning)]))
            ConversationRowView(item: ConversationRowData(id: "c2", title: "设计评审组", preview: "Kai: 新稿已上传", timestampLabel: "13:05", tags: [ConversationRowTag(text: "Group", tone: .info)]))
        }.padding()
    }
}

struct FlareConversationList_Previews: PreviewProvider {
    static var previews: some View {
        ConversationListView(items: [
            ConversationRowData(id: "c1", title: "Ivy Chen", preview: "好的 👍", timestampLabel: "14:32", unreadCount: 3, pinned: true),
            ConversationRowData(id: "c2", title: "设计评审组", preview: "Kai: 新稿已上传", timestampLabel: "13:05"),
        ], activeId: "c1")
    }
}

struct FlareConversationDetails_Previews: PreviewProvider {
    static var previews: some View {
        ConversationDetailsView(conversation: FlareConversationSummary(id: "c1", title: "设计评审组", kind: .group, memberCount: 12), connectionText: "已连接", connectionTone: .ok, messageCount: 128).padding()
    }
}

// MARK: Contacts / Profile

struct FlareContactItem_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ContactItemView(item: Contact(id: "u1", name: "Henry Ford", signature: "Keep it simple.", presence: .online))
            ContactItemView(item: Contact(id: "u2", name: "Ivy Chen", signature: "设计即沟通", presence: .busy))
        }.padding()
    }
}

struct FlareContactList_Previews: PreviewProvider {
    static var previews: some View {
        ContactListView(items: [
            Contact(id: "u1", name: "Henry Ford", presence: .online),
            Contact(id: "u2", name: "Ivy Chen", presence: .busy),
            Contact(id: "u3", name: "Kai"),
        ])
    }
}

struct FlareContactDetail_Previews: PreviewProvider {
    static var previews: some View { ContactDetailView(contact: Contact(id: "u2", name: "Ivy Chen", signature: "设计即沟通", presence: .online)).padding() }
}

struct FlareGroupList_Previews: PreviewProvider {
    static var previews: some View {
        GroupListView(items: [GroupSummary(id: "g1", name: "设计评审组", memberCount: 12), GroupSummary(id: "g2", name: "Flare 前端", memberCount: 34)])
    }
}

struct FlareNewFriendRequests_Previews: PreviewProvider {
    static var previews: some View {
        NewFriendRequestsView(items: [FriendRequest(id: "r1", name: "Ivy Chen", message: "一起做设计～"), FriendRequest(id: "r2", name: "Kai", message: "加个好友")])
    }
}

struct FlareProfilePanel_Previews: PreviewProvider {
    static var previews: some View { ProfilePanelView(user: UserProfile(id: "me", name: "Ivy Chen", signature: "设计即沟通", flareId: "ivy_chen")) }
}

struct FlareProfileEditor_Previews: PreviewProvider {
    static var previews: some View { ProfileEditorView(user: UserProfile(id: "me", name: "Ivy Chen", signature: "设计即沟通", flareId: "ivy_chen")) }
}

struct FlareSettingsList_Previews: PreviewProvider {
    static var previews: some View {
        SettingsListView(sections: [
            FlareSettingsSection(title: "通用", items: [
                FlareSettingsItem(key: "notify", label: "新消息通知", kind: .toggle, value: true),
                FlareSettingsItem(key: "lang", label: "语言", detail: "简体中文"),
            ]),
        ])
    }
}

// MARK: Message bodies

struct FlareTextMessage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextMessageView(text: "收到，我下午过一遍给你反馈 👍", isSelf: true)
            TextMessageView(text: "新版设计稿已经上传啦，帮忙看下～")
        }.padding()
    }
}

struct FlareMessageBodies_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 12) {
            ImageMessageView(alt: "示例图片")
            VideoMessageView(duration: "01:24")
            VoiceMessageView(seconds: 12)
            FileMessageView(name: "设计规范.pdf", size: "2.4 MB", ext: "pdf")
            LocationMessageView(title: "深圳湾科技生态园", address: "科技南路 · 3 栋")
            ContactMessageView(name: "Ivy Chen", subtitle: "设计师")
            LinkCardMessageView(title: "Flare IM Design", domain: "flare.im", description: "一套契约，四端原生实现")
            TaskMessageView(title: "提交本周周报", meta: "周五 18:00", done: false)
            VoteMessageView(title: "周会时间", options: [FlareVoteOption("周三上午", 60), FlareVoteOption("周四下午", 40)], total: "10 票")
            HStack { StickerMessageView(); EmojiMessageView() }
            SystemMessageView(text: "Ivy 加入了群聊")
        }.padding()
    }
}

struct FlareMessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 4) {
            MessageBubbleView(message: demoRow("2", "Ivy Chen", "新版设计稿已经上传啦，帮忙看下～"), currentUserId: "me", conversationKind: .group)
            MessageBubbleView(message: demoRow("3", "Ivy Chen", "收到，我下午过一遍给你反馈 👍", self: true), currentUserId: "me", conversationKind: .group)
        }.padding()
    }
}

struct FlareMessageList_Previews: PreviewProvider {
    static var previews: some View {
        MessageListView(messages: [
            demoRow("1", "Ivy Chen", "新版设计稿已经上传啦～"),
            demoRow("2", "Me", "收到，下午看", self: true),
            demoRow("3", "Ivy Chen", "辛苦～重点看会话列表"),
        ], currentUserId: "me", conversationKind: .group)
    }
}

struct FlarePinnedMessageBar_Previews: PreviewProvider {
    static var previews: some View {
        PinnedMessageBarView(items: [FlarePinnedMessage(id: "1", summary: "周五 15:00 设计评审", senderName: "Ivy Chen")]).padding()
    }
}

// MARK: Composer

struct FlareComposerParts_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            FlareVoiceHoldButton()
            FlareComposerActionPanel()
            FlareComposerSendButton(active: true)
            FlareComposerReplyStrip(senderName: "Ivy Chen", summary: "新版设计稿已经上传啦")
        }.padding()
    }
}

struct FlareComposer_Previews: PreviewProvider {
    static var previews: some View { ComposerView(placeholder: "发送给 Ivy Chen").padding() }
}

struct FlareRichMarkdownInput_Previews: PreviewProvider {
    static var previews: some View { RichMarkdownInputView(text: .constant("支持 **加粗** / *斜体* / 链接"), formattingPreview: true).padding() }
}

struct FlareMessageActionSheet_Previews: PreviewProvider {
    static var previews: some View { MessageActionSheetView().padding() }
}

// MARK: Chat header / Call

struct FlareChatHeader_Previews: PreviewProvider {
    static var previews: some View { ChatHeaderView(title: "Ivy Chen", subtitle: "在线", presence: .online, avatarUserId: "u2") }
}

struct FlareCall_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            CallControlsView(cameraOn: true, mode: .video)
            IncomingCallView(callerName: "Ivy Chen", mode: .video)
        }
    }
}

struct FlareCallView_Previews: PreviewProvider {
    static var previews: some View { CallView(peerName: "Ivy Chen", mode: .video, state: .connected, durationLabel: "03:24") }
}

// MARK: Form controls

/// Stateful host so the interactive form controls can be driven inside the canvas.
private struct FormControlsDemo: View {
    @State private var select = "sf"
    @State private var bio = "Flare IM 设计系统 —— 多行输入，聚焦有焦点环，自动增高。"
    @State private var qty: Double = 2
    @State private var volume: Double = 40
    @State private var stars = 3
    @State private var time = "09:30"
    @State private var date = "2026-07-16"

    private let cities = [
        FlareSelectOption(value: "sf", label: "San Francisco"),
        FlareSelectOption(value: "ny", label: "New York"),
        FlareSelectOption(value: "tk", label: "Tokyo"),
        FlareSelectOption(value: "sh", label: "Shanghai（暂不可选）", disabled: true),
        FlareSelectOption(value: "ld", label: "London"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Select（底部 Sheet）").font(.system(size: 13, weight: .medium))
                    SelectView(options: cities, selection: $select, placeholder: "选择城市", title: "选择城市")
                }
                Group {
                    Text("TimePicker（底部 Sheet + 原生滚轮）").font(.system(size: 13, weight: .medium))
                    TimePickerView(value: $time, placeholder: "选择时间", minuteStep: 15, title: "选择时间")
                }
                Group {
                    Text("DatePicker（底部 Sheet + 月历）").font(.system(size: 13, weight: .medium))
                    DatePickerView(value: $date, placeholder: "选择日期",
                                   min: "2026-01-01", max: "2026-12-31", title: "选择日期")
                }
                Group {
                    Text("Textarea").font(.system(size: 13, weight: .medium))
                    TextareaView(text: $bio, placeholder: "介绍一下…", rows: 3, maxRows: 6,
                                 showCount: true, maxlength: 120)
                }
                Group {
                    Text("Stepper").font(.system(size: 13, weight: .medium))
                    HStack(spacing: 16) {
                        StepperView(value: $qty, min: 0, max: 10, size: .sm)
                        StepperView(value: $qty, min: 0, max: 10)
                        StepperView(value: $qty, min: 0, max: 10, size: .lg, readonly: true)
                    }
                }
                Group {
                    Text("Slider").font(.system(size: 13, weight: .medium))
                    SliderView(value: $volume, showValue: true)
                }
                Group {
                    Text("Rating").font(.system(size: 13, weight: .medium))
                    VStack(alignment: .leading, spacing: 10) {
                        RatingView(value: $stars, clearable: true)
                        RatingView(value: .constant(4), size: 18, readonly: true)
                    }
                }
            }
            .padding()
        }
    }
}

struct FlareFormControls_Previews: PreviewProvider {
    static var previews: some View {
        FormControlsDemo()
        FormControlsDemo().preferredColorScheme(.dark)
    }
}
#endif
