package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ConversationBatchToolbarTest {
    private val caps = ConversationBatchCapabilities(markRead = true, mute = true, delete = true)

    @Test fun availableActionsFollowCapabilitiesInCanonicalOrder() {
        assertEquals(
            listOf(ConversationBatchAction.MarkRead, ConversationBatchAction.Mute, ConversationBatchAction.Delete),
            batchActionsAvailable(listOf("a", "b"), caps, busy = false),
        )
        assertEquals(
            listOf(ConversationBatchAction.Archive, ConversationBatchAction.Delete),
            batchActionsAvailable(listOf("a"), ConversationBatchCapabilities(delete = true, archive = true), busy = false),
        )
    }

    @Test fun availableActionsEmptyWhenIdleBusyUncapableOrOverLimit() {
        assertEquals(emptyList(), batchActionsAvailable(emptyList(), caps, busy = false))
        assertEquals(emptyList(), batchActionsAvailable(listOf("a"), caps, busy = true))
        assertEquals(emptyList(), batchActionsAvailable(listOf("a"), ConversationBatchCapabilities(), busy = false))
        assertEquals(emptyList(), batchActionsAvailable(listOf("a"), null, busy = false))
        assertEquals(emptyList(), batchActionsAvailable(listOf("a", "b", "c"), caps, busy = false, maxSelection = 2))
        assertEquals(3, batchActionsAvailable(listOf("a", "b"), caps, busy = false, maxSelection = 2).size)
        assertEquals(3, batchActionsAvailable(listOf("a", "b", "c"), caps, busy = false, maxSelection = 0).size)
        assertTrue(batchSelectionExceeded(3, 2))
        assertFalse(batchSelectionExceeded(2, 2))
        assertFalse(batchSelectionExceeded(3, null))
    }

    @Test fun summaryKeepsSuccessesAndDeduplicatesRetryIds() {
        val result = ConversationBatchResult(
            succeeded = listOf("a", "b"),
            failed = listOf(
                ConversationBatchFailure("d", "设计群", "无权限"),
                ConversationBatchFailure("d", "设计群", "再次失败"),
                ConversationBatchFailure("", "未知", "无 ID"),
                ConversationBatchFailure("e", "客服", "网络中断"),
            ),
        )
        assertEquals(ConversationBatchSummary(2, 4, listOf("d", "e")), summarizeBatchResult(result))
        assertEquals(ConversationBatchSummary(0, 0, emptyList()), summarizeBatchResult(null))
    }
}
