package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.launch

/**
 * The invite code, a registration QR when configured, and referral information.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun MyInvitePanel(
    /** The person's invite code; empty while the host has none yet. */
    code: String,
    /** Host-built registration link used only as the QR payload. */
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
    title: String? = null,
    /** Carries the code. */
    onCopy: ((String) -> Unit)? = null,
    onLoadMore: (() -> Unit)? = null,
    /** Carries the invitee's userId. */
    onSelect: ((String) -> Unit)? = null,
    /** A hosting screen with the same title can show its own heading. */
    showTitle: Boolean = true,
    /** Loads a page of direct children of an invitee. */
    onLoadChildren: (suspend (String, String?) -> FlareInviteeBranchPage)? = null,
) {
    val strings = flareStrings()
    val colors = flareColors()
    val heading = title ?: strings.myInviteTitle
    val link = shareUrl?.takeIf { it.isNotBlank() }
    val hasCode = code.isNotBlank()
    val showSkeleton = loading

    val rows = referralDepthRows(stats, maxDepthShown)
    val showEmpty = !loading && showProfiles && invitees.isEmpty() && !hasMore

    Column(Modifier.fillMaxWidth().wrapContentWidth().widthIn(max = 560.dp).fillMaxWidth()) {
        if (showTitle) {
            Text(heading, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeLg.value.sp)
            Spacer(Modifier.height(FlareSizes.spacingMd))
        }

        Column(
            Modifier.fillMaxWidth()
                .clip(RoundedCornerShape(FlareSizes.radiusLg))
                .background(colors.bgSecondary)
                .background(colors.primary.copy(alpha = 0.08f))
                .padding(FlareSizes.spacingMd),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            when {
                showSkeleton -> Spacer(
                    Modifier.width(160.dp).height(28.dp)
                        .semantics { contentDescription = strings.myInviteLoading; liveRegion = LiveRegionMode.Polite }
                        .clip(RoundedCornerShape(FlareSizes.radiusSm)).background(colors.bgPrimary),
                )
                !hasCode -> Text(
                    strings.myInviteCodeUnavailable, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp,
                )
                else -> {
                    val symbol = remember(link) { link?.let { QrEncoder.encodeText(it) } }
                    if (symbol != null) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                        ) {
                            FlareQrFrame(symbol, strings.myInviteQrHint, Modifier.widthIn(max = 196.dp))
                            Text(
                                strings.myInviteQrHint, color = colors.textSecondary,
                                fontSize = FlareSizes.fontSizeSm.value.sp, textAlign = TextAlign.Center,
                                modifier = Modifier.clearAndSetSemantics {},
                            )
                        }
                    }
                    InviteCodeRow(code, onCopy)
                }
            }
        }

        if (rows.isNotEmpty()) {
            Spacer(Modifier.height(FlareSizes.spacingMd))
            Text(strings.myInviteStatsTitle, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeMd.value.sp)
            Spacer(Modifier.height(FlareSizes.spacingSm))
            FlowRow(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
            ) {
                for (depth in rows) {
                    Column(
                        Modifier.widthIn(min = 72.dp).weight(1f)
                            .clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgSecondary)
                            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingSm),
                    ) {
                        Text(inviteDepthLabel(strings, depth), color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
                        Text(
                            stats!!.of(depth).toString(),
                            color = if (depth == FlareReferralDepth.Total) colors.primaryText else colors.textPrimary,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = FlareSizes.fontSizeXl.value.sp,
                        )
                    }
                }
            }
        }

        if (showProfiles && maxDepthShown > 0) {
            Spacer(Modifier.height(FlareSizes.spacingMd))
            Text(strings.myInviteRelationships, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeMd.value.sp)
            Spacer(Modifier.height(FlareSizes.spacingSm))
            when {
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
                        key(invitee.userId) {
                            InviteeBranchRow(invitee, maxDepthShown - 1, onSelect, onLoadChildren)
                        }
                    }
                    if (hasMore) {
                        Spacer(Modifier.height(FlareSizes.spacingSm))
                        Button(
                            label = strings.myInviteLoadMore, variant = FlareButtonVariant.Ghost, size = FlareControlSize.Sm,
                            block = true, loading = loadingMore, disabled = loadingMore || loading,
                            maintainTouchTarget = true, onClick = { onLoadMore?.invoke() },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun InviteeBranchRow(
    invitee: FlareInvitee,
    remainingDepth: Int,
    onSelect: ((String) -> Unit)?,
    onLoadChildren: (suspend (String, String?) -> FlareInviteeBranchPage)?,
) {
    val strings = flareStrings()
    val colors = flareColors()
    val scope = rememberCoroutineScope()
    val expandable = remainingDepth > 0 && invitee.hasChildren && onLoadChildren != null
    var expanded by remember { mutableStateOf(false) }
    var children by remember { mutableStateOf<List<FlareInvitee>?>(null) }
    var nextCursor by remember { mutableStateOf<String?>(null) }
    var loading by remember { mutableStateOf(false) }
    var failed by remember { mutableStateOf(false) }

    fun loadPage() {
        if (loading || onLoadChildren == null) return
        loading = true
        failed = false
        val cursor = nextCursor
        scope.launch {
            try {
                val page = onLoadChildren(invitee.userId, cursor)
                children = (children.orEmpty() + page.invitees).distinctBy(FlareInvitee::userId)
                nextCursor = page.nextCursor?.takeUnless { it == cursor }
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                failed = true
            } finally {
                loading = false
            }
        }
    }

    fun toggleBranch() {
        expanded = !expanded
        if (expanded && children == null && !failed) loadPage()
    }

    val branchLabel = (if (expanded) strings.myInviteCollapse else strings.myInviteExpand)
        .replace("{name}", invitee.displayName)
    val branchIcon = if (expanded) "chevron-down" else "chevron-right"
    val expandsFromRow = expandable && onSelect == null

    Column {
        Row(
            Modifier.fillMaxWidth().then(
                if (expandsFromRow) Modifier.clickable(role = Role.Button, onClick = ::toggleBranch)
                    .semantics { contentDescription = branchLabel }
                else Modifier,
            ),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(
                Modifier.weight(1f).heightIn(min = FlareSizes.touchTarget)
                    .then(
                        if (onSelect != null) Modifier.clickable(role = Role.Button, onClickLabel = invitee.displayName) { onSelect(invitee.userId) }
                        else Modifier,
                    )
                    .padding(vertical = FlareSizes.spacingXs),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Avatar(userId = invitee.userId, displayName = invitee.displayName, size = FlareSizes.avatarSize, avatarUrl = invitee.avatarUrl)
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Column(Modifier.weight(1f)) {
                    Text(invitee.displayName, color = colors.textPrimary, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeLg.value.sp)
                    if (invitee.joinedAt > 0) {
                        Text(
                            strings.myInviteJoined.replace("{date}", inviteJoinedDateLabel(invitee.joinedAt)),
                            color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp,
                        )
                    }
                }
            }
            if (expandsFromRow) {
                Box(Modifier.width(FlareSizes.touchTarget), contentAlignment = Alignment.Center) {
                    FlareIcon(branchIcon, size = FlareSizes.iconSizeSm)
                }
            } else if (expandable) {
                IconButton(icon = branchIcon, contentDescription = branchLabel, onClick = ::toggleBranch)
            }
        }
        if (expanded && expandable) {
            Column(
                Modifier.fillMaxWidth().padding(start = FlareSizes.spacing2xl),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
            ) {
                children.orEmpty().forEach { child ->
                    key(child.userId) { InviteeBranchRow(child, remainingDepth - 1, onSelect, onLoadChildren) }
                }
                when {
                    loading -> Text(
                        strings.myInviteLoading, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp,
                        modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite },
                    )
                    failed -> Button(
                        label = strings.retry, variant = FlareButtonVariant.Ghost, size = FlareControlSize.Sm,
                        maintainTouchTarget = true, onClick = ::loadPage,
                    )
                    nextCursor != null -> Button(
                        label = strings.myInviteLoadMore, variant = FlareButtonVariant.Ghost, size = FlareControlSize.Sm,
                        maintainTouchTarget = true, onClick = ::loadPage,
                    )
                    children?.isEmpty() == true -> Text(
                        strings.myInviteNoChildren, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp,
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

@Composable
private fun InviteCodeRow(code: String, onCopy: ((String) -> Unit)?) {
    val colors = flareColors()
    val strings = flareStrings()
    val fontScale = LocalDensity.current.fontScale
    BoxWithConstraints(
        Modifier.fillMaxWidth()
            .clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(colors.bgPrimary)
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
    ) {
        val identity: @Composable (Modifier) -> Unit = { modifier ->
            Column(modifier, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Text(strings.myInviteCodeLabel, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
                Text(
                    code, color = colors.primaryText, fontFamily = FontFamily.Monospace,
                    fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSize3xl.value.sp,
                )
            }
        }
        val copy: @Composable () -> Unit = {
            if (onCopy != null) {
                Button(
                    label = strings.myInviteCopy, icon = "copy", variant = FlareButtonVariant.Primary,
                    size = FlareControlSize.Sm, maintainTouchTarget = true, onClick = { onCopy(code) },
                )
            }
        }
        if (onCopy == null) {
            identity(Modifier.fillMaxWidth())
        } else if (maxWidth >= 240.dp * fontScale) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
            ) {
                identity(Modifier.weight(1f))
                copy()
            }
        } else {
            Column(
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                horizontalAlignment = Alignment.End,
            ) {
                identity(Modifier.fillMaxWidth())
                copy()
            }
        }
    }
}
