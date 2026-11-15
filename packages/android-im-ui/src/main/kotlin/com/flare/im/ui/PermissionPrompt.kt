package com.flare.im.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Which system permission the prompt explains. Spec: General/PermissionPrompt. */
enum class FlarePermissionKind { Microphone, Camera, Notifications, Storage, Photos, Contacts, Location, Screen }

/**
 * Host-reported permission state; the composable never queries the platform. [Granted] lets a host bind the
 * platform's permission status directly: the prompt renders nothing for it.
 */
enum class FlarePermissionState { Undetermined, Denied, Restricted, Unavailable, Granted }

/**
 * Where the prompt appears. [Inline] sits in the page (a card, or the compact strip); [Sheet] hosts it in the
 * kit [BottomSheet] with the automatic presentation (a bottom sheet on the phone form factor, a centered [Modal]
 * elsewhere): composing it shows it, a key closes it and its callback runs once the sheet is gone, and closing it
 * by the scrim, back or Escape is a dismiss.
 */
enum class FlarePermissionPresentation { Inline, Sheet }

/** The key a sheet prompt closed with, handed to its callback once the sheet is gone. */
private enum class PermissionSheetChoice { Request, OpenSettings, Dismiss }

/**
 * Whether the prompt draws anything. Nothing for [FlarePermissionState.Granted]. A soft-ask is an invitation the
 * person can act on, so it shows only while the permission can be asked for or turned on in settings.
 */
fun permissionPromptShows(state: FlarePermissionState, softAsk: Boolean = false): Boolean = when (state) {
    FlarePermissionState.Granted -> false
    FlarePermissionState.Undetermined, FlarePermissionState.Denied -> true
    FlarePermissionState.Restricted, FlarePermissionState.Unavailable -> !softAsk
}

/**
 * Action visibility computed from state + which callbacks the host supplied.
 * [request] only while undetermined, [openSettings] only while denied, [dismiss] whenever
 * supplied and the prompt shows; [enabled] is false while busy (visible actions stay rendered but disabled).
 */
data class FlarePermissionActions(val request: Boolean, val openSettings: Boolean, val dismiss: Boolean, val enabled: Boolean)

fun permissionActions(
    state: FlarePermissionState,
    hasRequest: Boolean,
    hasOpenSettings: Boolean,
    hasDismiss: Boolean,
    busy: Boolean = false,
): FlarePermissionActions = FlarePermissionActions(
    request = state == FlarePermissionState.Undetermined && hasRequest,
    openSettings = state == FlarePermissionState.Denied && hasOpenSettings,
    dismiss = state != FlarePermissionState.Granted && hasDismiss,
    enabled = !busy,
)

/** Default copy for a kind + state pair. */
data class FlarePermissionCopy(val title: String, val description: String, val primaryLabel: String)

/** Kit icon name per kind (resolved through [FlareIcon]; same names on every platform). */
fun permissionIconName(kind: FlarePermissionKind): String = when (kind) {
    FlarePermissionKind.Microphone -> "mic"
    FlarePermissionKind.Camera -> "camera"
    FlarePermissionKind.Notifications -> "notification"
    FlarePermissionKind.Storage -> "storage"
    FlarePermissionKind.Photos -> "image"
    FlarePermissionKind.Contacts -> "people"
    FlarePermissionKind.Location -> "location"
    FlarePermissionKind.Screen -> "screen-share"
}

/** State glyph so status never relies on colour alone. */
fun permissionStateIconName(state: FlarePermissionState): String = when (state) {
    FlarePermissionState.Undetermined -> "info"
    FlarePermissionState.Denied -> "error"
    FlarePermissionState.Restricted -> "lock"
    FlarePermissionState.Unavailable -> "warning"
    FlarePermissionState.Granted -> "success"
}

/**
 * `featureLabel` (e.g. "发送语音消息") is embedded in the description. All wording comes from
 * [strings] (`permissionNoun` / `permissionVerb` / `permission*Body` …) so a host that installs
 * another language at the root gets it here too; the composable passes `flareStrings()`.
 * [FlarePermissionState.Granted] has nothing to explain: an empty description and no primary action.
 */
