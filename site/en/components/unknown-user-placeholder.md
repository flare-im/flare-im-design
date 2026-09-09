---
title: UnknownUserPlaceholder
---

# UnknownUserPlaceholder

Contact rows, group member lists and message senders do not always resolve to a person the host can describe: the id resolved to nothing, the account was deactivated, it is blocked, or it is simply not contactable right now. Each of those needs an understandable presentation rather than a blank row — or, worse, a raw user id promoted to the title. This component is that placeholder: a neutral avatar, a title that states the reason, an icon unique to the state, and the id demoted to a diagnostic line. Pure display: no actions, no callbacks, no I/O.

<div class="flare-demo flare-demo--stack"><UnknownUserPlaceholderDemo /></div>

<ComponentApi name="UnknownUserPlaceholder" />

Kinds and their defaults: `unknown` ("未知用户", person outline, neutral), `deactivated` ("该账号已注销", person-off, neutral), `blocked` ("该账号已被屏蔽", no-sign, danger tone), `unreachable` ("暂时无法联系该账号", lock, warning tone). Every kind carries its own icon and its own text, so the state is never colour-only, and the avatar slot is a neutral silhouette — never an emoji.

Rules come from two shared pure functions, implemented identically on all four platforms. `unknownUserPresentation(kind)` maps a kind to its icon and tone and degrades an absent or unrecognised kind to `unknown` instead of rendering blank. `shortenUserId(userId, maxLength)` trims the id and middle-elides it to `idMaxLength` characters (24 by default, floored at 8), so a 64-character id never becomes the widest thing on screen; a blank id removes the diagnostic line entirely rather than leaving an empty `ID` label.

`density` picks the shape: `row` (44px avatar, single-line title, minimum height 48) drops into a bounded list; `card` (64px avatar, centred, secondary surface) sits at the top of a detail page. `detail` inserts one host-supplied line between the title and the id.

Hosts decide the kind — unresolved lookup, deactivated account, block list, privacy restriction — and the component never guesses, requests or retries.

Entries: FlareUnknownUserPlaceholder (Vue/Flutter), UnknownUserPlaceholderView (SwiftUI), UnknownUserPlaceholder (Compose). No events on any platform. Ids stay LTR in RTL layouts (`bdi dir="ltr"`, `Directionality`, the `layoutDirection` environment value); the block reads as one accessibility element named reason first, host detail second, and the full — not elided — id last, and holds no focusable control. See the [full integration guide](/components/unknown-user-placeholder).
