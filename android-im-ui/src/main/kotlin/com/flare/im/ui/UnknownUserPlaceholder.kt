package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Block
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PersonOff
import androidx.compose.material.icons.outlined.PersonOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// MARK: contract (pure, testable without a Compose runtime)

/** Why the host cannot show a real profile; names match the cross-platform contract. */
enum class FlareUnknownUserKind { Unknown, Deactivated, Blocked, Unreachable }

/** `Row` inside lists, `Card` on a detail surface. */
enum class FlareUnknownUserDensity { Row, Card }

/** Tone accompanies — never replaces — the icon and the title text. */
enum class FlareUnknownUserTone { Neutral, Warning, Danger }

/** Icon + tone for one [FlareUnknownUserKind]. */
data class FlareUnknownUserPresentation(
    val kind: FlareUnknownUserKind,
    val tone: FlareUnknownUserTone,
)

/**
 * Icon + tone for [kind]; a null kind degrades to [FlareUnknownUserKind.Unknown]
 * rather than rendering blank, so a stale host value can never blank the row.
 */
fun unknownUserPresentation(kind: FlareUnknownUserKind?): FlareUnknownUserPresentation = when (kind) {
    FlareUnknownUserKind.Deactivated ->
        FlareUnknownUserPresentation(FlareUnknownUserKind.Deactivated, FlareUnknownUserTone.Neutral)
    FlareUnknownUserKind.Blocked ->
        FlareUnknownUserPresentation(FlareUnknownUserKind.Blocked, FlareUnknownUserTone.Danger)
    FlareUnknownUserKind.Unreachable ->
        FlareUnknownUserPresentation(FlareUnknownUserKind.Unreachable, FlareUnknownUserTone.Warning)
    else ->
        FlareUnknownUserPresentation(FlareUnknownUserKind.Unknown, FlareUnknownUserTone.Neutral)
}

/** Default budget for the diagnostic id line; long ids are middle-elided. */
const val FLARE_UNKNOWN_USER_ID_MAX_LENGTH = 24

/**
 * The user id as it appears in the diagnostic slot: trimmed, and middle-elided to
 * [maxLength] characters (ellipsis included) so a 64-character id never becomes the
 * widest thing on screen. Never used as the title.
 */
fun shortenUserId(userId: String?, maxLength: Int = FLARE_UNKNOWN_USER_ID_MAX_LENGTH): String {
    val id = (userId ?: "").trim()
    val limit = if (maxLength < 8) 8 else maxLength
    if (id.length <= limit) return id
    val head = (limit - 1 + 1) / 2 // ceil((limit - 1) / 2)
    val tail = limit - 1 - head
    return id.substring(0, head) + "…" + id.substring(id.length - tail)
}

/** Semantic glyph for [kind]; each kind gets its own, so state is never colour-only. */
fun unknownUserIcon(kind: FlareUnknownUserKind): ImageVector = when (kind) {
    FlareUnknownUserKind.Unknown -> Icons.Outlined.PersonOutline
    FlareUnknownUserKind.Deactivated -> Icons.Outlined.PersonOff
    FlareUnknownUserKind.Blocked -> Icons.Outlined.Block
    FlareUnknownUserKind.Unreachable -> Icons.Outlined.Lock
}

/**
 * Placeholder for an account the host cannot describe: an id that resolved to
 * nothing, a deactivated account, a blocked one, or one that is simply not
 * contactable right now. Without it these rows render blank or, worse, show a
 * bare user id as the title. Pure display: no actions, no callbacks, no I/O.
 * Spec: Contacts/UnknownUserPlaceholder (`UnknownUserPlaceholder`).
 */
