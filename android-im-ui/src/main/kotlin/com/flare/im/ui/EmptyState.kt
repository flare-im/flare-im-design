package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Inbox
import androidx.compose.material3.CircularProgressIndicator
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

/** Empty-state tone — `normal` (default look) or `error` (danger-colored title/icon). */
enum class FlareEmptyStateTone { Normal, Error }

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
    loading: Boolean = false,
    onTap: (() -> Unit)? = null,
    iconContent: (@Composable () -> Unit)? = null,
    tone: FlareEmptyStateTone = FlareEmptyStateTone.Normal,
) {
    val colors = flareColors()
    val isError = tone == FlareEmptyStateTone.Error
    val accentColor = if (isError) colors.error else colors.primary
    val defaultIconTint = if (isError) colors.error else colors.textTertiary
    Column(
        Modifier.fillMaxWidth()
            .then(if (onTap != null) Modifier.clickable { onTap() } else Modifier)
            .padding(FlareSizes.spacing2xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        when {
            loading -> CircularProgressIndicator(Modifier.size(44.dp), color = accentColor)
            iconContent != null -> iconContent()
            else -> Icon(icon, null, Modifier.size(44.dp), tint = defaultIconTint)
        }
        Spacer(Modifier.height(FlareSizes.spacingSm))
        Text(title, color = if (isError) colors.error else colors.textPrimary, fontSize = FlareSizes.fontSize2xl.value.sp, textAlign = TextAlign.Center)
        if (description != null) {
            Spacer(Modifier.height(FlareSizes.spacingSm))
            Text(description, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp, textAlign = TextAlign.Center)
        }
        if (actionText != null) {
            Spacer(Modifier.height(FlareSizes.spacingLg))
            OutlinedButton(onClick = { onAction?.invoke() }) { Text(actionText) }
        }
    }
}
