package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/** The sheet as a host uses it: the core's availability in, action ids and emoji out. */
class MessageActionSheetInteractionTest {
    @get:Rule val compose = createComposeRule()

    @Test fun availabilityDrivesTheStandardActionsAndTheHostDispatches() {
        var action = ""
        var reaction = ""
        val strings = FlareStrings()
        compose.setContent { MaterialTheme {
            MessageActionSheet(
                availability = FlareMessageActionAvailability(
                    canReply = true, canForward = true, canCopy = true, canPin = true,
                    canDelete = true, canReact = true, canMultiSelect = true,
                ),
                content = FlareTextContent("明天十点开会"),
                hiddenActions = setOf("preview"),
                actions = listOf(FlareMessageMenuEntry("editRich", "编辑富文本", "rich-text")),
                onAction = { action = it },
                onReact = { reaction = it },
            )
        } }
        for (label in listOf(
            strings.messageActionReply, strings.messageActionForward, strings.messageActionMultiSelect,
            strings.messageActionMark, strings.messageActionPin, strings.messageActionPinSelf,
            strings.messageActionCopy, strings.messageActionDelete, "编辑富文本",
        )) compose.onNodeWithText(label).assertIsDisplayed()
        compose.onNodeWithText(strings.messageActionPreview).assertDoesNotExist()
        compose.onNodeWithText(strings.messageActionRecall).assertDoesNotExist()

        compose.onNodeWithText(strings.messageActionCopy).performClick()
        compose.runOnIdle { assertEquals("copy", action) }
        compose.onNodeWithText("编辑富文本").performClick()
        compose.runOnIdle { assertEquals("editRich", action) }
        compose.onNodeWithContentDescription(flareQuickReactions[3]).performClick()
        compose.runOnIdle { assertEquals(flareQuickReactions[3], reaction) }
    }

    @Test fun anImageMessageOffersNoCopyEvenWhenTheCoreAllowsIt() {
        val strings = FlareStrings()
        compose.setContent { MaterialTheme {
            MessageActionSheet(
                availability = FlareMessageActionAvailability(canForward = true, canCopy = true),
                content = FlareImageContent("https://example.invalid/photo.jpg"),
            )
        } }
        compose.onNodeWithText(strings.messageActionForward).assertIsDisplayed()
        compose.onNodeWithText(strings.messageActionCopy).assertDoesNotExist()
    }

    @Test fun nothingAllowedShowsTheEmptyText() {
        compose.setContent { MaterialTheme { MessageActionSheet(availability = FlareMessageActionAvailability(canReact = false)) } }
        compose.onNodeWithText(FlareStrings().messageActionSheetEmpty).assertIsDisplayed()
    }
}
