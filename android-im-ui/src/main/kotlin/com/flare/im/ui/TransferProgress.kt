package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

enum class FlareTransferAction { Pause, Resume, Cancel, Retry, Open }
enum class FlareTransferState {
    Queued, Transferring, Paused, Failed, Completed, Cancelled;
    val actions: List<FlareTransferAction> get() = when (this) {
        Queued -> listOf(FlareTransferAction.Cancel)
        Transferring -> listOf(FlareTransferAction.Pause, FlareTransferAction.Cancel)
        Paused -> listOf(FlareTransferAction.Resume, FlareTransferAction.Cancel)
        Failed, Cancelled -> listOf(FlareTransferAction.Retry)
        Completed -> listOf(FlareTransferAction.Open)
    }
    fun normalizedProgress(value: Float?): Float? = if (this == Completed) 1f else value?.takeIf { it.isFinite() }?.coerceIn(0f, 1f)
}

/** Rendering only: the host supplies capabilities and owns every operation. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun TransferProgress(name: String, state: FlareTransferState, statusText: String, progress: Float? = null,
                     actionLabels: Map<FlareTransferAction, String> = emptyMap(), busy: Boolean = false,
                     onAction: ((FlareTransferAction) -> Unit)? = null) {
    val colors = flareColors()
    val value = state.normalizedProgress(progress)
    Column(Modifier.fillMaxWidth().background(colors.bgPrimary, RoundedCornerShape(10.dp))
        .border(1.dp, colors.borderPrimary, RoundedCornerShape(10.dp)).padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(name, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = colors.textPrimary)
        Text(statusText, fontSize = 13.sp, color = colors.textSecondary, modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
        if (value != null) LinearProgressIndicator(progress = { value }, modifier = Modifier.fillMaxWidth(), color = colors.primary)
        else if (state == FlareTransferState.Transferring) LinearProgressIndicator(modifier = Modifier.fillMaxWidth(), color = colors.primary)
        val actions = state.actions.filter { !actionLabels[it].isNullOrBlank() && onAction != null }
        if (actions.isNotEmpty()) FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            actions.forEach { action ->
                TextButton(onClick = { if (!busy) onAction?.invoke(action) }, enabled = !busy,
                    modifier = Modifier.defaultMinSize(minWidth = 48.dp, minHeight = 48.dp)) { Text(actionLabels.getValue(action), color = colors.textPrimary.copy(alpha = if (busy) 0.4f else 1f)) }
            }
        }
    }
}
