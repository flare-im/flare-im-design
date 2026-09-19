package com.flare.im.ui

import androidx.compose.runtime.State
import androidx.compose.runtime.compositionLocalOf

/** The mark a located row wears while the reader's eye catches up with the jump. */
internal data class LocateHighlight(
    /** Whether the row is marked at all. False once the window is over. */
    val marked: Boolean,
    /** The ring's opacity. */
    val alpha: Float,
    /** How far the ring reaches beyond the bubble's edge, in dp. */
    val spread: Float,
) {
    companion object {
        val None = LocateHighlight(marked = false, alpha = 0f, spread = 0f)
    }
}

/** How long a located row stays marked. One number: the ring reaches nothing exactly as the window closes. */
internal const val LOCATE_HIGHLIGHT_DURATION_MS = 1600

private val stops = listOf(
    Triple(0f, 0.36f, 0f),
    Triple(700f, 0.18f, 10f),
    Triple(LOCATE_HIGHLIGHT_DURATION_MS.toFloat(), 0f, 18f),
)

/**
 * Held still for a reader who asked for less motion: the middle stop, for the whole window. Less motion is
 * not no answer — the jump still has to say where it landed.
 */
private val reducedMotionMark = LocateHighlight(marked = true, alpha = 0.18f, spread = 10f)

/**
 * The one locate-mark rule, shared with the Flutter and SwiftUI kits and with Vue's stylesheet, and tested
 * against `spec/locate-highlight-vectors.json`. [elapsedMs] counts from the moment the list started moving
 * towards the row.
 */
internal fun locateHighlight(elapsedMs: Float, reducedMotion: Boolean): LocateHighlight {
    if (elapsedMs >= LOCATE_HIGHLIGHT_DURATION_MS) return LocateHighlight.None
    if (reducedMotion) return reducedMotionMark
    val elapsed = if (elapsedMs < 0f) 0f else elapsedMs
    for (i in 0 until stops.size - 1) {
        val (fromAt, fromAlpha, fromSpread) = stops[i]
        val (toAt, toAlpha, toSpread) = stops[i + 1]
        if (elapsed > toAt) continue
        val t = (elapsed - fromAt) / (toAt - fromAt)
        return LocateHighlight(
            marked = true,
            alpha = fromAlpha + (toAlpha - fromAlpha) * t,
            spread = fromSpread + (toSpread - fromSpread) * t,
        )
    }
    return LocateHighlight.None
}

/**
 * Which row is marked after a jump, and the clock the mark reads. The list owns both and provides them; a
 * bubble takes the mark only when it is the marked one. The clock is a [State] read inside the drawing
 * lambda, so a running mark repaints one row rather than recomposing the rows in the viewport.
 */
internal class LocateHighlightHost(
    val messageId: String?,
    val elapsedMs: State<Float>,
    val reducedMotion: Boolean,
)

internal val LocalLocateHighlight = compositionLocalOf<LocateHighlightHost?> { null }
