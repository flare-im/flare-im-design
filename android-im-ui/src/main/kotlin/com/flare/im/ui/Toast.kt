package com.flare.im.ui

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

enum class ToastVariant { Info, Success, Error, Warning, Loading }

/** Lightweight feedback toast. Spec: General/Toast. */
@Composable
fun Toast(
    message: String,
    variant: ToastVariant = ToastVariant.Info,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val (icon, tint) = when (variant) {
        ToastVariant.Info -> Icons.Outlined.Info to colors.primary
        ToastVariant.Success -> Icons.Filled.CheckCircle to colors.success
        ToastVariant.Error -> Icons.Filled.Cancel to colors.error
        ToastVariant.Warning -> Icons.Filled.Warning to colors.warning
        ToastVariant.Loading -> Icons.Outlined.Sync to colors.textSecondary
    }
    val spin = rememberInfiniteTransition(label = "toast")
    val angle by spin.animateFloat(
        initialValue = 0f, targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(900, easing = LinearEasing), RepeatMode.Restart),
        label = "spin",
    )
    Row(
        Modifier.widthIn(max = 420.dp).clip(RoundedCornerShape(FlareSizes.radiusLg))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusLg))
            .padding(horizontal = 14.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = tint,
            modifier = Modifier.size(18.dp)
                .then(if (variant == ToastVariant.Loading) Modifier.rotate(angle) else Modifier))
        Spacer(Modifier.width(10.dp))
        Text(message, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd.value.sp, modifier = Modifier.weight(1f, fill = false))
        if (actionLabel != null) {
            Spacer(Modifier.width(10.dp))
            Text(actionLabel, color = colors.primary, fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeMd.value.sp,
                modifier = Modifier.clickable { onAction?.invoke() })
        }
    }
}
