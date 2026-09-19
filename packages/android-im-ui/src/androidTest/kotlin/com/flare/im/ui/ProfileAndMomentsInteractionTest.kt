package com.flare.im.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertHasNoClickAction
import androidx.compose.ui.test.assertHeightIsAtLeast
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertWidthIsAtLeast
import androidx.compose.ui.test.click
import androidx.compose.ui.test.hasAnyAncestor
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * Batch 4 parity as a host sees it: a contact profile offers only the handled intents, the profile header is one
 * identity control beside a separate QR control, a profile card has a tile only for a handled intent, and moment
 * people and comments are controls only when handled.
 */
class ProfileAndMomentsInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()
    private val labels = FlareContactDetailLabels()
    private val isSwitch = SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Switch)

    // MARK: P1 ContactDetail

    @Test fun aStrangersProfileOffersOnlyTheIntentsTheHostHandles() {
        compose.setContent { MaterialTheme { ContactDetail(contact = Contact("u_lin", "林夏"), onMessage = {}) } }
        compose.onNodeWithText(labels.message).assertHasClickAction()
        listOf(labels.voice, labels.video, labels.block, labels.remove, labels.remark, labels.description, labels.star)
            .forEach { compose.onAllNodesWithText(it).assertCountEquals(0) }
        compose.onAllNodes(isSwitch).assertCountEquals(0)
        // No public handle: no Flare ID row, and the account id is never shown.
        compose.onAllNodesWithText(labels.flareId).assertCountEquals(0)
        compose.onAllNodesWithText("u_lin", substring = true).assertCountEquals(0)
        // Nothing to show or edit: no empty 资料 card either.
        compose.onAllNodesWithText(labels.infoSection).assertCountEquals(0)
    }

    @Test fun theFlareIdRowShowsThePublicHandle() {
        compose.setContent { MaterialTheme { ContactDetail(contact = Contact("u_lin", "林夏", flareId = "linxia"), onMessage = {}) } }
        compose.onNode(hasText(labels.flareId) and hasText("linxia")).assertIsDisplayed()
        compose.onAllNodesWithText("u_lin", substring = true).assertCountEquals(0)
    }

    @Test fun aFriendsProfileEditsTheRowsTogglesTheStarAndOffersTheDangerZone() {
        val events = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            ContactDetail(
                contact = Contact("u_lin", "林夏", remark = "设计评审"),
                description = "响应快",
                onMessage = { events += "message" },
                onEditRemark = { events += "remark" },
                onEditDescription = { events += "description" },
                onToggleStar = { events += "star:$it" },
                onBlock = { events += "block" },
                onRemove = { events += "remove" },
            )
        } }
        // No call handlers: no call buttons.
        compose.onAllNodesWithText(labels.voice).assertCountEquals(0)
        compose.onNode(hasText(labels.remark) and hasText("设计评审")).performScrollTo().performClick()
        compose.onNode(isSwitch).performScrollTo().performClick()
        compose.onNodeWithText(labels.block).performScrollTo().performClick()
        compose.onNodeWithText(labels.remove).performScrollTo().performClick()
        compose.runOnIdle { assertEquals(listOf("remark", "star:true", "block", "remove"), events) }
    }

    // MARK: P2 ProfilePanel

    @Test fun theIdentityRowAndTheQrButtonAreSeparateNamedControls() {
        val events = mutableListOf<String>()
        compose.setContent { MaterialTheme {
            ProfilePanel(
                user = UserProfile(id = "u_lin", name = "林夏", signature = "产品设计", flareId = "lin"),
                entries = emptyList(),
                onEdit = { events += "edit" },
                onQr = { events += "qr" },
            )
        } }
        val identity = compose.onNodeWithContentDescription(strings.profilePanelEditProfile("林夏"))
        identity.assertHasClickAction()
        // The QR control is a sibling of the identity control, never nested in it.
        compose.onNode(hasContentDescription(strings.myQrCode) and hasAnyAncestor(hasContentDescription(strings.profilePanelEditProfile("林夏")))).assertDoesNotExist()
        compose.onNodeWithContentDescription(strings.myQrCode)
            .assertHasClickAction().assertWidthIsAtLeast(48.dp).assertHeightIsAtLeast(48.dp)
            .performClick()
        identity.performClick()
        compose.runOnIdle { assertEquals(listOf("qr", "edit"), events) }
    }

    // MARK: ProfileCard

    @Test fun aProfileCardWithoutCallbacksHasNoTiles() {
        compose.setContent { MaterialTheme { ProfileCard(user = Contact("u_lin", "林夏")) } }
        compose.onAllNodes(hasClickAction()).assertCountEquals(0)
        compose.onAllNodesWithText(strings.sendMessage).assertCountEquals(0)
        listOf(strings.contactDetailVoice, strings.contactDetailVideo)
            .forEach { compose.onAllNodesWithContentDescription(it).assertCountEquals(0) }
    }

    @Test fun aHandledCallIsANamedButtonAtLeastTheTouchTarget() {
        var calls = 0
        compose.setContent { MaterialTheme { ProfileCard(user = Contact("u_lin", "林夏"), onCall = { calls++ }) } }
        compose.onNodeWithContentDescription(strings.contactDetailVoice)
            .assertHasClickAction()
            .assert(SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Button))
            .assertWidthIsAtLeast(48.dp).assertHeightIsAtLeast(48.dp)
            .performClick()
        // Only the handled intent has a tile.
        compose.onAllNodesWithContentDescription(strings.contactDetailVideo).assertCountEquals(0)
        compose.onAllNodesWithText(strings.sendMessage).assertCountEquals(0)
        compose.runOnIdle { assertEquals(1, calls) }
    }

    // MARK: P3 Moments

    private val moment = Moment(
        id = "m1",
        author = MomentAuthor("u_lin", "林夏"),
        text = "周末去爬山",
        time = "10 分钟前",
        likes = listOf(MomentLike("u_zhou", "周屿"), MomentLike("u_su", "苏晚晴")),
        comments = listOf(MomentComment(id = "c1", author = MomentAuthor("u_he", "何川"), text = "带上我")),
    )

    @Test fun peopleAndCommentsAreTextWhenTheHostDoesNothingWithThem() {
        compose.setContent { MaterialTheme { MomentCard(moment = moment, onLike = {}) } }
        compose.onNodeWithText("林夏").assertHasNoClickAction()
        compose.onNodeWithText("周屿", substring = true).assertHasNoClickAction()
        compose.onNodeWithText("带上我", substring = true).assertHasNoClickAction()
        compose.onAllNodesWithContentDescription(strings.momentReplyToComment("何川", "带上我")).assertCountEquals(0)
    }

    @Test fun theAuthorLikersAndCommentsAreNamedControlsWhenHandled() {
        val events = mutableListOf<Pair<String, String>>()
        compose.setContent { MaterialTheme {
            MomentCard(
                moment = moment,
                onSelectAuthor = { events += "author" to it },
                onSelectLiker = { events += "liker" to it },
                onSelectComment = { events += "comment" to it.id },
            )
        } }
        compose.onNodeWithText("林夏").assertHasClickAction().performClick()
        // The avatar repeats the name: its initial is hidden from accessibility.
        compose.onAllNodesWithText("林").assertCountEquals(0)
        compose.onNodeWithText("苏晚晴").assertHasClickAction().performClick()
        val row = compose.onNodeWithContentDescription(strings.momentReplyToComment("何川", "带上我"))
        row.assertHasClickAction().performClick()
        // A tap on the author's name at the start of the row opens the author.
        row.performTouchInput { click(Offset(12f, centerY)) }
        compose.runOnIdle { assertEquals(listOf("author" to "u_lin", "liker" to "u_su", "comment" to "c1", "author" to "u_he"), events) }
    }

    @Test fun aCoverWithoutAnImageOffersNoEditControlTheHostDoesNotHandle() {
        var edits = 0
        compose.setContent { MaterialTheme {
            Column {
                MomentsCoverHeader(userId = "u_lin", name = "林夏", signature = "周末去爬山")
                MomentsCoverHeader(userId = "u_he", name = "何川", onEditCover = { edits++ })
            }
        } }
        compose.onNodeWithText("林夏").assertIsDisplayed()
        compose.onAllNodesWithText(strings.changeCover).assertCountEquals(1)
        compose.onNodeWithText(strings.changeCover).performClick()
        compose.runOnIdle { assertEquals(1, edits) }
    }
}
