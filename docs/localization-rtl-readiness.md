# Localization and RTL readiness

## Current contract

- Host-overridable string providers exist on Vue, Flutter, Compose, and SwiftUI.
- Long English fixture copy and 200% text baselines cover expansion pressure.
- IM payload text remains application data and is never translated by the kit.
- Dates, times, plurals, and locale-aware formatting remain host responsibilities.

## RTL status

`RTL_NOT_SUPPORTED_FOR_2_0_STABLE`. The implementations generally use logical
leading/trailing APIs, but full Arabic/Hebrew fixtures, mirrored directional icons,
mixed-direction message content, selection, swipe actions, and cursor behavior do not
yet have four-platform automated and physical-device evidence. Stable documentation
must not imply RTL support.

## Release checks

Use a pseudo locale with labels at least 1.8 times English length; verify Button, Input,
ConversationRow, MessageMeta, MessageBubble, Composer, dialogs, menus, errors, transfer
rows, and permission prompts. Hard-coded user-facing copy is rejected by the existing
string-provider gates. RTL is scheduled after 2.0 in `post-2.0-roadmap.md`.
