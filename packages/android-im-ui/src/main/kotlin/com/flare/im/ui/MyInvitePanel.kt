package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

/**
 * "My invite" — the person's invite code with copy / share / regenerate, how many people each
 * referral depth holds, and who they invited directly. Spec: Profile/MyInvitePanel (`MyInvitePanel`).
 *
 * The host fetched all of it and performs every action; this card only shows the snapshot and
 * dispatches intent. It never touches the clipboard or a share sheet.
 */
@Composable
fun MyInvitePanel(
    /** The person's invite code; empty while the host has none yet. */
    code: String,
    /** Host-built share link; shown under the code and carried by [onShare]. */
    shareUrl: String? = null,
    /** Referral counts per depth; null while unknown. */
    stats: FlareReferralStats? = null,
    /** Depth rows to show (1–3). */
    maxDepthShown: Int = 3,
    /** Direct invitees loaded so far. */
    invitees: List<FlareInvitee> = emptyList(),
    /** `false` replaces the invitee list with its count. */
    showProfiles: Boolean = true,
    hasMore: Boolean = false,
    loadingMore: Boolean = false,
    /** First load in flight — skeleton, never a fake empty list. */
    loading: Boolean = false,
    canRegenerate: Boolean = false,
    /** Epoch ms from which regenerating is allowed again. */
    regenerateAvailableAt: Long? = null,
    regenerating: Boolean = false,
    title: String? = null,
    /** Carries the code. */
    onCopy: ((String) -> Unit)? = null,
    /** Carries the share URL, or the code when the host built none. */
    onShare: ((String) -> Unit)? = null,
    onRegenerate: (() -> Unit)? = null,
    onLoadMore: (() -> Unit)? = null,
    /** Carries the invitee's userId. */
    onSelect: ((String) -> Unit)? = null,
) {
    val strings = flareStrings()
    val colors = flareColors()
    val heading = title ?: strings.myInviteTitle
    val hasCode = code.isNotBlank()
    val showSkeleton = loading && !hasCode

    // The cooldown is a clock reading; re-read it every half minute so the control re-enables on
    // its own once the server's deadline passes.
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(regenerateAvailableAt) {
        while (regenerateAvailableAt != null && regenerateAvailableAt > now) {
            delay(30_000)
            now = System.currentTimeMillis()
        }
    }
    val regenerate = regenerateAvailability(canRegenerate, regenerateAvailableAt, now)
    val rows = referralDepthRows(stats, maxDepthShown)
    val inviteeCount = stats?.direct ?: invitees.size
    val showEmpty = !loading && showProfiles && invitees.isEmpty()

    Column(
        Modifier.fillMaxWidth()
            .semantics { contentDescription = heading }
            .clip(RoundedCornerShape(FlareSizes.radiusLg))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusLg))
            .padding(FlareSizes.spacingMd),
    ) {
        Text(heading, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeLg.value.sp)
        Spacer(Modifier.height(FlareSizes.spacingMd))

        Column(
            Modifier.fillMaxWidth()
                .clip(RoundedCornerShape(FlareSizes.radiusMd))
                .background(colors.bgSecondary)
                .padding(FlareSizes.spacingMd),
        ) {
            Text(strings.myInviteCodeLabel, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
            Spacer(Modifier.height(FlareSizes.spacingSm))
            when {
                showSkeleton -> Spacer(
                    Modifier.width(160.dp).height(28.dp)
                        .semantics { contentDescription = strings.myInviteLoading; liveRegion = LiveRegionMode.Polite }
                        .clip(RoundedCornerShape(FlareSizes.radiusSm)).background(colors.bgPrimary),
                )
                hasCode -> Text(
                    code,
                    color = colors.primaryText,
                    fontFamily = FontFamily.Monospace,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = FlareSizes.fontSize4xl.value.sp,
                    letterSpacing = 0.18.em,
                )
                else -> Text(strings.myInviteCodeUnavailable, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
            }
            if (hasCode && !shareUrl.isNullOrEmpty()) {
                Spacer(Modifier.height(FlareSizes.spacingXs))
                Text(shareUrl, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
            }
            Spacer(Modifier.height(FlareSizes.spacingSm))
            Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm), verticalAlignment = Alignment.CenterVertically) {
                Button(
                    label = strings.myInviteCopy, icon = "copy", variant = FlareButtonVariant.Secondary,
                    size = FlareControlSize.Sm, disabled = !hasCode, onClick = { onCopy?.invoke(code) },
                )
                Button(
                    label = strings.myInviteShare, icon = "share", variant = FlareButtonVariant.Primary,
                    size = FlareControlSize.Sm, disabled = !hasCode,
                    onClick = { onShare?.invoke(if (!shareUrl.isNullOrEmpty()) shareUrl else code) },
                )
                if (regenerate.shown) {
                    Button(
                        label = if (regenerating) strings.myInviteRegenerating else strings.myInviteRegenerate,
                        icon = "refresh", variant = FlareButtonVariant.Ghost, size = FlareControlSize.Sm,
                        loading = regenerating,
                        disabled = !regenerate.enabled || regenerating || loading,
                        onClick = { onRegenerate?.invoke() },
                    )
                }
            }
            regenerate.remaining?.let { remaining ->
                Spacer(Modifier.height(FlareSizes.spacingXs))
                Text(
                    inviteCooldownText(strings, remaining),
                    color = colors.textSecondary,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                    modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite },
                )
            }
        }

        if (rows.isNotEmpty()) {
            Spacer(Modifier.height(FlareSizes.spacingMd))
            Row(
                Modifier.fillMaxWidth().semantics { contentDescription = strings.myInviteStatsTitle },
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                for (depth in rows) {
                    Column(
                        Modifier.weight(1f).widthIn(min = 72.dp)
                            .border(1.dp, colors.borderSecondary, RoundedCornerShape(FlareSizes.radiusMd))
                            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
                    ) {
                        Text(inviteDepthLabel(strings, depth), color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
                        Text(
                            stats!!.of(depth).toString(),
                            color = if (depth == FlareReferralDepth.Total) colors.primaryText else colors.textPrimary,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = FlareSizes.fontSize3xl.value.sp,
                        )
                    }
                }
            }
        }

        Spacer(Modifier.height(FlareSizes.spacingMd))
        Text(strings.myInviteInviteesTitle, color = colors.textSecondary, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeMd.value.sp)
        Spacer(Modifier.height(FlareSizes.spacingSm))
        when {
            !showProfiles -> Text(
                strings.myInviteCountOnly.replace("{count}", inviteeCount.toString()),
                color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp,
            )
            showSkeleton -> repeat(3) {
                Row(Modifier.heightIn(min = FlareSizes.touchTarget), verticalAlignment = Alignment.CenterVertically) {
                    Spacer(Modifier.size(FlareSizes.avatarSize).clip(CircleShape).background(colors.bgSecondary))
                    Spacer(Modifier.width(FlareSizes.spacingMd))
                    Spacer(Modifier.width(120.dp).height(FlareSizes.iconSizeSm).clip(RoundedCornerShape(FlareSizes.radiusSm)).background(colors.bgSecondary))
                }
            }
            showEmpty -> Text(
                strings.myInviteEmpty, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp,
                modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite },
            )
            else -> {
                invitees.forEachIndexed { index, invitee ->
                    if (index > 0) HorizontalDivider(color = colors.borderSecondary)
                    Row(
                        Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget)
                            .then(
                                if (onSelect != null) Modifier.clickable(role = Role.Button, onClickLabel = invitee.displayName) { onSelect(invitee.userId) }
                                else Modifier,
                            )
                            .padding(vertical = FlareSizes.spacingSm),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Avatar(userId = invitee.userId, displayName = invitee.displayName, size = FlareSizes.avatarSize, avatarUrl = invitee.avatarUrl)
                        Spacer(Modifier.width(FlareSizes.spacingMd))
                        Column(Modifier.weight(1f)) {
                            Text(invitee.displayName, color = colors.textPrimary, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeLg.value.sp)
                            Text(
                                strings.myInviteJoined.replace("{date}", inviteJoinedDateLabel(invitee.joinedAt)),
                                color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                            )
                        }
                    }
                }
                if (hasMore) {
                    Spacer(Modifier.height(FlareSizes.spacingSm))
                    Button(
                        label = strings.myInviteLoadMore, variant = FlareButtonVariant.Ghost, size = FlareControlSize.Sm,
                        block = true, loading = loadingMore, disabled = loadingMore, onClick = { onLoadMore?.invoke() },
                    )
                }
            }
        }
    }
}

internal fun inviteDepthLabel(strings: FlareStrings, depth: FlareReferralDepth): String = when (depth) {
    FlareReferralDepth.Direct -> strings.myInviteDirect
    FlareReferralDepth.L2 -> strings.myInviteLevel2
    FlareReferralDepth.L3 -> strings.myInviteLevel3
    FlareReferralDepth.Total -> strings.myInviteTotal
}

internal fun inviteCooldownText(strings: FlareStrings, remaining: FlareInviteCooldown): String {
    val unit = when (remaining.unit) {
        FlareInviteCooldownUnit.Minute -> strings.myInviteUnitMinutes
        FlareInviteCooldownUnit.Hour -> strings.myInviteUnitHours
        FlareInviteCooldownUnit.Day -> strings.myInviteUnitDays
    }
    return strings.myInviteCooldown.replace("{time}", unit.replace("{n}", remaining.count.toString()))
}
