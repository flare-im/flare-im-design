package com.flare.im.ui

import android.os.Build
import android.view.View
import android.view.Window
import android.view.WindowInsetsController
import android.view.WindowManager
import androidx.activity.compose.BackHandler
import androidx.activity.compose.LocalOnBackPressedDispatcherOwner
import androidx.activity.findViewTreeOnBackPressedDispatcherOwner
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.MutableTransitionState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.traversalIndex
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.compose.ui.window.DialogWindowProvider

// The overlay family — BottomSheet, Modal and Drawer — shares one scaffold: a full-display dialog window with
// the platform dim switched off and the token scrim drawn instead, one back handler, Escape, the close animation
// under reduced motion, initial focus, the overlay-surface local and the toast layer of the topmost overlay.
// Each component only draws its surface.

/** The kit overlay a composable is drawn on, or null outside every overlay. */
internal enum class FlareOverlaySurfaceKind { Sheet, Modal, Drawer }

/**
 * The overlay surface the content is drawn on (formerly `LocalFlareBottomSheet`). Kit content such as
 * [MessageActionSheet] draws on that surface instead of bringing its own card; composites such as [DangerConfirm]
 * lay their buttons out for it.
 */
internal val LocalFlareOverlaySurface = staticCompositionLocalOf<FlareOverlaySurfaceKind?> { null }

/** True below a [FlarePlatformProvider]: the host declared its capabilities rather than falling back. */
internal val LocalFlarePlatformInstalled = staticCompositionLocalOf { false }

/**
 * Whether overlays take the phone form factor here: a bottom sheet for [BottomSheet]'s automatic presentation,
 * and a page rather than a [Drawer] for long-lived secondary content. An installed [FlarePlatformProvider] answers
 * with `capabilities.bottomSheet` (so a host adapter must build its capabilities from the live window width);
 * otherwise the enclosing shell's responsive mode answers (phone navigation); otherwise the window width
 * (narrower than the navigation-rail breakpoint). The kit never branches on the device model.
 */
@Composable
fun flareCompactOverlays(): Boolean = resolveCompactOverlays(
    installed = LocalFlarePlatformInstalled.current,
    capabilityBottomSheet = LocalFlarePlatform.current.capabilities.bottomSheet,
    shellMode = LocalFlareShellResponsiveMode.current,
    screenWidthDp = LocalConfiguration.current.screenWidthDp,
)

/** [flareCompactOverlays]' decision table: installed capabilities, then the shell's mode, then the window width. */
internal fun resolveCompactOverlays(
    installed: Boolean,
    capabilityBottomSheet: Boolean,
    shellMode: FlareApplicationResponsiveMode?,
    screenWidthDp: Int,
): Boolean = when {
    installed -> capabilityBottomSheet
    shellMode != null -> shellMode == FlareApplicationResponsiveMode.Mobile
    else -> screenWidthDp < FlareSizes.navigationRailMinWidth.value
}

/** The form a [BottomSheet] takes once its presentation is resolved. */
internal enum class FlareResolvedOverlay { Sheet, Modal }

/** Auto is a sheet on the phone form factor and a [Modal] elsewhere; Sheet is always a sheet. */
internal fun resolveOverlayPresentation(requested: FlareSheetPresentation, compact: Boolean): FlareResolvedOverlay =
    when (requested) {
        FlareSheetPresentation.Sheet -> FlareResolvedOverlay.Sheet
        FlareSheetPresentation.Auto -> if (compact) FlareResolvedOverlay.Sheet else FlareResolvedOverlay.Modal
    }

/** A drawer never covers the whole window: at most the window minus a touch target, so a scrim gutter stays tappable. */
internal fun flareDrawerWidth(requested: Dp, available: Dp): Dp =
    minOf(requested, available - FlareSizes.touchTarget).coerceAtLeast(0.dp)

/** A modal keeps a spacing-xl margin on both sides of the window. */
internal fun flareModalWidth(requested: Dp, available: Dp): Dp =
    minOf(requested, available - FlareSizes.spacingXl * 2).coerceAtLeast(0.dp)

/** Share of the available height an overlay takes when the host gives no maxHeight (Vue's 72vh). */
internal const val FLARE_OVERLAY_HEIGHT_SHARE = 0.72f

