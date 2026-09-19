# Composition Proof: the Golden Reference App

Date: 2026-09-14, after Round 4; re-measured 2026-09-16, after Round 5. Subject: `flare-social/flare-social-sdk/examples/apps/flare-social-web-app`, the golden reference app (see `golden-app.md`).

## Claim

Every generic IM surface in the golden app is a component of this kit, reached through its published entries. The app contributes:

- data mapping
- orchestration and routing
- product copy
- a few token-only layout rules that place kit components on the page

## Evidence 1: gates

| Check | Result (Round 5, 2026-09-16) |
|---|---|
| `vue-tsc --noEmit` | 0 errors |
| App unit tests (`vitest`) | 77 pass |
| Application specs on the fixture core (`tests/app-visual`) | 52 pass, including 12 application-visual baselines |
| `examples/apps/scripts/check-kit-reference.mjs` | naive-ui imports 0, deep kit imports 0, vendor glyph imports 0, visual literals in styles 0, legacy UI directories 0 |
| `tooling/check-reference-app-consumers.mjs` | 234 kit imports resolve against the published entries |

## Evidence 2: every screen file, what it renders

Kit components are counted from each template. Raw elements are the HTML tags the app writes itself; style lines are non-empty declarations in the file's style block.

| File | Role | Kit components rendered | Raw elements | Style lines |
|---|---|---|---:|---:|
| `App.vue` | Provider root | FlareUiProvider | 0 | 0 |
| `views/MainView.vue` | Shell and cross-tab flow | FlareIMAppKit, FlareStatusBanner | 1 | 14 |
| `views/AuthView.vue` | Sign-in and sign-up | FlareScreen, FlareFormField, FlareInput, FlareCheckbox, FlareSegmentedControl, FlareButton, FlareStatusBanner | 8 | 32 |
| `components/ConversationPane.vue` | Inbox | FlareConversationListContainer, FlareConversationList, FlareSearchBar, FlareStatusBanner, FlareEmptyState, FlareIconButton | 1 | 11 |
| `components/ChatArea.vue` | Conversation | FlareConversationHeader, FlareMessageList, FlareComposer, FlareEmojiStickerPicker, FlareStatusBanner, FlareEmptyState | 2 | 20 |
| `components/ConversationSearch.vue` | In-conversation search | FlareScreen, FlareSearchPanel | 0 | 4 |
| `components/GlobalSearch.vue` | Global search | FlareScreen, FlareSearchBar, FlareSearchResults, FlareEmptyState, FlareButton | 1 | 15 |
| `components/GroupDetailPanel.vue` | Group details | FlareScreen, FlareGroupDetail, FlareAnnouncementReadBar, FlareButton | 0 | 1 |
| `components/ContactDetailPanel.vue` | Contact details | FlareScreen, FlareContactDetail, FlareFormSheet, FlareInput, FlareButton, FlareStatusBanner | 1 | 2 |
| `components/ContactsTab.vue` | Contacts tab | FlareScreen, FlareScreenHeader, FlareFriendListContainer, FlareContactList, FlareGroupList, FlareNewFriendRequests, FlareSettingsList, FlareEmptyState, FlareButton, FlareIconButton | 1 | 9 |
| `components/AddFriendPanel.vue` | Add friend | FlareSearchBar, FlareContactList, FlareContactMatchList, FlareFormSheet, FlareFormField, FlareInput, FlareStatusBanner, FlareEmptyState, FlareButton | 4 | 22 |
| `components/JoinGroupPanel.vue` | Join group | FlareSearchBar, FlareGroupList, FlareFormSheet, FlareFormField, FlareInput, FlareStatusBanner, FlareEmptyState | 3 | 15 |
| `components/CreateGroupDialog.vue` | Create group | FlareFormSheet, FlareFormField, FlareInput, FlareContactList, FlareEmptyState | 2 | 9 |
| `components/MomentsTab.vue` | Moments | FlareScreen, FlareMomentsCoverHeader, FlareMomentCard, FlareMomentComposer, FlareMomentAudienceSheet, FlareBottomSheet, FlareFormSheet, FlareFormField, FlareInput, FlareStatusBanner, FlareEmptyState, FlareButton | 2 | 12 |
| `components/MeTab.vue` | Me | FlareScreen, FlareProfilePanel, FlareProfileEditor, FlareQRCard, FlareSettingsList, FlareEmptyState | 3 | 14 |
| `components/SettingsPanel.vue` | Settings | FlareScreen, FlareSettingsList, FlareNotificationPreferences, FlareDeviceSessions, FlareStorageUsage, FlareMomentsVisibilityRuleList, FlareRadioGroup, FlareContactList, FlareQRCard, FlareBottomSheet, FlareFormSheet, FlareStatusBanner, FlareEmptyState, FlareButton | 8 | 10 |
| `components/ReportSheet.vue` | Report form | FlareFormSheet, FlareFormField, FlareRadioGroup, FlareTextarea | 1 | 7 |

