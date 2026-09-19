# Icon Inventory

Date: 2026-09-15 (Round 5). Scope: the semantic icon registry of the four kits (Vue, Flutter, SwiftUI, Compose), every place the kits and the five flare-social reference apps draw an icon, and the decision for each name.

Method: read-only audits of the kit sources and app sources with file:line evidence and commands for every count (kept with the Round 5 audit record). Related: `icon-coverage.md` (IM concepts against the registry), `icon-guidelines.md` (rules), `../ICON-LIBRARY.md` (how to use the registry on each platform).

## 1. Summary

| Measure | Vue | Flutter | SwiftUI | Compose |
|---|---:|---:|---:|---:|
| Semantic names in the registry | 61 | 61 | 61 | 61 |
| Icon sites that go through the registry | 25 of 259 elements | 7 | 14 | 11 |
| Glyph references that bypass the registry | 237 shim imports in 73 files (160 of them have a semantic name) | 335 in 81 files | 322 in 62 files | 309 in 67 files |
| Distinct raw glyphs drawn | 114 (through the shim) | 157 | 129 | 151 |
| Icon size tokens available | 16 / 20 / 24 / 32 | same | same | same |
| Icon sizes written as literals | 16 prop values + 13 CSS values | 129 sites, 19 sizes | 130 sites, 18 sizes | 134 sites, 17 sizes |
| Icon-only controls without an accessible name | 1 (fixed in Round 5) | 27 | 29 | 8, plus 3 with a click label only |
| Unicode characters used as control icons | 9 (kit) | 1 | 2 | 3 |

Apps: web 40 icon sites (1 invalid name, 2 Unicode); Tauri 76 (18 vendor glyph components from 6 files, 2 Unicode); Flutter app 46 direct Material glyphs; iOS app 51 SF Symbol literals and 5 semantic names; Android app 34 direct Material glyphs and 1 Unicode arrow. No native app uses the kit's semantic icon view.

Root causes:

- **Kit components bypass their own registry.** Components import glyphs directly, so the registry covers a minority of what is drawn.
- **Public APIs take platform glyph types.** Flutter `IconData`, SwiftUI SF Symbol strings, Compose `ImageVector` and Vue glyph components are the parameter types, which pushes apps onto Material and SF Symbols directly.
- **The Vue shim is a public entry.** `@flare-im/vue-ui/icon-glyphs` exposes Ionicons-style glyph names; Tauri imports 16 of them and the app gate allows it.
- **No native gate.** Only Vue has a package-boundary rule, and it treats shim imports as compliant.

## 2. The registry

One row per semantic name. Web shows the Ionicons-style shim export and the Lucide glyph it resolves to. Kit uses and app uses are Vue measurements (semantic uses / files importing the same glyph directly / web and Tauri sites). Decision: KEEP, REMAP (the name stays, the glyph changes on the platforms named), NARROW (the name keeps one meaning; other meanings move to the names given), REMOVE.

