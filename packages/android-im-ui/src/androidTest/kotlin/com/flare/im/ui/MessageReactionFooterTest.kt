package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.click
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class MessageReactionFooterTest {
    @get:Rule val rule = createComposeRule()

    @Test fun outgoingFooterWrapsAndKeepsTapTargetsSeparate() {
        val toggles = mutableListOf<String>()
        rule.setContent {
            MessageReactionFooter(
                reactions = listOf(
                    ReactionGroup("👍", 1, true),
                    ReactionGroup("❤️", 2, false),
                    ReactionGroup("🎉", 3, false),
                ),
                outgoing = true,
                onToggle = { toggles += it },
                modifier = Modifier.width(126.dp),
                body = { Box(Modifier.width(126.dp).height(32.dp)) },
                metadata = { Box(Modifier.width(36.dp).height(12.dp).testTag("metadata")) },
            )
        }

        val firstPill = rule.onNodeWithText("1").assertIsSelected()
        val first = firstPill.getUnclippedBoundsInRoot()
        val second = rule.onNodeWithText("2").getUnclippedBoundsInRoot()
        val third = rule.onNodeWithText("3").getUnclippedBoundsInRoot()
        val meta = rule.onNodeWithTag("metadata").getUnclippedBoundsInRoot()

        assertTrue(first.right - first.left >= 44.dp && first.bottom - first.top >= 44.dp)
        assertEquals(first.top, second.top)
        assertTrue(second.left >= first.right)
        assertTrue(third.top >= second.bottom)
        assertTrue(meta.top >= third.top && meta.top < third.bottom)
        assertTrue(meta.left >= third.right)
        assertEquals(second.right, meta.right)

        firstPill.performTouchInput { click(Offset(center.x, height - 2f)) }
        rule.runOnIdle { assertEquals(listOf("👍"), toggles) }
    }
}
