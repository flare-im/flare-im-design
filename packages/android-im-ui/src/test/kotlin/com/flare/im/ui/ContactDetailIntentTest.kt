package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/** A contact profile offers an intent only when the host handles it, so a stranger gets no friend-only actions. */
class ContactDetailIntentTest {
    private val labels = FlareContactDetailLabels()
    private val lin = Contact(id = "u_lin", name = "林夏")

    @Test fun theActionRowHoldsOnlyTheHandledIntents() {
        assertEquals(listOf(ContactDetailAction.Message), contactDetailActions(handlesMessage = true, handlesCall = false, handlesVideo = false))
        assertEquals(
            listOf(ContactDetailAction.Message, ContactDetailAction.Call, ContactDetailAction.Video),
            contactDetailActions(handlesMessage = true, handlesCall = true, handlesVideo = true),
        )
        assertEquals(emptyList(), contactDetailActions(handlesMessage = false, handlesCall = false, handlesVideo = false))
    }

    @Test fun aStrangerSeesOnlyTheValuesThatAreSet() {
        fun rows(contact: Contact, description: String?) = contactDetailInfoItems(contact, false, description, labels, editsRemark = false, editsDescription = false, togglesStar = false)
            .map { Triple(it.key, it.kind, it.detail) }
        // Nothing public to show: no rows, and never the account id.
        assertEquals(emptyList(), rows(lin, null))
        // Read-only values show only when they exist, and never as rows that open an editor.
        assertEquals(
            listOf(
                Triple("flareId", FlareSettingKind.Value, "linxia"),
                Triple("remark", FlareSettingKind.Value, "设计评审"),
                Triple("description", FlareSettingKind.Value, "响应快"),
            ),
            rows(lin.copy(flareId = "linxia", remark = "设计评审"), "响应快"),
        )
    }

    @Test fun theFlareIdIsThePublicHandleAndNeverTheAccountId() {
        fun flareIdRow(contact: Contact) = contactDetailInfoItems(contact, false, null, labels, editsRemark = true, editsDescription = false, togglesStar = false)
            .firstOrNull { it.key == "flareId" }
        assertEquals(null, flareIdRow(lin))
        assertEquals(null, flareIdRow(lin.copy(flareId = "  ")))
        assertEquals("linxia", flareIdRow(lin.copy(flareId = "linxia"))?.detail)
        // The mini profile card follows the same rule.
        assertEquals("", profileCardMeta(lin))
        assertEquals("上海", profileCardMeta(lin.copy(region = "上海")))
        assertEquals("Flare ID · linxia · 上海", profileCardMeta(lin.copy(flareId = "linxia", region = "上海")))
    }

    @Test fun aFriendGetsEditableRowsAndTheStarSwitch() {
        val items = contactDetailInfoItems(lin.copy(flareId = "linxia"), starred = true, description = "", labels = labels, editsRemark = true, editsDescription = true, togglesStar = true)
        assertEquals(listOf("flareId", "remark", "description", "star"), items.map { it.key })
        assertEquals(listOf(FlareSettingKind.Value, FlareSettingKind.Navigation, FlareSettingKind.Navigation, FlareSettingKind.Toggle), items.map { it.kind })
        assertEquals(listOf(labels.notSet, labels.notSet), items.drop(1).take(2).map { it.detail })
        assertEquals(true, items.last().value)
    }
}
