package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

/** Shared form/confirmation surface. The host owns data, validation and SDK work. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun FormDialog(
    title: String,
    confirmLabel: String,
    cancelLabel: String,
    onDismiss: () -> Unit,
    onConfirm: () -> Unit,
    confirmEnabled: Boolean = true,
    busy: Boolean = false,
    danger: Boolean = false,
    content: @Composable () -> Unit,
) {
    val colors = flareColors()
    Dialog(
        onDismissRequest = { if (!busy) onDismiss() },
        properties = DialogProperties(dismissOnBackPress = !busy, dismissOnClickOutside = !busy, usePlatformDefaultWidth = false),
    ) {
        Surface(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 24.dp).widthIn(max = 480.dp).fillMaxWidth(),
            shape = RoundedCornerShape(FlareSizes.radiusXl), color = colors.bgPrimary, contentColor = colors.textPrimary,
        ) {
            Column(Modifier.padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.SemiBold)
                Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState())) { content() }
                FlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp, androidx.compose.ui.Alignment.End), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(label = cancelLabel, variant = FlareButtonVariant.Secondary, disabled = busy, onClick = onDismiss)
                    Button(label = confirmLabel, variant = if (danger) FlareButtonVariant.Danger else FlareButtonVariant.Primary,
                        disabled = !confirmEnabled, loading = busy, onClick = onConfirm)
                }
            }
        }
    }
}
