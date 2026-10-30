# MessageMeta

## Purpose

MessageMeta owns the low-emphasis metadata region of a message:

- preformatted timestamp
- edited state
- ephemeral/read-once state
- the outgoing receipt (the SDK's `MessageReceiptView.status`), or the group read summary
- optional failed/retry control

Reaction remains a separate interaction region.

## Contract

Timestamp, edited, status, lifecycle, ephemeral, density, `placement` and `readSummary` are presentational inputs. When a lifecycle is supplied, it remains orthogonal and takes precedence for mutation, ephemeral, and receipt projection. The receipt has five states — pending, sending, sent, read, failed — and no delivered state (`spec/message-receipt-vectors.json`).

Compact is the default bubble density; normal adds spacing without changing semantic order. Incoming messages omit status, so they never expose an outgoing receipt.

## Placement

Where the row sits follows the message's surface (`spec/message-surface-vectors.json`, `spec/message-meta-placement-vectors.json`):

| Surface | Placement | Where |
| --- | --- | --- |
| bubble with text | `inline` | Inside the bubble at the trailing end of the text's last line, bottom-aligned, never over the text; when it cannot fit beside the text it drops to its own trailing row (bubbleFooter). |
| bubble with anything else | `bubbleFooter` | Inside the bubble, its own row under the content, at the trailing edge. |
| bareMedia, card | `below` | Under the surface with `spacing.xs` between them, at the trailing edge for incoming and outgoing messages alike. |
| centered (system, recall, delete) | `none` | No time, no status. |

Nothing is drawn over a picture or a card: there is no overlay pill. The row reserves a stable icon-height box so sent, read and failed transitions do not move surrounding content.

### Below a picture or a card

- Stickers, standalone emoji (including a single emoji in a text payload), photos, uncaptioned videos, plugin cards, red packets, locations, contact cards and the other card contents use an unframed footer under the surface.
- Leave `spacing.xs` between the surface and the metadata. Incoming and outgoing footers both align to the trailing edge (inline-end), the same edge as the time inside a bubble, so the time is read in one place down the whole timeline. These rules are identical on phones, tablets, and desktop.
- Use `message.metaForeground` for the time and the default receipt palette: pending and sent stay neutral, read uses the brand semantic. Do not use the light `onOutgoing` palette on the chat background.
- A failed outgoing message shows the text key "发送失败，重试" / "Failed to send. Retry" in `status.failed` in place of the receipt glyph. Inside a bubble the failed glyph is the retry key, and the bubble is the failure surface: `message.failed.background` with its text in `message.failed.foreground` and a 1px `message.failed.border` edge (`spec/message-surface-vectors.json` `palette`), so the glyph never sits on the outgoing fill. Both hit areas are at least `layout.touchTarget`; without a resend listener nothing is tappable.
- Keep timestamps visible without hover. Edited and ephemeral labels can wrap on narrow media; the status must remain visible. Video duration stays with the video, separate from the message timestamp below it.
- Quoted media and captioned video are bubbles. Upload/download state remains independent from delivery/read state.

### Group read summary

On the viewer's own messages in a group, the SDK's `readSummary` replaces the check glyph once the message is sent: "3 人未读" / "3 unread" while some members have not read it, "全部已读" / "Read by all" (in `status.read`) when all have. With a `readReceiptOpen` listener it is a text key that emits `readReceiptOpen(messageId)` and the host fills ReadReceiptSheet; without one it is plain text. The host opens ReadReceiptSheet in a BottomSheet with `fill`, passes the same summary as `readCount` / `unreadCount` (the tab numbers), starts with `state: "loading"` and appends each column's pages from the SDK's `readReceiptMembers` on `loadMore(column)`; `unavailable` covers NOT_FOUND and `available:false`, `error` offers `retry` (spec/read-receipt-vectors.json). The kit keeps that paging for the host (spec/read-receipt-list-vectors.json: Vue `useFlareReadReceiptList(key, page)`, Compose `rememberFlareReadReceiptListState(key, page)` with the `ReadReceiptSheet(list, …)` overload): the host gives one loader that reads a page of a column, names its user ids and answers null when the list is not offered. Pending, sending and failed keep their glyph. Single chats, big groups (the SDK leaves the summary empty) and messages without data show only the glyph — never a made-up number.

Vue implements this in `MessageBubble` + `MessageMeta`. Hosts must not add their own overlay or stylesheet override.

## Accessibility

Visible metadata remains readable text in visual order. MessageStatus contributes one localized status semantic. Only retry and the read summary are focusable; passive metadata stays out of the focus order. The message row's accessible name is sender, content summary, time and status (or read summary), in that order.
