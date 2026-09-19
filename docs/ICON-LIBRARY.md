# Flare 图标库使用说明

一套**跨端语义化图标**：业务只写语义名（如 `send`、`recall`、`end-call`），各端把同名映射到自己的原生字形源。风格统一为细线。

| 端 | 视图 | 包 | 字形源 |
|---|---|---|---|
| Vue（Web / Tauri） | `FlareIcon`、组件的 `icon` 属性（`FlareGlyph`） | `@flare-im/vue-ui` | Lucide（经 kit 内部 shim） |
| Flutter | `FlareIcon` | `flare_im_ui` | Material Icons（Outlined） |
| iOS（SwiftUI） | `IconView` | `FlareIMUI` | SF Symbols（iOS 16 可用） |
| Android（Compose） | `FlareIcon` | `com.flare.im:im-ui-compose` | Material Icons（Outlined，方向性字形用 AutoMirrored） |

> 为什么不用一套 SVG 打全端：各端原生字形有最好的清晰度、动态字重与无障碍支持，体积也更小。语义名是唯一稳定契约，底层字形可以各自演进。规则见 `design/icon-guidelines.md`，现状审计见 `design/icon-inventory.md` 与 `design/icon-coverage.md`。

---

## 一、语义名（105 个，四端一致）

```
通用      search send more back close check add remove edit delete
社交      heart comment chats moments share camera image location mic phone video
人与设置  settings person people person-add star download link emoji file folder
          notification mute copy forward reply refresh chevron-down chevron-right arrow-down
状态      warning info success error calendar clock eye eye-off lock qr
设置页    block tag announcement theme language devices logout pin poll
消息操作  recall unpin merge-forward multi-select quote reaction translate mention read mark
输入      rich-text attachment
会话      mark-unread archive unarchive clear-history
通话      mic-off camera-off speaker speaker-off end-call switch-camera screen-share
媒体      play pause expand collapse zoom-in zoom-out rotate
成员与群  group admin remove-member transfer-owner silence report
通用补充  chevron-up chevron-left keyboard mini-app
概念补充  pin-self diagnostics card id join-request storage
```

- 这份清单是跨端契约：四端的 `flareIconNames`（Vue 为 `flareIcons` 的键）**名字、数量、顺序**完全一致，每个名字在每端都有字形。`npm run check` 的 `icon registry parity` 一项（`node tooling/check-icon-registry.mjs`）检查这一点，改动必须四端同一次提交。
- 名字按含义命名，不按长相命名。容易混用的几组：

| 名字 | 含义 | 不要用于 |
|---|---|---|
| `mute` | 会话免打扰 | 成员禁言（`silence`）、关闭声音输出（`speaker-off`）、关麦（`mic-off`） |
| `silence` | 群成员禁言、全员禁言 | 会话免打扰 |
| `delete` | 删除一条消息或会话 | 清空聊天记录（`clear-history`）、移出成员（`remove-member`） |
| `recall` | 撤回消息 | 重试、刷新（`refresh`） |
| `forward` / `merge-forward` | 逐条转发 / 合并转发 | 分享到外部（`share`） |
| `read` / `mark-unread` | 标为已读 / 标为未读 | 已读回执状态以外的装饰 |
| `back` / `chevron-left` | 导航返回 / 上一页、向左展开 | 互换 |
| `chevron-up` / `chevron-down` | 展开或收起一段内容 | 调整窗口或输入框大小（`expand` / `collapse`） |
| `group` / `people` | 群聊 / 联系人、成员 | 互换 |
| `comment` / `chats` | 单条评论 / 会话列表或消息 tab | 互换 |
| `clock` | 时间范围、历史区间 | 日程卡片（`calendar`） |
| `group` | 群聊、创建群聊 | 联系人与成员（`people`） |
| `info` | 说明 | 警告（`warning`）、开发诊断页（`diagnostics`） |
| `pin` / `unpin` | 置顶 / 取消置顶 | 同一个字形表示两个动作 |
| `pin` / `pin-self` | 为所有人置顶 / 只为自己置顶 | 互换（两者在同一个消息菜单里并列） |
| `person` / `card` | 人、个人资料 / 发送名片 | 互换 |
| `tag` / `id` | 标签、群名 / 公开账号 ID | 互换 |
| `person-add` / `join-request` | 自己添加一个人 / 别人申请入群 | 互换 |
| `folder` / `storage` | 文件夹 / 本机存储 | 互换 |

