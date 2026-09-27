# Allowed Platform Differences

The spec aligns meaning and capability. It does not force DOM, Material, or SwiftUI rendering to look mechanically identical.

| Area | Vue | Flutter | Compose | SwiftUI |
|---|---|---|---|---|
| Navigation | browser history and ARIA landmarks | NavigationRail/Bar and FocusTraversal | Material navigation semantics | native navigation containers |
| Hover / context | CSS hover and context events | MouseRegion and secondary click | pointer input where hardware exists | hover/context menu where supported |
| Keyboard | DOM focus and key events | Shortcuts/Actions | focus/key input modifiers | commands/focused values |
| BottomSheet / Modal / Drawer | Teleport onto one modal-surface stack with a focus trap | root-navigator routes; Drawer keeps a nested Navigator | dialog windows with the window dim off and a token scrim | system sheet for BottomSheet; full-screen cover with a kit scrim for Modal and Drawer (iOS 16.4+) |
| Text input | browser IME/composition | EditableText composition | Compose text field/IME | native TextField/Dynamic Type |
| Motion | `prefers-reduced-motion` | `MediaQuery.disableAnimations` | system animation scale/instant state | `accessibilityReduceMotion` |
| Typography | CSS rem/line-height | logical px with text scale | sp with font scale | Dynamic Type-relative fonts |

## Overlays: BottomSheet, Modal and Drawer

One rule on every kit: a short task is a BottomSheet with `presentation` `auto` (a sheet on the phone form factor, a Modal elsewhere, resolved once when it opens), a focused wide-layout task is a Modal, and long-lived secondary content is a Drawer on wide layouts and a page on phones. The form factor comes from the kit, never from platform sniffing: Vue `platform.capabilities.value.bottomSheet`, Flutter `flareCapabilitiesOf(context).bottomSheet`, iOS `@Environment(\.flareCompactOverlays)`, Compose `flareCompactOverlays()`.

| Difference | Vue | Flutter | Compose | SwiftUI |
|---|---|---|---|---|
| Drawer on the phone form factor | a full-width drawer (web hosts do not compute the form factor) | `FlareDrawer.showAdaptive` pushes a page | the host shows a page when `flareCompactOverlays()` is true | `compactFallback: .push` pushes onto the enclosing NavigationStack |
| Pages inside a Drawer | host swaps the default slot and sets `showBack` | nested Navigator (`navigable`, the default) | host swaps content and sets `showBack` | `navigable: true` wraps a kit NavigationStack |
| Back and Escape | Escape and platform back emit `back` with `showBack`, else `close` | Escape and system back pop one page; the scrim closes the stack | one BackHandler on the dialog: `onBack`, else close; Escape via key events on the dialog root | escape action and cancel shortcut; interactive dismiss follows `dismissible` |
| Scrim | `var(--flare-color-scrim)` | `FlareColors.of(context).scrim` | `colors.scrim`, window dim off | kit scrim for Modal and Drawer; the system sheet dim for BottomSheet cannot be recoloured |
| Busy lock | reactive `dismissible` / `busy` | `busy` listenable and PopScope; a busy-capable sheet has drag-to-close off for its life | `dismissible` / `busy` | `.flareLayerDismissDisabled(_:)` read by the layer |
| Toasts above an open overlay | one page-level toast layer above the modal layer | a root-overlay entry, inserted above the routes open when the toast is shown | the topmost overlay window draws the toasts | the topmost presence entry installs the toast layer |
| Fallbacks | - | - | - | below iOS 16.4 and on macOS, Modal and Drawer fall back to a system sheet without the kit scrim |

Differences are allowed when they preserve the same state model, intent callbacks, content priority, accessible name, and recovery path. Product or protocol semantics may never be inferred differently by platform UI code.
