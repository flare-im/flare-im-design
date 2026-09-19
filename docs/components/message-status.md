# MessageStatus

## Purpose

MessageStatus is the visual projection of the orthogonal message lifecycle. It does not replace or collapse TransferState, SendState, DeliveryState, ReadState, MutationState, or EphemeralState.

## Visual Contract

- pending: static clock.
- sending and retrying: subtle indeterminate progress; a static clock is used when motion is reduced.
- sent: one rounded check path.
- delivered: compact double-check in the messageStatusDelivered token.
- read: the exact same double-check geometry in the messageStatusRead token.
- failed: error indicator in the messageStatusFailed token.

The double-check uses one 16 x 16 drawing surface. Its two paths overlap horizontally and use 1.5 logical-pixel round strokes and joins. Implementations are SVG on Vue, CustomPainter on Flutter, Canvas on Compose, and Shape on SwiftUI.

## Behavior And Accessibility

The component is passive by default. A failed state becomes a retry control only when resend or onResend is supplied. Screen readers receive localized state names such as “已送达” or “Read”; drawn paths are decorative and never announced as “check” or “blue check”.

MessageStatus keeps a fixed intrinsic box at both densities. Receipt changes do not bounce, scale, pulse, or resize message content.

## Theme And Responsive

Standalone read receipts use theme-specific read blue. Self-bubble receipts use messageStatusOnOutgoing, which preserves contrast on the brand-purple surface. Meaning and geometry do not change at responsive breakpoints.
