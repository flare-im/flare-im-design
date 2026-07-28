package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.sp

/**
 * The inbox — a lazily rendered list of [ConversationRow]s. Spec:
 * Conversation/ConversationList (`ConversationList`). `LazyColumn` is virtualised
 * (O(visible)).
 */
@Composable
fun ConversationList(
    items: List<ConversationRowData>,
    activeId: String? = null,
    loading: Boolean = false,
    emptyText: String = "暂无会话",
    draftLabel: String = "[Draft] ",
    mentionLabel: String = "[@me] ",
    emptyDescription: String? = null,
    onSelect: ((ConversationRowData) -> Unit)? = null,
    onLongPress: ((ConversationRowData) -> Unit)? = null,
) {
    if (items.isEmpty()) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            if (loading) {
                CircularProgressIndicator()
            } else {
                EmptyState(title = emptyText, description = emptyDescription)
            }
        }
    } else {
        LazyColumn(Modifier.fillMaxSize()) {
            items(items, key = { it.id }) { item ->
                ConversationRow(
                    draftLabel = draftLabel,
                    mentionLabel = mentionLabel,
                    item = item,
                    active = item.id == activeId,
                    onSelect = onSelect?.let { cb -> { cb(item) } },
                    onLongPress = onLongPress?.let { cb -> { cb(item) } },
                )
            }
        }
    }
}