| # | Name | Category | Web | iOS | Flutter | Compose | Vue kit uses / bypass files / apps W-T | Decision |
|---|---|---|---|---|---|---|---|---|
| 1 | `search` | navigation | `SearchOutline` -> `Search` | `magnifyingglass` | `search` | `Outlined.Search` | 5 / 2 / 4-4 | KEEP |
| 2 | `send` | message | `SendOutline` -> `Send` | `paperplane` | `send` | `AutoMirrored.Outlined.Send` | 0 / 2 / 0-0 | REMAP on Flutter: filled `Icons.send`; use the outlined glyph the composer already draws. |
| 3 | `more` | navigation | `EllipsisHorizontal` -> `Ellipsis` | `ellipsis` | `more_horiz` | `Outlined.MoreHoriz` | 2 / 1 / 0-0 | KEEP |
| 4 | `back` | navigation | `ArrowBackOutline` -> `ArrowLeft` | `chevron.left` | `arrow_back` | `AutoMirrored.Outlined.ArrowBack` | 1 / 1 / 0-0 | KEEP |
| 5 | `close` | navigation | `CloseOutline` -> `X` | `xmark` | `close` | `Outlined.Close` | 4 / 14 / 0-2 | KEEP |
| 6 | `check` | general | `CheckmarkOutline` -> `Check` | `checkmark` | `check` | `Outlined.Check` | 3 / 8 / 0-2 | NARROW to select, accept and checked items; read receipts move to `read`, batch mode to `multi-select`. |
| 7 | `add` | general | `AddOutline` -> `Plus` | `plus` | `add` | `Outlined.Add` | 2 / 6 / 1-2 | NARROW to add; image zoom moves to `zoom-in`. |
| 8 | `remove` | general | `RemoveOutline` -> `Minus` | `minus` | `remove` | `Outlined.Remove` | 0 / 4 / 0-0 | NARROW to decrement; image zoom moves to `zoom-out`. |
| 9 | `edit` | general | `CreateOutline` -> `Pencil` | `pencil` | `edit_outlined` | `Outlined.Edit` | 2 / 2 / 0-1 | KEEP |
| 10 | `delete` | message | `TrashOutline` -> `Trash` | `trash` | `delete_outline` | `Outlined.Delete` | 0 / 8 / 0-2 | KEEP |
| 11 | `heart` | message | `HeartOutline` -> `Heart` | `heart` | `favorite_border` | `Outlined.FavoriteBorder` | 0 / 2 / 0-0 | KEEP |
| 12 | `heart-filled` | message | `Heart` -> `Heart` | `heart.fill` | `favorite` | `Filled.Favorite` | 0 / 0 / 0-0 | REMOVE: no consumer on any kit or app. |
| 13 | `comment` | message | `ChatbubbleOutline` -> `MessageCircle` | `bubble.left` | `chat_bubble_outline` | `Outlined.ChatBubbleOutline` | 4 / 2 / 0-2 | NARROW to comments; reply uses `reply`, the messages tab uses `chats`. |
| 14 | `share` | general | `ShareSocialOutline` -> `Share2` | `square.and.arrow.up` | `share_outlined` | `Outlined.Share` | 3 / 2 / 0-0 | KEEP |
| 15 | `camera` | composer | `CameraOutline` -> `Camera` | `camera` | `photo_camera_outlined` | `Outlined.PhotoCamera` | 2 / 1 / 0-0 | KEEP |
| 16 | `image` | composer | `ImageOutline` -> `Image` | `photo` | `image_outlined` | `Outlined.Image` | 2 / 3 / 0-0 | KEEP |
| 17 | `location` | composer | `LocationOutline` -> `MapPin` | `location` | `location_on_outlined` | `Outlined.LocationOn` | 2 / 3 / 0-0 | REMAP on iOS: `location` draws the current-position arrow; use `mappin.and.ellipse`, as the iOS kit's own location bodies do. |
| 18 | `mic` | composer | `MicOutline` -> `Mic` | `mic` | `mic_none_outlined` | `Outlined.Mic` | 2 / 5 / 0-0 | NARROW to voice input; a muted microphone moves to `mic-off`. |
| 19 | `phone` | calls | `CallOutline` -> `Phone` | `phone` | `phone_outlined` | `Outlined.Call` | 2 / 5 / 0-0 | NARROW to audio calls and accept; hang up moves to `end-call`. |
| 20 | `video` | calls | `VideocamOutline` -> `Video` | `video` | `videocam_outlined` | `Outlined.Videocam` | 4 / 5 / 0-0 | NARROW to video calls and video content; camera off moves to `camera-off`. |
| 21 | `settings` | navigation | `SettingsOutline` -> `Settings` | `gearshape` | `settings_outlined` | `Outlined.Settings` | 1 / 0 / 1-3 | KEEP |
| 22 | `person` | members | `PersonOutline` -> `User` | `person` | `person_outline` | `Outlined.Person` | 5 / 2 / 1-3 | KEEP |
| 23 | `people` | members | `PeopleOutline` -> `Users` | `person.2` | `people_outline` | `Outlined.People` | 9 / 1 / 5-14 | NARROW to contacts and member lists; groups move to `group`. |
| 24 | `person-add` | members | `PersonAddOutline` -> `UserPlus` | `person.badge.plus` | `person_add_alt_1_outlined` | `Outlined.PersonAddAlt` | 3 / 4 / 2-3 | KEEP |
| 25 | `star` | general | `StarOutline` -> `Star` | `star` | `star_border` | `Outlined.StarBorder` | 3 / 2 / 0-0 | NARROW to favourites and starred contacts; ownership transfer moves to `transfer-owner`. |
| 26 | `bookmark` | general | `BookmarkOutline` -> `Bookmark` | `bookmark` | `bookmark_border` | `Outlined.BookmarkBorder` | 0 / 0 / 0-0 | REMOVE: no consumer on any kit or app. |
| 27 | `download` | media | `DownloadOutline` -> `Download` | `arrow.down.circle` | `download_outlined` | `Outlined.Download` | 0 / 3 / 0-0 | KEEP |
| 28 | `link` | general | `LinkOutline` -> `Link` | `link` | `link` | `Outlined.Link` | 2 / 1 / 0-0 | KEEP |
| 29 | `emoji` | composer | `HappyOutline` -> `FaceSlightlySmiling` | `face.smiling` | `emoji_emotions_outlined` | `Outlined.EmojiEmotions` | 0 / 3 / 0-0 | KEEP |
| 30 | `file` | files | `DocumentOutline` -> `File` | `doc` | `insert_drive_file_outlined` | `Outlined.Description` | 1 / 1 / 0-0 | KEEP |
| 31 | `folder` | files | `FolderOutline` -> `Folder` | `folder` | `folder_outlined` | `Outlined.Folder` | 5 / 0 / 1-0 | KEEP |
| 32 | `notification` | conversation | `NotificationsOutline` -> `Bell` | `bell` | `notifications_outlined` | `Outlined.Notifications` | 3 / 2 / 0-3 | NARROW to notification settings and unmute; mark unread moves to `mark-unread`. |
| 33 | `mute` | conversation | `NotificationsOffOutline` -> `BellOff` | `bell.slash` | `notifications_off_outlined` | `Outlined.NotificationsOff` | 1 / 3 / 0-2 | NARROW to do not disturb; member and all-member silence moves to `silence`. |
| 34 | `copy` | message | `CopyOutline` -> `Copy` | `doc.on.doc` | `copy_outlined` | `Outlined.ContentCopy` | 0 / 1 / 0-1 | KEEP |
| 35 | `forward` | message | `ArrowRedoOutline` -> `Forward` | `arrowshape.turn.up.right` | `forward` | `AutoMirrored.Outlined.Forward` | 0 / 1 / 0-0 | KEEP |
| 36 | `reply` | message | `ArrowUndoOutline` -> `Reply` | `arrowshape.turn.up.left` | `reply` | `AutoMirrored.Outlined.Reply` | 0 / 1 / 0-0 | NARROW to reply only; recall moves to `recall`, quoted content to `quote`. |
| 37 | `refresh` | general | `RefreshOutline` -> `RefreshCw` | `arrow.clockwise` | `refresh` | `Outlined.Refresh` | 1 / 6 / 0-6 | NARROW to refresh, retry and resend; loading uses a spinner, rotation moves to `rotate`. |
| 38 | `chevron-down` | general | `ChevronDownOutline` -> `ChevronDown` | `chevron.down` | `keyboard_arrow_down` | `Outlined.ExpandMore` | 0 / 9 / 0-0 | KEEP |
| 39 | `chevron-right` | general | `ChevronForwardOutline` -> `ChevronRight` | `chevron.right` | `chevron_right` | `Outlined.ChevronRight` | 0 / 5 / 0-0 | KEEP |
| 40 | `arrow-down` | navigation | `ArrowDownOutline` -> `ArrowDown` | `arrow.down` | `arrow_downward` | `Outlined.ArrowDownward` | 0 / 1 / 0-0 | KEEP |
| 41 | `warning` | status | `WarningOutline` -> `TriangleAlert` | `exclamationmark.triangle` | `warning_amber_outlined` | `Outlined.WarningAmber` | 2 / 1 / 3-2 | KEEP |
| 42 | `info` | status | `InformationCircleOutline` -> `Info` | `info.circle` | `info_outline` | `Outlined.Info` | 7 / 1 / 1-1 | KEEP |
| 43 | `success` | status | `CheckmarkCircleOutline` -> `CircleCheck` | `checkmark.circle` | `check_circle_outline` | `Outlined.CheckCircle` | 1 / 3 / 0-0 | KEEP |
| 44 | `error` | status | `CloseCircleOutline` -> `CircleX` | `xmark.circle` | `cancel_outlined` | `Outlined.Cancel` | 0 / 2 / 0-0 | REMAP on all four: an x-circle reads as cancel; use the exclamation circle that message status and toasts already draw. |
| 45 | `calendar` | general | `CalendarOutline` -> `Calendar` | `calendar` | `calendar_today_outlined` | `Outlined.CalendarToday` | 3 / 2 / 1-0 | KEEP |
| 46 | `clock` | general | `TimeOutline` -> `Clock` | `clock` | `access_time` | `Outlined.Schedule` | 0 / 4 / 0-0 | KEEP |
| 47 | `eye` | security | `EyeOutline` -> `Eye` | `eye` | `visibility_outlined` | `Outlined.Visibility` | 1 / 2 / 0-0 | KEEP |
| 48 | `eye-off` | security | `EyeOffOutline` -> `EyeOff` | `eye.slash` | `visibility_off_outlined` | `Outlined.VisibilityOff` | 0 / 3 / 0-0 | KEEP |
| 49 | `lock` | security | `LockClosedOutline` -> `Lock` | `lock` | `lock_outline` | `Outlined.Lock` | 2 / 5 / 2-2 | KEEP |
| 50 | `qr` | members | `QrCodeOutline` -> `QrCode` | `qrcode` | `qr_code` | `Outlined.QrCode` | 0 / 1 / 2-1 | KEEP |
| 51 | `chats` | navigation | `ChatbubblesOutline` -> `MessagesSquare` | `bubble.left.and.bubble.right` | `forum_outlined` | `Outlined.Forum` | 3 / 0 / 4-4 | KEEP |
| 52 | `moments` | navigation | `PlanetOutline` -> `Compass` | `safari` | `explore_outlined` | `Outlined.Explore` | 1 / 0 / 3-2 | KEEP |
| 53 | `block` | members | `BanOutline` -> `Ban` | `nosign` | `block` | `Outlined.Block` | 3 / 2 / 2-2 | NARROW to blocking people; stop sharing and permission denied use their own names. |
| 54 | `tag` | general | `PricetagOutline` -> `Tag` | `tag` | `label_outline` | `AutoMirrored.Outlined.Label` | 1 / 0 / 0-0 | KEEP |
| 55 | `announcement` | conversation | `MegaphoneOutline` -> `Megaphone` | `megaphone` | `campaign_outlined` | `Outlined.Campaign` | 2 / 3 / 0-1 | KEEP |
| 56 | `theme` | general | `MoonOutline` -> `Moon` | `moon` | `dark_mode_outlined` | `Outlined.DarkMode` | 0 / 0 / 1-0 | KEEP |
| 57 | `language` | general | `LanguageOutline` -> `Languages` | `globe` | `language` | `Outlined.Language` | 1 / 1 / 1-0 | REMAP on Web: the translate glyph; use a globe. Translation gets its own `translate` name. |
| 58 | `devices` | security | `PhonePortraitOutline` -> `MonitorSmartphone` | `laptopcomputer` | `devices_outlined` | `Outlined.Devices` | 5 / 0 / 1-0 | REMAP on iOS: a single laptop; use a multi-device symbol (`laptopcomputer.and.iphone`). |
| 59 | `logout` | security | `LogOutOutline` -> `LogOut` | `rectangle.portrait.and.arrow.right` | `logout` | `AutoMirrored.Outlined.Logout` | 0 / 1 / 1-2 | NARROW to signing out and leaving; member removal moves to `remove-member`. |
| 60 | `pin` | conversation | `PinOutline` -> `Pin` | `pin` | `push_pin_outlined` | `Outlined.PushPin` | 2 / 7 / 0-2 | NARROW to pin; unpin moves to `unpin`. |
| 61 | `poll` | composer | `PodiumOutline` -> `Vote` | `chart.bar` | `poll_outlined` | `Outlined.Poll` | 2 / 0 / 0-0 | REMAP on Web: a ballot box; use a bar chart, as the natives and `MsgIcon` do. |

