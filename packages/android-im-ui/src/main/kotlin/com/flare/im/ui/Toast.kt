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
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

enum class ToastVariant { Info, Success, Error, Warning, Loading }

/**
 * Lightweight feedback toast. Spec: General/Toast.
 *
 * [onClose] adds a trailing close button (label = strings.close); without it no
 * close control is rendered — the host decides whether a toast is dismissable.
 * Transient feedback goes through the presenter instead of placing this directly:
 * [FlareToastHost] at the root, `LocalFlareToast.current.show(…)` anywhere below.
 */
@Composable
fun Toast(
    message: String,
    variant: ToastVariant = ToastVariant.Info,
    tone: FlareStatusTone? = null,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
    onClose: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val (icon, tint) = when {
        tone != null && variant != ToastVariant.Loading -> toastToneIcon(tone) to statusToneColor(colors, tone)
        else -> when (variant) {
            ToastVariant.Info -> Icons.Filled.Info to colors.primary
            ToastVariant.Success -> Icons.Filled.CheckCircle to colors.success
            ToastVariant.Error -> Icons.Filled.Cancel to colors.error
            ToastVariant.Warning -> Icons.Filled.Warning to colors.warning
            ToastVariant.Loading -> Icons.Outlined.Sync to colors.textSecondary
        }
    }
    val spin = rememberInfiniteTransition(label = "toast")
    val angle by spin.animateFloat(
        initialValue = 0f, targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(900, easing = LinearEasing), RepeatMode.Restart),
        label = "spin",
    )
    Row(
        Modifier.widthIn(max = 420.dp)
            .shadow(10.dp, RoundedCornerShape(FlareSizes.radiusLg), clip = false)
            .clip(RoundedCornerShape(FlareSizes.radiusLg))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusLg))
            .padding(horizontal = FlareSizes.spacing2md, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = tint,
            modifier = Modifier.size(18.dp)
                .then(if (variant == ToastVariant.Loading) Modifier.rotate(angle) else Modifier))
        Spacer(Modifier.width(FlareSizes.spacing2sm))
        Text(message, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, modifier = Modifier.weight(1f, fill = false))
        if (actionLabel != null) {
            Spacer(Modifier.width(FlareSizes.spacing2sm))
            Text(actionLabel, color = colors.primaryText, fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeLg.value.sp,
                modifier = Modifier.clickable { onAction?.invoke() })
        }
        if (toastCloseVisible(onClose != null)) {
            Spacer(Modifier.width(4.dp))
            IconButton(onClick = { onClose?.invoke() }, modifier = Modifier.size(28.dp)) {
                Icon(Icons.Filled.Close, contentDescription = flareStrings().close, tint = colors.textTertiary,
                    modifier = Modifier.size(16.dp))
            }
        }
    }
}

/**
 * Feedback presenter: draws [content] with the toast stack of [state] over it — top center
 * below the safe area, oldest first — and the confirm or prompt dialog of [dialogs], and
 * provides them as [LocalFlareToast] and [LocalFlareDialog]. The host wires every toast's
 * close button and action, runs the timers while it is composed, and keeps the stack a
 * polite live region so each new message is announced.
 */
@Composable
fun FlareToastHost(
    state: FlareToastState = rememberFlareToastState(),
    modifier: Modifier = Modifier,
    dialogs: FlareDialogState = rememberFlareDialogState(),
    content: @Composable () -> Unit,
) {
    CompositionLocalProvider(LocalFlareToast provides state, LocalFlareDialog provides dialogs) {
        Box(modifier) {
            content()
            // Composed even when empty: a toast joining an existing live region is announced.
            Column(
                Modifier.align(Alignment.TopCenter)
                    .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal))
                    // 让开页头：贴着最顶端的 toast 会压在标题和页头动作上 —— 字压字，
                    // 而且它盖住的按钮在它消失前一直点不到。
                    .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingLg)
                    .padding(top = FlareSizes.screenHeaderHeight)
                    .semantics { liveRegion = LiveRegionMode.Polite },
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                for (entry in state.entries) key(entry.id) {
                    if (entry.durationMs > 0) LaunchedEffect(Unit) {
                        delay(entry.durationMs)
                        state.dismiss(entry.id)
                    }
                    Toast(
                        message = entry.message,
                        variant = entry.variant,
                        tone = entry.tone,
                        actionLabel = entry.actionLabel,
                        onAction = { state.runAction(entry.id) },
                        onClose = { state.dismiss(entry.id) },
                    )
                }
            }
            // A dialog opens its own window above the content and the toasts.
            FlareDialogPresenter(dialogs)
        }
    }
}

/** The close control exists only when the host supplied [Toast]' `onClose`. */
internal fun toastCloseVisible(hasOnClose: Boolean): Boolean = hasOnClose

private fun toastToneIcon(tone: FlareStatusTone) = when (tone) {
    FlareStatusTone.Success -> Icons.Filled.CheckCircle
    FlareStatusTone.Warning -> Icons.Filled.Warning
    FlareStatusTone.Danger -> Icons.Filled.Cancel
    FlareStatusTone.Info, FlareStatusTone.Neutral -> Icons.Filled.Info
}
