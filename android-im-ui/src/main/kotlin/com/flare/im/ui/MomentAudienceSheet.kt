package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.PersonAdd
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Copy for [MomentAudienceSheet]. 两个方向的措辞刻意分开。 */
data class FlareMomentAudienceLabels(
    val title: String = "谁可以看",
    val public: String = "公开",
    val publicHint: String = "所有人可见",
    val friends: String = "朋友可见",
    val friendsHint: String = "你的好友可见",
    val private: String = "私密",
    val privateHint: String = "仅自己可见",
    val include: String = "部分可见",
    val includeHint: String = "仅选中的朋友可见",
    val exclude: String = "不给谁看",
    val excludeHint: String = "选中的朋友看不到",
    val pick: String = "选择朋友",
    val done: String = "完成",
    /** 「已选 N 人」。lambda 而非模板串，让复数形式不同的语言也能表达。 */
    val selected: (Int) -> String = { "已选 $it 人" },
)

/**
 * 发动态时的「谁可以看」。
 *
 * 两层正交：[visibility] 圈定人群（0=朋友 1=公开 2=私密），[audienceMode] 在其上做加减
 * （1=部分可见 2=不给谁看）。
 *
 * **两个方向的出错后果不对称**：把「部分可见」设成「不给谁看」，动态会发给你本想避开
 * 的所有人；反过来只是少给几个人看。所以两项不共用措辞，也不共用强调色。
 * Spec: Moments/MomentAudienceSheet (`MomentAudienceSheet`).
 */
@Composable
fun MomentAudienceSheet(
    visibility: Int,
    audienceMode: Int,
    audienceUserIds: List<String>,
    contacts: List<ContactBrief>,
    labels: FlareMomentAudienceLabels = FlareMomentAudienceLabels(),
    onVisibilityChanged: ((Int) -> Unit)? = null,
    onAudienceChanged: ((Int, List<String>) -> Unit)? = null,
    onClose: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val picked = audienceUserIds.toSet()

    // 私密时名单没有意义：没人看得到，加减谁都不改变结果。
    val audienceApplies = visibility != 2

    fun pickMode(mode: Int) {
        // 再点一次当前模式即取消，并清空名单 —— 留着名单而把 mode 归零，
        // 下次切回来会突然冒出一份用户以为已经删掉的名单。
        val next = if (audienceMode == mode) 0 else mode
        onAudienceChanged?.invoke(next, if (next == 0) emptyList() else audienceUserIds)
    }

    @Composable
    fun row(
        icon: ImageVector,
        title: String,
        hint: String,
        active: Boolean,
        accent: Color? = null,
        trailing: String? = null,
        onClick: () -> Unit,
    ) {
        val tone = if (active) (accent ?: colors.textPrimary) else colors.textSecondary
        Row(
            Modifier.fillMaxWidth().clickable(onClick = onClick)
                .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(icon, contentDescription = null, tint = tone, modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(FlareSizes.spacingSm))
            Column(Modifier.weight(1f)) {
                Text(title, color = tone, fontSize = FlareSizes.fontSizeLg.value.sp)
                Text(hint, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
            }
            when {
                trailing != null -> Text(
                    trailing, color = colors.textTertiary,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                )
                active -> Icon(
                    Icons.Filled.Check, contentDescription = null,
                    tint = colors.primary, modifier = Modifier.size(16.dp),
                )
            }
        }
    }

    Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState())) {
        Text(
            labels.title, color = colors.textPrimary,
            fontSize = FlareSizes.fontSizeLg.value.sp,
            modifier = Modifier.padding(FlareSizes.spacingMd),
        )
        row(Icons.Outlined.People, labels.friends, labels.friendsHint, visibility == 0) {
            onVisibilityChanged?.invoke(0)
        }
        row(Icons.Outlined.Public, labels.public, labels.publicHint, visibility == 1) {
            onVisibilityChanged?.invoke(1)
        }
        row(Icons.Outlined.Lock, labels.private, labels.privateHint, visibility == 2) {
            onVisibilityChanged?.invoke(2)
        }

        if (audienceApplies) {
            HorizontalDivider()
            row(
                Icons.Outlined.PersonAdd, labels.include, labels.includeHint,
                audienceMode == 1, accent = colors.primary,
                trailing = if (audienceMode == 1) labels.selected(audienceUserIds.size) else null,
            ) { pickMode(1) }
            row(
                Icons.Outlined.VisibilityOff, labels.exclude, labels.excludeHint,
                audienceMode == 2, accent = colors.warning,
                trailing = if (audienceMode == 2) labels.selected(audienceUserIds.size) else null,
            ) { pickMode(2) }

            if (audienceMode != 0) {
                HorizontalDivider()
                Text(
                    labels.pick, color = colors.textTertiary,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                    modifier = Modifier.padding(
                        horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm,
                    ),
                )
                Column(Modifier.heightIn(max = 240.dp).verticalScroll(rememberScrollState())) {
                    contacts.forEach { c ->
                        val on = c.userId in picked
                        Row(
                            Modifier.fillMaxWidth()
                                .clickable {
                                    val ids = audienceUserIds.toMutableList()
                                    if (on) ids.remove(c.userId) else ids.add(c.userId)
                                    onAudienceChanged?.invoke(audienceMode, ids)
                                }
                                .background(if (on) colors.bgHover else Color.Transparent)
                                .padding(
                                    horizontal = FlareSizes.spacingMd,
                                    vertical = FlareSizes.spacingXs,
                                ),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Avatar(userId = c.userId, displayName = c.displayName, size = 32.dp)
                            Spacer(Modifier.width(FlareSizes.spacingSm))
                            Text(
                                c.displayName, color = colors.textPrimary,
                                fontSize = FlareSizes.fontSizeLg.value.sp,
                                maxLines = 1, overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.weight(1f),
                            )
                            if (on) {
                                Icon(
                                    Icons.Filled.Check, contentDescription = null,
                                    tint = colors.primary, modifier = Modifier.size(16.dp),
                                )
                            }
                        }
                    }
                }
            }
        }

        HorizontalDivider()
        Row(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingMd),
            horizontalArrangement = androidx.compose.foundation.layout.Arrangement.End,
        ) {
            Text(
                labels.done, color = colors.primary, fontWeight = FontWeight.Medium,
                fontSize = FlareSizes.fontSizeMd.value.sp,
                modifier = Modifier.clickable { onClose?.invoke() },
            )
        }
    }
}
