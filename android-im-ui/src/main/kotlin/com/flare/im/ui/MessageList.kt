package com.flare.im.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.sp

/**
 * The message thread — grouping, media state. Spec: Message/MessageList
 * (`MessageList`). `LazyColumn` is virtualised (O(visible)); order is
 * oldest→newest. The host feeds [messages] from the timeline view.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MessageList(
    messages: List<FlareMessageData>,
    currentUserId: String,
    conversationKind: FlareConversationKind = FlareConversationKind.Single,
    loading: Boolean = false,
    loadingOlder: Boolean = false,
    mediaDownloadStates: Map<String, FlareMediaDownloadState> = emptyMap(),
    emptyText: String = "暂无消息",
    onMessageLongPress: ((FlareMessageData) -> Unit)? = null,
    onMediaAction: ((FlareMessageData, FlareMessageContent) -> Unit)? = null,
    onResend: ((FlareMessageData) -> Unit)? = null,
    hasOlder: Boolean = false,
    olderError: String? = null,
    loadOlderText: String = "加载更早消息",
    onLoadOlder: (() -> Unit)? = null,
    conversationId: String? = null,
    listState: LazyListState = rememberLazyListState(),
) {
    val colors = flareColors()
    var requested by remember(conversationId) { mutableStateOf(false) }
    LaunchedEffect(loadingOlder, messages.firstOrNull()?.id, olderError) { if (!loadingOlder) requested = false }
    LaunchedEffect(conversationId) { listState.scrollToItem(0) }
    Column(Modifier.fillMaxSize().background(colors.bgSecondary)) {
        if (hasOlder || loadingOlder || olderError != null) {
            if (olderError != null) Text(olderError, color = colors.textPrimary, modifier = Modifier.padding(horizontal = 12.dp))
            if (loadingOlder) Box(Modifier.fillMaxWidth().defaultMinSize(minHeight = 48.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
            else if (hasOlder && onLoadOlder != null) TextButton(
                onClick = { if (!requested && !loadingOlder) { requested = true; onLoadOlder() } }, enabled = !requested,
                modifier = Modifier.defaultMinSize(minWidth = 48.dp, minHeight = 48.dp)
            ) { Text(loadOlderText) }
        }
        if (messages.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                if (loading) CircularProgressIndicator() else EmptyState(title = emptyText)
            }
        } else LazyColumn(Modifier.weight(1f).fillMaxWidth(), state = listState) {
            itemsIndexed(messages, key = { _, msg -> msg.id }) { index, msg ->
                Box(if (onMessageLongPress != null) Modifier.combinedClickable(onClick = {}, onLongClick = { onMessageLongPress(msg) }) else Modifier) {
                    MessageBubble(message = msg, currentUserId = currentUserId, conversationKind = conversationKind,
                        groupStart = isGroupStart(messages, index), groupEnd = isGroupEnd(messages, index),
                        mediaState = mediaDownloadStates[msg.id], onMediaAction = onMediaAction, onResend = onResend)
                }
            }
        }
    }
}

private fun isGroupStart(messages: List<FlareMessageData>, i: Int): Boolean {
    if (i <= 0) return true
    val prev = messages[i - 1]; val cur = messages[i]
    return prev.senderId != cur.senderId || prev.isSystem || cur.isSystem
}

private fun isGroupEnd(messages: List<FlareMessageData>, i: Int): Boolean {
    if (i >= messages.size - 1) return true
    val next = messages[i + 1]; val cur = messages[i]
    return next.senderId != cur.senderId || next.isSystem || cur.isSystem
}
