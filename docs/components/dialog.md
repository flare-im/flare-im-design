# Dialog

The catalog component is **Modal** (`componentContracts.Dialog` is an alias of it): Vue `FlareModal`, Flutter `FlareModal`, iOS `ModalView` with `.flareModal`, Compose `Modal`.

> Flutter's former `FlareDialog` was merged into `FlareModal` in 2.0 (see `docs/release/migration/2.0-rc-to-2.0.md` §4r).

## Overview
A centred box over a scrim for one focused task: a confirmation, a short form, a picker, or a page-like tool such as global search. The content behind the scrim is inert until the box closes.

## When to use
Use Modal on wide layouts for a task that must finish or be cancelled before the user goes back to the page. For a short task that should also work on phones, use BottomSheet with `presentation` `auto`: it is a sheet on the phone form factor and hands the same content to Modal everywhere else. DangerConfirm, FormSheet and the prompt presenters already follow that rule.

## When not to use
Do not put long-lived secondary content in a Modal (conversation, group or contact details, a settings stack, a profile editor): that belongs in Drawer, or a page on phones. Do not use it for routine navigation, and do not stack a second Modal on top when the task can continue inside the first.

## Anatomy
Scrim (`colors.scrim`), surface, optional header row (title, `actions`, close button), body, and an optional `footer` button row. The header row is omitted when there is no visible title, no actions and `showClose` is false. Regions use semantic tokens and host-owned content.

## Variants
Default: the box grows with its content up to `maxHeight` (72% of the available height) and the body scrolls. `fill`: the box is fixed at `maxHeight`, so it does not jump as results arrive (global search). `scrollable=false` gives page-like content bounded constraints and lets it own its scrolling.

## Sizes
Width defaults to the `sizes.component.sheetDialogWidth` token (480) and is clamped to the window minus twice `spacing-xl`; `width` overrides it per instance (Vue also honours `--flare-component-sheet-dialog-width`). Minimum interactive targets remain 48 logical pixels (44 pt on iOS).

## States
Closed, open, busy. `busy` and `dismissible=false` lock the box: the close button is disabled and the scrim, Escape and back do nothing until the task settles. Errors stay inside the box with a recovery path; loading preserves geometry.

## Interactions
The box emits `close` (Flutter `onClose`, iOS `onClose`, Compose `onClose`); the host owns the open state, data, permissions and side effects. Footer buttons trail on wide layouts and stack full width, primary on top, on narrow ones.

## Keyboard
Focus moves into the body on open (the first control in the content, then the header controls, then the surface); Tab is contained, including when the focused element is removed; Escape closes when dismissible; focus returns to the opener on close.

## Accessibility
The surface is a named modal dialog: Vue `role="dialog"`, `aria-modal` and `aria-label` from `title`, then `label`, then the localized "Dialog" fallback, plus `aria-busy`; Flutter names and scopes the route; iOS adds the modal trait and an escape action; Compose sets `paneTitle` and dialog semantics. Reduced motion removes the scale and fade.

## Responsive
On the phone form factor prefer BottomSheet `auto` (a sheet) or a page; Modal is the wide-layout form. The box never exceeds the window: width and height are clamped, and the safe areas are respected.

## Platform differences
Vue teleports the surface onto the shared modal-surface stack. Flutter presents it with `FlareModal.show` on the root navigator, and a `FlareModal` placed directly in `showDialog` still centres itself. Compose draws it in a dialog window with the window dim off and a token scrim, and toasts render inside the topmost overlay window. iOS 16.4+ uses a full-screen cover with a clear background and a kit-drawn scrim; below 16.4 and on macOS it falls back to a system sheet. Semantic states and intents remain identical.

## Code examples
```vue
<FlareModal :open="open" title="群公告" :busy="saving" @close="open = false">
  <p>…</p>
  <template #footer>
    <FlareButton label="取消" variant="secondary" @click="open = false" />
    <FlareButton label="发布" :loading="saving" @click="publish" />
  </template>
</FlareModal>
```
Flutter `FlareModal.show(context, title: …, footer: [...], builder: …)`; iOS `.flareModal(isPresented: $open, title: …) { … }`; Compose `Modal(onClose = …, title = …) { … }`. See the shared fixtures in `examples/gallery/gallery-manifest.json` and the `modal-busy` scenario in `spec/scenarios/rc.json`.

## Do / Don't
Do give every box an accessible name (a title, or `label` with `titleHidden`), lock it while a write runs, and keep the error inside it. Don't hand-build a centred dialog in an app, pass the removed BottomSheet `presentation="dialog"`, or introduce local scrim colours or widths.
