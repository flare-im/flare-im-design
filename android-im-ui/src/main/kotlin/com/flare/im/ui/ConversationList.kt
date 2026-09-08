package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
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

/**
 * Host-rows variant of [ConversationList] — for screens that build each row
 * themselves (to keep per-row long-press menus, swipe actions, or a store
 * subscription) while still getting the kit's standardised empty / loading
 * treatment and lazy list wrapper. Bring your own [items] + [key] and a
 * [rowContent] composable; supply [empty] for the no-items state.
 *
 * Complements [ConversationList] (the self-contained variant): reach for this
 * when the host owns the row visuals/affordances and only wants the kit to
 * standardise the container.
 */
@Composable
fun <T> ConversationListContainer(
    items: List<T>,
    key: (T) -> Any,
    modifier: Modifier = Modifier,
    loading: Boolean = false,
    contentPadding: PaddingValues = PaddingValues(0.dp),
    emptyText: String = "暂无会话",
    emptyDescription: String? = null,
    empty: (@Composable () -> Unit)? = null,
    rowContent: @Composable (T) -> Unit,
) {
    if (items.isEmpty()) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            when {
                loading -> CircularProgressIndicator()
                empty != null -> empty()
                else -> EmptyState(title = emptyText, description = emptyDescription)
            }
        }
    } else {
        LazyColumn(
            modifier = modifier.fillMaxSize(),
            contentPadding = contentPadding,
        ) {
            items(items, key = key) { item -> rowContent(item) }
        }
    }
}