---

## 二、各端用法

### Vue（Web / Tauri）

```vue
<script setup lang="ts">
import { FlareIcon } from "@flare-im/vue-ui";
</script>
<template>
  <FlareIcon name="send" :size="22" />
  <FlareIcon name="recall" :size="20" />
</template>
```

- `name` 的类型是 `FlareIconName`，拼错会被 TS 拦下；`size` 默认 20，颜色继承 `currentColor`。
- `flareIconNames`（`@flare-im/vue-ui/components`）可遍历全集，登记在 `spec/public-api-exceptions.json#companionExports`。

**组件的 `icon?: string` 属性走 `FlareGlyph`**：`FlareEmptyState`、设置行、`FlareProfilePanel` 行、应用壳导航项等接受开放 `icon` 字符串的组件内部用 `<FlareGlyph :icon="...">` 渲染。传语义名出线性图标；传 emoji 或单个字符时按文字渲染并对读屏隐藏；传不认识的英文词时什么都不画，开发模式下在控制台警告（原来会把单词当文字画出来）。

```vue
<FlareEmptyState icon="chats" title="暂无会话" />
<!-- settings item -->
{ key: "theme", label: "深色模式", icon: "theme", kind: "toggle" }
```

应用代码不导入任何字形库，也不导入 kit 的 `@flare-im/vue-ui/icon-glyphs`：参考应用门禁 `examples/apps/scripts/check-kit-reference.mjs` 的 `vendorGlyphImport` 计数，web 与 Tauri 基线为 0。

### Flutter

```dart
import 'package:flare_im_ui/flare_im_ui.dart';

FlareIcon('send', size: 22);
FlareIcon('recall', size: 20, color: Colors.grey);
```

未知名兜底 `Icons.help_outline`（可见而非空白）。

**组件的 `icon` 参数收语义名**（Round 5 起，不再收 `IconData`）：`FlareSettingsItem`、`FlareNavigationItem`、`FlareMessageMenuEntry`、`FlareComposerAction`、`FlareComposerIconButton`、`FlareButton`、`FlareIconButton`、`FlareEmptyState`、`FlareWorkspacePaneView(emptyIcon)`、`FlareMessageActionExtension`。未知名画兜底字形，并在 debug 构建里按名字去重告警一次（release 静默）——`IconData` 写进语义名参数不会编译报错，只会在产品里静默变问号。

### iOS（SwiftUI）

```swift
import FlareIMUI

IconView("send", size: 22)
IconView("recall", size: 20, color: .secondary)
```

未知名兜底 `questionmark`。

**组件的 `icon` 参数收语义名**（Round 5 起，不再收 SF Symbol 名）：`FlareSettingsItem`、`FlareFilterTabOption`、`FlareComposerAction`、`FlareMessageMenuEntry`、`FlareApplicationNavigationItem`、`IconButtonView`、`ButtonView`、`EmptyStateView`、`WorkspacePaneView(emptyIcon)`。未知名画注册表兜底字形，并在 DEBUG 下按名字去重告警一次——SF Symbol 名写进语义名参数不会编译报错，只会在产品里静默变问号。选中态的实心变体由导航条自己决定，宿主只传名字。

### Android（Compose）

```kotlin
import com.flare.im.ui.FlareIcon

FlareIcon(name = "send", size = 22.dp)
FlareIcon(name = "recall", tint = MaterialTheme.colorScheme.onSurfaceVariant)
```

未知名兜底 `Icons.AutoMirrored.Outlined.HelpOutline`，并按名字去重告警一次。

**组件的 `icon` 参数收语义名**（Round 5 起，不再收 `ImageVector`）：`FlareApplicationNavigationItem`、`FlareComposerAction`、`SettingsItem`、`FlareMessageMenuEntry`、`EmptyState`、`WorkspacePane(emptyIcon)`、`Button`、`IconButton`。唯一的字形出口是 `UnknownUserPlaceholder.unknownUserIcon`（没有对应语义名的占位图）。

### 纯图标控件

