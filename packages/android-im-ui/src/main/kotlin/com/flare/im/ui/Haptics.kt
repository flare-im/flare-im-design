package com.flare.im.ui

import androidx.compose.ui.hapticfeedback.HapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType

/**
 * Whether a gesture crossing from [was] to [now] deserves a tick.
 *
 * One tick per change of state, in both directions and never per frame: a finger resting past the line is
 * not a drum, and a finger trembling on it is counted by crossings. The rule is shared with the Flutter and
 * SwiftUI kits and tested against `spec/haptic-vectors.json`.
 */
internal fun flareHapticCrossed(was: Boolean, now: Boolean): Boolean = was != now

/**
 * The tick itself: the platform's *selection* feedback — the light one, not the long-press one.
 *
 * Whether it is felt at all is the reader's own system setting, which the platform primitive already
 * honours, so this kit adds no switch of its own.
 */
internal fun HapticFeedback.flareHapticTick() {
    performHapticFeedback(HapticFeedbackType.TextHandleMove)
}
