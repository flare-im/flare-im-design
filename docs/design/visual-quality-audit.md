# Visual Quality Audit: Round 5

Date: 2026-09-15, with the final pass on 2026-09-16. Scope: the five flare-social reference apps composed from this kit, reviewed as products (hierarchy, states, responsive behaviour, dark mode, accessibility), and the kit changes that followed. Mode: IN-SYSTEM. Every value named below is an existing token or a component token added through the kit (`--flare-component-*`).

## Method

- **Web (golden app):** 29 review captures of the real app on the in-memory fixture core (`tests/app-visual/review-capture.spec.ts` with `CAPTURE_DIR`): desktop 1440 and 1280, tablet 1024, 834 and 768, small 600, phones 390 and 320; light and dark; long, empty, error, offline, send-failure and 1,000-conversation scenarios. Keyboard, back and focus behaviour were checked in the browser at 1280 and 375 px.
- **Tauri:** code review plus `vue-tsc` and `vite build` (no fixture harness).
- **Flutter, SwiftUI, Compose:** kit widget, snapshot and instrumented tests named in each batch report, and the apps' builds. No device session.
- Screenshots are review evidence, not regression baselines; the website keeps the regression baselines (`tests/visual/vue/baselines/darwin`).

## Passes and findings

Severity follows the program rule: P0 blocks the task or is inaccessible, P1 is a major usability, hierarchy, state or responsive problem, P2 is polish.

### Pass 1 to 4 (shell, messages, composer, search)

| Finding | Severity | Resolution |
|---|---|---|
| Conversation row time column cut `2025/12/31` | P1 | Fixed: column fits a full date |
| Every Chinese contact under "#" | P1 | Fixed on four kits (engine collation, platform transliteration, Flutter table) |
| Emoji panel English literals and light-only colours in dark mode | P1 | Fixed: localized, token colours |
| Mention picker could not be driven by Enter | P1 | Fixed: combobox with keyboard model on four kits |
| Timeline separators every five minutes | P2 HIGH | Fixed: first message and day changes only |

### Pass 5 (members and group)

| Finding | Severity | Resolution |
|---|---|---|
| Group announcement squeezed the label to one character per line | P1 | Fixed: long values stack under the label (four kits) |
| 500-member groups rendered every avatar; 群成员 row inert | P1 | Fixed: 20-cell preview and a searchable member list (four kits) |
| A single overflow action opened a one-item menu | P2 HIGH | Fixed: direct button (four kits) |

### Pass 6 (me, moments, settings, identity)

| Finding | Severity | Resolution |
|---|---|---|
| Profile header was a full-bleed brand banner and a clickable `div` with a nested QR button (keyboard could not reach it) | P1 | Fixed: an identity card on the list surface; identity and QR are separate controls (Vue, Flutter, SwiftUI, Compose) |
| Moments cover without a photo was a saturated brand gradient | P2 HIGH | Fixed: a short tertiary band with normal text colours |
| Author and liker names were a clickable `div` and links without `href`; comment rows were clickable list items | P1 | Fixed: controls only when handled, named "回复 {name}：{text}" |
| Contact details showed disabled call buttons and friend-only actions to strangers; the account id was printed as "Flare ID" | P1 | Fixed: intents only when handled; `flareId` is the public handle only |
| Desktop pages were one 1,200 px column | P1 | Fixed: `FlareScreen` `readable` 720 px column on 我, 圈子, 设置, 通讯录 |

### Pass 7 (responsive and dark)

| Finding | Severity | Resolution |
|---|---|---|
| Keyboard focus ring on desktop bubbles was painted over by the hover shadow | P1 | Fixed: `borderSelected` outline with offset |
| Pinned messages took about 140 px as a panel of cards above the timeline | P1 | Fixed: compact bar (about 75 px) with single-line rows |
| At 600 px the expanded composer toolbar pushed the send button out of the pane | P1 | Fixed in the web app: expanded tools on desktop only |
| Batch toolbar labels squashed at 390 px | P1 | Fixed: labels keep their width and the row scrolls |
| Dark avatar fallbacks glared on dark lists | P1 | Fixed: dark avatar tint tokens |
| 600 to 767 px keeps list and chat side by side; the chat is about 210 px wide | P1 | Open: single pane below a usable chat width lands with shell-derived back visibility (FR-083, FR-095) |

### Pass 8 (states and final review)

| Finding | Severity | Resolution |
|---|---|---|
| Kicked and expired sessions were dead ends; Tauri said it would reconnect | P1 | Fixed: kit connection notice with 重新登录 above every tab |
| Load failures looked like empty lists; failed writes closed as if done | P1 | Fixed in all apps: kit error states with 重试, dialogs stay open with the error |
| System and recall notices were bold bordered pills | P2 MEDIUM | Fixed: quiet chip, matching the native notice line |
| A failed bubble turns all its text red on pink | P2 MEDIUM | Open: the natives already use a normal bubble with a meta-row mark, but a red mark on an outgoing bubble fails contrast; the mark moves beside the bubble on four kits together |
| Moments "举报" sits outside the card | P2 | Open: MomentCard has no host action slot |
| 600 px voice bubble label overlaps the waveform | P2 | Open |

### Pass 8b (final review on the application-visual set, 2026-09-16)

The final pass reviewed the app as twelve baseline screenshots of the running application (`flare-social-web-app/tests/app-visual/baselines/darwin`), not review captures: inbox, group chat, dark group chat, search, group members, settings, image preview, empty, error, tablet chat, phone chat and dark phone inbox.

| Finding | Severity | Resolution |
|---|---|---|
| Global search took over the whole window on desktop: a full-width field and an empty state floating in a void (the PASS 1 finding was still open) | P1 | Fixed: a centred palette over a dimmed app on pointer devices (720 px through the kit's new dialog-width component token); phones keep the full page |
| Settings rows that only display a value (版本, Flare ID, a setting that failed to load) were buttons | P1 | Fixed: `value` rows are read-only, `action` rows are the in-place ones, and only navigation rows carry a chevron |
| Business cards (poll, schedule, task, mini app, announcement) drew a 查看详情 button no host handles; the mini-program card printed its app id and page path | P1 | Fixed: the button is gone and the card names the program |
| A window between 600 and 751 px still split the list and the chat, leaving the chat about 210 px wide | P1 | Fixed: one pane with the rail below 752 px, and the chat carries the back control |
| When the conversation list fails to load, the content pane still says 从左侧列表选择一个会话开始聊天 | P2 | Open: the empty content pane does not know the list failed |
| The application-visual baselines are macOS only | P2 (test) | Open by design: Linux baselines are generated on the CI image (External Validation Steps C9) |

## Critique gate (anti-template)

- No new gradients, glows or glass were introduced; two brand-coloured surfaces (profile banner, moments placeholder) were removed.
- No pill inflation: notices became quieter; pills remain only for chips that float over content (the sticky date chip, the start-of-history hint).
- One accent role: the brand colour marks selection, the unread divider and primary actions; names use `primaryText`, which clears AA in both themes.
- Hierarchy survives grayscale: the timeline outranks pinned messages, notices and dates.

## Accessibility summary

- Timeline: one Tab stop, arrow navigation, named focused messages, visible focus.
- Every icon-only control named on four kits; native targets 44 pt and 48 dp. Inline text controls (names inside a sentence) are the stated exception, consistent across kits.
- Platform back closes the innermost layer on Android and, when the host opts in, on phone browsers.
- Not verified: screen reader passes with VoiceOver, TalkBack and NVDA (listed in the final report's External Validation Steps).
