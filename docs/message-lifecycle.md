# Message Lifecycle Contract

`MessageLifecycle` is the current framework-neutral UI projection supplied by the host. It does not expose transport enums or redefine the host's authoritative state.

| Dimension | Values |
|---|---|
| Transfer | `idle`, `queued`, `transferring`, `paused`, `completed`, `failed`, `cancelled` |
| Send | `draft`, `sending`, `sent`, `failed` |
| Delivery | `serverAccepted`, `delivered`, `partiallyDelivered` |
| Read | `unread`, `partiallyRead`, `read` |
| Mutation | `normal`, `edited`, `recalled`, `deleted` |
| Ephemeral | `none`, `readOnce`, `burnAfterRead`, `expired` |

The dimensions remain orthogonal. A message can be uploaded, server accepted, partially delivered, partially read, and edited at the same time.

## Visual Projection

`MessageStatus` derives a receipt glyph from lifecycle with this precedence (five visual states, `spec/message-receipt-vectors.json`):

1. Failed send or transfer renders `failed`.
2. Draft, queued, sending, transferring, or paused renders `pending` or `sending`.
3. Read renders `read`.
4. Otherwise it renders `sent`. Delivered and partially delivered stay `sent`: there is no delivered glyph (it had no real delivery data behind it and differed from read only by colour, which fails WCAG 1.4.1).

The core SDK projects the receipt for every message (`MessageReceiptView {status, readSummary?}`); hosts pass `status` and, for their own group messages, `readSummary {readCount, unreadCount, total}`, which MessageMeta draws as "N unread" / "Read by all" in place of the check glyph.

Mutation and ephemeral terminal states are rendered by message content or placeholders, not overloaded onto delivery ticks. Vue's `MessageLike.status` is a semantic `MessageStatusState`; numeric transport status adapters are intentionally outside the package.

The host maps its authoritative model before rendering. The UI package never infers delivery from a socket state, sequence number, or server identifier.
