package com.flare.im.ui

import kotlin.math.abs
import kotlin.math.min

/** How far a message row has been dragged sideways, and whether letting go of it now starts a reply. */
internal data class SwipeReplyGesture(
    /** How far the row is drawn from its resting place, in dp. Never negative: the direction is the layout's leading edge. */
    val travel: Float,
    /** Whether releasing now replies. The affordance is fully drawn here, so the reader knows before letting go. */
    val armed: Boolean,
) {
    companion object {
        val None = SwipeReplyGesture(travel = 0f, armed = false)
    }
}

/**
 * Gesture geometry, in dp. These are distances a hand works in rather than visual styling, so they are
 * constants and not design tokens — and they are the same three numbers in the Flutter and SwiftUI kits.
 */
internal const val SWIPE_REPLY_ARM_DISTANCE = 56f
internal const val SWIPE_REPLY_MAX_TRAVEL = 72f
private const val SWIPE_REPLY_RESISTANCE = 0.35f
private const val SWIPE_REPLY_DOMINANCE = 1.25f

/**
 * The one swipe-to-reply rule, shared with the Flutter and SwiftUI kits and tested against
 * `spec/swipe-reply-vectors.json`: only the leading direction counts (mirrored under RTL), the list's own
 * scrolling wins a drag that is not mostly horizontal, and the row follows the finger to
 * [SWIPE_REPLY_ARM_DISTANCE] before resisting and stopping at [SWIPE_REPLY_MAX_TRAVEL].
 *
 * [dx] and [dy] are the drag's travel from where the finger went down, in dp.
 */
internal fun swipeReplyGesture(dx: Float, dy: Float, rtl: Boolean): SwipeReplyGesture {
    val leading = if (rtl) dx < 0f else dx > 0f
    if (!leading) return SwipeReplyGesture.None
    val horizontal = abs(dx)
    // A drag that is mostly vertical belongs to the timeline's own scrolling.
    if (horizontal < abs(dy) * SWIPE_REPLY_DOMINANCE) return SwipeReplyGesture.None
    val travel = if (horizontal <= SWIPE_REPLY_ARM_DISTANCE) {
        horizontal
    } else {
        min(SWIPE_REPLY_MAX_TRAVEL, SWIPE_REPLY_ARM_DISTANCE + (horizontal - SWIPE_REPLY_ARM_DISTANCE) * SWIPE_REPLY_RESISTANCE)
    }
    return SwipeReplyGesture(travel = travel, armed = travel >= SWIPE_REPLY_ARM_DISTANCE)
}
