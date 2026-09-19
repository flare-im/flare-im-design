# Component Usage（2.0.0-rc.1）

自动统计（plans/audit-2026-09-12/tools/inventory.mjs，159 个 catalog 组件）。引用计数 = 含该端 symbol 的文件数：kit 内部（排除自身源文件、facade/index、测试）、website demos、五个 example（web 含 examples/shared/vue-reference，Tauri 只有 bootstrap 因此与 web 共用同一份参考 UI）。Android 只算 `import com.flare.im.ui.X`。

## 总览

| 指标 | 数 |
|---|---|
| 五个 example 都不使用的 public component | 115 / 159 |
| example 与 kit 内部都不使用（只有 demo） | 40 |
| 没有任何端测试引用的组件 | 59 |
| 没有 website Playwright 引用的组件 | 136 |
| Vue 公开导出总数 / 其中未登记进 catalog | 155 / 7 |
| example 文件数（web+shared / tauri / ios / android / flutter） | 53 / 7 / 44 / 39 / 99 |

## 逐组件

| Component | Layer | Public(v/f/i/c) | kit 内部 vue | kit 内部 native | web | ios | android | flutter | demo | Vue test | native tests(f/i/c) | website test refs | a11y 契约 | 替代/重叠 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Avatar | L1 | ✓✓✓✓ | 32 | 31/26/27 | 1 | 2 | 0 | 1 | 1 | 3 | 1/1/0 | 2 | ✗ |  |
| BrandLogo | L1 | ✓✓✓✓ | 0 | 0/0/0 | 1 | 1 | 1 | 1 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| Button | L1 | ✓✓✓✓ | 4 | 3/6/18 | 2 | 3 | 0 | 0 | 10 | 1 | 5/1/0 | 9 | ✓ |  |
| Checkbox | L1 | ✓✓✓✓ | 1 | 1/1/0 | 1 | 0 | 0 | 0 | 1 | 1 | 1/1/0 | 0 | ✓ |  |
| DatePicker | L1 | ✓✓✓✓ | 2 | 1/2/2 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 1 | ✓ |  |
| FormField | L1 | ✓✓✓✓ | 0 | 0/0/0 | 3 | 3 | 1 | 2 | 2 | 0 | 1/0/0 | 0 | ✗ |  |
| Icon | L1 | ✓✓✓✓ | 10 | 3/4/4 | 0 | 0 | 0 | 0 | 4 | 0 | 0/0/0 | 0 | ✗ |  |
| IconButton | L1 | ✓✓✓✓ | 1 | 1/0/10 | 1 | 1 | 0 | 2 | 2 | 0 | 1/0/0 | 0 | ✓ |  |
| Input | L1 | ✓✓✓✓ | 2 | 2/3/3 | 2 | 4 | 1 | 3 | 5 | 2 | 4/1/0 | 3 | ✓ |  |
| PrimaryButton | L1 | ✓✓✓✓ | 0 | 1/2/4 | 0 | 0 | 0 | 0 | 1 | 0 | 0/1/0 | 0 | ✓ | Button |
| RadioGroup | L1 | ✓✓✓✓ | 1 | 2/0/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| Rating | L1 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| SearchDateRangeFilter | L1 | ✗✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| Select | L1 | ✓✓✓✓ | 0 | 3/1/3 | 1 | 0 | 0 | 0 | 6 | 1 | 0/0/0 | 4 | ✓ |  |
| Slider | L1 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 1 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| Stepper | L1 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| Switch | L1 | ✓✓✓✓ | 0 | 1/1/4 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 1 | ✓ |  |
| Textarea | L1 | ✓✓✓✓ | 1 | 0/1/1 | 1 | 0 | 0 | 0 | 2 | 1 | 0/0/0 | 4 | ✓ |  |
| TimePicker | L1 | ✓✓✓✓ | 0 | 1/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 1 | ✓ |  |
| TimeStamp | L1 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✗ | DatePill |
| AdaptiveNavigation | L2 | ✓✓✓✓ | 3 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 2 | 0/0/0 | 0 | ✓ |  |
| BottomSheet | L2 | ✓✗✗✗ | 8 | 0/0/0 | 0 | 0 | 0 | 0 | 4 | 0 | 0/0/0 | 1 | ✓ |  |
| CapabilityBoundary | L2 | ✗✓✓✓ | 2 | 1/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/0/0 | 0 | ✓ |  |
| CommandPalette | L2 | ✗✓✓✓ | 0 | 0/1/2 | 0 | 0 | 0 | 0 | 1 | 1 | 2/0/1 | 0 | ✓ |  |
| DangerConfirm | L2 | ✗✓✓✓ | 1 | 1/0/3 | 1 | 0 | 0 | 1 | 2 | 0 | 1/0/0 | 0 | ✓ |  |
| EmptyState | L2 | ✓✓✓✓ | 12 | 5/6/9 | 4 | 6 | 1 | 5 | 2 | 1 | 2/1/0 | 0 | ✓ |  |
| FilterTabs | L2 | ✓✓✓✓ | 3 | 0/1/1 | 2 | 1 | 0 | 1 | 1 | 0 | 1/0/0 | 0 | ✓ |  |
| FormSheet | L2 | ✓✗✓✗ | 1 | 0/1/0 | 3 | 0 | 0 | 0 | 2 | 2 | 0/0/0 | 0 | ✓ |  |
| PermissionPrompt | L2 | ✓✓✓✓ | 0 | 1/1/2 | 0 | 0 | 0 | 0 | 1 | 0 | 2/0/0 | 0 | ✓ |  |
| ScreenHeader | L2 | ✓✓✓✓ | 1 | 0/0/1 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✗ |  |
| SearchBar | L2 | ✓✓✓✓ | 1 | 1/2/2 | 1 | 0 | 0 | 0 | 2 | 0 | 1/1/0 | 0 | ✓ |  |
| SearchResults | L2 | ✓✓✓✓ | 1 | 1/1/1 | 1 | 0 | 0 | 0 | 1 | 0 | 1/0/0 | 0 | ✓ |  |
| SegmentedControl | L2 | ✓✓✓✓ | 0 | 0/0/1 | 0 | 2 | 1 | 2 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| Skeleton | L2 | ✓✓✓✓ | 3 | 1/2/2 | 0 | 0 | 0 | 0 | 1 | 0 | 1/0/1 | 0 | ✗ |  |
| StatusBanner | L2 | ✓✓✓✓ | 8 | 4/6/6 | 4 | 3 | 0 | 0 | 3 | 0 | 2/0/0 | 0 | ✓ |  |
| Toast | L2 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 1 | 0 | 1 | 1 | 1 | 1/2/0 | 0 | ✓ |  |
| AnnouncementBanner | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| AnnouncementReadBar | L3 | ✓✓✓✓ | 0 | 0/1/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| CallControls | L3 | ✓✓✓✓ | 2 | 2/2/3 | 0 | 0 | 0 | 0 | 1 | 0 | 3/1/0 | 0 | ✓ |  |
| CallDock | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| ChatWallpaperPicker | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| CommentThread | L3 | ✓✓✓✓ | 1 | 1/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| ComposerActionPanel | L3 | ✓✗✓✓ | 0 | 1/2/2 | 1 | 0 | 0 | 0 | 2 | 1 | 2/2/0 | 0 | ✓ |  |
| ComposerReplyStrip | L3 | ✓✗✓✓ | 0 | 1/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 1 | ✓ | Composer 内联实现 |
| ComposerSendButton | L3 | ✓✗✓✓ | 0 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 0 | 0/0/0 | 0 | ✓ | Composer 内联实现 |
| ContactItem | L3 | ✓✓✓✓ | 1 | 1/1/2 | 0 | 0 | 0 | 0 | 1 | 0 | 0/1/0 | 0 | ✓ |  |
| ContactList | L3 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| ContactMatchList | L3 | ✓✓✓✓ | 0 | 0/1/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| ContactMessage | L3 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 1 | 2/1/0 | 0 | ✓ | MessagesView/views/*View.vue |
| ConversationHeader | L3 | ✓✓✓✓ | 0 | 0/0/0 | 1 | 1 | 1 | 1 | 3 | 2 | 1/0/0 | 2 | ✓ |  |
| ConversationList | L3 | ✓✓✓✓ | 1 | 0/1/1 | 0 | 2 | 0 | 0 | 2 | 2 | 1/1/0 | 1 | ✓ |  |
| ConversationRow | L3 | ✓✓✓✓ | 2 | 1/3/3 | 0 | 1 | 0 | 1 | 3 | 1 | 4/3/0 | 0 | ✓ |  |
| DatePill | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 1 | 0 | 1 | 1 | 0 | 0/0/0 | 0 | ✗ |  |
| EmojiMessage | L3 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 1 | 2/1/0 | 0 | ✓ | MessagesView/views/*View.vue |
| EmojiPicker | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| FileMessage | L3 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 1 | 2/1/0 | 0 | ✓ | MessagesView/views/*View.vue |
| GroupList | L3 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| GroupMemberGrid | L3 | ✓✓✓✓ | 1 | 1/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| ImageGrid | L3 | ✓✓✓✓ | 1 | 1/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| ImageMessage | L3 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 1 | 2/1/0 | 0 | ✓ | MessagesView/views/*View.vue |
| ImagePreviewModal | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 1 | 1 | 1 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| LinkCardMessage | L3 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 1 | 1/1/0 | 0 | ✓ | MessagesView/views/*View.vue |
| LocationMessage | L3 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 1 | 2/1/0 | 0 | ✓ | MessagesView/views/*View.vue |
| MarkdownPreview | L3 | ✓✓✓✓ | 0 | 1/2/2 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✗ |  |
| MentionPicker | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| MessageBubble | L3 | ✓✓✓✓ | 0 | 2/3/3 | 0 | 1 | 1 | 1 | 4 | 1 | 3/3/0 | 3 | ✓ |  |
| MessageContentView | L3 | ✓✓✓✓ | 0 | 2/4/4 | 0 | 0 | 0 | 0 | 1 | 0 | 2/1/0 | 0 | ✓ |  |
| MessageList | L3 | ✓✓✓✓ | 0 | 1/3/2 | 1 | 0 | 0 | 0 | 4 | 0 | 2/2/0 | 2 | ✓ |  |
| MessageMeta | L3 | ✓✓✓✓ | 0 | 1/2/2 | 0 | 0 | 0 | 0 | 1 | 2 | 4/2/0 | 2 | ✓ |  |
| MessageStatus | L3 | ✓✓✓✓ | 0 | 1/2/2 | 0 | 0 | 0 | 0 | 1 | 1 | 3/3/0 | 4 | ✓ |  |
| MomentActionPopover | L3 | ✓✓✓✓ | 1 | 1/0/0 | 0 | 0 | 0 | 0 | 2 | 0 | 0/0/0 | 0 | ✓ |  |
| MomentCard | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| MomentsCoverHeader | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| MomentsVisibilityRuleList | L3 | ✓✓✓✓ | 0 | 0/1/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| NewFriendRequests | L3 | ✓✓✓✓ | 0 | 0/2/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/2/0 | 0 | ✓ |  |
| PinnedMessageBar | L3 | ✓✓✓✓ | 0 | 1/2/2 | 1 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| ProfileCard | L3 | ✓✓✓✓ | 0 | 0/0/1 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| ProfileEditor | L3 | ✓✓✓✓ | 0 | 0/2/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| QRCard | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✗ |  |
| QuickPhrases | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| ReactionSummary | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 1 | 1 | 0 | 1/0/0 | 0 | ✓ |  |
| RedPacketCard | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| RelationActionBar | L3 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| RichMarkdownInput | L3 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/0/0 | 0 | ✓ |  |
| ScrollToLatest | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| SettingsList | L3 | ✓✓✓✓ | 4 | 3/1/3 | 0 | 0 | 0 | 1 | 2 | 1 | 2/1/0 | 0 | ✓ |  |
| SettingsRow | L3 | ✓✓✓✓ | 2 | 1/2/2 | 0 | 1 | 0 | 1 | 2 | 1 | 1/0/0 | 0 | ✓ |  |
| SlashCommandMenu | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| StickerMessage | L3 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 1 | 2/1/0 | 0 | ✓ | MessagesView/views/*View.vue |
| StickerPanel | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| SystemMessage | L3 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 1 | 2/1/0 | 0 | ✗ | MessagesView/views/*View.vue |
| TaskMessage | L3 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 1 | 2/1/0 | 0 | ✓ | MessagesView/views/*View.vue |
| TextMessage | L3 | ✓✓✓✓ | 1 | 1/1/1 | 0 | 0 | 0 | 0 | 2 | 1 | 2/1/0 | 0 | ✓ | MessagesView/views/*View.vue |
| TopicChip | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| TransferProgress | L3 | ✓✓✓✓ | 1 | 1/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/0/0 | 0 | ✓ |  |
| TransferQueue | L3 | ✗✓✓✓ | 1 | 1/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/0/0 | 0 | ✓ |  |
| TranslationView | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✗ |  |
| TypingIndicator | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✗ |  |
| UnknownMessage | L3 | ✓✓✓✓ | 1 | 1/2/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| UnknownUserPlaceholder | L3 | ✓✓✓✓ | 0 | 0/1/0 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✗ |  |
| UnreadDivider | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✗ |  |
| VideoMessage | L3 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 1 | 2/1/0 | 0 | ✓ | MessagesView/views/*View.vue |
| VideoPlayerModal | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 1 | 1 | 1 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| VoiceHoldButton | L3 | ✓✗✓✓ | 0 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 0 | 0/0/0 | 0 | ✓ | Composer 内联实现 |
| VoiceMessage | L3 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 2 | 2/1/0 | 0 | ✓ | VoicePlayer |
| VoicePlayer | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 1 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| VoiceRecordingBar | L3 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| VoteMessage | L3 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 2 | 1 | 2/1/0 | 0 | ✓ | MessagesView/views/*View.vue |
| AdaptiveWorkbench | L4 | ✓✓✓✓ | 1 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/1/0 | 0 | ✗ |  |
| AppLayout | L4 | ✓✓✓✓ | 3 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✗ |  |
| AppShell | L4 | ✓✓✓✓ | 0 | 1/0/2 | 0 | 0 | 0 | 0 | 2 | 0 | 1/1/0 | 0 | ✓ | MobileAppShell + DesktopAppShell |
| CallDevicePicker | L4 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 1/0/0 | 0 | ✓ |  |
| CallView | L4 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 2/1/0 | 0 | ✓ |  |
| CallWorkspace | L4 | ✓✓✓✗ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ | WorkspaceFrame ×7 |
| ChatWorkspace | L4 | ✓✓✓✓ | 0 | 0/0/0 | 4 | 0 | 0 | 0 | 1 | 1 | 0/0/0 | 1 | ✓ |  |
| Composer | L4 | ✓✓✓✓ | 0 | 2/4/14 | 2 | 2 | 0 | 1 | 5 | 2 | 3/2/0 | 5 | ✓ |  |
| ContactDetail | L4 | ✓✓✓✓ | 0 | 0/2/2 | 0 | 0 | 0 | 0 | 1 | 0 | 1/2/0 | 0 | ✓ |  |
| ContactsWorkspace | L4 | ✓✓✓✗ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ | WorkspaceFrame ×7 |
| ConversationActionSheet | L4 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 1 | 0 | 1 | 1 | 0 | 1/1/0 | 1 | ✓ |  |
| ConversationBatchToolbar | L4 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| ConversationDetails | L4 | ✓✓✓✓ | 0 | 1/3/1 | 2 | 0 | 0 | 0 | 1 | 1 | 1/1/0 | 0 | ✓ |  |
| ConversationListContainer | L4 | ✓✓✓✓ | 2 | 0/0/1 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ | FlareConversationListPanel（未登记导出） |
| ConversationWorkspace | L4 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/0/0 | 1 | ✓ |  |
| DesktopAppShell | L4 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| DesktopWorkbench | L4 | ✓✓✗✗ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 2 | 1 | 1/0/0 | 1 | ✓ | DesktopAppShell |
| DeviceSessions | L4 | ✗✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 1/0/0 | 0 | ✓ | SceneList（内部） |
| ForwardPicker | L4 | ✓✓✓✓ | 0 | 0/0/0 | 1 | 0 | 0 | 0 | 1 | 1 | 0/0/0 | 0 | ✓ |  |
| FriendListContainer | L4 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ | ConversationListContainer / ConversationListPanel |
| GroupCallView | L4 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 1/0/0 | 0 | ✓ |  |
| GroupDetail | L4 | ✓✓✓✓ | 1 | 1/1/0 | 0 | 0 | 0 | 0 | 1 | 1 | 0/0/0 | 0 | ✓ |  |
| GroupPermissionMatrix | L4 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| GroupWorkspace | L4 | ✓✓✓✗ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ | WorkspaceFrame ×7 |
| IMAppKit | L4 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 1 | 1 | 1 | 1 | 1 | 0/0/0 | 0 | ✓ |  |
| IncomingCall | L4 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 2/1/0 | 0 | ✓ |  |
| MasterDetailLayout | L4 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/1/0 | 0 | ✗ | AdaptiveWorkbench |
| MediaCenter | L4 | ✗✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 1/0/0 | 0 | ✓ | SceneList（内部） |
| MediaWorkspace | L4 | ✓✓✓✗ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ | WorkspaceFrame ×7 |
| MemberPanel | L4 | ✗✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ | SceneList（内部） |
| MemberRoleSheet | L4 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 1 | ✓ |  |
| MessageActionSheet | L4 | ✓✓✓✓ | 0 | 1/2/1 | 0 | 0 | 0 | 1 | 1 | 0 | 1/2/0 | 1 | ✓ | ComposerActionPanel / FlareMessageContextMenuSheet |
| MessageBatchToolbar | L4 | ✓✓✓✓ | 1 | 1/1/1 | 1 | 0 | 0 | 0 | 1 | 1 | 0/0/0 | 0 | ✓ |  |
| MobileAppShell | L4 | ✓✓✓✓ | 1 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| MomentAudienceSheet | L4 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| MomentComposer | L4 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| NotificationPreferences | L4 | ✗✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 1/0/0 | 0 | ✓ | SceneList（内部） |
| PollComposer | L4 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| ProfilePanel | L4 | ✓✓✓✓ | 1 | 1/2/2 | 0 | 0 | 0 | 0 | 1 | 0 | 1/2/0 | 0 | ✓ |  |
| ReadReceiptSheet | L4 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| ResponsiveLayout | L4 | ✓✓✓✓ | 1 | 1/1/2 | 0 | 0 | 0 | 0 | 2 | 0 | 3/1/0 | 0 | ✓ |  |
| SavedMessagesWorkspace | L4 | ✓✓✓✗ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ | WorkspaceFrame ×7 |
| Screen | L4 | ✓✓✓✗ | 0 | 0/0/0 | 1 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ |  |
| ScreenShare | L4 | ✗✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 1/1/0 | 0 | ✓ |  |
| SearchPanel | L4 | ✗✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 2/0/0 | 0 | ✓ |  |
| SearchWorkspace | L4 | ✓✓✓✗ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ | WorkspaceFrame ×7 |
| SettingsWorkspace | L4 | ✓✓✓✗ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/0/0 | 0 | ✓ | WorkspaceFrame ×7 |
| StartConversationDialog | L4 | ✓✓✓✓ | 0 | 1/2/2 | 1 | 0 | 0 | 0 | 2 | 0 | 1/1/0 | 0 | ✓ |  |
| StorageUsage | L4 | ✓✓✓✓ | 0 | 0/1/1 | 0 | 0 | 0 | 0 | 1 | 0 | 0/1/0 | 0 | ✓ | SceneList（内部） |
| ThreePaneLayout | L4 | ✓✓✓✓ | 0 | 0/0/0 | 0 | 0 | 0 | 0 | 1 | 0 | 0/1/0 | 0 | ✗ | AdaptiveWorkbench |
| ConfigProvider | L5 | ✓✗✗✗ | 3 | 0/0/0 | 3 | 0 | 0 | 0 | 5 | 3 | 0/0/0 | 0 | ✗ |  |

## 重点名单

### Public but unused（example 与 kit 内部零引用，只有 demo）

- DesktopAppShell [L4 Feature/Compound] demos=1 tests=0
- FriendListContainer [L4 Feature/Compound] demos=1 tests=0
- ContactsWorkspace [L4 Feature/Compound] demos=1 tests=0
- GroupWorkspace [L4 Feature/Compound] demos=1 tests=0
- SearchWorkspace [L4 Feature/Compound] demos=1 tests=0
- MediaWorkspace [L4 Feature/Compound] demos=1 tests=0
- CallWorkspace [L4 Feature/Compound] demos=1 tests=0
- SettingsWorkspace [L4 Feature/Compound] demos=1 tests=0
- SavedMessagesWorkspace [L4 Feature/Compound] demos=1 tests=0
- GroupCallView [L4 Feature/Compound] demos=1 tests=0
- TypingIndicator [L3 IM Domain] demos=1 tests=0
- UnreadDivider [L3 IM Domain] demos=1 tests=0
- ScrollToLatest [L3 IM Domain] demos=1 tests=0
- ReadReceiptSheet [L4 Feature/Compound] demos=1 tests=0
- MentionPicker [L3 IM Domain] demos=1 tests=0
- QuickPhrases [L3 IM Domain] demos=1 tests=0
- CallDock [L3 IM Domain] demos=1 tests=0
- AnnouncementBanner [L3 IM Domain] demos=1 tests=0
- RedPacketCard [L3 IM Domain] demos=1 tests=0
- SlashCommandMenu [L3 IM Domain] demos=1 tests=0
- TranslationView [L3 IM Domain] demos=1 tests=0
- QRCard [L3 IM Domain] demos=1 tests=0
- VoiceRecordingBar [L3 IM Domain] demos=1 tests=0
- PollComposer [L4 Feature/Compound] demos=1 tests=0
- ChatWallpaperPicker [L3 IM Domain] demos=1 tests=0
- EmojiPicker [L3 IM Domain] demos=1 tests=0
- StickerPanel [L3 IM Domain] demos=1 tests=0
- MomentCard [L3 IM Domain] demos=1 tests=0
- MomentComposer [L4 Feature/Compound] demos=1 tests=0
- MomentsCoverHeader [L3 IM Domain] demos=1 tests=0
- TopicChip [L3 IM Domain] demos=1 tests=0
- SearchPanel [L4 Feature/Compound] demos=1 tests=0
- MemberPanel [L4 Feature/Compound] demos=1 tests=0
- DeviceSessions [L4 Feature/Compound] demos=1 tests=0
- NotificationPreferences [L4 Feature/Compound] demos=1 tests=0
- MediaCenter [L4 Feature/Compound] demos=1 tests=0
- CallDevicePicker [L4 Feature/Compound] demos=1 tests=0
- DesktopWorkbench [L4 Feature/Compound] demos=2 tests=1
- MasterDetailLayout [L4 Feature/Compound] demos=1 tests=0
- ThreePaneLayout [L4 Feature/Compound] demos=1 tests=0

### Used only in demo/test（example 零使用、kit 内部有引用）

- TimeStamp（kit 内部 vue 0，native 2）
- AppLayout（kit 内部 vue 3，native 0）
- AdaptiveNavigation（kit 内部 vue 3，native 0）
- MobileAppShell（kit 内部 vue 1，native 0）
- ConversationListContainer（kit 内部 vue 2，native 1）
- MessageStatus（kit 内部 vue 0，native 5）
- MessageMeta（kit 内部 vue 0，native 5）
- MessageContentView（kit 内部 vue 0，native 10）
- TextMessage（kit 内部 vue 1，native 3）
- ImageMessage（kit 内部 vue 1，native 5）
- VideoMessage（kit 内部 vue 1，native 5）
- VoiceMessage（kit 内部 vue 1，native 5）
- FileMessage（kit 内部 vue 1，native 5）
- LocationMessage（kit 内部 vue 1，native 5）
- ContactMessage（kit 内部 vue 1，native 5）
- LinkCardMessage（kit 内部 vue 1，native 5）
- VoteMessage（kit 内部 vue 1，native 5）
- TaskMessage（kit 内部 vue 1，native 5）
- StickerMessage（kit 内部 vue 1，native 5）
- EmojiMessage（kit 内部 vue 1，native 5）
- SystemMessage（kit 内部 vue 1，native 5）
- VoiceHoldButton（kit 内部 vue 0，native 5）
- ComposerSendButton（kit 内部 vue 0，native 5）
- ComposerReplyStrip（kit 内部 vue 0，native 3）
- RichMarkdownInput（kit 内部 vue 0，native 2）
- MarkdownPreview（kit 内部 vue 0，native 5）
- ContactList（kit 内部 vue 0，native 2）
- ContactItem（kit 内部 vue 1，native 4）
- ContactDetail（kit 内部 vue 0，native 4）
- GroupDetail（kit 内部 vue 1，native 2）
- NewFriendRequests（kit 内部 vue 0，native 3）
- GroupList（kit 内部 vue 0，native 2）
- ProfilePanel（kit 内部 vue 1，native 5）
- ProfileEditor（kit 内部 vue 0，native 3）
- CallView（kit 内部 vue 0，native 2）
- IncomingCall（kit 内部 vue 0，native 2）
- CallControls（kit 内部 vue 2，native 7）
- AppShell（kit 内部 vue 0，native 3）
- ResponsiveLayout（kit 内部 vue 1，native 4）
- ProfileCard（kit 内部 vue 0，native 1）
- GroupMemberGrid（kit 内部 vue 1，native 3）
- Skeleton（kit 内部 vue 3，native 5）
- ImageGrid（kit 内部 vue 1，native 3）
- ConversationBatchToolbar（kit 内部 vue 0，native 2）
- UnknownMessage（kit 内部 vue 1，native 4）
- PrimaryButton（kit 内部 vue 0，native 7）
- ScreenHeader（kit 内部 vue 1，native 1）
- MomentActionPopover（kit 内部 vue 1，native 1）
- CommentThread（kit 内部 vue 1，native 1）
- Switch（kit 内部 vue 0，native 6）
- RadioGroup（kit 内部 vue 1，native 3）
- Stepper（kit 内部 vue 0，native 2）
- Rating（kit 内部 vue 0，native 2）
- TimePicker（kit 内部 vue 0，native 3）
- DatePicker（kit 内部 vue 2，native 5）
- Icon（kit 内部 vue 10，native 11）
- ConversationWorkspace（kit 内部 vue 0，native 2）
- MomentsVisibilityRuleList（kit 内部 vue 0，native 1）
- ContactMatchList（kit 内部 vue 0，native 1）
- AnnouncementReadBar（kit 内部 vue 0，native 1）
- MomentAudienceSheet（kit 内部 vue 0，native 2）
- TransferProgress（kit 内部 vue 1，native 3）
- TransferQueue（kit 内部 vue 1，native 3）
- CapabilityBoundary（kit 内部 vue 2，native 3）
- PermissionPrompt（kit 内部 vue 0，native 4）
- SearchDateRangeFilter（kit 内部 vue 0，native 2）
- UnknownUserPlaceholder（kit 内部 vue 0，native 1）
- RelationActionBar（kit 内部 vue 0，native 2）
- GroupPermissionMatrix（kit 内部 vue 0，native 2）
- MemberRoleSheet（kit 内部 vue 0，native 2）
- StorageUsage（kit 内部 vue 0，native 2）
- ScreenShare（kit 内部 vue 0，native 2）
- AdaptiveWorkbench（kit 内部 vue 1，native 0）
- CommandPalette（kit 内部 vue 0，native 3）
- BottomSheet（kit 内部 vue 8，native 0）

### Used only once（五个 example 合计恰好 1 个文件）

- StartConversationDialog
- MessageList
- PinnedMessageBar
- ComposerActionPanel
- MessageActionSheet
- SearchBar
- SettingsList
- ReactionSummary
- MessageBatchToolbar
- SearchResults
- ForwardPicker
- VoicePlayer
- Checkbox
- Select
- Textarea
- Slider
- Screen

### Public but not in catalog（Vue 导出，见 architecture audit 末表）

- FlareConversationListPanel ← ./conversation/FlareConversationListPanel.vue internal=0 demos=0 examples=1 tests=1
- FlareChatHeader ← ./messages/ChatConversationHeader.vue internal=1 demos=2 examples=1 tests=1
- FlareChatHeaderIdentity ← ./messages/ChatConversationHeaderIdentity.vue internal=0 demos=0 examples=1 tests=0
- FlareMessagePreviewModal ← ./message-preview/MessagePreviewModal.vue internal=0 demos=0 examples=1 tests=0
- FlareComposerEmojiStickerPanel ← ./composer/ComposerEmojiStickerPanel/index.vue internal=0 demos=2 examples=2 tests=0
- FlareStartConversationSheet ← ./shell/FlareStartConversationSheet.vue internal=0 demos=1 examples=1 tests=0
- FlareMediaComposerPreviewModal ← ./composer/FlareMediaComposerPreviewModal.vue internal=0 demos=1 examples=2 tests=1

### Duplicate implementation（详见 component-duplication.md）

- Flare*Message（standalone 15）↔ MessagesView/views/*View（20）+ business/*View（5）
- VoiceMessage ↔ VoicePlayer；TimeStamp ↔ DatePill；MessageList 内置回底 ↔ ScrollToLatest；PrimaryButton ↔ Button；ChatHeader ↔ ConversationHeader；StartConversationSheet ↔ StartConversationDialog；MessageActionSheet(附件九宫格) ↔ ComposerActionPanel；ConversationListContainer ↔ ConversationListPanel；7 个 *Workspace ↔ WorkspaceFrame；MasterDetail/ThreePane ↔ AdaptiveWorkbench；DesktopWorkbench ↔ DesktopAppShell；AppShell ↔ Mobile/DesktopAppShell；4 个预览模态。

### Orphan（无 catalog、无消费者、无测试）

- FlareContentView、FlareStickerPicker、FlareThemeProvider、FlareMessageTimeline（别名）、FlareMessageDoubleCheckIcon

### 测试覆盖缺口（任何端都没有测试引用，58 个）

- AppLayout
- MobileAppShell
- DesktopAppShell
- ConversationListContainer
- FriendListContainer
- ContactsWorkspace
- GroupWorkspace
- SearchWorkspace
- MediaWorkspace
- CallWorkspace
- SettingsWorkspace
- SavedMessagesWorkspace
- VoiceHoldButton
- ComposerSendButton
- ComposerReplyStrip
- TypingIndicator
- UnreadDivider
- ScrollToLatest
- ProfileCard
- GroupMemberGrid
- ReadReceiptSheet
- MentionPicker
- QuickPhrases
- CallDock
- AnnouncementBanner
- DatePill
- RedPacketCard
- SlashCommandMenu
- TranslationView
- QRCard
- ImageGrid
- VoiceRecordingBar
- PollComposer
- ChatWallpaperPicker
- VoicePlayer
- EmojiPicker
- StickerPanel
- SegmentedControl
- ScreenHeader
- MomentCard
- MomentComposer
- MomentActionPopover
- MomentsCoverHeader
- CommentThread
- TopicChip
- Stepper
- Slider
- Rating
- TimePicker
- DatePicker
- Icon
- MomentsVisibilityRuleList
- ContactMatchList
- AnnouncementReadBar
- MomentAudienceSheet
- MemberPanel
- Screen
- BottomSheet
- BrandLogo

## 说明

- 『使用』按文件级引用统计，含通过组合组件的间接使用（kit 内部列）；网站 demo 不算消费者。
- example 零使用不等于无价值：Call/Moments 等的消费者在 flare-social（不在本次 5 个 example 内），但 2.0 定稿前每个 KEEP 组件必须有一个真实消费者或降为 BETA。
- Tauri 示例的 UI 与 Web 共用 examples/shared/vue-reference，因此 web 列即两者。
