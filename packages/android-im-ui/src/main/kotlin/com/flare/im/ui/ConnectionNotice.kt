package com.flare.im.ui

import androidx.compose.runtime.Immutable

/** The IM connection states an app shell tells the user about (the Vue `FlareConnectionPhase`). */
enum class FlareConnectionPhase { Connected, Connecting, Reconnecting, Offline, Disconnected, Kicked, Expired }

/** The way back a [FlareConnectionNotice] offers: try the connection again, or sign in again. */
enum class FlareConnectionRecovery { Reconnect, SignIn }

/**
 * What an app shell shows for its connection, drawn with [StatusBanner]: [text] in [tone], a pulsing dot
 * while a connection attempt is under way ([pulse]), and the recovery action labelled [recoveryText].
 */
@Immutable
data class FlareConnectionNotice(
    val phase: FlareConnectionPhase,
    val text: String,
    val tone: FlareStatusTone,
    val pulse: Boolean,
    val recovery: FlareConnectionRecovery? = null,
    val recoveryText: String? = null,
)

/**
 * The notice for [phase] (Vue `connectionNotice`); the kit owns the wording, the tone and the way back, so
 * every app says the same thing for the same state. Connected shows nothing (null). Connecting and
 * reconnecting pulse, since the core retries on its own; offline waits for the network; disconnected names
 * [reason] when there is one and offers to reconnect only when the host [canReconnect]. Kicked and expired
 * are final (the core does not reconnect from them), so both are danger and always offer to sign in again;
 * a kicked [reason] replaces the default text.
 */
fun flareConnectionNotice(
    phase: FlareConnectionPhase,
    strings: FlareStrings,
    reason: String? = null,
    canReconnect: Boolean = false,
): FlareConnectionNotice? {
    val why = reason?.trim().orEmpty()
    return when (phase) {
        FlareConnectionPhase.Connected -> null
        FlareConnectionPhase.Connecting -> FlareConnectionNotice(phase, strings.connectionConnecting, FlareStatusTone.Warning, pulse = true)
        FlareConnectionPhase.Reconnecting -> FlareConnectionNotice(phase, strings.connectionReconnecting, FlareStatusTone.Warning, pulse = true)
        FlareConnectionPhase.Offline -> FlareConnectionNotice(phase, strings.connectionOffline, FlareStatusTone.Warning, pulse = false)
        FlareConnectionPhase.Disconnected -> FlareConnectionNotice(
            phase = phase,
            text = if (why.isNotEmpty()) strings.connectionDisconnectedReason(why) else strings.connectionDisconnected,
            tone = FlareStatusTone.Warning,
            pulse = false,
            recovery = FlareConnectionRecovery.Reconnect.takeIf { canReconnect },
            recoveryText = strings.connectionReconnect.takeIf { canReconnect },
        )
        FlareConnectionPhase.Kicked -> FlareConnectionNotice(
            phase, why.ifEmpty { strings.connectionKicked }, FlareStatusTone.Danger, pulse = false,
            recovery = FlareConnectionRecovery.SignIn, recoveryText = strings.connectionSignIn,
        )
        FlareConnectionPhase.Expired -> FlareConnectionNotice(
            phase, strings.connectionExpired, FlareStatusTone.Danger, pulse = false,
            recovery = FlareConnectionRecovery.SignIn, recoveryText = strings.connectionSignIn,
        )
    }
}