每个只有图标的控件都要有说明动作的无障碍名称（“关闭预览”“挂断”“删除选项”），用产品语言，图标本身对读屏隐藏；触控目标 iOS 至少 44pt、Android 至少 48dp。四端 kit 自带的纯图标控件都已命名，测试分别在 Flutter `test/icon_only_controls_semantics_test.dart`、iOS `IconOnlyControlAccessibilityTests`、Compose `IconControlAccessibilityTest` 与 Vue 各组件测试里。

---

## 三、会话头部动作的别名

会话头部（`ConversationHeader`）的动作 id 与图标名不同名时，iOS 与 Compose 用一张别名表解析：

| 动作 id | 图标名 |
|---|---|
| `audioCall` | `phone` |
| `videoCall` | `video` |
| `addMember` | `person-add` |
| `details` | `info` |

别名表之外的未知 id 画各端的兜底字形，不会画成 `more`。Vue 的头部动作直接带图标名。

---

## 四、Web 字形源：Lucide 与 kit 内部 shim

kit 组件从中央 shim 取字形：

```
packages/vue-im-ui/src/shared/icon-glyphs.ts   （由 scripts/gen-icon-shim.mjs 生成，150 个导出）
```

- 导出名沿用 ionicons 风格（`SendOutline`），每个导出渲染一个 Lucide 字形：`size: "1em"`（让 naive `<n-icon>` 用 `font-size` 控制大小）、`stroke-width: 1.75`；heart、star、success、error、info 的填充变体加 `fill: "currentColor"`。
- 改映射或加字形：编辑 `scripts/gen-icon-shim.mjs` 的 MAP，再运行 `npm run gen:icons`（在 `packages/vue-im-ui`）。
- 语义层 `shared/icons.ts` 的 `flareIcons` 从 shim 取字形；组件优先用语义名（`flareIcons.recall`），只有没有跨端含义的字形（如富文本格式按钮）才直接用 shim 导出。
- shim 是 kit 的实现接缝，不是应用 API（见第二节门禁）。

---

## 五、四端映射表

由 `node tooling/check-icon-registry.mjs --table` 生成，改注册表后重新生成本节。

