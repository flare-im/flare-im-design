# MessageStatus

## Purpose

MessageStatus is the visual projection of the orthogonal message lifecycle, the receipt status the core SDK gives every message. It does not replace or collapse TransferState, SendState, DeliveryState, ReadState, MutationState, or EphemeralState.

## Visual Contract

Five states (`spec/message-receipt-vectors.json`):

- pending: static clock.
- sending: subtle indeterminate progress; a static clock is used when motion is reduced.
- sent: one rounded check path — the server has the message.
- read: the double-check in the messageStatusRead token — the peer read it.
- failed: error indicator in the messageStatusFailed token.

There is no delivered state: without real delivery data it differed from read only by colour, which fails WCAG 1.4.1. In groups the viewer's own sent and read messages show MessageMeta's read summary instead of a glyph.

The double-check uses one 16 x 16 drawing surface. Its two paths overlap horizontally and use 1.5 logical-pixel round strokes and joins. Implementations are SVG on Vue, CustomPainter on Flutter, Canvas on Compose, and Shape on SwiftUI.

## Behavior And Accessibility

The component is passive by default. A failed state becomes a retry control only when resend or onResend is supplied; its hit area is at least `layout.touchTarget`. Screen readers receive localized state names such as “已读” or “Sent”; drawn paths are decorative and never announced as “check” or “blue check”.

MessageStatus keeps a fixed intrinsic box at both densities. Receipt changes do not bounce, scale, pulse, or resize message content.

## Theme And Responsive

Standalone read receipts use theme-specific read blue. Self-bubble receipts use messageStatusOnOutgoing, which preserves contrast on the brand-purple surface. Meaning and geometry do not change at responsive breakpoints.
