package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.Campaign
import androidx.compose.material.icons.outlined.PersonAdd
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material.icons.outlined.VolumeOff
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** A minimal contact reference — enough to render a row (avatar + name). */
data class ContactBrief(
    val userId: String,
    val displayName: String,
    val avatarUrl: String? = null,
)

/** One hit from a contact-book match. */
data class MatchedContact(
    val userId: String,
    val displayName: String,
    val avatarUrl: String? = null,
    /**
     * The phone/email that matched. Echoed on the row because the display name is
     * a nickname the user may not recognise from their address book.
     */
    val matchedBy: String,
    /** Already a friend → offer 发消息 instead of 添加. */
    val alreadyFriend: Boolean = false,
)

/**
 * Which direction a Moments visibility rule points.
 *
 * The two are opposites and setting the wrong one has privacy consequences, so
 * components must never share wording between them.
 */
enum class MomentsVisibilityRuleKind {
    /** Hide my moments from this person. */
    HIDE_FROM,

    /** Do not show me this person's moments. */
    MUTE,
}

/** Chinese-default labels for [MomentsVisibilityRuleList]. Kept per-kind on purpose. */
data class FlareMomentsVisibilityLabels(
    val hideFromTitle: String = "不让他看我的朋友圈",
    val hideFromHint: String = "名单中的人看不到你发的内容",
    val muteTitle: String = "不看他的朋友圈",
    val muteHint: String = "你不会看到名单中的人发的内容",
    val empty: String = "名单为空",
    val remove: String = "移出",
)

/**
 * Moments visibility list — the members under one rule, with add / remove.
 *
 * The two rule kinds point in **opposite** directions: hide-from controls who
 * cannot see me, mute controls whose posts I do not see. Getting them backwards
 * leaks moments to someone the user meant to hide from, so title, hint, empty copy
 * and accent colour are all keyed off [kind] rather than shared.
 * Spec: Moments/MomentsVisibilityRuleList (`MomentsVisibilityRuleList`).
 */
@Composable
fun MomentsVisibilityRuleList(
    kind: MomentsVisibilityRuleKind,
    members: List<ContactBrief>,
    loading: Boolean = false,
    labels: FlareMomentsVisibilityLabels = FlareMomentsVisibilityLabels(),
    onAdd: (() -> Unit)? = null,
    onRemove: ((ContactBrief) -> Unit)? = null,
    onSelectMember: ((ContactBrief) -> Unit)? = null,
) {
    val colors = flareColors()
    val isHideFrom = kind == MomentsVisibilityRuleKind.HIDE_FROM

    Column(Modifier.fillMaxWidth()) {
        Row(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingMd),
            verticalAlignment = Alignment.Top,
        ) {
            Icon(
                if (isHideFrom) Icons.Outlined.VisibilityOff else Icons.Outlined.VolumeOff,
                contentDescription = null,
                // Distinct accents so both rules on one screen stay tellable apart.
                tint = if (isHideFrom) colors.warning else colors.textTertiary,
                modifier = Modifier.size(16.dp).padding(top = 2.dp),
            )
            Spacer(Modifier.width(FlareSizes.spacingSm))
            Column(Modifier.weight(1f)) {
                Text(
                    if (isHideFrom) labels.hideFromTitle else labels.muteTitle,
                    color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp,
                )
                Text(
                    if (isHideFrom) labels.hideFromHint else labels.muteHint,
                    color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                )
            }
            if (onAdd != null) {
                Icon(
                    Icons.Outlined.PersonAdd, contentDescription = null,
                    tint = colors.textSecondary,
                    modifier = Modifier.size(20.dp).clickable { onAdd() },
                )
            }
        }

        when {
            loading -> Box(Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingLg),
                contentAlignment = Alignment.Center) {
                CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
            }

            members.isEmpty() -> Text(
                labels.empty, color = colors.textTertiary,
                fontSize = FlareSizes.fontSizeMd.value.sp,
                modifier = Modifier.padding(
                    start = FlareSizes.spacingMd, end = FlareSizes.spacingMd,
                    bottom = FlareSizes.spacingLg,
                ),
            )

            else -> members.forEach { m ->
                Row(
                    Modifier.fillMaxWidth()
                        .then(if (onSelectMember != null) Modifier.clickable { onSelectMember(m) } else Modifier)
                        .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Avatar(userId = m.userId, displayName = m.displayName, size = 32.dp)
                    Spacer(Modifier.width(FlareSizes.spacingSm))
                    Text(
                        m.displayName, color = colors.textPrimary,
                        fontSize = FlareSizes.fontSizeLg.value.sp,
                        maxLines = 1, overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f),
                    )
                    if (onRemove != null) {
                        Text(
                            labels.remove, color = colors.textSecondary,
                            fontSize = FlareSizes.fontSizeMd.value.sp,
                            modifier = Modifier.clickable { onRemove(m) },
                        )
                    }
                }
            }
        }
    }
}

/** Chinese-default labels for [ContactMatchList]. */
data class FlareContactMatchLabels(
    val add: String = "添加",
    val message: String = "发消息",
    val empty: String = "通讯录里还没有已注册的联系人",
)

