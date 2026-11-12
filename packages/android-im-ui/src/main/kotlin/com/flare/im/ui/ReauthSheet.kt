package com.flare.im.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

/** Opaque SDK id and masked display copy, without a credential or proof. */
data class FlareReauthDestination(val id: String, val label: String, val detail: String? = null)

/** Pure OTP form body; the host owns presentation, effects and countdown state. */
@Composable
fun ReauthSheet(
    destinations: List<FlareReauthDestination>, selectedId: String, code: String,
    onSelectDestination: (String) -> Unit, onCodeChange: (String) -> Unit,
    onSend: () -> Unit, onSubmit: () -> Unit, onCancel: () -> Unit,
    canSend: Boolean, canSubmit: Boolean, title: String? = null, subtitle: String? = null,
    codeLength: Int = 6, sending: Boolean = false, submitting: Boolean = false,
    resendInSeconds: Int = 0, error: String? = null, notice: String? = null,
) {
    val strings = LocalFlareStrings.current
    val colors = flareColors()
    val busy = sending || submitting
    val selected = destinations.firstOrNull { it.id == selectedId }
    val maySend = canSend && selected != null && !busy && resendInSeconds <= 0
    val maySubmit = canSubmit && selected != null && !busy
    Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
        Text(title ?: strings.reauthTitle, color = colors.textPrimary)
        if (subtitle != null) Text(subtitle, color = colors.textSecondary)
        if (notice != null) StatusBanner(text = notice, tone = FlareStatusTone.Info)
        if (error != null) StatusBanner(text = error, tone = FlareStatusTone.Danger)
        if (destinations.isEmpty()) StatusBanner(text = strings.reauthUnavailable, tone = FlareStatusTone.Warning)
        FormField(label = strings.reauthDestination, hint = selected?.detail) {
            Select(options = destinations.map { FlareSelectOption(value = it.id, label = it.label) }, value = selectedId, disabled = busy || destinations.isEmpty(), onChange = onSelectDestination)
        }
        FormField(label = strings.reauthCode) {
            Input(value = code, onValueChange = onCodeChange, placeholder = strings.reauthCode, maxLength = codeLength, disabled = busy, monospace = true, onSubmit = { if (maySubmit) onSubmit() })
        }
        Button(label = if (resendInSeconds > 0) strings.reauthResendIn.replace("{seconds}", resendInSeconds.toString()) else strings.reauthSendCode, variant = FlareButtonVariant.Secondary, loading = sending, disabled = !maySend, block = true, onClick = { if (maySend) onSend() })
        Button(label = strings.confirm, loading = submitting, disabled = !maySubmit, block = true, onClick = { if (maySubmit) onSubmit() })
        Button(label = strings.cancel, variant = FlareButtonVariant.Quiet, block = true, onClick = onCancel)
    }
}
