# Allowed Platform Differences

The spec aligns meaning and capability. It does not force DOM, Material, or SwiftUI rendering to look mechanically identical.

| Area | Vue | Flutter | Compose | SwiftUI |
|---|---|---|---|---|
| Navigation | browser history and ARIA landmarks | NavigationRail/Bar and FocusTraversal | Material navigation semantics | native navigation containers |
| Hover / context | CSS hover and context events | MouseRegion and secondary click | pointer input where hardware exists | hover/context menu where supported |
| Keyboard | DOM focus and key events | Shortcuts/Actions | focus/key input modifiers | commands/focused values |
| Dialog / drawer | portal and focus trap | Navigator/Overlay/Drawer | Dialog/Sheet/Drawer | sheet/popover/navigation presentation |
| Text input | browser IME/composition | EditableText composition | Compose text field/IME | native TextField/Dynamic Type |
| Motion | `prefers-reduced-motion` | `MediaQuery.disableAnimations` | system animation scale/instant state | `accessibilityReduceMotion` |
| Typography | CSS rem/line-height | logical px with text scale | sp with font scale | Dynamic Type-relative fonts |

Differences are allowed when they preserve the same state model, intent callbacks, content priority, accessible name, and recovery path. Product or protocol semantics may never be inferred differently by platform UI code.
