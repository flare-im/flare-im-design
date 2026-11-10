package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

/** Generic visual wrapper over the shared upload slot. It never holds bytes or makes requests. */
@Composable
internal fun PluginFileInput(input: PluginInput, state: PluginFileState, disabled: Boolean, onAction: (PluginFileActionKind) -> Unit) {
    val strings = flareStrings()
    val phase = when (state.phase) {
        PluginFilePhase.Empty, PluginFilePhase.Selected -> FlareImageUploadState.Empty
        PluginFilePhase.Uploading -> FlareImageUploadState.Uploading
        PluginFilePhase.Uploaded -> FlareImageUploadState.Uploaded
        PluginFilePhase.Failed -> FlareImageUploadState.Failed
    }
    val text = when (state.phase) {
        PluginFilePhase.Empty -> strings.pluginFileChoose
        PluginFilePhase.Selected -> strings.pluginFileSelected
        PluginFilePhase.Uploading -> strings.pluginFileUploading + (state.progress?.takeIf { it.isFinite() }?.let { " ${(it.coerceIn(0.0, 1.0) * 100).toInt()}%" } ?: "")
        PluginFilePhase.Uploaded -> state.error ?: strings.pluginFileUploaded
        PluginFilePhase.Failed -> state.error ?: strings.pluginFileFailed
    }
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        FlareImageUploadSlot(
            title = state.fileName ?: input.placeholder ?: input.label,
            state = phase, statusText = text,
            actionText = if (state.phase == PluginFilePhase.Selected) strings.pluginFileSelected else strings.pluginFileChoose, retryText = strings.retry,
            modifier = Modifier.fillMaxWidth(), icon = "file", disabled = disabled || state.phase == PluginFilePhase.Selected,
            onChoose = { onAction(PluginFileActionKind.Choose) },
            onRetry = if (state.phase == PluginFilePhase.Failed) ({ onAction(PluginFileActionKind.Retry) }) else null,
            previewLabel = strings.pluginFilePreview.takeIf { state.preview }, previewLoading = state.previewLoading,
            previewDisabled = disabled, onPreview = { onAction(PluginFileActionKind.Preview) },
        )
        Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            if (state.phase == PluginFilePhase.Selected || state.phase == PluginFilePhase.Uploading) {
                Button(label = strings.cancel, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Sm,
                    disabled = disabled, onClick = { onAction(PluginFileActionKind.Cancel) })
            } else if (state.phase != PluginFilePhase.Empty) {
                Button(label = strings.pluginFileReplace, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Sm,
                    disabled = disabled, onClick = { onAction(PluginFileActionKind.Replace) })
                Button(label = strings.pluginFileRemove, variant = FlareButtonVariant.Text, size = FlareControlSize.Sm,
                    disabled = disabled, onClick = { onAction(PluginFileActionKind.Remove) })
            }
        }
    }
}
