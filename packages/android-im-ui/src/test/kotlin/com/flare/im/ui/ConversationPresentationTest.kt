package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

class ConversationPresentationTest {
    @Test fun canonicalStateCombinations() {
        // The four-bit truth table is frozen by spec/conversation-state-vectors.json.
        val expected = listOf("normal", "failed", "draft", "failed", "typing", "failed", "draft", "failed",
            "mention", "failed", "draft", "failed", "typing", "failed", "draft", "failed")
        for (mask in 0 until 64) {
            val row = ConversationRowData(id = "$mask", title = "Chat", failed = mask and 1 != 0,
                draftPreview = if (mask and 2 != 0) "Review checklist" else " ", typing = mask and 4 != 0,
                mentioned = mask and 8 != 0, pinned = mask and 16 != 0, muted = mask and 32 != 0)
            assertEquals(expected[mask % 16], row.previewKind, "mask=$mask")
            assertEquals("quiet", row.titleEmphasis, "mask=$mask read")
            val unread = row.copy(unreadCount = 12)
            val quiet = unread.muted && !unread.mentioned
            assertEquals(if (quiet) "quiet" else "strong", unread.titleEmphasis, "mask=$mask unread")
        }
    }
    @Test fun unreadCountBounds() {
        for ((count, label) in listOf(-1 to "0", 0 to "0", 1 to "1", 99 to "99", 100 to "100", 999 to "999", 1000 to "999+")) {
            assertEquals(label, ConversationRowData(id = "one", title = "Chat", unreadCount = count).unreadLabel)
        }
    }
}
