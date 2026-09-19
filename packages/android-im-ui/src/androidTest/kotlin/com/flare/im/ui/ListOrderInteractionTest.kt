package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/** Lists keep the order they are given (conversations) or the order the index defines (contacts), on the device. */
class ListOrderInteractionTest {
    @get:Rule val compose = createComposeRule()

    @Test fun conversationRowsRenderInHostOrderAndAPinnedRowIsNotMoved() {
        val rows = listOf(
            ConversationRowData("c1", "产品周会", preview = "明天见"),
            ConversationRowData("c2", "设计评审组", preview = "稿子更新了", pinned = true),
            ConversationRowData("c3", "陈默", preview = "好的"),
        )
        compose.setContent { MaterialTheme { ConversationList(items = rows) } }
        // Each row is one merged node named "title, …".
        val tops = rows.map { row -> compose.onNodeWithContentDescription(row.title, substring = true).getUnclippedBoundsInRoot().top }
        assertTrue("rows keep host order: $tops", tops[0] < tops[1] && tops[1] < tops[2])
        // The pinned row keeps its pin mark and says so.
        compose.onNodeWithContentDescription("设计评审组, ${FlareStrings().conversationActionSheetPin}", substring = true).assertExists()
    }

    /**
     * The index on a real device. It used to need API 29 for ICU; the generated table has no API level, so the
     * assumption that skipped this test on Android 8 and 9 — the two versions where the index was broken — is
     * gone with it (FR-044).
     */
    @Test fun theIndexReadsChineseNamesByPinyinInitialOnTheDevice() {
        assertEquals("C", contactIndexLetter("陈默", null))
        assertEquals("L", contactIndexLetter("林澈", null))
        assertEquals("Z", contactIndexLetter("周舟", null))
        assertEquals("GB2312 level 2 used to land under #", "Z", contactIndexLetter("梓涵", null))
        val groups = contactIndexGroups(listOf(Contact("1", "周舟"), Contact("2", "#hash"), Contact("3", "陈曦"), Contact("4", "陈默")))
        assertEquals(listOf("C", "Z", CONTACT_INDEX_OTHER), groups.map { it.first })
        assertEquals(listOf("陈默", "陈曦"), groups.first().second.map { it.name })
    }
}
