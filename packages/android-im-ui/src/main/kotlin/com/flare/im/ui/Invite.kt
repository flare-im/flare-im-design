package com.flare.im.ui

import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/**
 * Invite contracts — pure logic shared by the four platforms behind the registration form's
 * invite-code field ([InviteCodeField]) and the "my invite" card ([MyInvitePanel]).
 * Vectors: spec/invite-vectors.json.
 *
 * The host owns the network: it runs the pre-check, fetches the code, the stats and the invitees,
 * and performs copy / share / regenerate. Nothing here has a side effect. The alphabet is Crockford
 * base32 without I / L / O / U, so what a person types is corrected the way the server reads it
 * (O→0, I/L→1) before it is shown.
 */

/** Tenant invite mode: `Off` hides the field, `Optional` and `Required` show it. */
enum class FlareInviteCodeMode { Off, Optional, Required }

/** Result of the host's pre-check for one code. */
data class FlareInviteCodeCheckResult(
    val valid: Boolean,
    /** Masked display name of the inviter the code resolves to. */
    val inviterDisplayName: String? = null,
)

/** The invite-code field's state vector. */
enum class FlareInviteCodeFieldState { Off, Idle, Typing, Checking, Valid, Invalid, Disabled }

/** Referral counts per depth for the current person. */
data class FlareReferralStats(val direct: Int, val l2: Int, val l3: Int, val total: Int) {
    fun of(depth: FlareReferralDepth): Int = when (depth) {
        FlareReferralDepth.Direct -> direct
        FlareReferralDepth.L2 -> l2
        FlareReferralDepth.L3 -> l3
        FlareReferralDepth.Total -> total
    }
}

/** One person invited directly by the current person; [joinedAt] is epoch milliseconds. */
data class FlareInvitee(
    val userId: String,
    val displayName: String,
    val avatarUrl: String? = null,
    val joinedAt: Long,
)

const val FLARE_INVITE_CODE_DEFAULT_LENGTH = 6

/** Delay between the last keystroke and the check request, in milliseconds. */
const val FLARE_INVITE_CHECK_DEBOUNCE_MS = 400L

/**
 * What the server would read from what the person typed or pasted: whitespace and separators
 * dropped, uppercased, O→0 and I/L→1, cut to [length]. Idempotent, so it can run on every keystroke.
 */
fun normalizeInviteCode(raw: String?, length: Int = FLARE_INVITE_CODE_DEFAULT_LENGTH): String {
    val cap = if (length > 0) length else FLARE_INVITE_CODE_DEFAULT_LENGTH
    val out = StringBuilder()
    for (ch in (raw ?: "").uppercase()) {
        if (out.length >= cap) break
        when {
            ch == 'O' -> out.append('0')
            ch == 'I' || ch == 'L' -> out.append('1')
            ch in '0'..'9' || ch in 'A'..'Z' -> out.append(ch)
        }
    }
    return out.toString()
}

/**
 * One state at a time, in priority order: `Off` beats everything, `Disabled` beats what the host
 * says about the value, a host error beats a check result, an in-flight check beats a stale result,
 * then the result itself, then whether anything has been typed.
 */
fun inviteCodeFieldState(
    mode: FlareInviteCodeMode,
    value: String,
    checking: Boolean = false,
    checkResult: FlareInviteCodeCheckResult? = null,
    error: String? = null,
    disabled: Boolean = false,
): FlareInviteCodeFieldState = when {
    mode == FlareInviteCodeMode.Off -> FlareInviteCodeFieldState.Off
    disabled -> FlareInviteCodeFieldState.Disabled
    !error.isNullOrEmpty() -> FlareInviteCodeFieldState.Invalid
    checking -> FlareInviteCodeFieldState.Checking
    checkResult != null -> if (checkResult.valid) FlareInviteCodeFieldState.Valid else FlareInviteCodeFieldState.Invalid
    value.isEmpty() -> FlareInviteCodeFieldState.Idle
    else -> FlareInviteCodeFieldState.Typing
}

/**
 * The code the host should pre-check for [value], or null when no request should be made: a partial
 * code is never sent, a disabled or hidden field never asks.
 */
fun inviteCodeToCheck(
    value: String,
    length: Int = FLARE_INVITE_CODE_DEFAULT_LENGTH,
    mode: FlareInviteCodeMode = FlareInviteCodeMode.Optional,
    disabled: Boolean = false,
): String? {
    if (mode == FlareInviteCodeMode.Off || disabled) return null
    val code = normalizeInviteCode(value, length)
    return if (code.length == length) code else null
}

enum class FlareReferralDepth { Direct, L2, L3, Total }

/**
 * Which rows the panel lists for [stats], honouring the tenant's visibility depth (1–3, clamped).
 * `Total` is always the last row once stats exist.
 */
fun referralDepthRows(stats: FlareReferralStats?, maxDepthShown: Int = 3): List<FlareReferralDepth> {
    if (stats == null) return emptyList()
    val depth = min(3, max(1, maxDepthShown))
    return buildList {
        add(FlareReferralDepth.Direct)
        if (depth >= 2) add(FlareReferralDepth.L2)
        if (depth >= 3) add(FlareReferralDepth.L3)
        add(FlareReferralDepth.Total)
    }
}

enum class FlareInviteCooldownUnit { Minute, Hour, Day }

data class FlareInviteCooldown(val unit: FlareInviteCooldownUnit, val count: Int)

data class FlareRegenerateAvailability(
    /** The control is drawn at all (the tenant allows regenerating). */
    val shown: Boolean,
    /** The control can be pressed now. */
    val enabled: Boolean,
    /** Time left before it can, in the coarsest whole unit that is not zero. */
    val remaining: FlareInviteCooldown? = null,
)

/**
 * Whether regenerating is offered, and if so whether it is still cooling down. The remaining time
 * rounds *up* so the control never re-enables before the server would.
 */
fun regenerateAvailability(canRegenerate: Boolean, availableAt: Long?, now: Long): FlareRegenerateAvailability {
    if (!canRegenerate) return FlareRegenerateAvailability(shown = false, enabled = false)
    val remainingMs = if (availableAt == null) 0L else availableAt - now
    if (remainingMs <= 0L) return FlareRegenerateAvailability(shown = true, enabled = true)
    val minute = 60_000.0
    val hour = 60 * minute
    val day = 24 * hour
    val remaining = when {
        remainingMs < hour -> FlareInviteCooldown(FlareInviteCooldownUnit.Minute, max(1, ceil(remainingMs / minute).toInt()))
        remainingMs < day -> FlareInviteCooldown(FlareInviteCooldownUnit.Hour, ceil(remainingMs / hour).toInt())
        else -> FlareInviteCooldown(FlareInviteCooldownUnit.Day, ceil(remainingMs / day).toInt())
    }
    return FlareRegenerateAvailability(shown = true, enabled = false, remaining = remaining)
}

/** `YYYY-MM-DD` for a calendar date — the same on every platform. */
fun formatInviteJoinedDate(year: Int, month: Int, day: Int): String =
    "%04d-%02d-%02d".format(year, month, day)

/** `YYYY-MM-DD` of an epoch-millisecond instant in the device's time zone. */
fun inviteJoinedDateLabel(epochMs: Long): String {
    val calendar = java.util.Calendar.getInstance().apply { timeInMillis = epochMs }
    return formatInviteJoinedDate(
        calendar.get(java.util.Calendar.YEAR),
        calendar.get(java.util.Calendar.MONTH) + 1,
        calendar.get(java.util.Calendar.DAY_OF_MONTH),
    )
}
