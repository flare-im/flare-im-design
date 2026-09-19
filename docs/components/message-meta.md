# MessageMeta

## Purpose

MessageMeta owns the low-emphasis metadata region of a message:

- preformatted timestamp
- edited state
- ephemeral/read-once state
- outgoing delivery/read state
- optional failed/retry control

Reaction remains a separate interaction region.

## Contract

Timestamp, edited, status, lifecycle, ephemeral, and density are presentational inputs. When a lifecycle is supplied, it remains orthogonal and takes precedence for mutation, ephemeral, and receipt projection.

Compact is the default bubble density; normal adds spacing without changing semantic order. Incoming messages omit status, so they never expose an outgoing receipt.

## Placement

Text, reply, forwarded, file, voice, and other framed messages place the row after content at the trailing edge. Chromeless media keeps the same content-to-meta order and places the metadata immediately after the media frame. The row reserves a stable icon-height box so sent, delivered, read, failed, and retrying transitions do not move surrounding content.

### Bare Media

- Stickers, standalone emoji (including a single emoji in a text payload), photos, and uncaptioned videos use an unframed footer, never a timestamp capsule over the artwork.
- Leave `spacing.xs` between the content and metadata. Outgoing footers align to the trailing edge; incoming footers align to the leading edge. These rules are identical on phones, tablets, and desktop.
- Use `message.metaForeground` for the time and the default receipt palette: pending/sent/delivered stay neutral, read uses the brand semantic, and failure retains its retry action. Do not use the light `onOutgoing` palette on the chat background.
- Keep timestamps visible without hover. Edited and ephemeral labels can wrap on narrow media; the status icon must remain visible. Video duration stays with the video, separate from the message timestamp below it.
- Quoted media, captioned video, text, and voice retain their existing framed presentation. Upload/download state remains independent from delivery/read state.

Vue implements this in `MessageBubble` + `MessageMeta`, matching the existing native media-footer composition. Hosts must not add their own overlay or stylesheet override.

## Accessibility

Visible metadata remains readable text in visual order. MessageStatus contributes one localized status semantic. Only retry is focusable; passive metadata stays out of the focus order.
