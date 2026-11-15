package com.flare.im.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalAccessibilityManager
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.dismiss
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay

/** How strongly a new message asks for attention: the engine's notification channel. */
enum class FlareInAppNotificationChannel { Messages, Quiet, Mentions, Urgent }

/**
 * A message that arrived while the app is open on another screen, as the host maps it from the engine's
 * `notification.present` (surface `inApp`). Spec: InAppNotificationBanner / InAppNotificationHost.
 *
 * [collapseId]: one banner per collapse id, a newer item replaces the shown or waiting one in place. [count] above 1
 * puts the kit's "[3条]" before the body; [channel] Mentions and Urgent carry a tag and an accent; without [avatarUrl]
 * the avatar shows the initials of [title].
 */
data class FlareInAppNotification(
    val collapseId: String,
    val conversationId: String,
    val messageId: String? = null,
    val title: String,
    val body: String,
    val count: Int = 1,
    val channel: FlareInAppNotificationChannel = FlareInAppNotificationChannel.Messages,
    val avatarUrl: String? = null,
) {
    /** Whether the count goes before the body: only above one message. */
    val showsCount: Boolean get() = count > 1

    /** The tag before the body in [strings], or null for the plain channels. */
    fun tag(strings: FlareStrings = FlareStrings()): String? = when (channel) {
        FlareInAppNotificationChannel.Mentions -> strings.inAppNotificationMention
        FlareInAppNotificationChannel.Urgent -> strings.inAppNotificationUrgent
        else -> null
    }

    /** What a reader hears: New message, the title, the tag, the count and the body. */
    fun spoken(strings: FlareStrings = FlareStrings()): String = listOfNotNull(
        strings.inAppNotificationLabel,
        title,
        tag(strings),
        if (showsCount) strings.inAppNotificationCount(count) else null,
        body,
    ).filter { it.isNotEmpty() }.joinToString(", ")
}

/** How long a banner stays after it shows or is replaced, and again after a touch on it ends. */
const val IN_APP_NOTIFICATION_DURATION_MS: Long = 4000

/** Banners waiting behind the visible one; beyond this the oldest waiting one is dropped, so the newest win. */
const val IN_APP_NOTIFICATION_PENDING_LIMIT: Int = 3

/** How far up a swipe has to travel before it dismisses the banner (24 logical px on every kit). */
private val InAppNotificationSwipeDismiss = FlareSizes.spacing2xl

/** The avatar, the same on the four kits. */
private val InAppNotificationAvatarSize = 40.dp

/**
 * The presenter of the in-app new-message banner: the app feeds it and [InAppNotificationHost] draws it.
 *
 * The app forwards the engine's `notification.present` events whose surface is `inApp` to [present] and its
 * `notification.clear` events to [clear] / [clearAll], from any thread. What shows and what waits follows
 * spec/in-app-notification-vectors.json; the host owns the time on screen and starts it over whenever [revision]
 * moves. Keep one per app: a field of the app's own state, or `remember { FlareInAppNotifications() }` at the root.
 */
@Stable
class FlareInAppNotifications {
    /** The visible banner. */
    var current: FlareInAppNotification? by mutableStateOf(null)
        private set

    /** Banners waiting, oldest first, at most [IN_APP_NOTIFICATION_PENDING_LIMIT]. */
    var pending: List<FlareInAppNotification> by mutableStateOf(emptyList())
        private set

    /** Moves whenever a banner shows or the visible one is replaced. */
    var revision: Int by mutableIntStateOf(0)
        private set

    /** Shows, replaces or queues [notification]. */
    fun present(notification: FlareInAppNotification) {
        val shown = current
        if (shown == null || shown.collapseId == notification.collapseId) {
            current = notification
            revision += 1
            return
        }
        val waiting = pending.indexOfFirst { it.collapseId == notification.collapseId }
        pending = if (waiting >= 0) {
            pending.toMutableList().also { it[waiting] = notification }
        } else {
            (pending + notification).takeLast(IN_APP_NOTIFICATION_PENDING_LIMIT)
        }
    }

