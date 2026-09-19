# Icon Coverage

Date: 2026-09-15 (Round 5), with the Batch 5 additions on 2026-09-16 and the Round 9 decision on the fifteen nominations on 2026-09-18 (105 names). The IM concepts a complete IM app needs, checked against the 61-name semantic registry (identical on Vue, Flutter, SwiftUI and Compose) and against what the kits and the five reference apps draw today. Registry details: `icon-inventory.md`. Rules: `icon-guidelines.md`.

Decision values: **Use** an existing name; **ADD** a name, because a kit or app draws the concept today with a borrowed or unnamed glyph; **Not added**, because nothing draws it (names are added when a consumer appears, not for completeness).

## Totals

| | Count |
|---|---:|
| IM concepts checked | 129 |
| Exist under the same name | 38 |
| Exist under another registry name | 13 |
| Absent | 78 |
| Absent and drawn today (added in Round 5 Batch 1) | 42 on the natives; the Vue kit adds `attachment`, `zoom-in`, `zoom-out`, `rotate`, `keyboard`, `speaker-off` |
| Absent with no consumer (not added) | 35 |

## Coverage

| Group | IM concept | Registry today | Drawn today (evidence) | Decision |
|---|---|---|---|---|
| Navigation | `home` | - | no: no home destination in any kit default nav or app | Not added: no home destination |
| Navigation | `messages` | as `chats` | yes: tabs: flutter-app base_shell.dart:268, ios-app MainShell.swift:19, android-app FlareSocialApp.kt:568; kit defaults application_composition.dart:114, ApplicationComposition.swift:124, ApplicationComposition.kt:90 | Use `chats` |
| Navigation | `contacts` | - (`people` nearest) | yes: tabs: base_shell.dart:280, MainShell.swift:21, FlareSocialApp.kt:571; kit defaults application_composition.dart:120, ApplicationComposition.swift:125, ApplicationComposition.kt:91 | Use `people` |
| Navigation | `groups` | - | yes: flutter-app tab base_shell.dart:292; kit contact-nav defaults application_composition.dart:141, ApplicationComposition.swift:131, ApplicationComposition.kt:97; ContactViews.swift:296 | ADD `group` |
| Navigation | `search` | exact | yes: flare_search_bar.dart:74, GeneralViews.swift:83, SearchBar.kt:84 | Use `search` |
| Navigation | `notifications` | as `notification` | yes: flare_conversation_action_sheet.dart:220 (unmute), PermissionPromptView.swift:53 | Use `notification` |
| Navigation | `settings` | exact | yes: flare_profile_panel.dart:60, ProfileViews.swift:26, ProfilePanel.kt:129 | Use `settings` |
| Navigation | `profile` | as `person` | yes: kit default nav application_composition.dart:126, ApplicationComposition.swift:126, ApplicationComposition.kt:92; apps MainShell.swift:23, FlareSocialApp.kt:573 | Use `person` |
| Navigation | `back` | exact | yes: flare_screen.dart:101, FlareScreen.swift:58, FlareScreen.kt:72 | Use `back` |
| Navigation | `forward` | exact (message forward) | no (as navigation): no forward navigation control; the registry name is used for message forwarding | Use `forward` (message forwarding; no forward navigation) |
| Navigation | `close` | exact | yes: flare_forward_picker.dart:130, ForwardPickerView.swift:49, ForwardPicker.kt:81 | Use `close` |
| Navigation | `more` | exact | yes: flare_conversation_header.dart:332, ConversationHeaderView.swift:255, ConversationHeader.kt:205; apps MoreVert ContactsScreen.kt:55 | Use `more` |
| Navigation | `menu` | - | no: no drawer/hamburger anywhere | Not added: no drawer or hamburger |
| Message | `send` | exact | yes: flare_composer_parts.dart:79, ComposerParts.swift:216, ComposerParts.kt:160 | Use `send` |
| Message | `reply` | exact | yes: flare_message_action_sheet.dart:97, MessageActionSheetView.swift:80, MessageActionSheet.kt:119 | Use `reply` |
| Message | `quote` | - | yes: format strip flare_composer.dart:473, ComposerView.swift:228 (text.quote), Composer.kt:227 (FormatQuote) | ADD `quote` |
| Message | `forward` | exact | yes: flare_message_action_sheet.dart:102, MessageActionSheetView.swift:81, MessageActionSheet.kt:120 | Use `forward` (message forwarding; no forward navigation) |
| Message | `mergeForward` | - | yes: flare_message_batch_toolbar.dart:101, MessageBatchToolbarView.swift:39, MessageBatchToolbar.kt:65 | ADD `merge-forward` |
| Message | `copy` | exact | yes: flare_message_action_sheet.dart:152, MessageActionSheetView.swift:89, MessageActionSheet.kt:128 | Use `copy` |
| Message | `edit` | exact | yes: flare_message_action_sheet.dart:173, MessageActionSheetView.swift:92, MessageActionSheet.kt:131 | Use `edit` |
| Message | `delete` | exact | yes: flare_message_action_sheet.dart:180, MessageActionSheetView.swift:93, MessageActionSheet.kt:132 | Use `delete` |
| Message | `recall` | - | yes: flare_message_action_sheet.dart:105 (undo), MessageActionSheetView.swift:82 (arrow.uturn.backward), MessageActionSheet.kt:121 (Undo) | ADD `recall` |
| Message | `pin` | exact | yes: flare_message_action_sheet.dart:131, MessageActionSheetView.swift:86, MessageActionSheet.kt:125 | Use `pin` |
| Message | `unpin` | - | yes: flare_message_action_sheet.dart:145, MessageActionSheetView.swift:88 (pin.slash), MessageActionSheet.kt:127 | ADD `unpin` |
| Message | `reaction` | - (`emoji` is the composer glyph) | yes: add-reaction flare_reaction_summary.dart:53, ReactionSummaryView.swift:59, ReactionSummary.kt:74 (AddReaction) | ADD `reaction` |
| Message | `translate` | - (`language` is the settings globe) | yes: flare_translation_view.dart:102, TranslationView.swift:35 (globe), TranslationView.kt:71 (Translate) | ADD `translate` |
| Message | `select` | - | yes: selection ring flare_message_bubble.dart:119-120, MessageBubbleView.swift:119, MessageBubble.kt:159 | Checkbox state, not an icon; use `check` |
| Message | `multiSelect` | - | yes: flare_message_action_sheet.dart:117, MessageActionSheetView.swift:84, MessageActionSheet.kt:123 (checklist on all three) | ADD `multi-select` |
| Message | `retry` | as `refresh` | yes: resend flare_message_action_sheet.dart:110, MessageActionSheetView.swift:83, MessageActionSheet.kt:122 | Use `refresh` |
| Message | `failed` | - (`error` is an x-circle; failed draws an exclamation circle) | yes: flare_message_status.dart:183, MessageStatusView.swift:148, MessageStatus.kt:94 | Use `error` (remapped to the exclamation circle) |
| Message | `delivered` | - (kit-painted double check) | yes, served by painters: flare_message_status.dart:169-174, MessageStatusView.swift:137-141, MessageStatus.kt:89-90 | Status painter; `read` covers the double check in menus |
| Message | `read` | - (kit-painted double check, read colour) | yes, served by painters: flare_message_status.dart:175-180, MessageStatusView.swift:142-146, MessageStatus.kt:91-92 | ADD `read` (double check) for menus and receipts; the status painter stays |
| Composer | `emoji` | exact | yes: flare_composer.dart:517, ComposerView.swift:205, Composer.kt:197 | Use `emoji` |
| Composer | `mention` | - | yes: flare_composer.dart:526, ComposerView.swift:207 (at), Composer.kt:198 (AlternateEmail) | ADD `mention` |
| Composer | `attachment` | - (kits use `add` as the panel toggle) | no: no paperclip anywhere; the + toggle is flare_composer.dart:563, ComposerView.swift:215, Composer.kt:203 | ADD `attachment` (the Vue upload strip draws a paperclip) |
| Composer | `image` | exact | yes: flare_composer.dart:548, ComposerView.swift:210, Composer.kt:200 | Use `image` |
| Composer | `gallery` | - | yes: album entry flare_profile_panel.dart:55, ProfileViews.swift:25, ProfilePanel.kt:128; flutter-app moments_screen.dart:142 | Use `image` |
| Composer | `camera` | exact | yes: flare_profile_editor.dart:89, ProfileViews.swift:148, ProfileEditor.kt:60 | Use `camera` |
| Composer | `video` | exact | yes: flare_message_bodies.dart:213, MessageBodyViews.swift:154, MessageBodies.kt:187 | Use `video` |
| Composer | `audio` | - | no: voice uses `mic`; no audio-file affordance | Not added: voice uses `mic` |
| Composer | `microphone` | as `mic` | yes: flare_composer.dart:534, ComposerView.swift:209, Composer.kt:199 | Use `mic` |
| Composer | `file` | exact | yes: flare_message_bodies.dart:347, MessageBodyViews.swift:225, MessageBodies.kt:242 | Use `file` |
| Composer | `location` | exact (concept differs on iOS) | yes: flare_message_bodies.dart:428, MessageBodyViews.swift:261, MessageBodies.kt:265 | Use `location` (remapped on iOS) |
| Composer | `contact` | - | yes: attach tile flare_composer_action_panel.dart:130, ComposerParts.swift:141, ComposerActions.kt:67; apps ChatView.swift:36, ChatScreen.kt:122 | Use `person` (Round 5); `card` since Round 9 |
| Composer | `poll` | exact | yes: flare_message_bodies.dart:693, MessageBodyViews.swift:387, MessageBodies.kt:341; apps ChatView.swift:37, ChatScreen.kt:123 | Use `poll` (remapped on Web) |
| Composer | `task` | - | no: TaskMessage draws a checkbox, not a task glyph (flare_message_bodies.dart:800, MessageBodyViews.swift:432, MessageBodies.kt:370) | Not added: the task body draws a checkbox |
| Composer | `schedule` | as `clock` | no (as scheduled send): no scheduled-send control; clock is used for pending/recent (flare_message_status.dart:149) | Not added: no scheduled send |
| Composer | `topic` | - | no: FlareTopicChip draws no glyph | Not added: the topic chip draws no glyph |
| Composer | `miniApp` | - | Flutter only: flare_message_content_view.dart:182 (apps_outlined); iOS MessageContentView.swift:115 and Compose MessageContentView.kt:104 draw none | ADD `mini-app` |
| Composer | `richText` | - | yes: toggle flare_composer.dart:553, ComposerView.swift:212, Composer.kt:201; strip bold/italic/strike/code/link/heading/quote/lists flare_composer.dart:433-483, ComposerView.swift:228, Composer.kt:227 | ADD `rich-text`; the format strip glyphs stay an internal table |
| Conversation | `privateChat` | - | no: no kind glyph in headers/rows | Not added: no kind glyph |
| Conversation | `groupChat` | - | yes (same as groups): flare_group_detail.dart:791 (groups_2_outlined), FlareGroupDetailView.swift:491 (person.3) | Use `group` |
| Conversation | `channel` | - | no: no channel glyph | Not added: no channels |
| Conversation | `unread` | - | yes: mark unread flare_conversation_action_sheet.dart:222, ConversationActionSheetView.swift:121, ConversationActionSheet.kt:110; mark read :221 / :120 / :109 | ADD `mark-unread` (mark read uses `read`) |
| Conversation | `mentionUnread` | - (text badge) | no glyph: rendered as text '@' application_composition.dart:530, ApplicationComposition.swift:311, ApplicationComposition.kt:312 | Text badge, not an icon |
| Conversation | `mute` | exact | yes: flare_conversation_row.dart:176, ConversationRowView.swift:89, ConversationRow.kt:81 | Use `mute` |
| Conversation | `unmute` | as `notification` | yes: flare_conversation_action_sheet.dart:220, ConversationActionSheetView.swift:119, ConversationActionSheet.kt:108 | Use `notification` |
| Conversation | `pin` | exact | yes: flare_conversation_row.dart:167, ConversationRowView.swift:88, ConversationRow.kt:80 | Use `pin` |
| Conversation | `archive` | - | yes: flare_conversation_action_sheet.dart:223-224, ConversationActionSheetView.swift:122-123, ConversationActionSheet.kt:111-112 | ADD `archive` and `unarchive` |
| Conversation | `draft` | - | no: no draft glyph | Not added: the draft prefix is text |
| Conversation | `typing` | - | no: animated dots, not a glyph | Animation, not an icon |
| Conversation | `online` | - | no: presence dot primitive (flare_presence_dot.dart) | Presence dot, not an icon |
| Conversation | `offline` | - | no: presence dot primitive | Presence dot, not an icon |
| Calls | `phone` | exact | yes: flare_contact_detail.dart:180, FlareContactDetailView.swift:134, ContactDetail.kt:110 | Use `phone` |
| Calls | `phoneIncoming` | - | no: no call log | Not added: no call log |
| Calls | `phoneOutgoing` | - | no: no call log | Not added: no call log |
| Calls | `phoneMissed` | - | no: no call log | Not added: no call log |
| Calls | `videoCall` | as `video`; alias `videoCall` (F,C) | yes: action_icon.dart:15, ActionMenu.kt:159; iOS has no alias (ConversationHeaderView.swift:308) | Use `video`; add the `video-call` alias on iOS so header actions match Flutter and Compose |
| Calls | `screenShare` | - (mapped to `devices`/`video`/`eye`) | yes: flare_screen_share.dart:266, ScreenShareView.swift:28-35, ScreenShare.kt:189 | ADD `screen-share` |
| Calls | `speaker` | - | yes: flare_call_controls.dart:64, CallViews.swift:37, CallControls.kt:67 | ADD `speaker` and `speaker-off` |
| Calls | `muteMic` | - | yes: flare_call_controls.dart:49, CallViews.swift:32, CallControls.kt:62; docks flare_call_dock.dart:142, CallDockView.swift:59, CallDock.kt:95 | ADD `mic-off` |
| Calls | `cameraOff` | - | yes: flare_call_controls.dart:56, CallViews.swift:34, CallControls.kt:64; group tiles flare_group_call_view.dart:200, GroupCallView.swift:100, GroupCallView.kt:135 | ADD `camera-off` |
| Calls | `endCall` | - | yes: flare_call_controls.dart:127, CallViews.swift:65, CallControls.kt:94 | ADD `end-call` |
| Media | `play` | - | yes: flare_video_player.dart:124, VideoPlayerView.swift:78, VideoPlayer.kt:54; voice flare_voice_player.dart:199, VoicePlayerView.swift:96, VoicePlayer.kt:79 | ADD `play` |
| Media | `pause` | - | yes: flare_voice_player.dart:199, VoicePlayerView.swift:96, VoicePlayer.kt:79 | ADD `pause` |
| Media | `stop` | - | no: no stop control | Not added: no stop control |
| Media | `download` | exact | yes: flare_image_preview.dart:104, ImagePreviewView.swift:75, ImagePreview.kt:101 | Use `download` |
| Media | `upload` | - | no: transfer queue/progress draw no glyph | Not added: transfers draw no glyph |
| Media | `save` | - (Flutter/Compose reuse download) | yes: flare_message_action_sheet.dart:166, MessageActionSheetView.swift:91 (square.and.arrow.down), MessageActionSheet.kt:130 | Use `download` |
| Media | `zoomIn` | - | no: pinch only | ADD `zoom-in` (Vue image preview) |
| Media | `zoomOut` | - | no: pinch only | ADD `zoom-out` (Vue image preview) |
| Media | `fullscreen` | - | yes: composer expand flare_composer.dart:730-731, ComposerView.swift:181, Composer.kt:243; call dock flare_call_dock.dart:131, CallDockView.swift:53, CallDock.kt:86 | ADD `expand` and `collapse` (composer resize, call dock) |
| Media | `rotate` | - | no: no rotate control (flip camera is separate: flare_call_controls.dart:61) | ADD `rotate` (Vue image preview) |
| Media | `volume` | - | yes: voice playing flare_message_bodies.dart:280, MessageBodyViews.swift:186, MessageBodies.kt:212 | Use `speaker` |
| Media | `volumeMute` | - | yes: member mute / mute-all flare_member_role_sheet.dart:214, MemberRoleSheetView.swift:153, MemberRoleSheet.kt:127; flare_group_permission_matrix.dart:281, GroupPermissionMatrixView.swift:192, GroupPermissionMatrix.kt:139 | Use `silence` for member mute; `speaker-off` for audio output |
| Files | `file` | exact | yes: see Composer/file | Use `file` |
| Files | `document` | - | no: transcript toggle uses a doc glyph (flare_voice_player.dart:131, VoicePlayerView.swift:149, VoicePlayer.kt:112); `file` covers it | Use `file` |
| Files | `pdf` | - | no: no per-type file glyphs (FileMessage only exposes an icon slot, MessageBodies.kt:225) | Not added: no per-type file glyphs |
| Files | `spreadsheet` | - | no: same | Not added |
| Files | `presentation` | - | no: same | Not added |
| Files | `archive` | - | no: same | Not added |
| Files | `code` | - | yes, as rich-text format only: flare_composer.dart:448, ComposerView.swift:228, Composer.kt:227 (see richText) | Format strip only; internal table |
| Files | `folder` | exact | yes: attach tile flare_composer_action_panel.dart:127, ComposerParts.swift:138, ComposerActions.kt:64 (for 'file' attach) | Use `folder` |
| Members | `user` | as `person` | yes: flare_unknown_user_placeholder.dart:227, UnknownUserPlaceholderView.swift:159, UnknownUserPlaceholder.kt:156 | Use `person` |
| Members | `users` | as `people` | yes: flare_mention_picker.dart:178, MentionPickerView.swift:75, MentionPicker.kt:107 | Use `people` |
| Members | `addMember` | as `person-add`; alias `addMember` (F,C) | yes: flare_call_controls.dart:71, CallViews.swift:40, CallControls.kt:69; action_icon.dart:16, ActionMenu.kt:160 | Use `person-add` |
| Members | `removeMember` | - (drawn with the logout glyph) | yes: flare_member_role_sheet.dart:217, MemberRoleSheetView.swift:156, MemberRoleSheet.kt:130 | ADD `remove-member` |
| Members | `admin` | - | yes: promote flare_member_role_sheet.dart:212, MemberRoleSheetView.swift:151, MemberRoleSheet.kt:125 | ADD `admin` |
| Members | `owner` | - | no glyph: owner shown as text role | Text role, not an icon |
| Members | `transferOwner` | - (drawn with the star glyph) | yes: flare_member_role_sheet.dart:216, MemberRoleSheetView.swift:155, MemberRoleSheet.kt:129 | ADD `transfer-owner` |
| Members | `block` | exact | yes: flare_relation_action_bar.dart:204, RelationActionBarView.swift:148, RelationActionBar.kt:137 | Use `block` |
| Members | `report` | - | yes (apps): ios-app FriendActionViews.swift:68, SettingsViews.swift:167, ReportViews.swift:96; android-app SettingsScreen.kt:129, :414 | ADD `report` |
| Status | `success` | exact | yes: flare_toast.dart:296, ToastView.swift:41, Toast.kt:79 (all draw filled variants, not the registry glyph) | Use `success` |
| Status | `info` | exact | yes: flare_unknown_message.dart:114, UnknownMessageView.swift:80, UnknownMessage.kt:90 | Use `info` |
| Status | `warning` | exact | yes: flare_search_date_range_filter.dart:422, SearchDateRangeFilterView.swift:270, SearchDateRangeFilter.kt:269 | Use `warning` |
| Status | `error` | exact | yes: flare_toast.dart:300, ToastView.swift:43, Toast.kt:80 | Use `error` |
| Status | `loading` | - | yes: toast loading flare_toast.dart:316, ToastView.swift:52, Toast.kt:82 | A progress primitive per kit, not an icon name |
| Status | `sync` | - | yes: flare_conversation_details.dart:131, ConversationDetailsView.swift:191, ConversationDetails.kt:101 | Use `refresh` |
| Status | `offline` | - | no glyph: status banners are text (apps FlareSocialRootView.swift:57) | Banner text, not an icon |
| Status | `reconnecting` | - | no glyph: same | Banner text, not an icon |
| Security | `lock` | exact | yes: flare_group_permission_matrix.dart:368, GroupPermissionMatrixView.swift:297, GroupPermissionMatrix.kt:271 | Use `lock` |
| Security | `unlock` | - | no: no unlock control | Not added |
| Security | `shield` | - | yes (as admin): see Members/admin | Use `admin` |
| Security | `verified` | - | no: no verified badge | Not added: no verified badge |
| Security | `permission` | - | no: permission prompt uses kind names (PermissionPromptView.swift:49-69) | Not added: prompts name the permission |
| Security | `privacy` | - | yes (apps): flutter-app base_shell.dart:740, profile_center_screen.dart:168; ios-app SettingsViews.swift:160; android-app SettingsScreen.kt:118 | Use `lock` |
| General | `add` | exact | yes: flare_group_member_grid.dart:162, GroupMemberGridView.swift:84, GroupMemberGrid.kt:114 | Use `add` |
| General | `remove` | exact | yes: flare_stepper.dart:88, FormControls.swift:162, FormControls.kt:188 | Use `remove` |
| General | `edit` | exact | yes: flare_quick_phrases.dart:121, QuickPhrasesView.swift:37, QuickPhrases.kt:75 | Use `edit` |
| General | `refresh` | exact | yes: flare_storage_usage.dart:305, StorageUsageView.swift:270, StorageUsage.kt:262 | Use `refresh` |
| General | `filter` | - | no: no filter glyph | Not added |
| General | `sort` | - | no: no sort glyph | Not added |
| General | `check` | exact | yes: flare_select.dart:253, FormViews.swift:422, FormComponents.kt:355 | Use `check` |
| General | `chevronDown` | as `chevron-down` | yes: flare_select.dart:130, FormViews.swift:359, FormComponents.kt:324 | Use `chevron-down` |
| General | `chevronRight` | as `chevron-right` | yes: flare_settings_list.dart:198, ProfileViews.swift:288, SettingsList.kt:142 | Use `chevron-right` |
| General | `expand` | - (`chevron-up` also absent) | yes: flare_conversation_batch_toolbar.dart:404, ConversationBatchToolbarView.swift:237, ConversationBatchToolbar.kt:288; flare_member_role_sheet.dart:551, MemberRoleSheetView.swift:341, MemberRoleSheet.kt:399 | ADD `chevron-up` for disclosure; `expand` for resize |
| General | `collapse` | - | yes: same sites (expand_less / chevron.up / ExpandLess) | Use `chevron-down` for disclosure; `collapse` for resize |
| General | `externalLink` | - | no: no open-in-browser control | Not added |
| General | `share` | exact | yes: flare_group_detail.dart:277, FlareGroupDetailView.swift:650, GroupPermissionMatrix.kt:142 | Use `share` |

