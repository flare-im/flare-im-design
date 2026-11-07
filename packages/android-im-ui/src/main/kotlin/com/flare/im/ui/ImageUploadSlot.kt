package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp

/** Controlled visual transfer state. This component never selects, stores or uploads a file. */
enum class FlareImageUploadState { Empty, Uploading, Uploaded, Failed }

/**
 * A compact image input: title, rectangular local-preview/placeholder and one transfer status.
 * Hosts supply localized copy, optional transient preview, and existing choose/retry intents.
 * Uploaded slots are read-only; an uploaded image never implies a remove/replace operation.
 */
@Composable
fun FlareImageUploadSlot(
    title: String,
    state: FlareImageUploadState,
    statusText: String,
    actionText: String,
    retryText: String,
    modifier: Modifier = Modifier,
    disabled: Boolean = false,
    icon: String = "camera",
    preview: (@Composable () -> Unit)? = null,
    onChoose: (() -> Unit)? = null,
    onRetry: (() -> Unit)? = null,
    previewLabel: String? = null,
    previewLoading: Boolean = false,
    previewDisabled: Boolean = false,
    onPreview: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    val tint = when (state) {
        FlareImageUploadState.Uploaded -> colors.success
        FlareImageUploadState.Failed -> colors.error
        else -> colors.textSecondary
    }
    val canChoose = onChoose != null && state != FlareImageUploadState.Uploaded && state != FlareImageUploadState.Uploading
    val viewLabel = previewLabel?.trim()?.takeIf { it.isNotEmpty() }
    val previewMode = state == FlareImageUploadState.Uploaded && viewLabel != null
    val interaction = when {
        previewMode -> Modifier.clickable(enabled = !previewLoading && !previewDisabled && onPreview != null,
            role = Role.Button) { onPreview?.invoke() }
        canChoose -> Modifier.clickable(enabled = !disabled, role = Role.Button) { onChoose?.invoke() }
        else -> Modifier
    }
    Column(modifier, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd,
            fontWeight = FontWeight.Medium, maxLines = 2, overflow = TextOverflow.Ellipsis)
        Box(
            Modifier.fillMaxWidth().aspectRatio(1.6f).heightIn(min = FlareSizes.touchTarget)
                .clip(shape).background(colors.bgSecondary)
                .border(1.dp, if (state == FlareImageUploadState.Failed) colors.error else colors.borderPrimary, shape)
                .then(interaction).semantics(mergeDescendants = true) {
                    contentDescription = title
                    stateDescription = if (previewLoading) strings.loading else statusText
                    liveRegion = LiveRegionMode.Polite
                },
            contentAlignment = Alignment.Center,
        ) {
            if (preview != null) {
                Box(Modifier.fillMaxSize().padding(FlareSizes.spacingSm), contentAlignment = Alignment.Center) { preview() }
            } else if (state != FlareImageUploadState.Uploading && !previewLoading) {
                Column(horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                    FlareIcon(if (previewMode) "image" else if (state == FlareImageUploadState.Uploaded) "success" else icon,
                        size = FlareSizes.iconSizeXl, tint = tint)
                    Text(if (previewMode) viewLabel.orEmpty() else if (state == FlareImageUploadState.Empty) actionText else statusText,
                        color = tint, fontSize = FlareSizes.fontSizeSm)
                }
            }
            if (state == FlareImageUploadState.Uploading || previewLoading) {
                CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeLg), color = colors.primary, strokeWidth = 2.dp)
            }
            if (preview != null || state == FlareImageUploadState.Uploading || previewLoading) {
                Text(if (previewMode) "$statusText · ${viewLabel.orEmpty()}" else statusText, color = tint, fontSize = FlareSizes.fontSizeSm,
                    modifier = Modifier.align(Alignment.BottomStart).fillMaxWidth()
                        .background(colors.bgElevated).padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs))
            }
        }
        if (state == FlareImageUploadState.Failed && onRetry != null) {
            Button(label = retryText, variant = FlareButtonVariant.Text, size = FlareControlSize.Sm,
                disabled = disabled, maintainTouchTarget = true, onClick = onRetry)
        }
    }
}