fun defaultPermissionCopy(
    kind: FlarePermissionKind,
    state: FlarePermissionState,
    featureLabel: String? = null,
    strings: FlareStrings = FlareStrings(),
): FlarePermissionCopy {
    val feature = featureLabel?.trim().takeUnless { it.isNullOrEmpty() } ?: strings.permissionFeatureFallback
    val verb = strings.permissionVerb(kind)
    val title = strings.permissionTitle(strings.permissionNoun(kind))
    return when (state) {
        FlarePermissionState.Undetermined -> FlarePermissionCopy(title, strings.permissionUndeterminedBody(feature, verb), strings.permissionAllow)
        FlarePermissionState.Denied -> FlarePermissionCopy(title, strings.permissionDeniedBody(feature, verb), strings.permissionOpenSettings)
        FlarePermissionState.Restricted -> FlarePermissionCopy(title, strings.permissionRestrictedBody(feature, verb), "")
        FlarePermissionState.Unavailable -> FlarePermissionCopy(title, strings.permissionUnavailableBody(feature, verb), "")
        FlarePermissionState.Granted -> FlarePermissionCopy(title, "", "")
    }
}

/**
 * The copy of a soft-ask (`PermissionPrompt(softAsk = true)`). The notifications kind has its own: an invitation
 * titled for new messages, "Turn on notifications" while the system can still ask and, once notifications were
 * turned off, "Open Settings" with where to turn them back on. Any other kind keeps [defaultPermissionCopy].
 */
fun defaultPermissionSoftAskCopy(
    kind: FlarePermissionKind,
    state: FlarePermissionState,
    featureLabel: String? = null,
    strings: FlareStrings = FlareStrings(),
): FlarePermissionCopy {
    if (kind != FlarePermissionKind.Notifications) return defaultPermissionCopy(kind, state, featureLabel, strings)
    val title = strings.permissionSoftAskNotificationsTitle
    return when (state) {
        FlarePermissionState.Undetermined -> FlarePermissionCopy(title, strings.permissionSoftAskNotificationsBody, strings.permissionSoftAskNotificationsAction)
        FlarePermissionState.Denied -> FlarePermissionCopy(title, strings.permissionSoftAskNotificationsDeniedBody, strings.permissionOpenSettings)
        else -> defaultPermissionCopy(kind, state, featureLabel, strings)
    }
}

fun defaultPermissionStateLabel(state: FlarePermissionState, strings: FlareStrings = FlareStrings()): String =
    strings.permissionStateLabel(state)

/**
 * Unified "permission missing / denied" panel. The host owns the real permission state and the
 * request / openSettings side effects; this composable only explains and dispatches.
 * Spec: General/PermissionPrompt (`PermissionPrompt`).
 *
 * [softAsk] is the non-blocking invitation a host shows at a moment it picks (the first visit to the
 * conversation list, say): no state chip, a "Not now" dismiss and, for the notifications kind, copy of its own
 * ([defaultPermissionSoftAskCopy]). It shows only while the person can act on it ([permissionPromptShows]);
 * [FlarePermissionState.Granted] renders nothing in any form, so a host binds the platform's status as it is.
 * [presentation] [FlarePermissionPresentation.Sheet] hosts the prompt in [BottomSheet]: composing it shows it. A
 * key closes the sheet first and its callback runs once the sheet is gone, so the system permission dialog the host
 * then opens has the screen to itself; the scrim, back and Escape close it the same way as a dismiss (only with
 * [onDismiss]), and nothing closes it while [busy]. Once closed it stays closed while the host keeps it composed;
 * composing it anew asks again.
 */