/**
 * The height cap of an overlay surface: the host's [requested] cap, else 72% of [available] (the window after
 * the keyboard and the safe area), and never more than [ceiling].
 */
internal fun flareOverlayMaxHeight(requested: Dp?, available: Dp, ceiling: Dp = available): Dp {
    val limit = ceiling.coerceAtLeast(0.dp)
    return (requested ?: available * FLARE_OVERLAY_HEIGHT_SHARE).coerceIn(0.dp, limit)
}

/**
 * Whether a drawer at [placement] enters from the physical right. Slide offsets are absolute (they do not mirror
 * under RTL), so the side comes from the placement and the layout direction together.
 */
internal fun flareDrawerSlidesFromRight(placement: FlareDrawerPlacement, direction: LayoutDirection): Boolean =
    (placement == FlareDrawerPlacement.End) != (direction == LayoutDirection.Rtl)

/** The sign of the horizontal slide offset (a fraction of the surface width) that hides a drawer at [placement]. */
internal fun flareDrawerSlideSign(placement: FlareDrawerPlacement, direction: LayoutDirection): Int =
    if (flareDrawerSlidesFromRight(placement, direction)) 1 else -1

/** What system back and Escape do on an overlay. */
internal enum class FlareOverlayBackAction { Ignore, Back, Close }

/** A locked overlay swallows back; one showing a back control steps back; any other closes. */
internal fun resolveOverlayBack(dismissible: Boolean, showBack: Boolean): FlareOverlayBackAction = when {
    !dismissible -> FlareOverlayBackAction.Ignore
    showBack -> FlareOverlayBackAction.Back
    else -> FlareOverlayBackAction.Close
}

/**
 * The scrim is announced as a close action only when it is the overlay's one close affordance: with a header
 * close button TalkBack would otherwise read two "close" nodes, and a locked overlay offers no close at all.
 */
internal fun flareScrimAnnounced(dismissible: Boolean, showClose: Boolean): Boolean = dismissible && !showClose

/** The header row exists only when it has something to show. */
internal fun flareOverlayHeaderVisible(
    title: String?,
    titleHidden: Boolean,
    hasActions: Boolean,
    showClose: Boolean,
    showBack: Boolean,
): Boolean = (!title.isNullOrBlank() && !titleHidden) || hasActions || showClose || showBack

/** The overlay's accessible name: its title, else the host's label, else the kit's fallback name. */
internal fun flareOverlayPaneTitle(title: String?, label: String?, fallback: String): String =
    title?.takeIf { it.isNotBlank() } ?: label?.takeIf { it.isNotBlank() } ?: fallback

/**
 * The overlays open under one [FlareToastHost], in opening order. Toasts are drawn in the activity window, which
 * sits under every dialog window, so the host draws its toast layer only while no overlay is open and the topmost
 * overlay draws it in its own window instead.
 */
@Stable
internal class FlareOverlayStack(val toasts: FlareToastState) {
    private val open = mutableStateListOf<Any>()

    val isEmpty: Boolean get() = open.isEmpty()

    fun push(token: Any) {
        if (open.none { it === token }) open += token
    }

    fun remove(token: Any) {
        open.removeAll { it === token }
    }

    fun isTop(token: Any): Boolean = open.lastOrNull() === token
}

internal val LocalFlareOverlayStack = staticCompositionLocalOf<FlareOverlayStack?> { null }

/** The window box an overlay surface is laid out in (after [FlareOverlayScaffold]'s bounds modifier). */
internal data class FlareOverlayBounds(val width: Dp, val height: Dp)

/**
 * The shared overlay window. Composing it shows it; [onClose] runs after the exit animation (at once under
 * reduced motion), and a host that keeps it composed after onClose sees it come back. While [dismissible], a tap
 * on the scrim closes it and system back / Escape either close it or, with [onBack], step back; while not, they
 * are swallowed. [scrimLabel] names the scrim's close action for TalkBack (null leaves it unannounced).
 * [surface] draws the panel inside [bounds] and gets the animated close.
 */