| Name | Web (Lucide) | Flutter (Icons.) | iOS (SF Symbol) | Compose (Icons.) |
|---|---|---|---|---|
| `search` | `Search` | `search` | `magnifyingglass` | `Outlined.Search` |
| `send` | `Send` | `send_outlined` | `paperplane` | `AutoMirrored.Outlined.Send` |
| `more` | `Ellipsis` | `more_horiz` | `ellipsis` | `Outlined.MoreHoriz` |
| `back` | `ArrowLeft` | `arrow_back` | `chevron.left` | `AutoMirrored.Outlined.ArrowBack` |
| `close` | `X` | `close` | `xmark` | `Outlined.Close` |
| `check` | `Check` | `check` | `checkmark` | `Outlined.Check` |
| `add` | `Plus` | `add` | `plus` | `Outlined.Add` |
| `remove` | `Minus` | `remove` | `minus` | `Outlined.Remove` |
| `edit` | `Pencil` | `edit_outlined` | `pencil` | `Outlined.Edit` |
| `delete` | `Trash` | `delete_outline` | `trash` | `Outlined.Delete` |
| `heart` | `Heart` | `favorite_border` | `heart` | `Outlined.FavoriteBorder` |
| `comment` | `MessageCircle` | `chat_bubble_outline` | `bubble.left` | `Outlined.ChatBubbleOutline` |
| `chats` | `MessagesSquare` | `forum_outlined` | `bubble.left.and.bubble.right` | `Outlined.Forum` |
| `moments` | `Compass` | `explore_outlined` | `safari` | `Outlined.Explore` |
| `share` | `Share2` | `share_outlined` | `square.and.arrow.up` | `Outlined.Share` |
| `camera` | `Camera` | `photo_camera_outlined` | `camera` | `Outlined.PhotoCamera` |
| `image` | `Image` | `image_outlined` | `photo` | `Outlined.Image` |
| `location` | `MapPin` | `location_on_outlined` | `mappin.and.ellipse` | `Outlined.LocationOn` |
| `mic` | `Mic` | `mic_none_outlined` | `mic` | `Outlined.Mic` |
| `phone` | `Phone` | `phone_outlined` | `phone` | `Outlined.Call` |
| `video` | `Video` | `videocam_outlined` | `video` | `Outlined.Videocam` |
| `settings` | `Settings` | `settings_outlined` | `gearshape` | `Outlined.Settings` |
| `person` | `User` | `person_outline` | `person` | `Outlined.Person` |
| `people` | `Users` | `people_outline` | `person.2` | `Outlined.People` |
| `person-add` | `UserPlus` | `person_add_alt_1_outlined` | `person.badge.plus` | `Outlined.PersonAddAlt` |
| `star` | `Star` | `star_border` | `star` | `Outlined.StarBorder` |
| `download` | `Download` | `download_outlined` | `arrow.down.circle` | `Outlined.Download` |
| `link` | `Link` | `link` | `link` | `Outlined.Link` |
| `emoji` | `FaceSlightlySmiling` | `emoji_emotions_outlined` | `face.smiling` | `Outlined.EmojiEmotions` |
| `file` | `File` | `insert_drive_file_outlined` | `doc` | `Outlined.Description` |
| `folder` | `Folder` | `folder_outlined` | `folder` | `Outlined.Folder` |
| `notification` | `Bell` | `notifications_outlined` | `bell` | `Outlined.Notifications` |
| `mute` | `BellOff` | `notifications_off_outlined` | `bell.slash` | `Outlined.NotificationsOff` |
| `copy` | `Copy` | `copy_outlined` | `doc.on.doc` | `Outlined.ContentCopy` |
| `forward` | `Forward` | `forward` | `arrowshape.turn.up.right` | `AutoMirrored.Outlined.Forward` |
| `reply` | `Reply` | `reply` | `arrowshape.turn.up.left` | `AutoMirrored.Outlined.Reply` |
| `refresh` | `RefreshCw` | `refresh` | `arrow.clockwise` | `Outlined.Refresh` |
| `chevron-down` | `ChevronDown` | `keyboard_arrow_down` | `chevron.down` | `Outlined.ExpandMore` |
| `chevron-right` | `ChevronRight` | `chevron_right` | `chevron.right` | `Outlined.ChevronRight` |
| `arrow-down` | `ArrowDown` | `arrow_downward` | `arrow.down` | `Outlined.ArrowDownward` |
| `warning` | `TriangleAlert` | `warning_amber_outlined` | `exclamationmark.triangle` | `Outlined.WarningAmber` |
| `info` | `Info` | `info_outline` | `info.circle` | `Outlined.Info` |
| `success` | `CircleCheck` | `check_circle_outline` | `checkmark.circle` | `Outlined.CheckCircle` |
| `error` | `CircleAlert` | `error_outline` | `exclamationmark.circle` | `Outlined.ErrorOutline` |
| `calendar` | `Calendar` | `calendar_today_outlined` | `calendar` | `Outlined.CalendarToday` |
| `clock` | `Clock` | `access_time` | `clock` | `Outlined.Schedule` |
| `eye` | `Eye` | `visibility_outlined` | `eye` | `Outlined.Visibility` |
| `eye-off` | `EyeOff` | `visibility_off_outlined` | `eye.slash` | `Outlined.VisibilityOff` |
| `lock` | `Lock` | `lock_outline` | `lock` | `Outlined.Lock` |
| `qr` | `QrCode` | `qr_code` | `qrcode` | `Outlined.QrCode` |
| `block` | `Ban` | `block` | `nosign` | `Outlined.Block` |
| `tag` | `Tag` | `label_outline` | `tag` | `AutoMirrored.Outlined.Label` |
| `announcement` | `Megaphone` | `campaign_outlined` | `megaphone` | `Outlined.Campaign` |
| `theme` | `Moon` | `dark_mode_outlined` | `moon` | `Outlined.DarkMode` |
| `language` | `Globe` | `language` | `globe` | `Outlined.Language` |
| `devices` | `MonitorSmartphone` | `devices_outlined` | `laptopcomputer.and.iphone` | `Outlined.Devices` |
| `logout` | `LogOut` | `logout` | `rectangle.portrait.and.arrow.right` | `AutoMirrored.Outlined.Logout` |
| `pin` | `Pin` | `push_pin_outlined` | `pin` | `Outlined.PushPin` |
| `poll` | `ChartColumn` | `poll_outlined` | `chart.bar` | `Outlined.Poll` |
| `recall` | `Undo2` | `undo_outlined` | `arrow.uturn.backward` | `AutoMirrored.Outlined.Undo` |
| `unpin` | `PinOff` | `push_pin` | `pin.slash` | `Filled.PushPin` |
| `merge-forward` | `Merge` | `merge_outlined` | `arrow.triangle.merge` | `Outlined.Merge` |
| `multi-select` | `ListChecks` | `checklist_outlined` | `checklist` | `Outlined.Checklist` |
| `quote` | `Quote` | `format_quote_outlined` | `quote.opening` | `Outlined.FormatQuote` |
| `reaction` | `FaceSlightlySmilingPlus` | `add_reaction_outlined` | `face.smiling` | `Outlined.AddReaction` |
| `translate` | `Languages` | `translate_outlined` | `character.bubble` | `Outlined.Translate` |
| `mention` | `AtSign` | `alternate_email_outlined` | `at` | `Outlined.AlternateEmail` |
| `read` | `CheckCheck` | `done_all_outlined` | `envelope.open` | `Outlined.DoneAll` |
| `mark` | `Flag` | `flag_outlined` | `flag` | `Outlined.Flag` |
| `rich-text` | `Type` | `text_format_outlined` | `textformat` | `Outlined.TextFormat` |
| `attachment` | `Paperclip` | `attach_file_outlined` | `paperclip` | `Outlined.AttachFile` |
| `mark-unread` | `MessageSquareDot` | `mark_chat_unread_outlined` | `message.badge` | `Outlined.MarkChatUnread` |
| `archive` | `Archive` | `archive_outlined` | `archivebox` | `Outlined.Archive` |
| `unarchive` | `ArchiveRestore` | `unarchive_outlined` | `tray.and.arrow.up` | `Outlined.Unarchive` |
| `clear-history` | `Eraser` | `delete_sweep_outlined` | `eraser` | `Outlined.DeleteSweep` |
| `mic-off` | `MicOff` | `mic_off_outlined` | `mic.slash` | `Outlined.MicOff` |
| `camera-off` | `VideoOff` | `videocam_off_outlined` | `video.slash` | `Outlined.VideocamOff` |
| `speaker` | `Volume2` | `volume_up_outlined` | `speaker.wave.2` | `AutoMirrored.Outlined.VolumeUp` |
| `speaker-off` | `VolumeX` | `volume_off_outlined` | `speaker.slash` | `AutoMirrored.Outlined.VolumeOff` |
| `end-call` | `PhoneOff` | `call_end_outlined` | `phone.down` | `Outlined.CallEnd` |
| `switch-camera` | `SwitchCamera` | `cameraswitch_outlined` | `arrow.triangle.2.circlepath.camera` | `Outlined.Cameraswitch` |
| `screen-share` | `ScreenShare` | `screen_share_outlined` | `rectangle.on.rectangle` | `AutoMirrored.Outlined.ScreenShare` |
| `play` | `Play` | `play_arrow_outlined` | `play` | `Outlined.PlayArrow` |
| `pause` | `Pause` | `pause_outlined` | `pause` | `Outlined.Pause` |
| `expand` | `Expand` | `open_in_full_outlined` | `arrow.up.left.and.arrow.down.right` | `Outlined.OpenInFull` |
| `collapse` | `Shrink` | `close_fullscreen_outlined` | `arrow.down.right.and.arrow.up.left` | `Outlined.CloseFullscreen` |
| `zoom-in` | `ZoomIn` | `zoom_in_outlined` | `plus.magnifyingglass` | `Outlined.ZoomIn` |
| `zoom-out` | `ZoomOut` | `zoom_out_outlined` | `minus.magnifyingglass` | `Outlined.ZoomOut` |
| `rotate` | `RotateCw` | `rotate_right_outlined` | `rotate.right` | `AutoMirrored.Outlined.RotateRight` |
| `group` | `UsersRound` | `groups_outlined` | `person.3` | `Outlined.Groups` |
| `admin` | `ShieldCheck` | `admin_panel_settings_outlined` | `checkmark.shield` | `Outlined.AdminPanelSettings` |
| `remove-member` | `UserMinus` | `person_remove_outlined` | `person.badge.minus` | `Outlined.PersonRemove` |
| `transfer-owner` | `KeyRound` | `key_outlined` | `key` | `Outlined.Key` |
| `silence` | `MessageSquareOff` | `comments_disabled_outlined` | `waveform.slash` | `Outlined.CommentsDisabled` |
| `report` | `OctagonAlert` | `report_outlined` | `exclamationmark.octagon` | `Outlined.Report` |
| `chevron-up` | `ChevronUp` | `expand_less_outlined` | `chevron.up` | `Outlined.ExpandLess` |
| `chevron-left` | `ChevronLeft` | `chevron_left_outlined` | `chevron.left` | `Outlined.ChevronLeft` |
| `keyboard` | `Keyboard` | `keyboard_outlined` | `keyboard` | `Outlined.Keyboard` |
| `mini-app` | `LayoutGrid` | `apps_outlined` | `square.grid.2x2` | `Outlined.Apps` |
| `pin-self` | `Bookmark` | `bookmark_border` | `bookmark` | `Outlined.BookmarkBorder` |
| `diagnostics` | `Bug` | `bug_report_outlined` | `ladybug` | `Outlined.BugReport` |
| `card` | `Contact` | `contact_page_outlined` | `person.crop.rectangle` | `Outlined.ContactPage` |
| `id` | `Hash` | `tag` | `number` | `Outlined.Tag` |
| `join-request` | `Inbox` | `move_to_inbox_outlined` | `tray.and.arrow.down` | `Outlined.MoveToInbox` |
| `storage` | `HardDrive` | `storage_outlined` | `internaldrive` | `Outlined.Storage` |