    /** The visible banner goes and the first waiting one shows. */
    fun dismiss() {
        val next = pending.firstOrNull()
        current = next
        pending = pending.drop(1)
        if (next != null) revision += 1
    }

    /** Takes away the banners of [collapseIds]; the visible one goes as [dismiss] says. */
    fun clear(collapseIds: Collection<String>) {
        if (collapseIds.isEmpty()) return
        pending = pending.filterNot { it.collapseId in collapseIds }
        if (current?.let { it.collapseId in collapseIds } == true) dismiss()
    }

    /** Takes every banner away. */
    fun clearAll() {
        current = null
        pending = emptyList()
    }
}

/**
 * The banner for a message that arrived while the app is open on another screen.
 * Spec: Feedback/InAppNotificationBanner (`InAppNotificationBanner`).
 *
 * Avatar (the host's `avatarUrl`, else the title's initials coloured by the conversation), the title and one line of
 * preview, both ellipsised; above one message the kit's "[3条]" goes before the body, and Mentions / Urgent put their
 * tag before it with an accent. A tap opens: [onOpen] with the item's conversation and message. A swipe up past a short
 * distance or the close key dismisses ([onDismiss]); TalkBack gets the same as the node's dismiss action.
 * [InAppNotificationHost] places the banner, queues the next ones and runs its time.
 */