## Names added in Round 5 Batch 1

Added on all four kits in one change, each with a real consumer (99 names in total, identical order, checked by `tooling/check-icon-registry.mjs`):

| Area | Names |
|---|---|
| Messages | `recall`, `unpin`, `merge-forward`, `multi-select`, `quote`, `reaction`, `translate`, `mention`, `read`, `mark`, `rich-text`, `attachment` |
| Conversations | `mark-unread`, `archive`, `unarchive`, `clear-history` |
| Calls | `mic-off`, `camera-off`, `speaker`, `speaker-off`, `end-call`, `switch-camera`, `screen-share` |
| Media | `play`, `pause`, `expand`, `collapse`, `zoom-in`, `zoom-out`, `rotate` |
| Members and groups | `group`, `admin`, `remove-member`, `transfer-owner`, `silence`, `report` |
| General | `chevron-up`, `chevron-left`, `keyboard`, `mini-app` |

`mark` (flag a message) was drawn by every message menu with a borrowed flag glyph and joined the list during implementation. `clear-history` and `switch-camera` are not in the concept list above; the row menu draws clear history with the delete glyph, and all three native call controls draw a camera flip.

Removed from the registry: `heart-filled` and `bookmark` (no consumer on any kit or app).

## The fifteen nominations, decided in Round 9