@Composable
internal fun FlareOverlayScaffold(
    kind: FlareOverlaySurfaceKind,
    onClose: () -> Unit,
    dismissible: Boolean,
    scrim: Color,
    scrimLabel: String?,
    contentAlignment: Alignment,
    enter: EnterTransition,
    exit: ExitTransition,
    onBack: (() -> Unit)? = null,
    lightStatusBars: Boolean? = null,
    boundsModifier: Modifier = Modifier,
    focusKey: Any? = null,
    surface: @Composable (close: () -> Unit, bounds: FlareOverlayBounds) -> Unit,
) {
    val reducedMotion = flareReducedMotion()
    val currentOnClose by rememberUpdatedState(onClose)
    val currentOnBack by rememberUpdatedState(onBack)
    val currentDismissible by rememberUpdatedState(dismissible)
    val shown = remember { MutableTransitionState(reducedMotion) }
    var closing by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { shown.targetState = true }
    val close: () -> Unit = {
        if (currentDismissible && !closing) {
            if (reducedMotion) currentOnClose() else { closing = true; shown.targetState = false }
        }
    }
    val currentClose by rememberUpdatedState(close)
    if (closing && shown.isIdle && !shown.currentState) {
        LaunchedEffect(Unit) {
            currentOnClose()
            // Still composed after onClose: the host kept the overlay, so it comes back.
            closing = false
            shown.targetState = true
        }
    }
    val back: () -> Unit = {
        when (resolveOverlayBack(currentDismissible, currentOnBack != null)) {
            FlareOverlayBackAction.Ignore -> Unit
            FlareOverlayBackAction.Back -> currentOnBack?.invoke()
            FlareOverlayBackAction.Close -> currentClose()
        }
    }
    val currentBack by rememberUpdatedState(back)

    // Registered in the activity composition, in opening order: the last one draws the toasts.
    val overlays = LocalFlareOverlayStack.current
    val token = remember { Any() }
    DisposableEffect(overlays, token) {
        overlays?.push(token)
        onDispose { overlays?.remove(token) }
    }

    // The dialog window mirrors the layout direction of the composition that opened it, so the panel's edge, its
    // corners and its slide agree with the host (a subtree that sets its own direction included).
    val direction = LocalLayoutDirection.current
    Dialog(
        onDismissRequest = { currentBack() },
        properties = DialogProperties(
            // One kit back handler decides instead (below): locked, step back, or close with the animation.
            dismissOnBackPress = false,
            dismissOnClickOutside = false,
            usePlatformDefaultWidth = false,
            decorFitsSystemWindows = false,
        ),
    ) {
        FlareEdgeToEdgeDialogWindow()
        FlareOverlayWindowChrome(lightStatusBars)
        FlareDialogLocals(direction) {
            // Registered after the dialog's own callback, so it wins; a page composed deeper inside the overlay (a
            // FlareScreen with a back action) registers later still and wins over this.
            BackHandler { currentBack() }
            Box(
                Modifier.fillMaxSize().onPreviewKeyEvent { event ->
                    // Both halves of the key are consumed, or the dialog would map the key-up to a second back.
                    if (event.key == Key.Escape) {
                        if (event.type == KeyEventType.KeyDown) currentBack()
                        true
                    } else {
                        false
                    }
                },
            ) {
                AnimatedVisibility(
                    visibleState = shown,
                    enter = if (reducedMotion) EnterTransition.None else fadeIn(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)),
                    exit = if (reducedMotion) ExitTransition.None else fadeOut(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)),
                ) {
                    Box(Modifier.fillMaxSize().background(scrim))
                }
                // The scrim's tap target; a tap on the surface never reaches it.
                Box(
                    Modifier.fillMaxSize()
                        .pointerInput(Unit) { detectTapGestures { currentClose() } }
                        .then(
                            if (scrimLabel != null && dismissible) {
                                Modifier.semantics {
                                    contentDescription = scrimLabel
                                    traversalIndex = 1f
                                    onClick { currentClose(); true }
                                }
                            } else {
                                Modifier
                            },
                        ),
                )
                BoxWithConstraints(Modifier.fillMaxSize().then(boundsModifier), contentAlignment = contentAlignment) {
                    val bounds = FlareOverlayBounds(maxWidth, maxHeight)
                    AnimatedVisibility(visibleState = shown, enter = enter, exit = exit) {
                        FlareOverlayFocusScope(focusKey) {
                            CompositionLocalProvider(LocalFlareOverlaySurface provides kind) {
                                surface(close, bounds)
                            }
                        }
                    }
                }
                if (overlays != null && overlays.isTop(token)) {
                    FlareToastLayer(overlays.toasts, Modifier.align(Alignment.TopCenter))
                }
            }
        }
    }
}