Order: the natives list `chats` and `moments` at 51-52; Vue and `ICON-LIBRARY.md` list them at 14-15. The name set is identical on all four. Accepted platform idioms: iOS `back` is a chevron and iOS `share` is the share-sheet glyph.

## 3. Where icons bypass the registry

### Vue

- 237 direct imports from the glyph shim across 73 component files; 160 import a glyph that already has a semantic name. The per-component glyph tables that should become `FlareIconName` tables: `utils/messageMenuIcons.ts`, `utils/conversationActionPresentation.ts`, `FlareMemberRoleSheet.vue`, `FlareRelationActionBar.vue`, `FlareGroupPermissionMatrix.vue`, `FlareUnknownUserPlaceholder.vue`, `FlareToast.vue`, `EnhancedComposer.vue`.
- One direct `@lucide/vue` import (`ComposerVoicePanel.vue`).
- Parallel hand-drawn sets: `MsgIcon.vue` (12 glyphs, stroke 1.6), `MessageStatus.vue` and `MessageDoubleCheckIcon.vue` (stroke 1.5), `FlareComposerSendButton.vue` (the send key is not the `send` glyph), `FlareComposerReplyStrip.vue`, `ComposerResizeIcon.vue`; the shim draws at stroke 1.75.
- Seven CSS spinners and three rotated-glyph spinners instead of one progress primitive.
- Host-facing icon fields are `string` (`FlareSettingsItem.icon`, `FlareNavigationItem.icon`, `FlareMessageActionExtension.icon`, `FlareActionItem.icon`, `FlareEmptyState.icon`), and `FlareGlyph` prints an unknown name as visible, announced text. Web passes `"bell"` for the notifications row, which renders the word "bell"; the kit passes `🔍` to an empty state.

