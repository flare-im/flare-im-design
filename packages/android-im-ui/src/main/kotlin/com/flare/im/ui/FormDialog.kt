package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

/**
 * Shared form surface (Spec: Overlay/FormSheet, Compose symbol `FormDialog`): the [title], the host's fields in
 * [content], and cancel / confirm. The host owns data, validation and side effects.
 *
 * It is hosted in [BottomSheet] with [presentation] (default [FlareSheetPresentation.Auto]): a bottom sheet on
 * the phone form factor and a centered [Modal] elsewhere, like the Vue FormSheet and the iOS FormSheetView.
 * While [busy] confirm shows progress, cancel is disabled and nothing closes it (scrim, back, Escape). The
 * fields scroll inside the sheet's height cap; the buttons stay in view.
 */
@Composable
fun FormDialog(
    title: String,
    confirmLabel: String,
    cancelLabel: String,
    onClose: () -> Unit,
    onConfirm: () -> Unit,
    confirmEnabled: Boolean = true,
    busy: Boolean = false,
    danger: Boolean = false,
    presentation: FlareSheetPresentation = FlareSheetPresentation.Auto,
    content: @Composable () -> Unit,
) {
    BottomSheet(onClose = { if (!busy) onClose() }, title = title, dismissible = !busy, presentation = presentation) {
        Column(
            Modifier.fillMaxWidth().weight(1f, fill = false).verticalScroll(rememberScrollState())
                .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
        ) { content() }
        Row(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2sm),
        ) {
            Box(Modifier.weight(1f)) {
                Button(label = cancelLabel, variant = FlareButtonVariant.Secondary, disabled = busy, block = true, onClick = onClose)
            }
            Box(Modifier.weight(1f)) {
                Button(
                    label = confirmLabel,
                    variant = if (danger) FlareButtonVariant.Danger else FlareButtonVariant.Primary,
                    disabled = !confirmEnabled,
                    loading = busy,
                    block = true,
                    onClick = onConfirm,
                )
            }
        }
    }
}