/**
 * The dialog content's locals: the opener's layout [direction], and back on the dialog window's own dispatcher —
 * never the activity's, even when a host provided the activity's owner as a composition local, which the dialog
 * content would otherwise inherit.
 */
@Composable
private fun FlareDialogLocals(direction: LayoutDirection, content: @Composable () -> Unit) {
    val owner = LocalView.current.findViewTreeOnBackPressedDispatcherOwner()
    CompositionLocalProvider(LocalLayoutDirection provides direction) {
        if (owner != null) CompositionLocalProvider(LocalOnBackPressedDispatcherOwner provides owner, content = content) else content()
    }
}

/**
 * Keyboard users land inside the overlay: on open (unless the content already focused one of its own controls,
 * such as a prompt's field) and whenever [focusKey] changes (a drawer stepping to another page), focus moves to
 * the surface. Focus returns to the opener on its own when the dialog window goes away.
 */
@Composable
private fun FlareOverlayFocusScope(focusKey: Any?, content: @Composable () -> Unit) {
    val requester = remember { FocusRequester() }
    var focusedInside by remember { mutableStateOf(false) }
    var opened by remember { mutableStateOf(false) }
    Box(Modifier.onFocusChanged { focusedInside = it.hasFocus }.focusRequester(requester).focusable()) { content() }
    LaunchedEffect(focusKey) {
        // Let the content's own focus requests of this frame run first.
        withFrameNanos {}
        if (!opened && focusedInside) {
            opened = true
            return@LaunchedEffect
        }
        opened = true
        runCatching { requester.requestFocus() }
    }
}

/**
 * The overlay's dialog window: no platform dim (the kit draws the token scrim instead, which the dim would
 * darken), and, for a full-height surface, status-bar icons that stay legible on it.
 */
@Composable
private fun FlareOverlayWindowChrome(lightStatusBars: Boolean?) {
    val view = LocalView.current
    val window = (view.parent as? DialogWindowProvider)?.window
    DisposableEffect(window, lightStatusBars) {
        if (window != null) {
            window.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
            if (lightStatusBars != null) window.flareLightStatusBars(lightStatusBars)
        }
        onDispose {}
    }
}

private fun Window.flareLightStatusBars(light: Boolean) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        insetsController?.setSystemBarsAppearance(
            if (light) WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS else 0,
            WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS,
        )
    } else {
        @Suppress("DEPRECATION")
        decorView.systemUiVisibility = if (light) {
            decorView.systemUiVisibility or View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        } else {
            decorView.systemUiVisibility and View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR.inv()
        }
    }
}

/**
 * The header row of a [Modal] or [Drawer]: `[back?] title … [actions] [close?]`. Back and close are 48 dp kit icon
 * controls labelled from the strings table; while the overlay is locked they stay in place, disabled.
 */
@Composable
internal fun FlareOverlayHeader(
    title: String?,
    titleHidden: Boolean,
    showBack: Boolean,
    showClose: Boolean,
    enabled: Boolean,
    onBack: () -> Unit,
    onClose: () -> Unit,
    actions: (@Composable RowScope.() -> Unit)?,
) {
    val colors = flareColors()
    val strings = flareStrings()
    Row(
        Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingXs, vertical = FlareSizes.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (showBack) {
            IconButton(icon = "back", contentDescription = strings.back, disabled = !enabled, onClick = onBack)
        } else {
            Spacer(Modifier.width(FlareSizes.spacingMd))
        }
        if (!title.isNullOrBlank() && !titleHidden) {
            Text(
                title,
                color = colors.textPrimary,
                fontSize = FlareSizes.fontSize2xl.value.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f).semantics { heading() },
            )
        } else {
            Spacer(Modifier.weight(1f))
        }
        actions?.invoke(this)
        if (showClose) {
            IconButton(icon = "close", contentDescription = strings.close, disabled = !enabled, onClick = onClose)
        } else {
            Spacer(Modifier.width(FlareSizes.spacingMd))
        }
    }
}
