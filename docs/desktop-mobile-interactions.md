# Desktop and Mobile Interactions

## Desktop contract

| Input | Intent |
|---|---|
| Primary + K | Open command palette |
| Primary + F | Search |
| Primary + N | New conversation |
| Primary + Shift + D | Toggle details |
| Escape | Close the top contextual layer |
| Secondary click | Open the host context menu |
| Pane handle drag | Resize within tokenized min/max widths |

`Primary` means Command on macOS and Control elsewhere. Shortcuts are scoped to `DesktopWorkbench`; they must not steal keystrokes from an unrelated window or browser surface. Flutter preserves the legacy Primary+K search callback only when no command-palette callback is supplied.

## Focus behavior

Tab order follows visual reading order. Dialogs trap focus through their platform dialog primitive, autofocus their primary field, and return focus to the triggering control where the platform provides a stable hook. Hidden responsive regions must not leave duplicate semantics in the accessibility tree.

## Mobile contract

Message rows support horizontal swipe-to-reply on Flutter, Compose, and iOS. The gesture is direction-aware, requires horizontal dominance, cancels rather than dismisses the message, and is disabled for system messages and while multi-select is active. Long press remains the entry to contextual actions; tap remains the primary content action.

Mobile detail surfaces use native sheets or navigation routes rather than desktop side panels. Touch targets remain at least the platform contract size and must tolerate large text without clipping.

## Host boundary

The kit emits `openSearch`, `openCommandPalette`, `newConversation`, `toggleDetails`, `filesDropped`, `swipeReply`, and selection intents. It does not create conversations, upload files, reply, or mutate message state itself.
