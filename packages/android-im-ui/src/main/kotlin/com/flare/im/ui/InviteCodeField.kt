package com.flare.im.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

/**
 * The registration form's invite-code field. Spec: Form/InviteCodeField (`InviteCodeField`).
 *
 * The tenant decides whether it exists ([mode]), the person types or pastes a code, the field
 * normalizes it the way the server reads it (what reaches [onValueChange] is already normalized) and
 * — once the code is complete — asks the host to pre-check it through [onCheck]. The host owns the
 * request: it sets [checking], then hands back [checkResult] (or an [error] it has already localized).
 * The field never touches the network.
 */
@Composable
fun InviteCodeField(
    value: String,
    onValueChange: (String) -> Unit,
    mode: FlareInviteCodeMode = FlareInviteCodeMode.Optional,
    /** Deep-link value applied once while the field is empty. */
    prefill: String? = null,
    checking: Boolean = false,
    checkResult: FlareInviteCodeCheckResult? = null,
    /** Host-localized error shown instead of the hint; wins over [checkResult]. */
    error: String? = null,
    disabled: Boolean = false,
    /** Code length the tenant configured; a check is only requested for a complete code. */
    length: Int = FLARE_INVITE_CODE_DEFAULT_LENGTH,
    label: String? = null,
    placeholder: String? = null,
    /** A complete, normalized code the host should pre-check; debounced after typing stops. */
    onCheck: ((String) -> Unit)? = null,
) {
    val state = inviteCodeFieldState(mode, value, checking, checkResult, error, disabled)
    if (state == FlareInviteCodeFieldState.Off) return
    val strings = flareStrings()
    val colors = flareColors()

    // Deep-link prefill: applied once, while the field is empty. A person who clears the field
    // afterwards is not re-filled.
    var prefillApplied by remember { mutableStateOf(false) }
    LaunchedEffect(prefill, mode) {
        if (prefillApplied || prefill.isNullOrEmpty() || value.isNotEmpty()) return@LaunchedEffect
        val next = normalizeInviteCode(prefill, length)
        if (next.isEmpty()) return@LaunchedEffect
        prefillApplied = true
        onValueChange(next)
    }

    // Debounced pre-check: one request about 400 ms after the last change, and only for a complete
    // code. Keyed on the value, so every keystroke restarts the wait.
    var lastRequested by remember { mutableStateOf<String?>(null) }
    val codeToCheck = inviteCodeToCheck(value, length, mode, disabled)
    LaunchedEffect(codeToCheck) {
        if (codeToCheck == null) { lastRequested = null; return@LaunchedEffect }
        if (codeToCheck == lastRequested) return@LaunchedEffect
        delay(FLARE_INVITE_CHECK_DEBOUNCE_MS)
        lastRequested = codeToCheck
        onCheck?.invoke(codeToCheck)
    }

    // A stale result for another code must not be shown as this code's verdict.
    val resultMatches = checkResult == null || inviteCodeToCheck(value, length) != null
    val inviter = checkResult?.inviterDisplayName?.trim()
    val errorLine = when {
        !error.isNullOrEmpty() -> error
        state == FlareInviteCodeFieldState.Invalid && resultMatches -> strings.inviteCodeInvalid
        else -> null
    }
    val hint = if (mode == FlareInviteCodeMode.Optional && state == FlareInviteCodeFieldState.Idle) strings.inviteCodeOptional else null

    FormField(
        label = label ?: strings.inviteCodeLabel,
        required = mode == FlareInviteCodeMode.Required,
        hint = hint,
        error = errorLine,
    ) {
        Column(Modifier.fillMaxWidth()) {
            Input(
                value = value,
                onValueChange = { raw -> onValueChange(normalizeInviteCode(raw, length)) },
                placeholder = placeholder ?: strings.inviteCodePlaceholder,
                disabled = disabled,
                monospace = true,
            )
            val statusModifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite }
            if (state == FlareInviteCodeFieldState.Checking) {
                Spacer(Modifier.height(FlareSizes.spacing2xs))
                Row(statusModifier, verticalAlignment = Alignment.CenterVertically) {
                    CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeSm), strokeWidth = 2.dp, color = colors.textSecondary)
                    Spacer(Modifier.width(FlareSizes.spacing2xs))
                    Text(strings.inviteCodeChecking, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
                }
            } else if (state == FlareInviteCodeFieldState.Valid && resultMatches) {
                Spacer(Modifier.height(FlareSizes.spacing2xs))
                Row(statusModifier, verticalAlignment = Alignment.CenterVertically) {
                    FlareIcon("success", size = FlareSizes.iconSizeSm, tint = colors.successText)
                    Spacer(Modifier.width(FlareSizes.spacing2xs))
                    Text(
                        if (!inviter.isNullOrEmpty()) strings.inviteCodeInviter.replace("{name}", inviter) else strings.inviteCodeValid,
                        color = colors.successText,
                        fontSize = FlareSizes.fontSizeSm.value.sp,
                    )
                }
            }
        }
    }
}
