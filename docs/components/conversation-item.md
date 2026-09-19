# ConversationItem

## Overview
Scan and select a conversation while preserving unread and activity priority.

## When to use
Scan and select a conversation while preserving unread and activity priority.

## When not to use
Do not overload the row with every available conversation action.

## Anatomy
avatar, title, preview, time, unread, status. Regions use semantic tokens and host-owned content.

## Variants
direct, group, channel. Choose one variant from task priority, not decoration.

## Sizes
compact desktop, touch mobile. Minimum interactive targets remain 48 logical pixels.

## States
idle, hover, focused, selected, muted, pinned, draft, failure. Loading preserves geometry; errors keep a recovery path.

## Interactions
Components emit intent callbacks. The host owns data, permissions, persistence, and side effects.

## Keyboard
Arrow navigation in list; Enter selects; context key opens actions.

## Accessibility
Provide a localized name, role, state, availability, focus order, visible focus, and reduced-motion equivalent. Decorative imagery is hidden.

## Responsive
Preserve the primary task. Supporting regions become a drawer, sheet, overlay, or route rather than compressed desktop geometry.

## Platform differences
Vue uses ARIA and pointer conventions; Flutter uses Semantics and Focus; Compose uses semantics and native gestures; SwiftUI uses accessibility traits, Dynamic Type, and native presentation. Semantic states and intents remain identical.

## Code examples
Use the public component named in `spec/components.json`; supply controlled state and intent callbacks. See the shared fixtures in `examples/gallery/gallery-manifest.json` for deterministic examples.

## Do / Don't
Do keep task hierarchy and recovery explicit. Don't duplicate business state, invent platform-only semantics, or introduce local visual constants.