/**
 * Contact-book match results — who from the user's address book is already here.
 *
 * Every row echoes [MatchedContact.matchedBy]: the display name is whatever
 * nickname the other person chose, which often does not match the address-book
 * name. Without the matched number the user cannot tell who this is.
 * Spec: Contacts/ContactMatchList (`ContactMatchList`).
 */
@Composable
fun ContactMatchList(
    matches: List<MatchedContact>,
    loading: Boolean = false,
    labels: FlareContactMatchLabels = FlareContactMatchLabels(),
    onAddFriend: ((MatchedContact) -> Unit)? = null,
    onOpenConversation: ((MatchedContact) -> Unit)? = null,
    onSelectContact: ((MatchedContact) -> Unit)? = null,
) {
    val colors = flareColors()

    if (loading) {
        Box(Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacing2xl),
            contentAlignment = Alignment.Center) {
            CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
        }
        return
    }
    if (matches.isEmpty()) {
        Box(Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacing2xl),
            contentAlignment = Alignment.Center) {
            Text(labels.empty, color = colors.textTertiary,
                fontSize = FlareSizes.fontSizeMd.value.sp)
        }
        return
    }

    Column(Modifier.fillMaxWidth()) {
        matches.forEach { c ->
            Row(
                Modifier.fillMaxWidth()
                    .then(if (onSelectContact != null) Modifier.clickable { onSelectContact(c) } else Modifier)
                    .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Avatar(userId = c.userId, displayName = c.displayName, size = 40.dp)
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Column(Modifier.weight(1f)) {
                    Text(c.displayName, color = colors.textPrimary,
                        fontSize = FlareSizes.fontSizeLg.value.sp,
                        maxLines = 1, overflow = TextOverflow.Ellipsis)
                    // Weaker than the name: it identifies, it does not label.
                    Text(c.matchedBy, color = colors.textTertiary,
                        fontSize = FlareSizes.fontSizeSm.value.sp,
                        maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
                if (c.alreadyFriend) {
                    Text(
                        labels.message, color = colors.textSecondary,
                        fontSize = FlareSizes.fontSizeMd.value.sp,
                        modifier = Modifier
                            .then(if (onOpenConversation != null) Modifier.clickable { onOpenConversation(c) } else Modifier),
                    )
                } else {
                    Text(
                        labels.add, color = colors.primary, fontWeight = FontWeight.Medium,
                        fontSize = FlareSizes.fontSizeMd.value.sp,
                        modifier = Modifier
                            .then(if (onAddFriend != null) Modifier.clickable { onAddFriend(c) } else Modifier),
                    )
                }
            }
        }
    }
}

/** Chinese-default labels for [AnnouncementReadBar]. */
data class FlareAnnouncementReadLabels(
    val confirmRead: String = "已读",
    val viewUnread: String = "查看未读",
    /**
     * Formats the x/y line. A lambda rather than a template so locales that reorder
     * or pluralise the counts can express it.
     */
    val readCount: (Int, Int) -> String = { read, total -> "$read/$total 人已读" },
)

/**
 * Group-announcement read bar — confirm while unread, x/y read once confirmed.
 *
 * [readCount] / [memberCount] must be the server's own counts. The unread member
 * list that ships alongside them is truncated by the server, so deriving a count
 * from its length silently under-reports in large groups — a wrong number that
 * never raises an error.
 * Spec: General/AnnouncementReadBar (`AnnouncementReadBar`).
 */
@Composable
fun AnnouncementReadBar(
    readCount: Int,
    memberCount: Int,
    selfRead: Boolean,
    canViewUnread: Boolean = false,
    labels: FlareAnnouncementReadLabels = FlareAnnouncementReadLabels(),
    onConfirm: (() -> Unit)? = null,
    onViewUnread: (() -> Unit)? = null,
) {
    val colors = flareColors()
    // Counts are hidden until the data lands, so "0/0" never flashes.
    val showCount = memberCount > 0
    val allRead = memberCount > 0 && readCount >= memberCount
    val tone = if (selfRead) colors.textTertiary else colors.textSecondary

    Row(
        Modifier.fillMaxWidth()
            .background(colors.bgSecondary, RoundedCornerShape(FlareSizes.radiusMd))
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            if (selfRead) Icons.Filled.CheckCircle else Icons.Outlined.Campaign,
            contentDescription = null, tint = tone, modifier = Modifier.size(16.dp),
        )
        Spacer(Modifier.width(FlareSizes.spacingSm))
        Box(Modifier.weight(1f)) {
            if (showCount) {
                Text(labels.readCount(readCount, memberCount), color = tone,
                    fontSize = FlareSizes.fontSizeMd.value.sp)
            } else {
                Spacer(Modifier.height(0.dp))
            }
        }
        if (!selfRead && onConfirm != null) {
            Text(
                labels.confirmRead, color = colors.primary, fontWeight = FontWeight.Medium,
                fontSize = FlareSizes.fontSizeMd.value.sp,
                modifier = Modifier.clickable { onConfirm() },
            )
        }
        if (canViewUnread && !allRead && onViewUnread != null) {
            Spacer(Modifier.width(FlareSizes.spacingSm))
            Text(
                labels.viewUnread, color = colors.textSecondary,
                fontSize = FlareSizes.fontSizeMd.value.sp,
                modifier = Modifier.clickable { onViewUnread() },
            )
        }
    }
}