### Flutter, SwiftUI, Compose

- Hard-coded glyphs: Flutter 335 (`Icons.*`), SwiftUI 322 (SF Symbol literals), Compose 309 (`Icons.<Style>.<Name>`). The registry is called 7, 14 and 11 times.
- Public APIs typed on platform glyphs (`IconData`, `String` symbol names, `ImageVector`) force apps to name platform glyphs.
- Header action aliases differ: Flutter and Compose map `audioCall`, `videoCall`, `addMember`, `details`; iOS has none, so an action with no icon draws `more`.
- Unknown names fall back differently: Flutter `help_outline` or `more_horiz_rounded`, iOS `questionmark` or `more`, Compose `HelpOutline` or `MoreHoriz`.
- iOS draws an emoji category's `symbol` as an SF Symbol name; the other kits treat it as emoji text, so a host passing an emoji gets a blank tab on iOS only.

## 4. Sizes

The token scale is `icon-size-sm` 16, `md` 20, `lg` 24, `xl` 32 on every platform. Measured use: Vue passes 16 distinct literal sizes to icon props and 13 more in CSS (13 lines use a token); Flutter 129 literal sites in 19 sizes, SwiftUI 130 in 18, Compose 134 in 17, mostly off the scale. The same control has a different icon size on each platform. `FlareIcon` (Vue) takes a raw number, so a token cannot be passed by name.