Date: 2026-09-18. The Batch 5 migrations left fifteen concepts drawn under the nearest existing name, each listed with the name a kit proposed for it. They were decided as one set, on four kits in one change, by one rule:

> A concept gets its own name when it is drawn today under a name that means something else, and a real screen draws it. When an existing name already means the concept, or only a preview or a decoration draws it, it gets no name.

### Accepted: six names

Appended after `mini-app`, in this order, on all four kits (105 names; `tooling/check-icon-registry.mjs`). Each glyph is drawn by no other name on its kit, and the registry tests of the four kits assert it differs from the name the concept borrowed before.

| Name | Concept | Drawn before | Why the borrowed name was wrong | Draws it now | Web / Flutter / iOS / Compose |
|---|---|---|---|---|---|
| `pin-self` | Pin a message for myself only | `pin` | The message menu offers pin and pin-for-me side by side: two actions, one glyph, in one sheet (the reason `unpin` was named in Round 5) | four kit message menus; Vue batch toolbar | `Bookmark` / `bookmark_border` / `bookmark` / `Outlined.BookmarkBorder` |
| `diagnostics` | Developer diagnostics page | `info` (iOS and Android apps), `mini-app` (Flutter app) | `info` is an explanation, `mini-app` a mini program | 联调诊断 rows (iOS, Android apps); SDK 能力 row (Flutter app) | `Bug` / `bug_report_outlined` / `ladybug` / `Outlined.BugReport` |
| `card` | Send a contact card | `person` | `person` is a person or a profile; the tile sends a card message | four kit composer attach panels; iOS and Android app attach actions | `Contact` / `contact_page_outlined` / `person.crop.rectangle` / `Outlined.ContactPage` |
| `id` | A public account id (Flare ID row) | `info` (Vue, Flutter), `tag` (iOS), nothing (Compose) | Three different borrowed glyphs for one row; `tag` is a label, `info` an explanation | four kit contact details | `Hash` / `tag` / `number` / `Outlined.Tag` |
| `join-request` | Requests to join a group | `person` (Vue), `person-add` (Flutter), `notification` (iOS), nothing (Compose) | Four answers for one row; `person-add` is adding someone yourself, `notification` is notification settings | four kit group details; SwiftUI empty request list | `Inbox` / `move_to_inbox_outlined` / `tray.and.arrow.down` / `Outlined.MoveToInbox` |
| `storage` | The device's local storage | `folder` | `folder` is a folder of files; the prompt and the rows are about storage on this device | four kit permission prompts (storage kind); web 存储空间 row; Flutter app 缓存与同步 row | `HardDrive` / `storage_outlined` / `internaldrive` / `Outlined.Storage` |