In total the templates render **50 distinct kit components** (Round 5; 45 after Round 4). The per-file table above is the Round 4 snapshot; Round 5 added `FlarePinnedMessageBar`, `FlareMessageBatchToolbar`, `FlareTypingIndicator` and `FlareForwardPicker` to the conversation, `FlareBottomSheet` to global search (the desktop palette), and split the search results into `components/search/GlobalSearchBody.vue` so the phone page and the palette share one body.

What the raw elements are:

- **Layout wrappers:** `div`, `section`. They carry token-only flex or grid rules.
- **Hidden file inputs:** in the chat and the avatar editor. They are the browser's file picker, triggered by kit attach actions.
- **Report target line:** one `p` in the report form.
- **Sign-in extras:** the sign-in page's form element and a short feature list. That list is finding P1-8 in `golden-app.md`.

None of these draws a row, bubble, menu, sheet, dialog, toast or control.

## Evidence 3: surfaces the app no longer owns

| Surface | Before this program | Now |
|---|---|---|
| Conversation rows and row menu | Rows with no row actions wired | `FlareConversationList` with the app's supported actions |
| Toast | App state, timer and floating host | `useFlareToast` |
| Destructive confirmation | None, or screen-held `FlareDangerConfirm` state | `useFlareConfirm` at every destructive step |
| Message menu configuration | 14-flag table | Listener mask |
| Phone panes | List and detail declared twice | `activePane` |
| Report dialog | Bespoke modal from a social UI package | Kit form sheet composition |
| Global search placement | Rendered as a grid item inside the navigation column | Kit overlay layer |
| Conversation row menu (Round 3) | A per-row action list the app built for each row | `capabilities` on `FlareConversationList`; the row presents its own menu |
| Inbox search entry (Round 3) | A secondary button labelled 搜索 | `FlareSearchBar` in read-only entry mode |
| Unread position (Round 3) | None | `unreadFromId` on `FlareMessageList` |
| Timeline loading and empty states (Round 3) | The load-older strip stood in for first-load loading | The list's `#empty` slot |
| Report a message (Round 3) | Not offered | A host action in the kit message menu |
| Create-group member picker (Round 3) | Checkbox rows rebuilt from `FlareCheckbox` | Selectable `FlareContactList` |
| Personal QR code (Round 3) | A decorative matrix | `FlareQRCard` encoding the QR token |
| Moment times (Round 3) | A Chinese-only relative time helper | `formatRelativeTime` from the kit utilities |
| Announcement read bar and group report placement (Round 4) | Placed above the hero and below the component, outside FlareGroupDetail | The component's `after-info` and `footer` slots |
| Join policy (Round 4) | SDK numbers cast into the kit model, unknown values shown as "open" | `FlareGroupJoinPolicy`, unknown shown as not set |
| Connection and session-end copy (Round 5) | The app wrote its own phase copy and recovery | `connectionNotice` gives copy, tone and the recovery action |
| Forward, multi-select, pinned bar, typing (Round 5) | Not offered | `FlareForwardPicker`, `FlareMessageBatchToolbar`, `FlarePinnedMessageBar`, `FlareTypingIndicator` |
| Settings row semantics (Round 5) | Every row was a button | `navigation` / `toggle` / `action` / read-only `value` |
| Pane mode and the chat's back control (Round 5) | The app guessed from the window width | `layoutChange` from the shell |
| Desktop search shell (Round 5) | A full-screen page over the app | `FlareBottomSheet` as a centred palette, phones keep the page |
| Reading column on full pages (Round 5) | The app set its own max width | `FlareScreen` `readable` |

## Evidence 4: dependencies that are not the kit

| Import | Kind | Verdict |
|---|---|---|
| `flare-social-typescript-sdk`, `flare-social-typescript-sdk/web`, the WASM package | SDK | Expected: data and operations |
| `flare-social-vue-ui` | Report reason list and validation (`REPORT_REASON_ITEMS`, `validateReportDraft`, `REPORT_DESCRIPTION_MAX`) | Allowed: domain data only. Its UI components are not used (friction log Appendix B, item 17). |
| `vue`, `vue-router` | Framework | Expected |

## Limits of the proof

- Static: it shows what the app renders and imports, not how each surface behaves when signed in. The live signed-in pass is still pending (`golden-app.md`, core IM loop). The report form, the overlay layer and the Round 3 compositions (unread divider, row menu, message menu dispatch, header identity, dialog and drawer presentation) were checked in browser harnesses.
- It covers the golden app only. Per-app escape hatches for the parity apps are in `design-system-escape-hatches.md`.
