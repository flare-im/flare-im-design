package com.flare.im.ui

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.sp

/**
 * Muted, small timestamp label. Spec: General/TimeStamp (`TimeStamp`).
 * Pure display — the caller formats [label] upstream.
 */
@Composable
fun TimeStamp(label: String) {
    Text(
        text = label,
        color = flareColors().textTertiary,
        fontSize = FlareSizes.fontSizeXs.value.sp,
    )
}