@Composable
fun InAppNotificationBanner(
    notification: FlareInAppNotification,
    onOpen: ((conversationId: String, messageId: String?) -> Unit)? = null,
    onDismiss: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val strings = flareStrings()
    val colors = flareColors()
    val dismissDistance = with(LocalDensity.current) { InAppNotificationSwipeDismiss.toPx() }
    var offset by remember(notification.collapseId) { mutableFloatStateOf(0f) }
    val urgent = notification.channel == FlareInAppNotificationChannel.Urgent
    val tag = notification.tag(strings)
    val shape = RoundedCornerShape(FlareSizes.radiusXl)
    val open = { onOpen?.invoke(notification.conversationId, notification.messageId); Unit }
    Row(
        modifier
            .fillMaxWidth()
            .graphicsLayer { translationY = offset }
            .shadow(flareShadowElevation(flareShadows().lg), shape, clip = false)
            .clip(shape)
            .background(colors.bgElevated)
            .border(1.dp, if (urgent) colors.error else colors.borderSecondary, shape)
            .pointerInput(notification.collapseId) {
                detectVerticalDragGestures(
                    onDragEnd = {
                        val dismissed = offset <= -dismissDistance
                        offset = 0f
                        if (dismissed) onDismiss?.invoke()
                    },
                    onDragCancel = { offset = 0f },
                ) { change, dragAmount ->
                    change.consume()
                    offset = (offset + dragAmount).coerceAtMost(0f)
                }
            }
            .clickable(onClickLabel = strings.inAppNotificationOpenHint, role = Role.Button, onClick = open)
            .clearAndSetSemantics {
                role = Role.Button
                contentDescription = notification.spoken(strings)
                onClick(label = strings.inAppNotificationOpenHint) { open(); true }
                if (onDismiss != null) dismiss(label = strings.close) { onDismiss(); true }
            }
            .padding(FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Avatar(
            userId = notification.conversationId,
            displayName = notification.title,
            size = InAppNotificationAvatarSize,
            avatarUrl = notification.avatarUrl,
        )
        Spacer(Modifier.width(FlareSizes.spacingMd))
        Column(Modifier.weight(1f)) {
            Text(
                notification.title,
                color = colors.textPrimary,
                fontSize = FlareSizes.fontSizeLg,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.height(FlareSizes.spacing3xs))
            Text(
                buildAnnotatedString {
                    if (tag != null) {
                        withStyle(SpanStyle(color = if (urgent) colors.errorText else colors.primaryText, fontWeight = FontWeight.SemiBold)) {
                            append(tag)
                        }
                        append(" ")
                    }
                    if (notification.showsCount) {
                        append(strings.inAppNotificationCount(notification.count))
                        append(" ")
                    }
                    append(notification.body)
                },
                color = colors.textSecondary,
                fontSize = FlareSizes.fontSizeMd,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        IconButton(onClick = { onDismiss?.invoke() }, modifier = Modifier.size(FlareSizes.touchTarget)) {
            FlareIcon("close", size = FlareSizes.iconSizeSm, tint = colors.textTertiary, contentDescription = strings.close)
        }
    }
}

/**
 * Puts the in-app new-message banner on screen. Spec: Feedback/InAppNotificationHost (`InAppNotificationHost`).
 *
 * Wrap the app content with it and feed [notifications] from the engine's `notification.present` (surface `inApp`)
 * and `notification.clear` events:
 *
 * ```kotlin
 * val inApp = remember { FlareInAppNotifications() }
 * LaunchedEffect(Unit) { sdk.inAppPresentations.collect { inApp.present(it.toBanner()) } }
 * InAppNotificationHost(inApp, onOpen = { conversationId, _ -> nav.openChat(conversationId) }) { AppNavHost() }
 * ```
 *
 * The presenter decides what shows and what waits (spec/in-app-notification-vectors.json); the host owns the time:
 * each banner stays [IN_APP_NOTIFICATION_DURATION_MS] after it shows or is replaced (stretched to the system's
 * recommended accessibility timeout, which keeps it until dismissed for a person who needs that), the time stops
 * while a finger is on it and starts over when it lifts. Opening dismisses the banner and calls [onOpen]. The banner
 * sits at the top centre under the status bar, a polite live region, and slides only when motion is allowed.
 */
@Composable
fun InAppNotificationHost(
    notifications: FlareInAppNotifications,
    onOpen: ((conversationId: String, messageId: String?) -> Unit)? = null,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val reducedMotion = flareReducedMotion()
    val accessibility = LocalAccessibilityManager.current
    val current = notifications.current
    // The banner a finger is on, by collapse id: a different banner that takes its place runs its own time.
    var pressed by remember { mutableStateOf<String?>(null) }
    val held = current != null && pressed == current.collapseId
    LaunchedEffect(notifications.revision, held, current == null) {
        if (notifications.current == null || held) return@LaunchedEffect
        val timeout = accessibility?.calculateRecommendedTimeoutMillis(
            IN_APP_NOTIFICATION_DURATION_MS, containsIcons = true, containsText = true, containsControls = true,
        ) ?: IN_APP_NOTIFICATION_DURATION_MS
        if (timeout == Long.MAX_VALUE) return@LaunchedEffect
        delay(timeout)
        notifications.dismiss()
    }
    Box(modifier) {
        content()
        Box(
            Modifier
                .align(Alignment.TopCenter)
                .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal))
                .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm)
                .widthIn(max = FlareSizes.authFormMaxWidth)
                .fillMaxWidth()
                .semantics { liveRegion = LiveRegionMode.Polite },
        ) {
            AnimatedContent(
                targetState = current,
                contentKey = { it?.collapseId },
                transitionSpec = {
                    if (reducedMotion) {
                        fadeIn(snap()) togetherWith fadeOut(snap())
                    } else {
                        (slideInVertically(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)) { -it } + fadeIn(tween(FlareMotion.normal)))
                            .togetherWith(slideOutVertically(tween(FlareMotion.normal, easing = FlareMotion.normalEasing)) { -it } + fadeOut(tween(FlareMotion.normal)))
                    }
                },
                label = "in-app-notification",
            ) { shown ->
                if (shown != null) {
                    InAppNotificationBanner(
                        notification = shown,
                        onOpen = { conversationId, messageId ->
                            notifications.dismiss()
                            onOpen?.invoke(conversationId, messageId)
                        },
                        onDismiss = { notifications.dismiss() },
                        modifier = Modifier.pointerInput(shown.collapseId) {
                            awaitEachGesture {
                                awaitFirstDown(requireUnconsumed = false, pass = PointerEventPass.Initial)
                                pressed = shown.collapseId
                                waitForUpOrCancellation(PointerEventPass.Initial)
                                pressed = null
                            }
                        },
                    )
                }
            }
        }
    }
}