@Composable
fun UnknownUserPlaceholder(
    /** The id the host failed to resolve. Diagnostic only — never the title. */
    userId: String,
    kind: FlareUnknownUserKind,
    density: FlareUnknownUserDensity = FlareUnknownUserDensity.Row,
    /** Host-supplied supplement, e.g. where the id came from. */
    detail: String? = null,
    unknownText: String = "未知用户",
    deactivatedText: String = "该账号已注销",
    blockedText: String = "该账号已被屏蔽",
    unreachableText: String = "暂时无法联系该账号",
    idLabel: String = "ID",
    idMaxLength: Int = FLARE_UNKNOWN_USER_ID_MAX_LENGTH,
) {
    val colors = flareColors()
    val presentation = unknownUserPresentation(kind)
    val card = density == FlareUnknownUserDensity.Card
    val title = when (presentation.kind) {
        FlareUnknownUserKind.Deactivated -> deactivatedText
        FlareUnknownUserKind.Blocked -> blockedText
        FlareUnknownUserKind.Unreachable -> unreachableText
        FlareUnknownUserKind.Unknown -> unknownText
    }
    val fullId = userId.trim()
    val shortId = shortenUserId(userId, idMaxLength)
    val supplement = (detail ?: "").trim()
    val badge = when (presentation.tone) {
        FlareUnknownUserTone.Danger -> colors.error
        FlareUnknownUserTone.Warning -> colors.warning
        FlareUnknownUserTone.Neutral -> colors.textSecondary
    }
    // The id is diagnostic, so it is read out after the reason, never before it.
    val description = buildList {
        add(title)
        if (supplement.isNotEmpty()) add(supplement)
        if (fullId.isNotEmpty()) add("$idLabel $fullId")
    }.joinToString(" · ")

    val avatar: @Composable () -> Unit = {
        Box(
            Modifier.size(if (card) 64.dp else FlareSizes.avatarSize)
                .clip(CircleShape)
                .background(colors.bgDisabled),
            contentAlignment = Alignment.Center,
        ) {
            // Neutral silhouette, never an emoji.
            Icon(
                Icons.Outlined.Person,
                contentDescription = null,
                tint = colors.textTertiary,
                modifier = Modifier.size(if (card) 28.dp else 20.dp),
            )
        }
    }

    val details: @Composable () -> Unit = {
        Column(horizontalAlignment = if (card) Alignment.CenterHorizontally else Alignment.Start) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    Modifier.size(22.dp).clip(CircleShape).background(colors.bgDisabled),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        unknownUserIcon(presentation.kind),
                        contentDescription = null,
                        tint = badge,
                        modifier = Modifier.size(14.dp),
                    )
                }
                Spacer(Modifier.width(6.dp))
                Text(
                    title,
                    color = colors.textPrimary,
                    fontSize = (if (card) FlareSizes.fontSize3xl else FlareSizes.fontSizeLg).value.sp,
                    fontWeight = FontWeight.SemiBold,
                    textAlign = if (card) TextAlign.Center else TextAlign.Start,
                )
            }
            if (supplement.isNotEmpty()) {
                Text(
                    supplement,
                    color = colors.textSecondary,
                    fontSize = FlareSizes.fontSizeMd.value.sp,
                    textAlign = if (card) TextAlign.Center else TextAlign.Start,
                )
            }
            if (shortId.isNotEmpty()) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(idLabel, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
                    Spacer(Modifier.width(5.dp))
                    // Ids are opaque tokens: they stay LTR and elide rather than wrap.
                    Text(
                        shortId,
                        color = colors.textTertiary,
                        fontSize = FlareSizes.fontSizeSm.value.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
    }

    if (card) {
        Column(
            Modifier.fillMaxWidth()
                .clip(RoundedCornerShape(FlareSizes.radiusLg))
                .background(colors.bgSecondary)
                .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingXl)
                .semantics(mergeDescendants = true) { contentDescription = description },
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            avatar()
            details()
        }
    } else {
        Row(
            Modifier.fillMaxWidth()
                .defaultMinSize(minHeight = FlareSizes.touchTarget)
                .semantics(mergeDescendants = true) { contentDescription = description },
            verticalAlignment = Alignment.CenterVertically,
        ) {
            avatar()
            Spacer(Modifier.width(FlareSizes.spacingMd))
            details()
        }
    }
}
