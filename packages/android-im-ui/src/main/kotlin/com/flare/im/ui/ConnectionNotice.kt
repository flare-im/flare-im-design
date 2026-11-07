package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import kotlinx.coroutines.delay
import kotlin.math.roundToInt

/** Where the IM connection stands: the core SDK's `connection://status` phase (the Vue `FlareConnectionPhase`). */
enum class FlareConnectionPhase {
    Idle, Connecting, Syncing, Online, Switching, Reconnecting, WaitingForNetwork, ServiceUnavailable, ActionRequired,
}

/** The line's quality while online. Neither value shows a banner. */
enum class FlareConnectionQuality { Good, Poor }

/** Why the core stopped and waits for the user ([FlareConnectionPhase.ActionRequired]): the reasons the notice explains. */
enum class FlareConnectionActionReason {
    Kicked, Expired, UpgradeRequired, TenantUnavailable;

    /** The SDK's wire value (`kicked`, `expired`, `upgradeRequired`, `tenantUnavailable`). */
    val wire: String get() = name.replaceFirstChar { it.lowercase() }

    companion object {
        /** The reason [wire] names; null for any other text or none. */
        fun parse(wire: String?): FlareConnectionActionReason? = entries.firstOrNull { it.wire == wire }
    }
}

/**
 * The core SDK's connection status as the host receives it from `connection://status`: [quality] while
 * online, [progress] (0 to 1) while syncing, [nextRetryAt] (epoch milliseconds on the device clock) and
 * [attempt] (not shown) while reconnecting, [reason] as the SDK says it, and [developmentMode] while the SDK
 * runs on development endpoints.
 *
 * [reason] is any text: actionRequired gives kicked, expired, upgradeRequired or tenantUnavailable; switching
 * gives failure, drain, failback, manual or manifest. The notice explains only the actionRequired reasons
 * ([actionReason]); an actionRequired without one of them reads as expired.
 */
@Immutable
data class FlareConnectionStatus(
    val phase: FlareConnectionPhase,
    val quality: FlareConnectionQuality? = null,
    val progress: Double? = null,
    val nextRetryAt: Long? = null,
    val attempt: Int? = null,
    val reason: String? = null,
    val developmentMode: Boolean = false,
) {
    /** The reason when it is one the notice explains; null for any other text or none. */
    val actionReason: FlareConnectionActionReason? get() = FlareConnectionActionReason.parse(reason)
}

/** The message a visible connection notice says. */
enum class FlareConnectionNoticeText {
    Connecting, Syncing, Switching, Reconnecting, WaitingForNetwork, ServiceUnavailable,
    Kicked, Expired, UpgradeRequired, TenantUnavailable,
}

/** The action a visible connection notice offers; the host performs it. */
enum class FlareConnectionNoticeAction { Retry, SignIn, Update, Diagnose }

/**
 * What the connection notice shows at one moment: whether the banner is [visible], its [text], [tone] and
 * [pulse], the reconnect [countdown] (whole seconds, rounded up), the sync [progress] (0 to 1), the
 * [action] it offers, and whether the development mode [badge] is drawn.
 */
@Immutable
data class FlareConnectionNoticeModel(
    val visible: Boolean,
    val text: FlareConnectionNoticeText? = null,
    val tone: FlareStatusTone? = null,
    val pulse: Boolean = false,
    val countdown: Int? = null,
    val progress: Double? = null,
    val action: FlareConnectionNoticeAction? = null,
    val badge: Boolean = false,
) {
    companion object {
        val Hidden = FlareConnectionNoticeModel(visible = false)
    }
}

/**
 * Tracks the connection status over time and answers what the notice shows, the same as the Vue, Flutter
 * and SwiftUI kits (`spec/connection-notice-vectors.json`): idle and online show nothing; connecting,
 * reconnecting, waiting for the network, an unavailable service and an action required show at once;
 * syncing shows once it has lasted [SYNCING_DELAY_MS] and switching once it has lasted
 * [SWITCHING_DELAY_MS], and until then a banner that was already up keeps what it showed; a reconnecting
 * banner stays up at least [RECONNECTING_MIN_SHOWN_MS].
 */
class FlareConnectionNoticeTracker {
    private data class Shown(val text: FlareConnectionNoticeText?, val tone: FlareStatusTone?, val pulse: Boolean)

    private var status: FlareConnectionStatus? = null
    private var phaseSince = 0L
    private var lastShown: Shown? = null
    private var holdUntil: Long? = null

    /** A status arrived at [nowMs]. The same phase again replaces its fields without restarting its clock. */
    fun observe(status: FlareConnectionStatus, nowMs: Long) {
        if (this.status?.phase != status.phase) {
            val outgoing = present(nowMs)
            lastShown = if (outgoing.visible) Shown(outgoing.text, outgoing.tone, outgoing.pulse) else null
            phaseSince = nowMs
            when (status.phase) {
                FlareConnectionPhase.Reconnecting -> holdUntil = nowMs + RECONNECTING_MIN_SHOWN_MS
                FlareConnectionPhase.Idle, FlareConnectionPhase.ActionRequired -> holdUntil = null
                else -> Unit
            }
        }
        this.status = status
    }

