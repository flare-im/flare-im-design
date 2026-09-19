package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * FR-129: the seams the contract declared and Compose did not have. A list that is empty has to be
 * able to say what to do about it, and a screen header has to be able to say what the screen is
 * reached through. Each one falls back to the kit's own answer when the host gives nothing.
 */
class EmptyAndLeadingSlotInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()

    @Test fun contactListDrawsTheKitEmptyStateWhenTheHostGivesNone() {
        compose.setContent { MaterialTheme { ContactList(items = emptyList()) } }
        compose.onNodeWithText(strings.noContacts).assertIsDisplayed()
    }

    @Test fun contactListTakesTheHostEmptyState() {
        compose.setContent {
            MaterialTheme { ContactList(items = emptyList(), empty = { Text("换个筛选条件试试") }) }
        }
        compose.onNodeWithText("换个筛选条件试试").assertIsDisplayed()
        compose.onNodeWithText(strings.noContacts).assertDoesNotExist()
    }

    @Test fun contactListShowsNeitherOnceThereIsSomeoneToList() {
        compose.setContent {
            MaterialTheme {
                ContactList(items = listOf(Contact(id = "u1", name = "Ada")), empty = { Text("换个筛选条件试试") })
            }
        }
        compose.onNodeWithText("换个筛选条件试试").assertDoesNotExist()
        compose.onNodeWithText("Ada").assertIsDisplayed()
    }

    @Test fun groupListTakesTheHostEmptyState() {
        compose.setContent {
            MaterialTheme { GroupList(items = emptyList(), empty = { Text("建一个群") }) }
        }
        compose.onNodeWithText("建一个群").assertIsDisplayed()
    }

    @Test fun groupListKeepsItsOwnEmptyStateWithoutOne() {
        compose.setContent { MaterialTheme { GroupList(items = emptyList()) } }
        compose.onNodeWithText(strings.noGroups).assertIsDisplayed()
    }

    @Test fun messageListTakesTheHostEmptyState() {
        compose.setContent {
            MaterialTheme {
                MessageList(messages = emptyList(), currentUserId = "me", empty = { Text("说点什么吧") })
            }
        }
        compose.onNodeWithText("说点什么吧").assertIsDisplayed()
        compose.onNodeWithText(strings.messageListEmpty).assertDoesNotExist()
    }

    @Test fun messageListEmptyTextStaysTheShorthand() {
        compose.setContent {
            MaterialTheme { MessageList(messages = emptyList(), currentUserId = "me", emptyText = "还没有消息") }
        }
        compose.onNodeWithText("还没有消息").assertIsDisplayed()
    }

    @Test fun screenHeaderShowsTheLeadingControlAndKeepsActionsSeparate() {
        var backs = 0
        var adds = 0
        compose.setContent {
            MaterialTheme {
                ScreenHeader(
                    title = "通讯录",
                    leading = { OutlinedButton(onClick = { backs += 1 }) { Text("返回") } },
                    actions = { OutlinedButton(onClick = { adds += 1 }) { Text("添加") } },
                )
            }
        }
        compose.onNodeWithText("返回").assertIsDisplayed().performClick()
        compose.onNodeWithText("添加").assertIsDisplayed().performClick()
        compose.waitForIdle()
        assertEquals(1, backs)
        assertEquals(1, adds)
    }

    @Test fun screenHeaderWithoutALeadingControlStillReads() {
        compose.setContent { MaterialTheme { ScreenHeader(title = "通讯录") } }
        compose.onNodeWithText("通讯录").assertIsDisplayed()
    }

    @Test fun emptyStateTakesHostControlsUnderTheText() {
        var invited = 0
        compose.setContent {
            MaterialTheme {
                EmptyState(
                    title = "还没有联系人",
                    actionText = "重试",
                    actions = { OutlinedButton(onClick = { invited += 1 }) { Text("邀请同事") } },
                )
            }
        }
        compose.onNodeWithText("重试").assertIsDisplayed()
        compose.onNodeWithText("邀请同事").assertIsDisplayed().performClick()
        compose.waitForIdle()
        assertEquals(1, invited)
    }
}
