package com.flare.im.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsOff
import androidx.compose.ui.test.assertIsOn
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.isToggleable
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.performTextReplacement
import androidx.compose.ui.test.pressKey
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/** Entry points and selection: read-only search, header identity and toggles, contact rows, requests, drafts. */
class EntryAndSelectionInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()
    private val isButton = SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Button)

    @OptIn(ExperimentalTestApi::class)
    @Test fun aReadOnlySearchBarIsOneButton() {
        var activations = 0
        compose.setContent { MaterialTheme {
            SearchBar(value = "", onValueChange = {}, placeholder = "搜索联系人、群组、消息", readOnly = true, onActivate = { activations++ })
        } }
        compose.onAllNodes(hasSetTextAction()).assertCountEquals(0)
        val bar = compose.onNodeWithContentDescription("搜索联系人、群组、消息").assert(isButton).assertHasClickAction()
        bar.performClick()
        // Keyboard users: out of touch mode the bar takes focus, then Space and Enter activate it.
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        instrumentation.setInTouchMode(false)
        try {
            bar.performSemanticsAction(SemanticsActions.RequestFocus)
            bar.assertIsFocused()
            bar.performKeyInput { pressKey(Key.Spacebar) }
            bar.performKeyInput { pressKey(Key.Enter) }
        } finally {
            instrumentation.setInTouchMode(true)
        }
        compose.runOnIdle { assertEquals(3, activations) }
    }

    @Test fun aReadOnlySearchBarWithoutActivateOnlyDisplays() {
        compose.setContent { MaterialTheme { SearchBar(value = "", onValueChange = {}, readOnly = true) } }
        compose.onNodeWithText(strings.search).assertIsDisplayed()
        compose.onAllNodes(hasClickAction()).assertCountEquals(0)
        compose.onAllNodes(hasSetTextAction()).assertCountEquals(0)
    }

    @Test fun theHeaderIdentityIsOneButtonBesideTheBackButton() {
        val acted = mutableListOf<String>()
        var backs = 0
        compose.setContent { MaterialTheme {
            ConversationHeader(
                identity = ConversationIdentity("g1", "设计评审组", ConversationHeaderKind.Group, action = ConversationHeaderAction("details", "群详情")),
                capabilities = ConversationHeaderCapabilities(setOf("details")),
                configuration = ConversationHeaderConfiguration(replaceDefaults = true),
                showBack = true,
                onBack = { backs++ },
                onAction = { acted += it.id },
            )
        } }
        compose.onNodeWithContentDescription(strings.conversationHeaderIdentityLabel("设计评审组", "群详情"))
            .assert(isButton).assertHasClickAction().performClick()
        compose.onNodeWithContentDescription(strings.back).performClick()
        compose.runOnIdle {
            assertEquals(listOf("details"), acted)
            assertEquals(1, backs)
        }
    }

    @Test fun aPressedHeaderActionIsAToggle() {
        var muted by mutableStateOf(false)
        compose.setContent { MaterialTheme {
            ConversationHeader(
                identity = ConversationIdentity("c1", "Ann"),
                configuration = ConversationHeaderConfiguration(replaceDefaults = true, compactMaxPrimaryActions = 2),
                actions = listOf(
                    ConversationHeaderAction("mute", "免打扰", pressed = muted),
                    ConversationHeaderAction("search", "搜索消息", "search"),
                ),
                onAction = { if (it.id == "mute") muted = !muted },
            )
        } }
        compose.onNodeWithContentDescription("免打扰").assertIsOff().performClick()
        compose.onNodeWithContentDescription("免打扰").assertIsOn()
        compose.onNodeWithContentDescription("搜索消息").assert(SemanticsMatcher.keyNotDefined(SemanticsProperties.ToggleableState))
        // Without an identity action the identity block is not a control.
        compose.onNodeWithText("Ann").assert(SemanticsMatcher.keyNotDefined(SemanticsActions.OnClick))
    }

    @Test fun aSelectableContactRowIsOneCheckboxNamedByTheContact() {
        var selected by mutableStateOf(false)
        var opened = 0
        var added = 0
        compose.setContent { MaterialTheme {
            ContactItem(
                item = Contact("u1", "Ann", signature = "设计"),
                onSelect = { opened++ },
                selectable = true,
                selected = selected,
                onToggleSelect = { selected = !selected },
                trailing = { Button(label = "添加", onClick = { added++ }) },
            )
        } }
        compose.onAllNodes(isToggleable()).assertCountEquals(1)
        val row = compose.onNode(hasContentDescription("Ann") and isToggleable())
        row.assertIsOff().performClick()
        row.assertIsOn()
        compose.onNodeWithText("添加").performClick()
        compose.runOnIdle {
            assertEquals(1, added)
            assertEquals(0, opened)
        }
        row.assertIsOn()
    }

    @Test fun contactListRowsFollowSelectedIdsAndKeepTrailingTaps() {
        val toggled = mutableListOf<String>()
        val removed = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            ContactList(
                items = listOf(Contact("a", "Ann"), Contact("b", "Bob")),
                selectable = true,
                selectedIds = setOf("b"),
                onToggleSelect = { toggled += it.id },
                trailing = { contact -> Button(label = "移出 ${contact.name}", onClick = { removed += contact.id }) },
            )
        } }
        compose.onNode(hasContentDescription("Bob") and isToggleable()).assertIsOn()
        compose.onNode(hasContentDescription("Ann") and isToggleable()).assertIsOff().performClick()
        compose.onNodeWithText("移出 Bob").performClick()
        compose.runOnIdle {
            assertEquals(listOf("a"), toggled)
            assertEquals(listOf("b"), removed)
        }
    }

    @Test fun anOutgoingRequestShowsPendingAndWithdrawsWithTheHost() {
        val withdrawn = mutableListOf<String>()
        val accepted = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            NewFriendRequests(
                items = listOf(
                    FriendRequest("r1", "Ann", message = "一起做设计"),
                    FriendRequest("r2", "Kai", message = "你好", direction = FriendRequestDirection.Outgoing),
                ),
                onAccept = { accepted += it.id },
                onReject = {},
                onWithdraw = { withdrawn += it.id },
            )
        } }
        compose.onAllNodesWithText(strings.newFriendRequestsPending).assertCountEquals(1)
        compose.onAllNodesWithText(strings.newFriendRequestsAccept).assertCountEquals(1)
        compose.onAllNodesWithText(strings.newFriendRequestsDecline).assertCountEquals(1)
        compose.onNodeWithText(strings.newFriendRequestsWithdraw).performClick()
        compose.onNodeWithText(strings.newFriendRequestsAccept).performClick()
        compose.runOnIdle {
            assertEquals(listOf("r2"), withdrawn)
            assertEquals(listOf("r1"), accepted)
        }
    }

    @Test fun withoutHandlersRequestsOfferNoButtons() {
        compose.setContent { MaterialTheme {
            NewFriendRequests(items = listOf(FriendRequest("r1", "Ann"), FriendRequest("r2", "Kai", direction = FriendRequestDirection.Outgoing)))
        } }
        compose.onNodeWithText(strings.newFriendRequestsPending).assertIsDisplayed()
        compose.onAllNodes(hasClickAction()).assertCountEquals(0)
    }

    @Test fun aControlledComposerShowsTheHostDraftAndClearsThroughIt() {
        var draft by mutableStateOf("第一个会话的草稿")
        val sent = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            Column { Composer(value = draft, onValueChange = { draft = it }, onSend = { sent += it }) }
        } }
        compose.onNodeWithText("第一个会话的草稿").assertIsDisplayed()
        compose.runOnIdle { draft = "第二个会话的草稿" }
        compose.onNodeWithText("第二个会话的草稿").assertIsDisplayed()
        compose.onNode(hasSetTextAction()).performTextReplacement("改好了")
        compose.runOnIdle { assertEquals("改好了", draft) }
        compose.onNodeWithContentDescription(strings.send).performClick()
        compose.runOnIdle {
            assertEquals(listOf("改好了"), sent)
            assertEquals("", draft)
        }
    }
}