### 已接受的平台差异

概念一致、像素可以不同。下面这些差异是有意的，其余差异按映射缺陷处理：

- iOS `back` 与 `chevron-left` 都是 `chevron.left`（iOS 导航习惯）。
- iOS `read` 用 `envelope.open`：SF Symbols 没有双对勾。
- iOS `translate` 用 `character.bubble`：`translate` 符号要 iOS 17.4，kit 下限是 iOS 16。
- iOS `silence` 用 `waveform.slash`，`screen-share` 用 `rectangle.on.rectangle`：iOS 16 没有带斜线的对话气泡与屏幕共享符号。
- iOS `reaction` 与 `emoji` 同为 `face.smiling`：没有带加号的笑脸符号，两者不会出现在同一个界面里。
- Flutter 与 Compose 的 `unpin` 是实心图钉（Material 用实心表示已置顶状态）。
- Compose 的方向性字形（`send`、`back`、`recall`、`speaker`、`rotate` 等）用 AutoMirrored 版本，RTL 下自动镜像；material-icons 1.7.6 已弃用对应的非镜像版本。

---

## 五b、两道棘轮（Round 5 新增）

- **kit 内部**：`node tooling/check-icon-registry.mjs` 除了校验四端名字与字形，还统计每个 kit 里**绕过注册表直接引用底层字形**的处数（基线 `tooling/icon-bypass-baseline.json`）。数字只能往下走，涨了就红。迁移完一批后用 `--baseline` 重新锁定。Round 5 收口值：vue 149、flutter **176**（原 221）、ios **76**（原 116）、compose **170**（原 182）。剩下的都是 kit 自己画的内部字形（规则 7 允许保留），公开入参里已经没有平台字形。
- **应用内部**：`examples/apps/scripts/check-kit-reference.mjs` 统计三个原生应用里直接写平台字形的处数（`platformGlyph`）。Round 5 收口值：flutter **0**（原 60）、ios **0**（原 48）、android **0**（原 32）；Vue 两个应用的 `vendorGlyphImport` 一直是 0。**五个参考应用现在没有一处直接写平台字形**，全部经由 kit 的语义名。

