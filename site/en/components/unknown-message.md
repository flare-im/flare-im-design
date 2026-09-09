---
title: UnknownMessage
---

# UnknownMessage

Body for a message this client cannot render. The plan requires unknown extension messages to keep "an understandable placeholder and diagnostic information" — printing the raw `contentType` as the body (`[flare.poll.v2]`) tells the reader nothing and looks like a rendering bug. So the presentation is split in three: a human title, a human body, and the raw type kept as a diagnostic line for support and bug reports.

<div class="flare-demo flare-demo--stack"><UnknownMessageDemo /></div>

<ComponentApi name="UnknownMessage" />

The pure `unknownMessagePresentation({ contentType, label, summary, hint, unsupportedText })` decides what the four platforms show, and each platform implements and unit-tests the same function so they cannot drift. Title: `label` if the host knows a human name for the type (e.g. "投票"), else the generic `unsupportedText`. Body: `summary` — the plain-text fallback the sender's client attached, which is the most useful thing available — else the generic `hint`. Diagnostic: `contentType`, monospaced and forced LTR; when it is empty the row is not rendered at all. Every input is trimmed, so a whitespace string never counts as a value. `hasSummary` tells the host whether the body is a real fallback or the generic hint, which makes it easy to measure how many extension messages actually ship one.

The action button appears only when the host supplies **both** a handler and a label — no upgrade path means no button that does nothing, which is the "don't show affordances for unavailable features" rule applied directly.

The component is already wired into the fallback branch of `MessageContentView` on all four platforms: it renders when the content registry misses and no built-in type matches. The three natives previously showed `chip("[type]")` and Vue showed `[Unknown message type]`; all four now agree. Vue additionally passes `getContentDecodedPreview(decoded)` as the `summary`, so a preview the sender embedded becomes the body automatically — native hosts that can pull the same fallback text out of their message model should pass it too.

Renderable extension types belong in `FlareContentRegistry` (present on all four platforms), not here. This component covers only the case the registry does not: a peer on a newer version, a type still being rolled out, or a plugin that is not installed. So it performs no capability probing, no network calls and no caching.

It renders inside the bubble and takes the bubble's width; body and diagnostic text wrap, so a long type name cannot burst the bubble. With `self` the text inherits the bubble foreground instead of the secondary token, keeping contrast on the brand-coloured bubble. The diagnostic row is forced LTR so an RTL interface cannot scramble the type name. The action button is at least 48 logical units, keyboard focusable with a visible ring, and state is carried by icon plus text rather than colour. The demo runs on local state and does not stand in for end-to-end acceptance of real extension messages. See the [full integration guide](/components/unknown-message).
