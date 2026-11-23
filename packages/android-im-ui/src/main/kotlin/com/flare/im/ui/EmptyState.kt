package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp

/** Empty-state tone — `normal` (default look) or `error` (danger-colored title/icon). */
enum class FlareEmptyStateTone { Normal, Error }

/**
 * Empty-state placeholder — icon + title + description + optional action, for
 * empty conversations / search / contacts. Spec: General/EmptyState
 * (`EmptyState`). [compact] is the in-block empty state of a plugin page (R8 of docs/plugin-experience.md): icon 32,
 * title 14/600, description 13, less padding.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun EmptyState(
    title: String,
    description: String? = null,
    actionText: String? = null,
    /** A semantic icon name from the registry (`docs/ICON-LIBRARY.md`), not a platform glyph. */
    icon: String = "folder",
    onAction: (() -> Unit)? = null,
    loading: Boolean = false,
    onTap: (() -> Unit)? = null,
    iconContent: (@Composable () -> Unit)? = null,
    tone: FlareEmptyStateTone = FlareEmptyStateTone.Normal,
    /**
     * Host controls under the text — what to do about the screen being empty. The kit owns the row
     * (centred, wrapping, one gap); the host owns the controls. [actionText] stays the one-button
     * shorthand, and both may be given.
     */
    actions: (@Composable () -> Unit)? = null,
    compact: Boolean = false,
) {
    val colors = flareColors()
    val iconSize = if (compact) FlareSizes.iconSizeXl else FlareSizes.componentEmptyStateIconSize
    val isError = tone == FlareEmptyStateTone.Error
    val accentColor = if (isError) colors.error else colors.primary
    val defaultIconTint = if (isError) colors.error else colors.textTertiary
    Column(
        Modifier.fillMaxWidth()
            .then(if (onTap != null) Modifier.clickable { onTap() } else Modifier)
            .padding(if (compact) FlareSizes.spacingLg else FlareSizes.spacing2xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        when {
            loading -> CircularProgressIndicator(Modifier.size(iconSize), color = accentColor)
            iconContent != null -> iconContent()
            else -> FlareIcon(name = icon, size = iconSize, tint = defaultIconTint)
        }
        Spacer(Modifier.height(FlareSizes.spacingSm))
        Text(title, color = if (isError) colors.errorText else colors.textPrimary,
            fontSize = if (compact) FlareSizes.fontSizeLg else FlareSizes.fontSize2xl,
            fontWeight = if (compact) androidx.compose.ui.text.font.FontWeight.SemiBold else null, textAlign = TextAlign.Center)
        if (description != null) {
            Spacer(Modifier.height(FlareSizes.spacingSm))
            Text(description, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp, textAlign = TextAlign.Center)
        }
        if (actionText != null) {
            Spacer(Modifier.height(if (compact) FlareSizes.spacingMd else FlareSizes.spacingLg))
            // Vue: a small ghost button.
            Button(label = actionText, variant = FlareButtonVariant.Ghost, size = FlareControlSize.Sm, maintainTouchTarget = true, onClick = { onAction?.invoke() })
        }
        if (actions != null) {
            Spacer(Modifier.height(if (compact) FlareSizes.spacingMd else FlareSizes.spacingLg))
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm, Alignment.CenterHorizontally),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) { actions() }
        }
    }
}