## 六、新增一个语义名

1. 找到消费方：某个 kit 组件或应用界面今天就在画这个概念（file:line），而且画它用的是一个意思不同的名字。没有消费方、或者已有名字就能表达的，不加（Round 9 的裁决规则与 15 个候选名的结论见 `design/icon-coverage.md`）。
2. 按含义取 kebab-case 名，四端各选一个概念相同的字形（Lucide 名对照 `node_modules/@lucide/vue` 的导出核对；SF Symbol 核对 iOS 16 可用；Material 核对 material-icons 1.7.6 未弃用）。
3. 四端同一次提交：
   - Vue：`packages/vue-im-ui/src/shared/icons.ts` 的 `flareIcons` 追加一项；shim 没有的字形先在 `scripts/gen-icon-shim.mjs` 的 MAP 加一条并重新生成。
   - Flutter：`packages/flutter-im-ui/lib/src/components/flare_icon.dart` 的 `flareIconNames` 与 `flareIconMap`。
   - iOS：`packages/ios-im-ui/Sources/FlareIMUI/Components/IconLibrary.swift` 的 `flareIconNames` 与 `flareIconMap`。
   - Compose：`packages/android-im-ui/src/main/kotlin/com/flare/im/ui/IconLibrary.kt` 的 import、`flareIconMap` 与 `flareIconNames`。
