package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Inbox
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Empty-state placeholder — icon + title + description + optional action, for
 * empty conversations / search / contacts. Spec: General/EmptyState
 * (`EmptyState`).
 */
@Composable
fun EmptyState(
    title: String,
    description: String? = null,
    actionText: String? = null,
    icon: ImageVector = Icons.Outlined.Inbox,
    onAction: (() -> Unit)? = null,
) {
    val colors = flareColors()
    Column(
        Modifier.fillMaxWidth().padding(FlareSizes.spacing2xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(icon, null, Modifier.size(56.dp), tint = colors.textTertiary)
        Spacer(Modifier.height(FlareSizes.spacingMd))
        Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSize2xl.value.sp, textAlign = TextAlign.Center)
        if (description != null) {
            Spacer(Modifier.height(FlareSizes.spacingXs))
            Text(description, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp, textAlign = TextAlign.Center)
        }
        if (actionText != null) {
            Spacer(Modifier.height(FlareSizes.spacingLg))
            OutlinedButton(onClick = { onAction?.invoke() }) { Text(actionText) }
        }
    }
}
