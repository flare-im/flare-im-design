# Specialized Message Contract

`MessageContentKind` is a UI projection over Core wire content, not a second protocol enum. The 26 presentation kinds cover text, rich text, Markdown, code, image groups, media, files, location, contact cards, links, polls, tasks, calendar events, mini apps, topics, system/notice, forwarding, replies, threads, and ephemeral treatments.

## Composition

`MessageBubble` composes `MessageContentHost`, optional reply/forward context, reactions, and `MessageMeta`. The host selects a renderer from the kind/family and supplies capabilities. Unknown product content uses the registered extension point and a safe fallback; one giant message switch is not the public extension model.

`reply`, `threadRoot`, `ephemeral`, `readOnce`, and `burnAfterRead` are presentation treatments. They do not create metadata aliases or replace lifecycle dimensions. `TransferState` remains independent from message send, delivery, and read state.

## Rich Content

Rich text preserves headings, emphasis, links, mentions, emoji, quotes, lists, inline code, code blocks, and selectable text where platform APIs permit. Code content uses a monospace face, horizontal scrolling for long lines, a named language when known, and a copy intent. Link previews expose loading, resolved, failed, missing-image, and blocked states without making unsafe URLs actionable.

## Media

Image, video, audio, and file capabilities are projected separately from lifecycle: open/save/zoom/swipe; play/pause/fullscreen; play/pause/seek; and open/save/reveal. Transfer failures expose retry without changing send state. Native viewers and file reveal behavior may differ by platform.

## Nesting

Merged forwarding is a bounded host composition. Deleted, recalled, or unavailable quote targets use a finite placeholder and preserve jump intent only when a target exists. Thread is a side panel on wide desktop and a page/sheet on compact layouts.
