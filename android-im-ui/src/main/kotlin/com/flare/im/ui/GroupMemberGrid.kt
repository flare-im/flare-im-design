package com.flare.im.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Group member grid. Spec: Contacts/GroupMemberGrid. */
@Composable
fun GroupMemberGrid(
    members: List<Contact>,
    ownerId: String? = null,
    adminIds: List<String> = emptyList(),
    showAdd: Boolean = true,
    columns: Int = 5,
    onSelect: ((String) -> Unit)? = null,
    onAddMember: (() -> Unit)? = null,
    title: String = "群成员",
    ownerLabel: String = "群主",
    adminLabel: String = "管理员",
    addLabel: String = "加成员",
    memberCountText: (Int) -> String = { "$it 名成员" },
) {
    val colors = flareColors()
    fun role(m: Contact): String? = when {
        m.id == ownerId -> ownerLabel
        adminIds.contains(m.id) -> adminLabel
        else -> null
    }
    Column(Modifier.padding(FlareSizes.spacingLg)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(title, color = colors.textPrimary, fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeLg.value.sp)
            Text(memberCountText(members.size), color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
        }
        Spacer(Modifier.height(14.dp))
        LazyVerticalGrid(
            columns = GridCells.Fixed(columns),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
            contentPadding = PaddingValues(0.dp),
            modifier = Modifier.height(((members.size + (if (showAdd) 1 else 0) + columns - 1) / columns * 84).dp),
        ) {
            items(members, key = { it.id }) { m ->
                Column(horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = if (onSelect != null) Modifier.clickable { onSelect(m.id) } else Modifier) {
                    Box(contentAlignment = Alignment.BottomCenter) {
                        Avatar(userId = m.id, displayName = m.name, size = 48.dp)
                        role(m)?.let { r ->
                            Text(r, color = Color.White, fontSize = 10.sp,
                                modifier = Modifier.offset(y = 6.dp).clip(RoundedCornerShape(999.dp))
                                    .background(if (m.id == ownerId) colors.warning else colors.textTertiary)
                                    .padding(horizontal = 6.dp, vertical = 1.dp))
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
                        Box(Modifier.size(48.dp).clip(CircleShape)
                            .border(BorderStroke(1.dp, colors.borderHover), CircleShape),
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
