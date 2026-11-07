package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * [total] is the display count when [members] holds a preview or a permission-filtered roster.
 * [onViewAll] makes the header a navigation button, including when the preview is empty.
 */
@Suppress("NAME_SHADOWING")
@Composable
fun GroupMemberGrid(
    members: List<Contact>,
    ownerId: String? = null,
    adminIds: List<String> = emptyList(),
    showAdd: Boolean = true,
    columns: Int = 5,
    onSelect: ((String) -> Unit)? = null,
    onAddMember: (() -> Unit)? = null,
    title: String? = null,
    ownerLabel: String? = null,
    adminLabel: String? = null,
    addLabel: String? = null,
    memberCountText: ((Int) -> String)? = null,
    total: Int? = null,
    onViewAll: (() -> Unit)? = null,
) {
    val strings = flareStrings()
    val title = title ?: strings.groupMembers
    val ownerLabel = ownerLabel ?: strings.groupOwner
    val adminLabel = adminLabel ?: strings.groupAdmin
    val addLabel = addLabel ?: strings.addMember
    val memberCountText = memberCountText ?: strings.memberCount
    val colors = flareColors()
    fun role(m: Contact): String? = when {
        m.id == ownerId -> ownerLabel
        adminIds.contains(m.id) -> adminLabel
        else -> null
    }
    Column(Modifier.padding(FlareSizes.spacingLg)) {
        val header = if (onViewAll != null) {
            Modifier.heightIn(min = FlareSizes.touchTarget).clickable(role = Role.Button, onClick = onViewAll)
        } else Modifier
        Row(Modifier.fillMaxWidth().then(header), verticalAlignment = Alignment.CenterVertically) {
            Text(title, color = colors.textPrimary, fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeLg.value.sp, modifier = Modifier.weight(1f))
            Text(memberCountText(total ?: members.size), color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
            if (onViewAll != null) {
                Icon(Icons.AutoMirrored.Rounded.KeyboardArrowRight, contentDescription = null,
                    tint = colors.textTertiary, modifier = Modifier.size(20.dp))
            }
        }
        Spacer(Modifier.height(FlareSizes.spacing2md))
        LazyVerticalGrid(
            columns = GridCells.Fixed(columns),
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2sm),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2md),
            contentPadding = PaddingValues(0.dp),
            modifier = Modifier.height(((members.size + (if (showAdd) 1 else 0) + columns - 1) / columns * 84).dp),
        ) {
            items(members, key = { it.id }) { m ->
                Column(horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = if (onSelect != null) Modifier.clickable { onSelect(m.id) } else Modifier) {
                    Box(contentAlignment = Alignment.BottomCenter) {
                        Avatar(userId = m.id, displayName = m.name, size = 48.dp)
                        role(m)?.let { r ->
                            Text(r, color = Color.White, fontSize = FlareSizes.fontSize2xs,
                                modifier = Modifier.offset(y = 6.dp).clip(RoundedCornerShape(999.dp))
                                    .background(if (m.id == ownerId) colors.warning else colors.textTertiary)
                                    .padding(horizontal = FlareSizes.spacing2xs, vertical = 1.dp))
                        }
                    }
                    Spacer(Modifier.height(8.dp))
                    Text(m.name, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp,
                        maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
            if (showAdd) {
                item {
                    Column(horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = if (onAddMember != null) Modifier.clickable { onAddMember() } else Modifier) {
                        // Dashed ring = "add" affordance (parity with iOS/Flutter).
                        val dashColor = colors.borderHover
                        Box(Modifier.size(48.dp).clip(CircleShape)
                            .drawBehind {
                                val stroke = 1.dp.toPx()
                                drawCircle(
                                    color = dashColor,
                                    radius = size.minDimension / 2f - stroke / 2f,
                                    style = Stroke(width = stroke, pathEffect = PathEffect.dashPathEffect(floatArrayOf(4.dp.toPx(), 3.dp.toPx()))),
                                )
                            },
                            contentAlignment = Alignment.Center) {
                            Icon(Icons.Outlined.Add, contentDescription = addLabel, tint = colors.textTertiary,
                                modifier = Modifier.size(22.dp))
                        }
                        Spacer(Modifier.height(8.dp))
                        Text(addLabel, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
                    }
                }
            }
        }
    }
}
