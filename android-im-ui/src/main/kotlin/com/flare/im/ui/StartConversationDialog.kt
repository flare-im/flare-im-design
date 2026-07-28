package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.RadioButtonUnchecked
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * New-conversation entry — pick a contact (single) or several (group). Spec:
 * Conversation/StartConversationDialog (`StartConversationDialog`). Contacts come
 * from the product; [onConfirm] returns the selected ids.
 */
@Composable
fun StartConversationDialog(
    searchPlaceholder: String = "搜索联系人",
    contacts: List<FlareContactOption>,
    allowGroup: Boolean = true,
    busy: Boolean = false,
    onConfirm: ((List<String>) -> Unit)? = null,
) {
    val colors = flareColors()
    var query by remember { mutableStateOf("") }
    val selected = remember { mutableStateListOf<String>() }
    val filtered = if (query.isBlank()) contacts else contacts.filter {
        it.name.contains(query, true) || (it.subtitle?.contains(query, true) ?: false)
    }

    Column(Modifier.fillMaxWidth()) {
        OutlinedTextField(
            value = query, onValueChange = { query = it },
            leadingIcon = { Icon(Icons.Rounded.Search, null) },
            placeholder = { Text(searchPlaceholder) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth().padding(FlareSizes.spacingMd),
        )
        LazyColumn(Modifier.weight(1f, fill = false)) {
            items(filtered, key = { it.id }) { c ->
                val checked = selected.contains(c.id)
                Row(
                    Modifier.fillMaxWidth().clickable {
                        if (!allowGroup) onConfirm?.invoke(listOf(c.id))
                        else if (checked) selected.remove(c.id) else selected.add(c.id)
                    }.padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Avatar(userId = c.id, displayName = c.name, size = 40.dp)
                    Spacer(Modifier.width(FlareSizes.spacingMd))
                    Column(Modifier.weight(1f)) {
                        Text(c.name, color = colors.textPrimary)
                        if (c.subtitle != null) {
                            Text(c.subtitle, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                                maxLines = 1, overflow = TextOverflow.Ellipsis)
                        }
                    }
                    if (allowGroup) {
                        Icon(
                            if (checked) Icons.Rounded.CheckCircle else Icons.Rounded.RadioButtonUnchecked,
                            null, tint = if (checked) colors.primary else colors.textTertiary,
                        )
                    }
                }
            }
        }
        if (allowGroup) {
            Button(
                onClick = { onConfirm?.invoke(selected.toList()) },
                enabled = selected.isNotEmpty() && !busy,
                colors = ButtonDefaults.buttonColors(containerColor = colors.primary),
                modifier = Modifier.fillMaxWidth().padding(FlareSizes.spacingMd),
            ) {
                if (busy) {
                    CircularProgressIndicator(Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                } else {
                    Text(if (selected.isEmpty()) "确定" else "确定 (${selected.size})")
                }
            }
        }
    }
}