## 5. Unicode used as control icons

| Where | file:line | Character | Used as | Replace with |
|---|---|---|---|---|
| Vue kit | `components/message-preview/ImagePreviewModal.vue:77` | × | close button | `close` |
| Vue kit | `components/contacts/FlareContactDetail.vue:97` | ★ | starred badge | `star` |
| Vue kit | `components/general/FlareSearchResults.vue:72` | 🔍 | empty state icon | `search` |
| Vue kit | `components/composer/ComposerRichMarkdownInput.vue:368-389` | IMG, ↗, •, ❝, {}, — | rich-text token icons | kit format glyphs |
| Vue kit | `components/composer/FlareStickerPanel.vue:41,60` | 🎨, 🖼️ | sticker placeholders | `image` or an empty tile |
| Web | `views/AuthView.vue:274` | ← | back to sign in | `back` through the button icon |
| Web | `social/directory.ts:105` | ★ | starred tag text | kit starred badge |
| Tauri | `views/Auth.vue:493` | ← | back to sign in | `back` |
| Tauri | `components/ContactDetailPanel.vue:52` | ★ | starred tag text | kit starred badge |
| Flutter kit | `flare_contact_detail.dart:149` | ★ | starred badge | `star` |
| SwiftUI kit | `FlareContactDetailView.swift:121` | ★ | starred badge | `star` |
| SwiftUI kit | `EmojiPickerView.swift:134` | • | emoji category fallback | category label |
| Compose kit | `ContactDetail.kt:98` | ★ | starred badge | `star` |
| Compose kit | `EmojiPicker.kt:135` | 🙂 | emoji category fallback | category label |
| Compose kit | `EmojiStickerViews.kt:185` | … | loading placeholder | progress indicator with a label |
| Android app | `FlareSocialApp.kt:289` | ← | back to sign in | kit `back` glyph |

