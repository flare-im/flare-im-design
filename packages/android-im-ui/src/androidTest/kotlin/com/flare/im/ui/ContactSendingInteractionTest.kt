package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.hasProgressBarRangeInfo
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * A stranger's primary action and a contact card while the host sends them: the running key (or row) spins and takes
 * no click, the rest of the page stays usable, and both let go when the host clears the flag.
 */
class ContactSendingInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val indeterminate = hasProgressBarRangeInfo(ProgressBarRangeInfo.Indeterminate)

    @Test fun aBusyPrimaryActionSpinsAloneAndLetsGo() {
        val events = mutableListOf<String>()
        var busy by mutableStateOf(true)
        compose.setContent {
            MaterialTheme {
                ContactDetail(
                    contact = Contact(id = "u_lin", name = "林夏"),
                    onMessage = { events += "message" },
                    primaryActionLabel = "添加到通讯录",
                    onPrimaryAction = { events += "primary" },
                    primaryActionBusy = busy,
                )
            }
        }
        compose.onNodeWithText("添加到通讯录", useUnmergedTree = false).assertIsNotEnabled()
        compose.onNode(indeterminate, useUnmergedTree = true).assertExists()
        compose.onNodeWithText("添加到通讯录").performClick()
        compose.onNodeWithText(FlareStrings().sendMessage).assertIsEnabled().performClick()
        compose.waitForIdle()
        assertEquals(listOf("message"), events)

        busy = false
        compose.waitForIdle()
        compose.onNode(indeterminate, useUnmergedTree = true).assertDoesNotExist()
        compose.onNodeWithText("添加到通讯录").assertIsEnabled().performClick()
        compose.waitForIdle()
        assertEquals(listOf("message", "primary"), events)
    }

    @Test fun aSendingPickerSpinsTheTappedRowAndForgetsItAfterwards() {
        val picked = mutableListOf<List<String>>()
        var sending by mutableStateOf(false)
        val groups = listOf(
            FlareContactPickerGroup(
                FlareContactPickerGroup.FRIENDS,
                entries = listOf(FlareContactPickerEntry("u-ada", "Ada"), FlareContactPickerEntry("u-bob", "Bob")),
            ),
        )
        compose.setContent {
            MaterialTheme {
                ContactPicker(
                    groups = groups,
                    sending = sending,
                    onSelect = { entries -> picked += entries.map { it.userId }; sending = true },
                )
            }
        }
        compose.onNodeWithText("Bob").performClick()
        compose.waitForIdle()
        assertEquals(listOf(listOf("u-bob")), picked)
        compose.onNode(indeterminate, useUnmergedTree = true).assertExists()
        compose.onNode(hasText("Ada")).performClick()
        compose.waitForIdle()
        assertEquals(1, picked.size)

        sending = false
        compose.waitForIdle()
        compose.onNode(indeterminate, useUnmergedTree = true).assertDoesNotExist()
        compose.onNodeWithText("Ada").performClick()
        compose.waitForIdle()
        assertEquals(listOf(listOf("u-bob"), listOf("u-ada")), picked)
    }
}
