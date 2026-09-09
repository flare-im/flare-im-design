---
title: RelationActionBar
---

# RelationActionBar

The relation action bar at the bottom of a contact detail page. The host owns the relation state; the component does exactly one thing with it — combine "what is the relation" with "which capabilities the host can honour" into one ordered set of buttons. The shared `relationActions(relation, capabilities)` contract decides the set, the order, which entry is primary and which are destructive, so all four platforms agree. The bar emits intent only: it never mutates the relation, never calls the network, never retries.

<div class="flare-demo flare-demo--stack"><RelationActionBarDemo /></div>

<ComponentApi name="RelationActionBar" />

Rules, in order: `none` → add (primary), block. `pendingOut` → a disabled "waiting for verification" notice plus block, and deliberately **no** add, so the request cannot be sent twice. `pendingIn` → accept (primary), reject, block. `friends` → message (primary), remove (destructive), block (destructive). `blocked` → unblock (primary) and nothing else — a blocked contact gets no message button and no friend request.

A capability that is absent or `false` hides its action rather than rendering a button that cannot work; with no capability at all the `emptyText` appears so the bar is never blank. `busy` disables every button and shows progress on the triggered one only, appending the busy text to its accessible name. `error` is a persistent alert strip with an icon, the reason and a dismiss control — the component never clears it on its own, and it does not block the remaining actions. The waiting notice for `pendingOut` ignores capabilities entirely: it reports state rather than offering a command.

The `action` payload is `{ action }` over the enum `add | accept | reject | remove | block | unblock | message`; `dismissError` only says the user wants the strip gone. Hosts set `busy` synchronously before dispatching, then write back `relation` or `error` once the SDK answers — destructive actions usually route through DangerConfirm first, which the host orchestrates.

Entries: FlareRelationActionBar (Vue/Flutter), RelationActionBarView (SwiftUI), RelationActionBar (Compose). Native callbacks: onAction(action), onDismissError(); a native bar with no onAction renders every button disabled. Buttons are at least 48×48 logical units and wrap on narrow screens without internal scrolling; the destructive group is separated by a rule and trails the primary actions. State is never colour-only — primary has a filled background plus icon, destructive has its own group, icon and error token, waiting has a clock icon plus text. See the [full integration guide](/components/relation-action-bar).