    /** What the notice shows at [nowMs]. */
    fun present(nowMs: Long): FlareConnectionNoticeModel {
        val status = status ?: return FlareConnectionNoticeModel.Hidden
        val badge = status.developmentMode
        if (status.phase == FlareConnectionPhase.Idle) return FlareConnectionNoticeModel(visible = false, badge = badge)
        val base = base(status, nowMs)
        if (base.visible) return base.copy(badge = badge)
        val shown = lastShown
        if (shown != null && (belowDelay(status, nowMs) || held(nowMs))) {
            return FlareConnectionNoticeModel(visible = true, text = shown.text, tone = shown.tone, pulse = shown.pulse, badge = badge)
        }
        return FlareConnectionNoticeModel(visible = false, badge = badge)
    }

    /** The next moment the presentation can change without a new status; null when it cannot. */
    fun nextChangeAt(nowMs: Long): Long? {
        val status = status ?: return null
        if (status.phase == FlareConnectionPhase.Idle) return null
        val candidates = mutableListOf<Long>()
        delayOf(status.phase)?.let { if (nowMs < phaseSince + it) candidates += phaseSince + it }
        if (status.phase == FlareConnectionPhase.Reconnecting) {
            val at = status.nextRetryAt
            val countdown = at?.let { flareConnectionCountdown(it, nowMs) }
            if (at != null && countdown != null) candidates += at - (countdown - 1) * 1000L
        }
        val hold = holdUntil
        if (lastShown != null && hold != null && nowMs < hold && !base(status, nowMs).visible) candidates += hold
        return candidates.minOrNull()
    }

    private fun belowDelay(status: FlareConnectionStatus, nowMs: Long): Boolean {
        val delay = delayOf(status.phase) ?: return false
        return nowMs - phaseSince < delay
    }

    private fun held(nowMs: Long): Boolean = holdUntil?.let { nowMs < it } ?: false

    private fun base(status: FlareConnectionStatus, nowMs: Long): FlareConnectionNoticeModel = when (status.phase) {
        FlareConnectionPhase.Idle, FlareConnectionPhase.Online -> FlareConnectionNoticeModel.Hidden
        FlareConnectionPhase.Connecting ->
            FlareConnectionNoticeModel(true, FlareConnectionNoticeText.Connecting, FlareStatusTone.Info, pulse = true)
        FlareConnectionPhase.Syncing ->
            if (belowDelay(status, nowMs)) FlareConnectionNoticeModel.Hidden
            else FlareConnectionNoticeModel(
                true, FlareConnectionNoticeText.Syncing, FlareStatusTone.Info, pulse = true,
                progress = status.progress?.coerceIn(0.0, 1.0),
            )
        FlareConnectionPhase.Switching ->
            if (belowDelay(status, nowMs)) FlareConnectionNoticeModel.Hidden
            else FlareConnectionNoticeModel(true, FlareConnectionNoticeText.Switching, FlareStatusTone.Info, pulse = true)
        FlareConnectionPhase.Reconnecting -> FlareConnectionNoticeModel(
            true, FlareConnectionNoticeText.Reconnecting, FlareStatusTone.Warning, pulse = true,
            countdown = status.nextRetryAt?.let { flareConnectionCountdown(it, nowMs) },
            action = FlareConnectionNoticeAction.Retry,
        )
        FlareConnectionPhase.WaitingForNetwork ->
            FlareConnectionNoticeModel(true, FlareConnectionNoticeText.WaitingForNetwork, FlareStatusTone.Warning, pulse = false)
        FlareConnectionPhase.ServiceUnavailable -> FlareConnectionNoticeModel(
            true, FlareConnectionNoticeText.ServiceUnavailable, FlareStatusTone.Warning, pulse = true,
            action = FlareConnectionNoticeAction.Diagnose,
        )
        FlareConnectionPhase.ActionRequired -> when (status.actionReason ?: FlareConnectionActionReason.Expired) {
            FlareConnectionActionReason.Kicked -> FlareConnectionNoticeModel(
                true, FlareConnectionNoticeText.Kicked, FlareStatusTone.Danger, action = FlareConnectionNoticeAction.SignIn,
            )
            FlareConnectionActionReason.Expired -> FlareConnectionNoticeModel(
                true, FlareConnectionNoticeText.Expired, FlareStatusTone.Danger, action = FlareConnectionNoticeAction.SignIn,
            )
            FlareConnectionActionReason.UpgradeRequired -> FlareConnectionNoticeModel(
                true, FlareConnectionNoticeText.UpgradeRequired, FlareStatusTone.Danger, action = FlareConnectionNoticeAction.Update,
            )
            FlareConnectionActionReason.TenantUnavailable ->
                FlareConnectionNoticeModel(true, FlareConnectionNoticeText.TenantUnavailable, FlareStatusTone.Danger)
        }
    }

    companion object {
        const val SYNCING_DELAY_MS = 1000L
        const val SWITCHING_DELAY_MS = 2000L
        const val RECONNECTING_MIN_SHOWN_MS = 1500L

        private fun delayOf(phase: FlareConnectionPhase): Long? = when (phase) {
            FlareConnectionPhase.Syncing -> SYNCING_DELAY_MS
            FlareConnectionPhase.Switching -> SWITCHING_DELAY_MS
            else -> null
        }
    }
}