The glyph `bookmark` drew the removed `bookmark` name in Round 5. The name stays removed: it named a shape, and `pin-self` names the action.

### Rejected: nine names

| Nominated | Concept | Keeps | Why |
|---|---|---|---|
| `group-add` | Add someone to a group | `person-add` | `person-add` already means adding a person, and nothing else is drawn under it; the group screen says where the person goes. |
| `person-off` | A blocked person | `block` | Round 5 narrowed `block` to blocking people; the blocklist is that concept. |
| `bio` | The 描述 row of a contact | `comment` | The row is the note the reader writes about a contact, not the contact's own signature. Vue and Flutter drew it with `comment`; iOS drew `info` and Compose nothing, and both now match. |
| `bot` | A bot | nothing | Only the SwiftUI preview catalogue draws it (a filter tab); no kit component or app has bots. |
| `transport` | Connection kind | nothing | Drawn only as a section decoration on the Flutter app's diagnostics page. The iOS and Android diagnostics pages draw text rows without section icons; the five Flutter section icons were removed to match. |
| `server` | A server | nothing | Same page, same decoration, same removal. |
| `search-off` | No search results | `search` | The kits' own empty result state draws `search` with a no-results title (Vue `FlareSearchResults`); the title carries the "none". |
| `summary` | A digest | nothing | Nothing draws a digest today; the Flutter moments site no longer exists. |
| `mail` | An invitation | nothing | Nothing draws an invitation; new friends use `person-add` in every kit and app. |

### Drift fixed on the way

Checking every consumer of the six names found rows that drew different borrowed glyphs per kit, and two app actions that the Round 5 migration missed:

- The same rows on every kit now draw the same names: contact details `id`, `edit` (remark), `comment` (description), `star`; group details `tag` (name), `announcement`, `people`, `edit` (my nickname), `mute`, `pin`, `lock` (join mode), `join-request`, `silence`, `link`, `mention`, `share`. Compose drew no icons on these rows; SwiftUI drew `person` for my nickname and `person-add` for join mode.
- The web and Tauri apps drew report entries (the message menu 举报 action, 我的举报 rows) with `warning`; they now draw `report`, as the native apps do.
- The Android app's attach 名片 action still drew `person`; the Flutter app's SDK 能力 row drew `mini-app`.

Not nominated on purpose: emoji categories (`EmojiCategory.symbol`) and sticker-pack covers keep platform glyphs or emoji characters — they are content, not interface, and the registry has no "smileys / animals / food / travel / symbols" concepts.

