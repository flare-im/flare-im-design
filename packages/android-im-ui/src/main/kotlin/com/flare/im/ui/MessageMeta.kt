package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.sp

enum class FlareMessageMetaDensity { Compact, Normal }

/** Stable metadata row for time, mutation, ephemeral state, and outgoing receipt. */
@Composable
fun MessageMeta(
    timestamp: String = "",
    edited: Boolean = false,
    status: FlareMessageDeliveryStatus? = null,
    lifecycle: FlareMessageLifecycle? = null,
    ephemeral: FlareMessageEphemeralState = FlareMessageEphemeralState.None,
    density: FlareMessageMetaDensity = FlareMessageMetaDensity.Compact,
    tint: Color? = null,
    onResend: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val strings = flareStrings()
    val colors = flareColors()
    val resolvedEphemeral = lifecycle?.ephemeral ?: ephemeral
    val ephemeralLabel = when (resolvedEphemeral) {
        FlareMessageEphemeralState.None -> ""
        FlareMessageEphemeralState.ReadOnce -> strings.messageReadOnce
        FlareMessageEphemeralState.BurnAfterRead -> strings.messageBurnAfterRead
        FlareMessageEphemeralState.Expired -> strings.messageExpired
    }
    val labels = buildList {
        if (timestamp.isNotEmpty()) add(timestamp)
        if (edited || lifecycle?.mutation == FlareMessageMutationState.Edited) add(strings.messageEdited)
        if (ephemeralLabel.isNotEmpty()) add(ephemeralLabel)
    }
    Row(
        modifier = modifier.heightIn(min = FlareSizes.iconSizeSm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(
            if (density == FlareMessageMetaDensity.Compact) FlareSizes.spacingXs else FlareSizes.spacing2xs,
        ),
    ) {
        if (labels.isNotEmpty()) {
            Text(
                labels.joinToString(" · "),
                color = tint ?: colors.textTertiary,
                fontSize = FlareSizes.fontSizeXs.value.sp,
                maxLines = 1,
            )
        }
        if (status != null || lifecycle != null) {
            MessageStatus(
                status = status ?: FlareMessageDeliveryStatus.Sent,
                lifecycle = lifecycle,
                variant = FlareMessageStatusVariant.Compact,
                tint = tint,
                onResend = onResend,
            )
        }
    }
}
