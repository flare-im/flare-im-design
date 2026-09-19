package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertHasNoClickAction
import androidx.compose.ui.test.assertIsNotSelected
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.assertLeftPositionInRootIsEqualTo
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isSelectable
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTextReplacement
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.isDialog
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * Group management as a host wires it: target-state member intents, header actions, host-confirmed
 * leave and removal, kit-confirmed ownership transfer, the page slots, the message button rule and
 * an unknown join policy.
 */
class GroupDetailInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val labels = FlareGroupDetailLabels()
    private val strings = FlareStrings()

    private val model = FlareGroupDetailModel(
        groupId = "g1",
        name = "设计评审组",
        memberCount = 3,
        members = listOf(Contact("me", "Me"), Contact("ann", "Ann"), Contact("bob", "Bob")),
        ownerId = "me",
        adminIds = listOf("ann"),
        mutedIds = listOf("bob"),
        canManage = true,
        isOwner = true,
    )

    @Test fun memberIntentsCarryTheStateTheirActionOffered() {
        val roles = mutableListOf<Pair<String, Boolean>>()
        val mutes = mutableListOf<Pair<String, Boolean>>()
        var leaves = 0
        compose.setContent { MaterialTheme {
            FlareGroupDetail(
                model = model,
                headerActions = { Text("更多操作") },
                onPromoteMember = { id, admin -> roles += id to admin },
                onMuteMember = { id, muted -> mutes += id to muted },
                onLeave = { leaves++ },
            )
        } }
        compose.onNodeWithText("更多操作").assertIsDisplayed()
        compose.onNodeWithText("Ann").performClick()
        compose.onNodeWithText(labels.unsetAdmin).performClick()
        compose.onNodeWithText("Bob").performClick()
        compose.onNodeWithText(labels.setAdmin).performClick()
        compose.onNodeWithText("Bob").performClick()
        compose.onNodeWithText(labels.unmute).performClick()
        // Leaving is the host's to confirm: the tap is the intent.
        compose.onNodeWithText(labels.dissolve).performScrollTo().performClick()
        compose.runOnIdle {
            assertEquals(listOf("ann" to false, "bob" to true), roles)
            assertEquals(listOf("bob" to false), mutes)
            assertEquals(1, leaves)
        }
    }

    @Test fun removingIsEmittedAsTappedWhileTransferAsksFirst() {
        val removed = mutableListOf<String>()
        val transferred = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            FlareGroupDetail(
                model = model,
                onRemoveMember = { removed += it },
                onTransferOwner = { transferred += it },
            )
        } }
        // Removing is the host's to confirm (DangerConfirm): the tap is the intent.
        compose.onNodeWithText("Bob").performClick()
        compose.onNodeWithText(labels.removeMember).performClick()
        compose.onAllNodesWithText(labels.confirmTransfer).assertCountEquals(0)
        compose.runOnIdle { assertEquals(listOf("bob"), removed) }
        // Transferring ownership is confirmed here, from the member sheet it starts in.
        compose.onNodeWithText("Ann").performClick()
        compose.onNodeWithText(labels.transferOwner).performClick()
        compose.onNodeWithText(labels.transferConfirmPrefix + "Ann" + labels.transferConfirmSuffix).assertIsDisplayed()
        compose.runOnIdle { assertEquals(emptyList<String>(), transferred) }
        compose.onNodeWithText(labels.confirmTransfer).performClick()
        compose.runOnIdle { assertEquals(listOf("ann"), transferred) }
    }

    @Test fun memberActionsWithoutHandlersAreNotOffered() {
        compose.setContent { MaterialTheme { FlareGroupDetail(model = model) } }
        compose.onNodeWithText("Ann").performClick()
        compose.onNodeWithText(labels.removeMember).assertIsDisplayed()
        compose.onAllNodesWithText(labels.unsetAdmin).assertCountEquals(0)
        compose.onAllNodesWithText(labels.mute).assertCountEquals(0)
    }

    @Test fun slotsSitAfterTheInfoSectionAndAfterTheButtonsInThePageInset() {
        compose.setContent { MaterialTheme {
            FlareGroupDetail(
                model = model.copy(announcement = "周五评审", myNickname = "主持人"),
                afterInfo = { Text("公告 2/3 人已读", Modifier.testTag("afterInfo")) },
                footer = { Text("举报群聊", Modifier.testTag("footer")) },
                onOpenChat = { _, _ -> },
            )
        } }
        // Bounds are compared at one scroll position: scroll first, then read every node.
        val afterInfo = compose.onNodeWithTag("afterInfo").performScrollTo().assertIsDisplayed()
        afterInfo.assertLeftPositionInRootIsEqualTo(FlareSizes.spacingLg)
        val afterInfoBounds = afterInfo.getUnclippedBoundsInRoot()
        val members = compose.onNode(hasText(labels.members) and hasText("3")).getUnclippedBoundsInRoot()
        val myInGroup = compose.onNodeWithText(labels.myInGroupSection).getUnclippedBoundsInRoot()
        assertTrue("afterInfo follows the info section", afterInfoBounds.top >= members.bottom)
        assertTrue("afterInfo precedes the next section", afterInfoBounds.bottom <= myInGroup.top)

        val footer = compose.onNodeWithTag("footer").performScrollTo().assertIsDisplayed()
        footer.assertLeftPositionInRootIsEqualTo(FlareSizes.spacingLg)
        val footerBounds = footer.getUnclippedBoundsInRoot()
        val leave = compose.onNodeWithText(labels.dissolve).getUnclippedBoundsInRoot()
        val message = compose.onNodeWithText(labels.message).getUnclippedBoundsInRoot()
        assertTrue("the message button precedes leave", message.bottom <= leave.top)
        assertTrue("footer follows the leave button", footerBounds.top >= leave.bottom)
    }

    @Test fun theMessageButtonIsDrawnOnlyWhenTheHostOpensChats() {
        val opened = mutableListOf<Pair<List<String>, String>>()
        var handlesChats by mutableStateOf(false)
        compose.setContent { MaterialTheme {
            FlareGroupDetail(
                model = model,
                onOpenChat = if (handlesChats) { ids, name -> opened += ids to name } else null,
            )
        } }
        compose.onNodeWithText(labels.dissolve).performScrollTo().assertIsDisplayed()
        compose.onAllNodesWithText(labels.message).assertCountEquals(0)
        handlesChats = true
        compose.onNodeWithText(labels.message).performScrollTo().performClick()
        compose.runOnIdle { assertEquals(listOf(listOf("me", "ann", "bob") to "设计评审组"), opened) }
    }

    @Test fun anUnknownJoinPolicyReadsNotSetAndOpensWithNothingSelected() {
        val chosen = mutableListOf<FlareGroupJoinPolicy>()
        var current by mutableStateOf(model.copy(announcement = "周五评审", myNickname = "主持人", joinPolicy = null))
        compose.setContent { MaterialTheme {
            FlareGroupDetail(
                model = current,
                onSetJoinPolicy = { policy -> chosen += policy; current = current.copy(joinPolicy = policy) },
            )
        } }
        compose.onNode(hasText(labels.joinMode) and hasText(labels.notSet)).performScrollTo().performClick()
        listOf(labels.joinOpen, labels.joinApproval, labels.joinInvite).forEach { compose.onNode(hasText(it) and isSelectable()).assertIsNotSelected() }
        compose.onNodeWithText(labels.save).assertIsNotEnabled()
        compose.onNode(hasText(labels.joinApproval) and isSelectable()).performClick()
        compose.onNodeWithText(labels.save).assertIsEnabled().performClick()
        compose.runOnIdle { assertEquals(listOf(FlareGroupJoinPolicy.Approval), chosen) }
        // The host's confirmed value is what the row and the picker show next.
        compose.onNode(hasText(labels.joinMode) and hasText(labels.joinApproval)).performScrollTo().performClick()
        compose.onNode(hasText(labels.joinApproval) and isSelectable()).assertIsSelected()
        compose.onNode(hasText(labels.joinOpen) and isSelectable()).assertIsNotSelected()
    }

    @Test fun withoutAJoinPolicyHandlerTheRowOpensNoPicker() {
        compose.setContent { MaterialTheme { FlareGroupDetail(model = model.copy(joinPolicy = FlareGroupJoinPolicy.Invite)) } }
        // Since Round 5 a row nobody can change is a value, not a disabled button: no click action at all.
        compose.onNode(hasText(labels.joinMode) and hasText(labels.joinInvite)).performScrollTo().assertHasNoClickAction().performClick()
        compose.onAllNodesWithText(labels.save).assertCountEquals(0)
    }

    @Test fun theMembersRowOpensASearchableSheetWhoseMembersOpenTheSameActions() {
        val big = model.copy(memberCount = 30, members = model.members + (1..27).map { Contact("m$it", "成员$it") })
        val roles = mutableListOf<Pair<String, Boolean>>()
        compose.setContent { MaterialTheme { FlareGroupDetail(model = big, onPromoteMember = { id, admin -> roles += id to admin }) } }
        // The grid previews 19 members and the add tile: member 27 is only in the sheet.
        compose.onAllNodesWithText("成员27").assertCountEquals(0)
        // The members row, not the grid's heading of the same word.
        compose.onNode(hasText(labels.members) and androidx.compose.ui.test.hasClickAction()).performScrollTo().performClick()
        compose.onNodeWithText(strings.groupDetailMembersTitle(30)).assertIsDisplayed()
        compose.onNode(androidx.compose.ui.test.hasSetTextAction()).performTextInput("成员27")
        // The member row, not the search field that now holds the same text.
        compose.onNode(hasText("成员27") and androidx.compose.ui.test.hasClickAction() and !androidx.compose.ui.test.hasSetTextAction()).performClick()
        compose.onNodeWithText(labels.setAdmin).performClick()
        compose.runOnIdle { assertEquals(listOf("m27" to true), roles) }
    }

    @Test fun aSearchWithoutMatchesSaysSo() {
        compose.setContent { MaterialTheme { FlareGroupDetail(model = model) } }
        compose.onNode(hasText(labels.members) and androidx.compose.ui.test.hasClickAction()).performScrollTo().performClick()
        compose.onNode(androidx.compose.ui.test.hasSetTextAction()).performTextInput("陈")
        compose.onNodeWithText(strings.groupDetailNoMatchingMembers).assertIsDisplayed()
    }

    @Test fun aSubmitEditKeepsTheEditorOpenWithTheDraftAndTheErrorUntilItSucceeds() {
        val submitted = mutableListOf<Pair<FlareGroupDetailEditKind, String>>()
        var fail = true
        compose.setContent { MaterialTheme {
            FlareGroupDetail(model = model, submitEdit = { kind, value ->
                submitted += kind to value
                if (fail) error("群聊名称保存失败，请重试。")
            })
        } }
        compose.onNode(hasText(labels.name) and hasText("设计评审组")).performScrollTo().performClick()
        compose.onNode(hasSetTextAction()).performTextReplacement("设计评审群")
        compose.onNodeWithText(labels.save).performClick()
        compose.onNodeWithText("群聊名称保存失败，请重试。").assertIsDisplayed()
        compose.onNode(hasSetTextAction() and hasText("设计评审群")).assertExists()
        fail = false
        compose.onNodeWithText(labels.save).performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertDoesNotExist()
        compose.runOnIdle { assertEquals(List(2) { FlareGroupDetailEditKind.Name to "设计评审群" }, submitted) }
    }

    @Test fun withoutSubmitEditTheUpdateCallbackFiresAndTheEditorCloses() {
        val nicknames = mutableListOf<String>()
        compose.setContent { MaterialTheme { FlareGroupDetail(model = model, onUpdateMyNickname = { nicknames += it }) } }
        compose.onNode(hasText(labels.myNickname) and hasText(labels.notSet)).performScrollTo().performClick()
        compose.onNode(hasSetTextAction()).performTextInput(" 主持人 ")
        compose.onNodeWithText(labels.save).performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertDoesNotExist()
        compose.runOnIdle { assertEquals(listOf("主持人"), nicknames) }
    }
}
