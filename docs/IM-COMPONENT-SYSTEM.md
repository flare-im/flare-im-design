# Flare IM Component System

## Purpose

Flare IM Design is a cross-platform component library, not an application or messaging runtime. Vue, Flutter, Compose, and SwiftUI implement one framework-neutral component contract while preserving native interaction conventions.

## Layers

| Layer | Owns | Must not own |
|---|---|---|
| Foundation | generated color, type, spacing, elevation, motion, and layout tokens | component behavior |
| General UI | buttons, inputs, feedback, overlays, navigation and layout primitives | IM policy or transport state |
| IM UI | conversations, messages, composer, media, contacts, calls and profile presentation | networking, persistence or authorization |
| Patterns | workspace composition, pane state, focus order and responsive collapse | application routing or sessions |
| Host integration | authoritative data, permissions, commands, media transport and business rules | duplicated component visuals |

General UI and IM UI are logical layers inside each platform's cohesive package. They can be physically split only when both become independently versioned, independently consumed products.

## State Model

All asynchronous surfaces distinguish initial loading, background refresh, empty, failure, offline, permission denied, unavailable, busy, and partial failure. Existing content remains visible during refresh. Recovery controls appear only when the host supplies a valid callback.

Message transfer, send, delivery, read, mutation, and ephemeral state remain orthogonal. Components emit intent; the host updates authoritative state.

## Responsive Contract

Layouts use available container width, text scale, safe areas, and host-provided pane sizes. Conversation layouts resolve to one, two, or three panes from the generated conversation breakpoints. Hidden and overlaid panes are removed from accessibility traversal rather than rendered as semantic duplicates.

## Theme Contract

Theme resolution flows from palette to semantic tokens to component semantics. Components consume only semantic or component tokens. Violet, Ocean, Forest, Sunset, Rose, and Graphite each provide light/dark message, status, focus, selection, reaction, and composer mappings. Custom themes override the same semantic color object.

## Accessibility Contract

Interactive targets are at least 48 logical pixels, named controls expose state and value, keyboard traversal follows visual order, contextual layers restore focus, status is never conveyed by color alone, large text reflows, and reduced-motion settings remove non-essential animation.

## Source Of Truth

- `spec/components.json`: public component contracts and platform symbols.
- `spec/ui-interaction-contracts.json`: framework-neutral behavior.
- `spec/scenarios/`: shared interaction and theme scenarios.
- `tokens/tokens.json` and `tokens/themes.json`: token sources.
- `docs/IM-COVERAGE.md`: generated scenario coverage.

Implementation counts prove surface coverage, not product behavior. A component is stable only when its contract, platform implementation, accessibility states, examples, and tests agree.
