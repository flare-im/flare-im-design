# MessageList

## Overview
Render a stable, lazy timeline with recovery and reading-anchor behavior.

## When to use
Render a stable, lazy timeline with recovery and reading-anchor behavior.

## When not to use
Do not pass an unbounded 100k in-memory projection.

## Anatomy
pagination, timeline, unread marker, latest affordance, selection layer. Regions use semantic tokens and host-owned content.

## Variants
chat, thread, search result timeline. Choose one variant from task priority, not decoration.

## Sizes
viewport-driven. Minimum interactive targets remain 48 logical pixels.

## States
loading, empty, loadingOlder, error, awayFromLatest, multiSelect. Loading preserves geometry; errors keep a recovery path.

## Interactions
Components emit intent callbacks. The host owns data, permissions, persistence, and side effects.

## Keyboard
Arrow/selection shortcuts are host-scoped; Escape exits contextual state.

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
