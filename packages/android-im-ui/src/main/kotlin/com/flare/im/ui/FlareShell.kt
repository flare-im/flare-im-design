package com.flare.im.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf

// The shell contract (FR-095): a shell measures its own box and hands the mode down, keeps each destination it has
// shown, and steps its phone navigation aside while the active destination shows a page beyond its root.

/**
 * The responsive mode the nearest shell resolved from its own box, or null outside any shell. A pane frame inside a
 * shell takes this mode; one outside any shell resolves its own.
 */
val LocalFlareShellResponsiveMode = staticCompositionLocalOf<FlareApplicationResponsiveMode?> { null }

/** A shell destination's count of the pages beyond its root that are showing inside it. */
internal class FlareDestinationDepthRegistry {
    var depth by mutableIntStateOf(0)
        private set

    fun enter() {
        depth += 1
    }

    fun leave() {
        depth = (depth - 1).coerceAtLeast(0)
    }
}

internal val LocalFlareDestinationDepth = staticCompositionLocalOf<FlareDestinationDepthRegistry?> { null }

/**
 * While [active] is true, the composable calling this is a page beyond the root of the destination it is shown in: a
 * detail, a sub-page, a chat that took the list's place. The shell hides its phone navigation while the active
 * destination has one. Kit pages declare themselves ([FlareScreen] with a back action, a pane frame showing a pane
 * other than its root); a page the host draws itself calls this. Outside a shell it does nothing.
 */
@Composable
fun FlareDestinationDepth(active: Boolean) {
    val registry = LocalFlareDestinationDepth.current ?: return
    DisposableEffect(registry, active) {
        if (active) registry.enter()
        onDispose { if (active) registry.leave() }
    }
}

/** The destinations a shell keeps: every one opened so far whose navigation item still exists, and the active one. */
internal fun flareShellDestinations(visited: List<String>, active: String, known: Set<String>): List<String> {
    val kept = visited.filter { it == active || it in known }
    return if (active in kept) kept else kept + active
}

/** The phone navigation shows unless the active destination has a page beyond its root; a rail always shows. */
internal fun flareShellNavigationVisible(mode: FlareApplicationResponsiveMode, activeDepth: Int): Boolean =
    mode != FlareApplicationResponsiveMode.Mobile || activeDepth == 0
