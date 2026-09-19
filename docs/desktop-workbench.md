# Desktop Workbench Contract

> 2.0.0-rc.1（2026-09-12）：`DesktopWorkbench` 组件已并入 `DesktopAppShell`（`paneMode` / `detailMode` / 窗格宽度 / 七个键盘命令），`MasterDetailLayout` / `ThreePaneLayout` 内部化为 `AdaptiveWorkbench` 的私有栅格；本文保留为桌面契约的设计背景，组件级真源以 `spec/components.json` 与 `docs/release/migration/2.0-rc-to-2.0.md` 为准。
>
> Round 10（2026-09-18，FR-140）：`AdaptiveWorkbench` 四端退役（登记 D18）。它与 `AppLayout` 是同一组区域、同一套词汇，却不量自己的盒子、不走分栏规则、不报告呈现，也没有任何消费方；`AppLayout` 是唯一的窗格组合件。

Status: Phase 5 baseline. `spec/components.json` and generated tokens are the source of truth. Vue PC remains the current UX reference implementation, not the contract owner.

## Architectural direction

The host-level shell composes navigation, primary content selection, the active content surface, optional detail, overlay and command hosts, and focus/keyboard policy. It does not own conversation data or SDK state.

`ResponsiveLayout` remains a conversation-level adaptive layout. `ConversationWorkspace` remains the IM state composition for list/chat/detail. Neither replaces the host shell.

```text
IMAppKit
└── AppLayout
    ├── navigation
    ├── primary
    ├── content
    ├── detail (hidden | inline | overlay | route)
    ├── overlay
    ├── floating
    └── command
```

## Modes

| Contract | Values |
|---|---|
| Pane mode | `singlePane`, `dualPane`, `triplePane` |
| Detail presentation | `hidden`, `inline`, `overlay`, `route` |
| Responsive mode | `mobile`, `tablet`, `desktop`, `wideDesktop` |
| Focus policy | `preserve`, `contentFirst`, `activePane` |

`AppLayout` is the one pane composition: it resolves its mode from its own box (or from the shell it is in), asks the shared pane rule how many panes fit, presents the detail inline, as an overlay or as a route, and reports the presentation it settled on. `DesktopAppShell` adds the desktop keyboard scope and focus policy.

## Breakpoints and the pane rule

The app shell has breakpoints; the panes do not:

| Namespace | Token | Value | Purpose |
|---|---|---:|---|
| App shell | `appShellCompact` | 900 | rail/navigation composition |
| App shell | `appShellExpanded` | 1500 | expanded desktop chrome |

How many panes fit is one content rule shared by every layout in the kit (FR-110, `spec/application-layout-vectors.json` `panes`): two panes need navigation + list + a usable chat (`chatMinWidth` x max(1, textScale)), three need the detail as well. The former `conversationDualPane` (720) and `conversationTriplePane` (1100) breakpoints were a second answer to that question and were removed; `spec/validate.mjs` rejects a pane-count token. AppLayout, ResponsiveLayout and their wrappers use one vocabulary: `FlareApplicationResponsiveMode`, `FlareWorkspacePaneMode`, `FlareWorkspaceDetailPresentation`.

## Platform scope

All four kits implement `IMAppKit`, `AppLayout` and `DesktopAppShell`. Native navigation and system overlay behavior remain platform appropriate.

## Keyboard and focus

Traversal follows navigation, primary pane, content pane, then inline detail. Escape closes the top contextual layer and focus returns to its trigger. Hidden and overlaid panes must not remain in the accessibility traversal as duplicate content.

Flutter desktop binds `Ctrl/Cmd+K` to search, `Ctrl/Cmd+,` to settings, and `Alt+/` to more actions through host callbacks. The desktop shell exposes optional file-drop and secondary-click intents without owning upload or menu business behavior. Resizable pane handles support pointer drag and screen-reader increase/decrease actions; widths are clamped to generated pane tokens.

Composer submission is explicit on desktop: `enter` sends on Enter, while `modifierEnter` sends only on `Ctrl+Enter` or `Cmd+Enter`; `Shift+Enter` always remains a newline. Mobile keeps its dedicated send control.
