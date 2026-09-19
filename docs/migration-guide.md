# 2.0 RC Breaking Migration

This RC deliberately removes development-era compatibility paths. Update consumers directly; no forwarding package, import alias, or token alias is shipped.

## Package Paths

| Former repository path | Current path |
|---|---|
| `vue-im-ui/` | `packages/vue-im-ui/` |
| `flutter-im-ui/` | `packages/flutter-im-ui/` |
| `android-im-ui/` | `packages/android-im-ui/` |
| `ios-im-ui/` | `packages/ios-im-ui/` |

Apple consumers point to the self-contained package at `packages/ios-im-ui`. The repository root is not a Swift package.

## Message State

Map transport-specific message state to `MessageLifecycle` and semantic `MessageStatusState` in the host. Vue no longer accepts a numeric status bridge. When lifecycle is supplied it is the source of the visual status.

## Android Strings

Use the typed builder. Positional constructors were removed.

```kotlin
val strings = FlareStrings {
    send = "Send"
    retry = "Retry"
    readTab = { count -> "Read ($count)" }
}
```

## Layout Tokens

Use `appShellCompactMinWidth` and `appShellExpandedMinWidth` for the shell. The generic `dualPaneMinWidth` and `triplePaneMinWidth` aliases were removed, and so were `conversationDualPaneMinWidth` (720) and `conversationTriplePaneMinWidth` (1100): how many panes fit is the pane rule (`resolvePaneMode` / `paneModeMinWidth` on Vue, SwiftUI and Compose; `flarePaneModeForWidth` / `flarePaneModeMinWidth` on Flutter), not a width token. `leftPanel` and `rightPanel` were the same columns under a second name: use `primaryPaneDefaultWidth` (320) and `detailPaneDefaultWidth` (300).

## Application Shell

`IMAppKit` measures its own box (width and text scale) and passes the mode down; hosts no longer pass `responsiveMode`, `primary`, `detail`, `hasDetail`, `activePane`, `paneMode`, `detailMode`, `hideMobileNavigation` or `onLayoutChange`. Render destinations by navigation id — Vue `destination` scoped slot, Flutter `destinationBuilder`, SwiftUI `destination`, Compose `destination` — and let visited destinations stay alive instead of retaining them yourself. `AppLayout` and `WorkspaceFrame` lost `responsiveMode`: inside a shell they use the shell's mode. The phone tab bar hides while the active destination reports depth: `FlareScreen` with a back action and a single-pane frame showing a non-root pane report it; a host-drawn secondary page registers with `useFlareDestinationDepth` / `FlareDestinationDepth` / `.flareDestinationDepth(_:)`. Flutter hosts no longer wrap the wide shell in a `Scaffold`.

## Message Bodies

Native hosts map the core's `rich_text` to `FlareRichTextContent(docJson, plainText, title)` and `image_group` to `FlareImageGroupContent(images, description)`; do not map either to a text message. The Vue timeline draws the stored rich document, not the sender's Markdown. Polls and tasks in a timeline become controls only when the host takes `vote` / `taskToggle`.

## Theme Mode

Every kit takes `FlareThemeMode` (`light` / `dark` / `system`) and resolves it with `flareThemeIsDark(mode, systemDark)` over `spec/theme-mode-vectors.json`: Vue `<FlareUiProvider theme-mode>`, Flutter `FlareTheme(mode:)`, SwiftUI `.flareTheme(mode:)`, Compose `FlareThemeProvider(mode = ...)`. Hosts hold and store the person's choice; the three labels are in every strings table (`themeSystem` / `themeLight` / `themeDark`). The Flutter `FlareTheme(dark: bool?)` and Compose `FlareThemeProvider(dark: Boolean)` parameters are gone, and an app that overrode `uiMode` or forced a scheme should stop.

## One Conversation Kind

`single | group | channel | ai | system` is the vocabulary for every component and kit (`spec/conversation-kind.json`). On Vue, `MessageList` / `MessageBubble` take `conversationKind` (was `conversationType`), the header identity's `kind` uses the same union (`direct` became `single`, `bot` became `ai`), and `FlareConversationDetailsModel.conversationKind` replaces a free string. `StartConversationDialog`'s model is `conversationKind`.

## Batch Toolbars

`MessageBatchToolbar` takes `selectedIds`, `total` and `capabilities` and reports one `action` carrying the ids, exactly like `ConversationBatchToolbar`; `count`, `showClear`, `showPin`, `showPinSelf` and the eight per-action events are gone. Select-all, clear and exit stay their own events. `spec/message-batch-vectors.json` is the availability rule (`forwardMerged` needs two).

## Input, Search And Detail Seams

- `Input.revealable` draws the unmask key inside a secure field; delete app-built show-password toggles.
- `SearchBar` owns the debounce (`debounce`, 300 ms) and emits `search` with the settled query; it also emits `cancel` where a host offers a way out. Delete per-app timers.
- `ContactDetail` and `GroupDetail` take `extraActions` (id / label / danger) and emit `extraAction`; a report or an admin tool belongs there instead of beside the component.
- `FlareContact.relation` puts the viewer's relationship on the row; stop rewriting the signature line to say it.
- The composer asks the platform adapter for images, video and files where the platform declares the capability, and reports them through `files-drop`; hidden file inputs can go. The composer also owns the emoji and sticker panel on every kit unless the host handles the emoji key, and reports a chosen sticker through `sendSticker`.

## View State

`FlareViewState` gained `emptyTitle` and `stale`, and `flareViewPresentation(status, stale)` (`spec/view-state-vectors.json`) is the rule on four kits: a failed refresh over content the host marks stale keeps the rows and draws the failure as a banner; an empty list takes its words from `emptyTitle`, not `error`. List containers also take `onRefresh` (Flutter) and an `empty` slot on the contact and group lists.

## Moments Privacy

`FlareMomentVisibility`, `FlareMomentAudienceMode` and `FlareMomentHistoryRange` replace the numeric codes on every kit (`spec/moments-privacy.json` records what the reference apps used to send, so a host can check its own mapping). Map numbers once, at the request boundary.

## Text Roles

`tokens.json` carries `textRole` (title / section / body / caption). Use `--flare-text-<role>-*` on the web and `FlareTextRoles` on Flutter, SwiftUI and Compose instead of platform fonts or literal sizes. There is no global density preset any more: the provider's `density` and the `DensityMode` type are gone, and only components with their own `density` prop have one.

## Theme Tokens

Components consume `--flare-*` semantic/component tokens. The former `--im-*` names were removed. Regenerate Dart, Kotlin, Swift, and CSS outputs from `tokens/tokens.json` and `tokens/themes.json`; never edit generated files.

## Verification

Run `npm run generate`, `npm run check`, all four platform package tests/builds, website visual tests, consumer fixture builds, and `git diff --check` before publishing.
