package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * My groups — group avatar, name, member count.
 * Spec: Contacts/GroupList (`GroupList`).
 */
@Composable
fun GroupList(
    items: List<GroupSummary>,
    emptyText: String = "暂无群组",
    onSelect: ((GroupSummary) -> Unit)? = null,
) {
    val colors = flareColors()
    if (items.isEmpty()) {
        EmptyState(title = emptyText)
        return
    }
    LazyColumn(Modifier.fillMaxWidth()) {
        items(items, key = { it.id }) { g ->
            Row(
                Modifier.fillMaxWidth()
                    .then(if (onSelect != null) Modifier.clickable { onSelect(g) } else Modifier)
                    .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Avatar(userId = g.id, displayName = g.name, size = 44.dp)
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Column {
                    Text(g.name, color = colors.textPrimary, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeXl.value.sp)
                    Text("${g.memberCount} 名成员", color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
                }
            }
        }
    }
}