@Suppress("NAME_SHADOWING")
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun PermissionPrompt(
    kind: FlarePermissionKind,
    state: FlarePermissionState,
    featureLabel: String? = null,
    detail: String? = null,
    busy: Boolean = false,
    compact: Boolean = false,
    softAsk: Boolean = false,
    presentation: FlarePermissionPresentation = FlarePermissionPresentation.Inline,
    title: String? = null,
    description: String? = null,
    stateText: String? = null,
    requestText: String? = null,
    openSettingsText: String? = null,
    dismissText: String? = null,
    onRequest: (() -> Unit)? = null,
    onOpenSettings: (() -> Unit)? = null,
    onDismiss: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    if (!permissionPromptShows(state, softAsk)) return
    val strings = flareStrings()
    val dismissText = dismissText ?: if (softAsk) strings.permissionNotNow else strings.permissionDismiss
    val colors = flareColors()
    val copy = if (softAsk) defaultPermissionSoftAskCopy(kind, state, featureLabel, strings) else defaultPermissionCopy(kind, state, featureLabel, strings)
    val actions = permissionActions(state, onRequest != null, onOpenSettings != null, onDismiss != null, busy)
    val resolvedTitle = title ?: copy.title
    val sheet = presentation == FlarePermissionPresentation.Sheet
    // The compact strip is an inline form; on a sheet the prompt lays out for the sheet.
    val compact = compact && !sheet
    val tone = when (state) {
        FlarePermissionState.Undetermined, FlarePermissionState.Granted -> colors.info
        FlarePermissionState.Denied -> colors.error
        FlarePermissionState.Restricted -> colors.warning
        FlarePermissionState.Unavailable -> colors.textSecondary
    }
    val hasActions = actions.request || actions.openSettings || actions.dismiss
    val radius = if (compact) FlareSizes.radiusMd else FlareSizes.radiusLg

    val icon: @Composable () -> Unit = {
        Box(
            Modifier.size(if (compact) 32.dp else 44.dp).clip(CircleShape).background(colors.primary.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center,
        ) { FlareIcon(permissionIconName(kind), size = if (compact) 20.dp else 26.dp, tint = colors.primaryText) }
    }
    val textBlock: @Composable (Modifier) -> Unit = { m ->
        Column(m, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
            FlowRow(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Text(
                    resolvedTitle,
                    color = colors.textPrimary,
                    fontSize = (if (compact) FlareSizes.fontSizeLg else FlareSizes.fontSizeXl).value.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                // A soft-ask is an invitation, not a status report: it carries no state chip.
                if (!softAsk) {
                    Row(
                        Modifier
                            .clip(RoundedCornerShape(FlareSizes.radiusFull))
                            .background(tone.copy(alpha = 0.12f))
                            .padding(horizontal = FlareSizes.spacingSm, vertical = 2.dp)
                            .semantics { liveRegion = LiveRegionMode.Polite },
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
                    ) {
                        FlareIcon(permissionStateIconName(state), size = 14.dp, tint = tone)
                        Text(stateText ?: defaultPermissionStateLabel(state, strings), color = tone, fontSize = FlareSizes.fontSizeXs.value.sp, fontWeight = FontWeight.SemiBold)
                    }
                }
            }
            Text(
                description ?: copy.description,
                color = colors.textSecondary,
                fontSize = (if (compact) FlareSizes.fontSizeSm else FlareSizes.fontSizeMd).value.sp,
            )
            if (!detail.isNullOrEmpty()) {
                Text(detail, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
            }
        }
    }
    val actionRow: @Composable () -> Unit = {
        FlowRow(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            if (actions.request && onRequest != null) {
                Box(Modifier.widthIn(min = 48.dp, max = 240.dp)) {
                    Button(label = requestText ?: copy.primaryLabel, size = FlareControlSize.Lg, block = true, loading = busy, disabled = !actions.enabled, onClick = onRequest)
                }
            }
            if (actions.openSettings && onOpenSettings != null) {
                Box(Modifier.widthIn(min = 48.dp, max = 240.dp)) {
                    Button(label = openSettingsText ?: copy.primaryLabel, size = FlareControlSize.Lg, block = true, loading = busy, disabled = !actions.enabled, onClick = onOpenSettings)
                }
            }
            if (actions.dismiss && onDismiss != null) {
                OutlinedButton(
                    onClick = onDismiss,
                    enabled = actions.enabled,
                    shape = RoundedCornerShape(FlareSizes.radiusLg),
                    border = BorderStroke(1.dp, colors.borderPrimary),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = colors.textPrimary),
                    modifier = Modifier.defaultMinSize(minWidth = 48.dp, minHeight = 48.dp),
                ) { Text(dismissText, fontSize = FlareSizes.fontSizeXl.value.sp, fontWeight = FontWeight.SemiBold) }
            }
        }
    }

    if (sheet) {
        // Every way out ends with the sheet gone before the host hears of it: a key slides the sheet out, the scrim,
        // back and Escape too (as a dismiss), and the choice reaches its callback once the sheet has left the
        // composition.
        var closed by rememberSaveable { mutableStateOf(false) }
        var picked by remember { mutableStateOf<PermissionSheetChoice?>(null) }
        var answer by remember { mutableStateOf<PermissionSheetChoice?>(null) }
        val currentRequest by rememberUpdatedState(onRequest)
        val currentOpenSettings by rememberUpdatedState(onOpenSettings)
        val currentDismiss by rememberUpdatedState(onDismiss)
        LaunchedEffect(answer) {
            val made = answer ?: return@LaunchedEffect
            answer = null
            when (made) {
                PermissionSheetChoice.Request -> currentRequest?.invoke()
                PermissionSheetChoice.OpenSettings -> currentOpenSettings?.invoke()
                PermissionSheetChoice.Dismiss -> currentDismiss?.invoke()
            }
        }
        if (closed) return
        // The prompt draws its own heading, so the sheet keeps the title as its accessible name only.
        BottomSheet(
            onClose = {
                answer = picked ?: PermissionSheetChoice.Dismiss
                closed = true
            },
            title = resolvedTitle,
            titleHidden = true,
            dismissible = !busy && onDismiss != null,
        ) {
            val finish = LocalFlareOverlayFinish.current
            val choose: (PermissionSheetChoice) -> Unit = { choice ->
                if (picked == null) {
                    picked = choice
                    finish?.invoke()
                }
            }
            Column(
                Modifier.fillMaxWidth().weight(1f, fill = false).verticalScroll(rememberScrollState())
                    .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                icon()
                Text(
                    resolvedTitle,
                    color = colors.textPrimary,
                    fontSize = FlareSizes.fontSizeXl,
                    fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.semantics { heading() },
                )
                Text(description ?: copy.description, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd, textAlign = TextAlign.Center)
                if (!detail.isNullOrEmpty()) {
                    Text(detail, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, textAlign = TextAlign.Center)
                }
            }
            // Full-width keys within thumb reach, the action first and "Not now" under it.
            if (hasActions) {
                Column(
                    Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
                    verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                ) {
                    if (actions.request) {
                        Button(label = requestText ?: copy.primaryLabel, size = FlareControlSize.Lg, block = true, loading = busy, disabled = !actions.enabled, onClick = { choose(PermissionSheetChoice.Request) })
                    }
                    if (actions.openSettings) {
                        Button(label = openSettingsText ?: copy.primaryLabel, size = FlareControlSize.Lg, block = true, loading = busy, disabled = !actions.enabled, onClick = { choose(PermissionSheetChoice.OpenSettings) })
                    }
                    if (actions.dismiss) {
                        Button(label = dismissText, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Lg, block = true, disabled = !actions.enabled, onClick = { choose(PermissionSheetChoice.Dismiss) })
                    }
                }
            }
        }
        return
    }

    Box(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(radius))
            .background(colors.bgSecondary)
            .then(if (compact) Modifier.border(1.dp, colors.borderSecondary, RoundedCornerShape(radius)) else Modifier)
            .padding(horizontal = if (compact) FlareSizes.spacingMd else FlareSizes.spacingLg, vertical = if (compact) FlareSizes.spacingSm else FlareSizes.spacingLg)
            .semantics { contentDescription = resolvedTitle },
    ) {
        if (compact) {
            BoxWithConstraints {
                if (maxWidth >= 480.dp) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        icon()
                        Spacer(Modifier.width(FlareSizes.spacingMd))
                        textBlock(Modifier.weight(1f))
                        if (hasActions) { Spacer(Modifier.width(FlareSizes.spacingMd)); actionRow() }
                    }
                } else {
                    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            icon()
                            Spacer(Modifier.width(FlareSizes.spacingMd))
                            textBlock(Modifier.weight(1f))
                        }
                        if (hasActions) actionRow()
                    }
                }
            }
        } else {
            Row(verticalAlignment = Alignment.Top) {
                icon()
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Column(Modifier.weight(1f)) {
                    textBlock(Modifier.fillMaxWidth())
                    if (hasActions) { Spacer(Modifier.height(FlareSizes.spacingMd)); actionRow() }
                }
            }
        }
    }
}
