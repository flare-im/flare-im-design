# Drawer

Vue `FlareDrawer`, Flutter `FlareDrawer` (`show` / `showAdaptive`), iOS `DrawerView` with `.flareDrawer`, Compose `Drawer`.

## Overview
A full-height panel that slides in from the inline end (default) or start edge over a scrim. It carries long-lived secondary content beside the main view while keeping that view visible behind it.

## When to use
Conversation, group and contact details, settings stacks, a profile editor, or in-conversation search on wide layouts. On the phone form factor the same content is a page: Flutter `FlareDrawer.showAdaptive`, iOS `compactFallback: .push`, and Compose hosts deciding with `flareCompactOverlays()`; a host layout fact such as a single-pane window wins. Vue draws the drawer full width on phones instead.

## When not to use
Do not use a Drawer for a short, focused task (use BottomSheet `auto`), for a real navigation destination (use a page), or to duplicate an inline detail pane that already fits: the AppLayout inline and overlay detail columns stay non-modal. Do not open a second Drawer from inside one; push a page inside it instead.

## Anatomy
Scrim (`colors.scrim`), surface (`bgPrimary`, start corners `radius-xl`, token shadow, safe areas consumed), optional header row ([back] title … `actions` [close]), body, and a sticky `footer`. The header row is omitted when there is no visible title, no actions and `showClose` is false, which is the case for page content that brings its own header.

## Variants
`placement` `end` (default) or `start`, mirrored under RTL. Navigable: the host swaps pages inside the drawer and turns on `showBack` (Vue, Compose), or the kit keeps a nested navigation stack (Flutter `navigable`, iOS `navigable`).

## Sizes
Width defaults to the `sizes.component.sheetWidth` token (420) and is clamped to the window minus one touch target so a scrim gutter always remains; `width` overrides it per instance (Vue also honours `--flare-component-sheet-width`). Minimum interactive targets remain 48 logical pixels (44 pt on iOS).

## States
Closed, open, nested (a page pushed inside). `dismissible=false` locks the drawer: the header buttons are disabled and the scrim, Escape and back do nothing, for example while a page inside it is saving.

## Interactions
The drawer emits `close` and, when `showBack` is set, `back`; the host owns the open state, the page stack, data and side effects. The scrim and the close button close the whole drawer; Escape and system back go back one page first.

## Keyboard
Focus moves into the body on open (skipping the header chrome); Tab is contained, including after a page swap removes the focused element; after a page swap focus moves to the heading; Escape goes back one page or closes; focus returns to the opener on close.

## Accessibility
The surface is a named modal dialog: Vue `role="dialog"`, `aria-modal` and `aria-label` from `title`, then `label`, then the localized "Side panel" fallback; Flutter names and scopes the route and labels the scrim with the modal-barrier dismiss label; iOS adds the modal trait, an escape action and a cancel shortcut; Compose sets `paneTitle` and dialog semantics. Reduced motion removes the slide.

## Responsive
Full height at the inline edge on wide layouts; a page on the phone form factor (Vue: a full-width drawer). The width is clamped so the scrim gutter remains on any window.

## Platform differences
Vue teleports the surface onto the shared modal-surface stack and is full width on phones rather than falling back to a page. Flutter presents a root-navigator route with a nested Navigator: the scrim closes the whole stack while Escape and system back pop one page, and `showAdaptive` pushes a page on phones. Compose draws a dialog window with the window dim off, a token scrim and one BackHandler that routes back to `onBack` or close. iOS 16.4+ uses a full-screen cover with a clear background and a kit-drawn panel, falls back to a system sheet below 16.4 and on macOS, and pushes a page in compact width with `compactFallback: .push`. Semantic states and intents remain identical.

## Code examples
```vue
<FlareDrawer :open="open" :title="page === 'root' ? '群设置' : '群成员'" :show-back="page !== 'root'"
  @back="page = 'root'" @close="open = false">
  <GroupSettingsPage v-if="page === 'root'" @members="page = 'members'" />
  <GroupMembersPage v-else />
</FlareDrawer>
```
Flutter `FlareDrawer.showAdaptive(context, asPage: singlePane, label: …, builder: …)`; iOS `.flareDrawer(isPresented: $showDetails, label: …, navigable: true, compactFallback: .push) { … }`; Compose `if (flareCompactOverlays()) page else Drawer(onClose = …, label = …, showClose = false) { … }`. See the shared fixtures in `examples/gallery/gallery-manifest.json` and the `drawer-open-back` scenario in `spec/scenarios/rc.json`.

## Do / Don't
Do name every drawer (a title, or `label` when the page draws its own header), keep one back claim, and lock it while a page inside is saving. Don't close one overlay and open a sibling to fake navigation, pass the removed BottomSheet `presentation="drawer"`, or introduce local widths and scrim colours.
