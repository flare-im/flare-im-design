package com.flare.im.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
    onMessageLongPress: ((FlareMessageData) -> Unit)? = null,
    onMediaAction: ((FlareMessageData, FlareMessageContent) -> Unit)? = null,
    onResend: ((FlareMessageData) -> Unit)? = null,
) {
    val colors = flareColors()
    if (messages.isEmpty()) {
        Box(Modifier.fillMaxSize().background(colors.bgSecondary), contentAlignment = Alignment.Center) {
            if (loading) CircularProgressIndicator()
            else Text("还没有消息", color = colors.textTertiary, fontSize = FlareSizes.fontSizeLg.value.sp)
        }
        return
    }

    // faint chat canvas so white received bubbles read as cards
    LazyColumn(Modifier.fillMaxSize().background(colors.bgSecondary), state = rememberLazyListState()) {
        if (loadingOlder) {
            item { Box(Modifier.fillMaxWidth().padding(FlareSizes.spacingMd), contentAlignment = Alignment.Center) { CircularProgressIndicator() } }
        }
        items(messages, key = { it.id }) { msg ->
            val index = messages.indexOf(msg)
            Box(Modifier.combinedClickable(onClick = {}, onLongClick = { onMessageLongPress?.invoke(msg) })) {
                MessageBubble(
                    message = msg,
                    currentUserId = currentUserId,
                    conversationKind = conversationKind,
                    groupStart = isGroupStart(messages, index),
                    groupEnd = isGroupEnd(messages, index),
                    mediaState = mediaDownloadStates[msg.id],
                    onMediaAction = onMediaAction,
                    onResend = onResend,
                )
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
