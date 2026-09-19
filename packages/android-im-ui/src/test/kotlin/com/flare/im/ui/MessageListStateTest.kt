package com.flare.im.ui

import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull

/**
 * What [FlareMessageListState.scrollToMessage] answers, without a list on screen. The answer is a real
 * lookup in the rows the list last laid out — that is how a host tells "shown" from "not in this
 * conversation" — and a handle with no composed list answers false rather than failing.
 * The scroll itself, and the row arriving in view, are asserted on the device
 * (`androidTest/MessageQuoteInteractionTest`).
 */
class MessageListStateTest {
    private val owner = Any()

    @Test fun aHandleNoListHasComposedYetLocatesNothing() {
        assertNull(FlareMessageListState().rowIndexOf("m1"))
    }

    @Test fun scrollToMessageIsFalseBeforeAnyListIsComposed() = runBlocking {
        // The host may ask before it rebuilds the list; that is an answer, not a crash.
        assertFalse(FlareMessageListState().scrollToMessage("m1"))
    }

    @Test fun anAttachedListAnswersFromTheRowsItLaidOut() {
        val state = FlareMessageListState()
        state.attach(owner, mapOf("m1" to 0, "m2" to 3), reducedMotion = false)
        assertEquals(0, state.rowIndexOf("m1"))
        assertEquals(3, state.rowIndexOf("m2"))
        assertNull(state.rowIndexOf("m3"))
    }

    @Test fun eachCompositionReplacesTheRowsRatherThanAddingToThem() {
        val state = FlareMessageListState()
        state.attach(owner, mapOf("old" to 0), reducedMotion = false)
        state.attach(owner, mapOf("new" to 0), reducedMotion = false)
        assertNull(state.rowIndexOf("old"))
        assertEquals(0, state.rowIndexOf("new"))
    }

    /**
     * The host asks with the id it was handed — a quote's id is the quoted message's core id — and the
     * handle answers for the row the list drew with a different id. Same rule as the tap inside the list,
     * because it is the same map ([messageRowIndexByAnyId]); this is why the host converts nothing.
     * That the answer is then `true` and the row arrives in view is the device's to prove
     * (`androidTest/MessageListStateInteractionTest`).
     */
    @Test fun theHandleAnswersToBothIdsOfARowTheListDrewWithTheOtherOne() {
        val messages = listOf(
            FlareMessageData(id = "cli-2", senderId = "me", senderName = "Me", content = FlareTextContent("我发的"), serverId = "srv-2"),
            FlareMessageData(id = "srv-3", senderId = "ann", senderName = "Ann", content = FlareTextContent("收到的")),
        )
        val rows = messageTimelineRows(messages, currentUserId = "me", unreadFromId = null, zone = java.time.ZoneId.of("Asia/Shanghai")) { "那天" }
        val state = FlareMessageListState()
        state.attach(owner, messageRowIndexByAnyId(rows, messages), reducedMotion = false)
        assertEquals(0, state.rowIndexOf("srv-2"))
        assertEquals(0, state.rowIndexOf("cli-2"))
        assertEquals(1, state.rowIndexOf("srv-3"))
        assertNull(state.rowIndexOf("srv-9"))
    }

    @Test fun aListThatLeftCompositionLocatesNothing() = runBlocking {
        val state = FlareMessageListState()
        state.attach(owner, mapOf("m1" to 0), reducedMotion = false)
        state.detach(owner)
        assertNull(state.rowIndexOf("m1"))
        assertFalse(state.scrollToMessage("m1"))
    }

    @Test fun aListLeavingAfterAnotherTookTheHandleDoesNotTakeItsRowsWithIt() {
        val state = FlareMessageListState()
        state.attach(owner, mapOf("m1" to 0), reducedMotion = false)
        val next = Any()
        state.attach(next, mapOf("m1" to 2), reducedMotion = false)
        state.detach(owner)
        assertEquals(2, state.rowIndexOf("m1"))
    }
}
