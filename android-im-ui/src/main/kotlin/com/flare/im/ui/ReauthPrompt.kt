package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Why the current session can no longer be used. Supplied by the host session layer. */
enum class FlareReauthReason { SessionExpired, Kicked, CredentialInvalid, AccountDisabled }

/** Semantic tone of the reason glyph (never the only signal: the text always names the reason). */
enum class FlareReauthTone { Info, Warning, Danger }

fun reauthTone(reason: FlareReauthReason): FlareReauthTone = when (reason) {
    FlareReauthReason.SessionExpired -> FlareReauthTone.Info
    FlareReauthReason.Kicked, FlareReauthReason.CredentialInvalid -> FlareReauthTone.Warning
    FlareReauthReason.AccountDisabled -> FlareReauthTone.Danger
}

/** Semantic icon name (shared [FlareIcon] library) for each reason. */
fun reauthIcon(reason: FlareReauthReason): String = when (reason) {
    FlareReauthReason.SessionExpired -> "clock"
    FlareReauthReason.Kicked -> "devices"
    FlareReauthReason.CredentialInvalid -> "lock"
    FlareReauthReason.AccountDisabled -> "block"
}

data class FlareReauthActionState(val visible: Boolean, val enabled: Boolean)

data class FlareReauthActions(
    val reauthenticate: FlareReauthActionState,
    val logout: FlareReauthActionState,
    /** True when Enter should trigger re-authentication; false when it is unavailable. */
    val primary: Boolean,
)

/**
 * Which actions to show and whether they are enabled.
 * - reauthenticate needs a host handler and is never offered for a disabled account.
 * - logout needs a host handler.
 * - busy locks every action; the host sets it synchronously before dispatching.
 */
fun reauthActions(reason: FlareReauthReason, hasReauth: Boolean, hasLogout: Boolean, busy: Boolean = false): FlareReauthActions {
    val reauthVisible = hasReauth && reason != FlareReauthReason.AccountDisabled
    return FlareReauthActions(
        reauthenticate = FlareReauthActionState(visible = reauthVisible, enabled = reauthVisible && !busy),
        logout = FlareReauthActionState(visible = hasLogout, enabled = hasLogout && !busy),
        primary = reauthVisible,
    )
}

/**
 * Re-authentication prompt shown when the session can no longer be used.
 * The host owns the login flow and the container (full-screen overlay or dialog);
 * this panel names the reason, locks repeat submits, keeps the last failure visible
 * and dispatches [onReauthenticate] / [onLogout]. Buttons whose callback is null are
 * not rendered. Enter triggers the primary action; Escape and system back are swallowed
 * because a broken session cannot be dismissed. Spec: General/ReauthPrompt (`ReauthPrompt`).
 */
@Composable
fun ReauthPrompt(
    reason: FlareReauthReason,
    detail: String? = null,
    busy: Boolean = false,
    error: String? = null,
    accountLabel: String? = null,
    title: String = "需要重新登录",
    sessionExpiredText: String = "登录状态已过期，请重新登录后继续。",
    kickedText: String = "你的账号已在其它设备登录，当前设备已下线。",
    credentialInvalidText: String = "登录凭证已失效，请重新登录。",
    accountDisabledText: String = "账号已被停用，暂时无法登录，请联系管理员。",
    reauthenticateText: String = "重新登录",
    busyText: String = "正在重新登录…",
    logoutText: String = "退出登录",
    accountCaption: String = "当前账号",
    onReauthenticate: (() -> Unit)? = null,
    onLogout: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val colors = flareColors()
    val tone = when (reauthTone(reason)) {
        FlareReauthTone.Info -> colors.info
        FlareReauthTone.Warning -> colors.warning
        FlareReauthTone.Danger -> colors.error
    }
    val actions = reauthActions(reason, hasReauth = onReauthenticate != null, hasLogout = onLogout != null, busy = busy)
    val reasonText = when (reason) {
        FlareReauthReason.SessionExpired -> sessionExpiredText
        FlareReauthReason.Kicked -> kickedText
        FlareReauthReason.CredentialInvalid -> credentialInvalidText
        FlareReauthReason.AccountDisabled -> accountDisabledText
    }
    val reauthenticate: () -> Unit = { if (actions.reauthenticate.enabled) onReauthenticate?.invoke() }


    Column(
        modifier = modifier
            .widthIn(max = 400.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(colors.bgPrimary)
            .padding(horizontal = FlareSizes.spacingXl, vertical = FlareSizes.spacing2xl)
            .onPreviewKeyEvent { event ->
                if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                when (event.key) {
                    Key.Enter, Key.NumPadEnter -> { if (actions.primary) reauthenticate(); actions.primary }
                    Key.Escape -> true
                    else -> false
                }
            },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        Box(
            Modifier.size(56.dp).clip(CircleShape).background(tone.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center,
        ) { FlareIcon(reauthIcon(reason), size = 28.dp, tint = tone) }
        Spacer(Modifier.height(FlareSizes.spacingXs))
        Text(
            title,
            color = colors.textPrimary,
            fontSize = FlareSizes.fontSize3xl.value.sp,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center,
            modifier = Modifier.semantics { heading() },
        )
        Text(reasonText, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, textAlign = TextAlign.Center)
        if (!detail.isNullOrEmpty()) {
            Text(detail, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp, textAlign = TextAlign.Center)
        }
        if (!accountLabel.isNullOrEmpty()) {
            Row(
                Modifier
                    .padding(top = FlareSizes.spacingXs)
                    .clip(RoundedCornerShape(FlareSizes.radiusFull))
                    .background(colors.bgSecondary)
                    .padding(horizontal = 10.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(accountCaption, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
                Spacer(Modifier.width(6.dp))
                Text(
                    accountLabel,
                    color = colors.textPrimary,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false),
                )
            }
        }
        if (!error.isNullOrEmpty()) {
            Box(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingXs).semantics { liveRegion = LiveRegionMode.Assertive }) {
                StatusBanner(error, tone = FlareStatusTone.Danger)
            }
        }
        if (actions.reauthenticate.visible || actions.logout.visible) {
            Column(
                Modifier.fillMaxWidth().padding(top = FlareSizes.spacingMd),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                if (actions.reauthenticate.visible) {
                    PrimaryButton(
                        text = reauthenticateText,
                        onClick = reauthenticate,
                        enabled = actions.reauthenticate.enabled,
                        loading = busy,
                        loadingText = busyText,
                    )
                }
                if (actions.logout.visible) {
                    Button(
                        label = logoutText,
                        variant = FlareButtonVariant.Secondary,
                        size = FlareControlSize.Lg,
                        block = true,
                        disabled = !actions.logout.enabled,
                        onClick = { if (actions.logout.enabled) onLogout?.invoke() },
                    )
                }
            }
        }
    }
}