4. 名字追加在四端清单的同一位置，然后运行 `node tooling/check-icon-registry.mjs`，并重新生成第五节的映射表。
5. 各端注册表测试：Vue `src/shared/icons.test.ts`、Flutter `test/icon_registry_test.dart`、iOS `IconRegistryTests`、Compose `IconLibraryTest`（数量与新名字的字形）。

---

## 七、坑与注意

- **Lucide 改名频繁**：如 `PlusCircle→CirclePlus`、`AlertCircle→CircleAlert`、`MoreHorizontal→Ellipsis`、`SmilePlus` 在 1.x 叫 `FaceSlightlySmilingPlus`。加映射时对着实际导出集验名（`node_modules/@lucide/vue/dist/*.d.ts` 的 `declare const`），当前锁定 `@lucide/vue@1.44.0`。
- **1em 尺寸**：shim 组件必须以 `size: "1em"` 渲染，`<n-icon>` 才能用 `font-size` 控制大小；直接用 Lucide 组件会固定 24px。
- **SF Symbol 名在运行时解析**：iOS 端名字写错不会编译报错，只会渲染 `questionmark`。`IconRegistryTests` 检查每个符号在 CoreGlyphs 里存在。
- **Android 需要 material-icons-extended**：注册表 105 个字形里 85 个来自扩展包，`build.gradle.kts` 已含该依赖。
- **SwiftUI 命中区**：按钮外层的 background、overlay、负 padding、contentShape 或外部 frame 都不会扩大可点区域，只有 label 自身的最小 frame 有效。kit 用 `flareTouchTarget` 扩到 44pt，`TouchTargetHitTests` 用真实点击锁定。

---

## 八、底部导航图标（相关）

`FlareMobileAppShell` / `FlareDesktopAppShell` 的 `navigation` 由 `FlareAdaptiveNavigation` 渲染，每个 item 的 `icon` 传语义名。导航按分组传入（`FlareNavigationGroup[]`），点击发出 `navigate(id)`。例：

```ts
import type { FlareNavigationGroup } from "@flare-im/vue-ui/contracts";

const navigation: FlareNavigationGroup[] = [
  {
    id: "main",
    items: [
      { id: "chats",    label: "消息",   icon: "chats" },
      { id: "contacts", label: "通讯录", icon: "people" },
      { id: "moments",  label: "圈子",   icon: "moments" },
      { id: "me",       label: "我",     icon: "person" },
    ],
  },
];
```

手机端进入会话可给 `FlareMobileAppShell` 传 `:hide-navigation="true"` 隐藏底部导航，让聊天占满全高。

> 2.0 之前这里写的是 `FlareAppShell` 的 `navItems` 与 `hide-bottom-nav`；该组件已拆为上面两个 shell，迁移见 `docs/release/migration/2.0-rc-to-2.0.md`。

---

## 参考

- 在线画廊（全部 105 个图标）：文档站 `Components → Icon`。
- 注册表对齐门禁与映射表：`tooling/check-icon-registry.mjs`（`--table`）。
- 规则：`docs/design/icon-guidelines.md`；审计与决策：`docs/design/icon-inventory.md`、`docs/design/icon-coverage.md`。