/** Whole seconds to [nextRetryAt], rounded up; null once it has passed. */
fun flareConnectionCountdown(nextRetryAt: Long, nowMs: Long): Int? {
    val remaining = nextRetryAt - nowMs
    return if (remaining > 0) ((remaining + 999) / 1000).toInt() else null
}

/** The message alone, as a screen reader is told it (the countdown is not re-announced every second). */
fun FlareConnectionNoticeModel.message(strings: FlareStrings): String? = when (text) {
    FlareConnectionNoticeText.Connecting -> strings.connectionConnecting
    FlareConnectionNoticeText.Syncing -> strings.connectionSyncing
    FlareConnectionNoticeText.Switching -> strings.connectionSwitching
    FlareConnectionNoticeText.Reconnecting -> strings.connectionReconnecting
    FlareConnectionNoticeText.WaitingForNetwork -> strings.connectionWaitingForNetwork
    FlareConnectionNoticeText.ServiceUnavailable -> strings.connectionServiceUnavailable
    FlareConnectionNoticeText.Kicked -> strings.connectionKicked
    FlareConnectionNoticeText.Expired -> strings.connectionExpired
    FlareConnectionNoticeText.UpgradeRequired -> strings.connectionUpgradeRequired
    FlareConnectionNoticeText.TenantUnavailable -> strings.connectionTenantUnavailable
    null -> null
}

/** The banner's words: the message, then the countdown or the sync progress. */
fun FlareConnectionNoticeModel.bannerText(strings: FlareStrings): String {
    val message = message(strings) ?: return ""
    countdown?.let { return "$message ${strings.connectionRetryIn(it)}" }
    progress?.let { return "$message ${(it * 100).roundToInt()}%" }
    return message
}

/** The action's label. */
fun FlareConnectionNoticeAction.label(strings: FlareStrings): String = when (this) {
    FlareConnectionNoticeAction.Retry -> strings.connectionRetry
    FlareConnectionNoticeAction.SignIn -> strings.connectionSignIn
    FlareConnectionNoticeAction.Update -> strings.connectionUpdate
    FlareConnectionNoticeAction.Diagnose -> strings.connectionDiagnose
}

/**
 * The connection notice an app shell places once, above every tab. Spec: IM/ConnectionNotice
 * (`ConnectionNotice`).
 *
 * The host hands in the core SDK's connection status as it arrives; what shows when is
 * [FlareConnectionNoticeTracker]'s call. The composable feeds it the status, wakes when the presentation can
 * next change and draws the banner with [StatusBanner]. An action is drawn only when the host passes its
 * handler: [onRetry] (the SDK's `connection.reconnectNow`), [onSignIn], [onUpdate], [onDiagnose]. The
 * message is announced when it changes; the countdown is not re-announced every second.
 */
@Composable
fun ConnectionNotice(
    status: FlareConnectionStatus?,
    floating: Boolean = false,
    onRetry: (() -> Unit)? = null,
    onSignIn: (() -> Unit)? = null,
    onUpdate: (() -> Unit)? = null,
    onDiagnose: (() -> Unit)? = null,
) {
    val strings = LocalFlareStrings.current
    val colors = flareColors()
    val view = LocalView.current
    val tracker = remember { FlareConnectionNoticeTracker() }
    var model by remember { mutableStateOf(FlareConnectionNoticeModel.Hidden) }
    LaunchedEffect(status) {
        tracker.observe(status ?: FlareConnectionStatus(FlareConnectionPhase.Idle), System.currentTimeMillis())
        while (true) {
            val now = System.currentTimeMillis()
            model = tracker.present(now)
            val wake = tracker.nextChangeAt(now) ?: break
            delay((wake - now).coerceAtLeast(0L))
        }
    }
    val spoken = if (model.visible) model.message(strings) else null
    LaunchedEffect(spoken) { if (spoken != null) view.announceForAccessibility(spoken) }
    val perform = when (model.action) {
        FlareConnectionNoticeAction.Retry -> onRetry
        FlareConnectionNoticeAction.SignIn -> onSignIn
        FlareConnectionNoticeAction.Update -> onUpdate
        FlareConnectionNoticeAction.Diagnose -> onDiagnose
        null -> null
    }
    Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
        if (model.badge) {
            Text(
                strings.connectionDevelopmentMode,
                color = colors.warningText,
                fontSize = FlareSizes.fontSizeXs,
                fontWeight = FontWeight.Medium,
                modifier = Modifier
                    .clip(RoundedCornerShape(FlareSizes.radiusFull))
                    .background(colors.warning.copy(alpha = 0.10f))
                    .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacing3xs),
            )
        }
        if (model.visible) {
            StatusBanner(
                text = model.bannerText(strings),
                tone = model.tone ?: FlareStatusTone.Info,
                pulse = model.pulse,
                actionText = if (perform != null) model.action?.label(strings) else null,
                onAction = perform,
                floating = floating,
            )
        }
    }
}