Emoji inside message content, reaction sets and emoji pickers are content, not control icons, and stay.

## 6. One concept, several glyphs; one glyph, several meanings

| Concept | Drawn today | One name |
|---|---|---|
| Reply | Reply (menu); MessageCircle (hover toolbar) | `reply` |
| Recall | the reply arrow (menu) | `recall` (new) |
| Forward | Forward; Share2 (forward each); Library (merged) | `forward`, `merge-forward` (new) |
| Unpin | the pin glyph | `unpin` (new) |
| Read receipts, mark read | double-check SVG; CheckCheck; `check` (Tauri) | `read` (new) |
| Multi-select | List (menu); `check` and CheckCheck (Tauri) | `multi-select` (new) |
| Do not disturb | BellOff (row); Bell (group detail) | `mute` |
| Silence a member, silence all | BellOff; VolumeX; unmute = Bell | `silence` (new) |
| Hang up | a rotated phone on four kits | `end-call` (new) |
| Remove member | LogOut | `remove-member` (new) |
| Transfer ownership | Star | `transfer-owner` (new) |
| Groups | Users (same as contacts); UsersRound (Tauri) | `group` (new) |
| Add member | `people` through a Vue-only remap; UserPlus; Plus | `person-add`; delete the remap |
| Error | CircleX; CircleAlert (6 sites); exclamation SVG | `error`, remapped to the exclamation circle |
| Report | `warning` in both Vue apps; Flag for "mark" | `report` (new) |
| Clear local history vs delete conversation | the same trash glyph in the row menu | `clear-history` (new); `delete` |
| Zoom, rotate (image preview) | Plus, Minus, RefreshCw | `zoom-in`, `zoom-out`, `rotate` (new) |
| Play, pause (voice, video) | Play, Pause, `MsgIcon` circle-play and volume | `play`, `pause` (new) |
| Loading | RefreshCw spinning, Languages spinning, dashed SVG, seven CSS spinners | one progress primitive per kit |
| Messages tab | `chats` (web); `comment` (Tauri) | `chats` |
| New friends | `person-add`; Mail (Tauri) | `person-add` |
| Mark unread | MailOpen (kit); `notification` (Tauri) | `mark-unread` (new) |
| Screen share, mini app | `devices` | `screen-share`, `mini-app` (new) |

## 7. Icon-only controls without an accessible name

| Kit | Count | Examples |
|---|---:|---|
| Vue | 1, fixed in Round 5 | profile editor avatar picker (was a clickable `div`) |
| Flutter | 27 | voice recording send and cancel, image preview close and download, exit multi-select, play video, play/pause voice, task checkbox, stepper, rating, moment actions, and the public `FlareComposerIconButton`, which has no label parameter |
| SwiftUI | 29 | the whole composer toolbar (expand, emoji, mention, voice, image, rich text, panel), call dock mute and hang up, incoming call accept and reject, image preview close and download, exit multi-select, stepper, rating |
| Compose | 8, plus 3 with a click label only | voice recording, image preview, exit multi-select, play |

The kits already ship labelled icon buttons (`FlareIconButton`, iOS `IconButtonView`, Compose `IconButton` wrappers); the SwiftUI kit uses its own labelled button zero times.

## 8. Decisions

