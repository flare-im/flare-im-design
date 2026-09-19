package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * FR-046: a report action used to float over the kit header, because the kit's detail screen had no
 * place for it. The host declares it now and the kit draws it with its own footer buttons.
 */
class DetailExtraActionsInteractionTest {
    @get:Rule val compose = createComposeRule()

    @Test fun theContactDetailDrawsHostActionsAndReportsTheId() {
        val reported = mutableListOf<String>()
        compose.setContent {
            MaterialTheme {
                ContactDetail(
                    contact = Contact(id = "u1", name = "Ada Chen"),
                    extraActions = listOf(
                        FlareDetailExtraAction("report", "举报", danger = true),
                        FlareDetailExtraAction("share", "分享名片"),
                    ),
                    onExtraAction = { reported += it },
                )
            }
        }

        compose.onNodeWithText("分享名片").assertExists()
        compose.onNodeWithText("举报").performClick()
        compose.waitForIdle()
        assertEquals(listOf("report"), reported)
    }
}
