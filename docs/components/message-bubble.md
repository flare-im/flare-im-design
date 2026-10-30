# MessageBubble

## Overview
Present one message, lifecycle, content, and contextual actions.

## When to use
Present one message, lifecycle, content, and contextual actions.

## When not to use
Do not embed authoritative send or mutation rules in the bubble.

## Anatomy
sender, content, metadata, lifecycle, reactions, action affordance. Regions use semantic tokens and host-owned content.

## Surface
The kit picks the surface from the content (`spec/message-surface-vectors.json`, `surface` prop to override): `bubble` (text, rich text, voice, file, album, captioned video, quoted content), `bareMedia` (picture, uncaptioned video, sticker, emoji, a lone emoji), `card` (every plugin card including red packets and polls, location, contact card, link card, task, schedule, announcement, mini program, merged forward, thread) and `centered` (system notices, recall and delete notices). A card is never put inside a bubble: the card's own shell is the surface and the bubble draws no background, border, padding, tail or shadow around it. Outgoing and incoming cards differ by alignment only. Hosts register a surface (`card` or `bareMedia`) only for a content type the kit does not know.

A bubble is drawn by its fill, never by an outline (`palette` in the same table): incoming takes `message.incoming.background` with `message.incoming.foreground`, outgoing `message.outgoing.background` with `message.outgoing.foreground`. The viewer's own failed message is the failure surface: `message.failed.background`, its text in `message.failed.foreground`, and a 1px `message.failed.border` edge — the one edge a bubble has, because there it carries the failure. Its failed glyph is the retry key. Every other status keeps the side's palette, and a failed card or picture keeps its own surface with the retry text key below it.

## Variants
self, other, system, content-type. Choose one variant from task priority, not decoration.

## Sizes
content-driven. Minimum interactive targets remain 48 logical pixels.

## States
pending, sending, sent, read (single chats: double check; groups: the read summary), failed, selected, edited, recalled, deleted, ephemeral. Loading preserves geometry; errors keep a recovery path.

## Multi-select
While the list is in multi-select every control inside the content is inert (poll options, task boxes, plugin keys and menus, links, media) and a tap anywhere on the row toggles its selection.

## Interactions
Components emit intent callbacks. The host owns data, permissions, persistence, and side effects.

## Keyboard
Context key opens actions; shortcuts apply only when row focus is explicit.

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
