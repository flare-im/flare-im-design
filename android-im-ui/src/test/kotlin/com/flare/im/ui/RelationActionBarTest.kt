package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class RelationActionBarTest {
    private val all = FlareRelationCapabilities(
        add = true, accept = true, reject = true, remove = true,
        block = true, unblock = true, message = true,
    )

    private fun ids(relation: FlareRelationState, caps: FlareRelationCapabilities?) =
        relationActions(relation, caps).map { it.action }

    @Test fun nothingWithoutCapabilities() {
        for (relation in FlareRelationState.entries) {
            assertEquals(emptyList(), ids(relation, FlareRelationCapabilities()))
            assertEquals(emptyList(), ids(relation, null))
        }
    }

    @Test fun noneOffersAddAsPrimaryPlusBlock() {
        assertEquals(listOf(FlareRelationAction.Add, FlareRelationAction.Block), ids(FlareRelationState.None, all))
        val entries = relationActions(FlareRelationState.None, all)
        assertEquals(FlareRelationActionEntry(FlareRelationAction.Add, primary = true), entries.first())
        assertEquals(FlareRelationActionEntry(FlareRelationAction.Block), entries.last())
    }

    @Test fun pendingOutNeverReOffersAdd() {
        assertEquals(listOf(FlareRelationAction.Block), ids(FlareRelationState.PendingOut, all))
        assertEquals(emptyList(), ids(FlareRelationState.PendingOut, FlareRelationCapabilities(add = true)))
        assertTrue(relationShowsPending(FlareRelationState.PendingOut))
        for (relation in FlareRelationState.entries.filter { it != FlareRelationState.PendingOut }) {
            assertFalse(relationShowsPending(relation))
        }
        assertFalse(relationShowsPending(null))
    }

    @Test fun pendingInOffersAcceptRejectBlock() {
        assertEquals(
            listOf(FlareRelationAction.Accept, FlareRelationAction.Reject, FlareRelationAction.Block),
            ids(FlareRelationState.PendingIn, all),
        )
        val entries = relationActions(FlareRelationState.PendingIn, all)
        assertEquals(listOf(FlareRelationAction.Accept), entries.filter { it.primary }.map { it.action })
        assertTrue(entries.none { it.destructive })
    }

    @Test fun friendsMarksRemoveAndBlockDestructive() {
        assertEquals(
            listOf(FlareRelationAction.Message, FlareRelationAction.Remove, FlareRelationAction.Block),
            ids(FlareRelationState.Friends, all),
        )
        val entries = relationActions(FlareRelationState.Friends, all)
        assertEquals(listOf(FlareRelationAction.Message), entries.filter { it.primary }.map { it.action })
        assertEquals(
            listOf(FlareRelationAction.Remove, FlareRelationAction.Block),
            entries.filter { it.destructive }.map { it.action },
        )
    }

    @Test fun blockedOffersUnblockAndNothingElse() {
        assertEquals(listOf(FlareRelationAction.Unblock), ids(FlareRelationState.Blocked, all))
        assertTrue(relationActions(FlareRelationState.Blocked, all).first().primary)
        assertEquals(
            emptyList(),
            ids(FlareRelationState.Blocked, FlareRelationCapabilities(add = true, message = true)),
        )
    }

    @Test fun missingCapabilityRemovesOnlyItsOwnEntry() {
        assertEquals(listOf(FlareRelationAction.Block), ids(FlareRelationState.None, FlareRelationCapabilities(block = true)))
        assertEquals(listOf(FlareRelationAction.Add), ids(FlareRelationState.None, FlareRelationCapabilities(add = true)))
        assertEquals(
            listOf(FlareRelationAction.Accept, FlareRelationAction.Block),
            ids(FlareRelationState.PendingIn, FlareRelationCapabilities(accept = true, block = true)),
        )
        assertEquals(listOf(FlareRelationAction.Reject), ids(FlareRelationState.PendingIn, FlareRelationCapabilities(reject = true)))
        assertEquals(
            listOf(FlareRelationAction.Remove, FlareRelationAction.Block),
            ids(FlareRelationState.Friends, FlareRelationCapabilities(remove = true, block = true)),
        )
        assertEquals(listOf(FlareRelationAction.Message), ids(FlareRelationState.Friends, FlareRelationCapabilities(message = true)))
    }

    @Test fun absentRelationDegradesToNone() {
        assertEquals(
            listOf(FlareRelationAction.Add, FlareRelationAction.Block),
            relationActions(null, all).map { it.action },
        )
    }
}