1. **Registry scope.** Keep 59 names (6 of them remapped and 16 narrowed to one meaning), remove 2 (`heart-filled`, `bookmark`), and add the 40 names in `icon-coverage.md` that the kits or apps draw today: the 39 concepts found absent plus `mark`, which every message menu already draws as a flag (99 names after the change). Do not add names nothing draws.
2. **One path.** Components and apps render icons by semantic name only: Vue `FlareIcon` or a `FlareIconName`-typed prop; Flutter, SwiftUI and Compose the registry view or a name-typed parameter. Platform glyph types leave public APIs. The Vue shim entry becomes internal.
3. **Accessible names.** Every icon-only control takes a required label; the unnamed controls in section 7 are fixed on all kits.
4. **Sizes.** Icon views take the token scale by name (`sm`, `md`, `lg`, `xl`).
5. **Gates.** A ratchet per kit counts glyph references outside the registry and fails when the count rises; it reaches zero as components migrate.
6. **Order.** The unnamed controls and the wrong meanings (recall, hang up, remove member, transfer owner, error) come first; the bulk migration of bypasses follows the ratchet.

## 9. Status after Round 5 Batch 1

| Measure | Vue | Flutter | SwiftUI | Compose |
|---|---:|---:|---:|---:|
| Semantic names in the registry | 99 | 99 | 99 | 99 |
| Order identical to Vue | ✓ | ✓ | ✓ | ✓ |
| Icon-only controls without an accessible name (kit) | 0 | 0 (27 named) | 0 (29 named) | 0 (8 named, 3 click-label-only named) |
| Registry tests | `icons.test.ts` | `icon_registry_test.dart` | `IconRegistryTests` | `IconLibraryTest` |
| Token literal count (`check-hardcoded-visuals`) | 1216 (was 1226) | 315 (was 339) | 427 (was 431) | 803 (was 825) |

- `tooling/check-icon-registry.mjs` runs in `npm run check`: the same names in the same order on four kits, a glyph for every name on every kit.
- Decision 2 is partly done: the wrong meanings (recall, hang up, remove member, transfer owner, error, member mute) and the Unicode control glyphs are fixed on four kits, and the Tauri app's 18 vendor glyph components now use the registry (web and Tauri `vendorGlyphImport` baseline 0 in `examples/apps/scripts/check-kit-reference.mjs`). Public APIs still take platform glyph types (Flutter `IconData`, SwiftUI glyph strings, Compose `ImageVector`); the Flutter and Android apps pass 46 and 34 platform glyphs through them, and the iOS app passes SF Symbol names through navigation items, `IconButtonView`, `ButtonView`, `EmptyStateView`, settings items and composer actions. Typed names and the bypass ratchet (decisions 2, 4 and 5) remain for R5.12.
- Platform substitutions where the natural glyph is unavailable at the platform floor are listed in `../ICON-LIBRARY.md` (accepted platform differences).

## 10. Status after Round 9

Date: 2026-09-18. The fifteen names the Batch 5 migrations nominated were decided as one set: six added on four kits, nine rejected. Decisions, reasons and the rows that drew each concept: `icon-coverage.md`.

| Measure | Vue | Flutter | SwiftUI | Compose |
|---|---:|---:|---:|---:|
| Semantic names in the registry | 105 | 105 | 105 | 105 |
| Order identical to Vue | ✓ | ✓ | ✓ | ✓ |
| Kit-internal glyph references (`check-icon-registry` ratchet) | 149 | 175 | 76 | 170 |

- Added after `mini-app`: `pin-self`, `diagnostics`, `card`, `id`, `join-request`, `storage`. The registry tests of every kit assert each new glyph differs from the name the concept borrowed before (`pin`, `info`, `person`, `tag`, `person-add`, `notification`, `folder`); reverse checks (one new name per kit set back to its old glyph) fail on all four kits.
- Row 26: the `bookmark` glyph is drawn again, by `pin-self`. The name `bookmark` stays removed; it named a shape.
- A limit of the application screenshots: the web app 设置 page changed exactly 120 pixels when the 18-pixel 存储空间 glyph changed from a folder to a hard drive, which is the allowance (`maxDiffPixels: 120`), so the comparison passed. Icon meaning is guarded by the registry tests and gates, not by application screenshots. Playwright's default `--update-snapshots` also skips a baseline whose change is inside the allowance; the settings baseline was retaken with `--update-snapshots=all`.
