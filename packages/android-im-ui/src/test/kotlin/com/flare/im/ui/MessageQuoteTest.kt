package com.flare.im.ui

import java.time.LocalDateTime
import java.time.ZoneId
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Reply quotes in the bubble and how the list locates the quoted message. */
class MessageQuoteTest {
    private val quote = FlareReplyTarget("Ann", "See you at 3", messageId = "m1")
    private val zone: ZoneId = ZoneId.of("Asia/Shanghai")

    private fun message(id: String, serverId: String? = null, sentAtMs: Long = 0) =
        FlareMessageData(id = id, senderId = "me", senderName = "Me", content = FlareTextContent(id), serverId = serverId, sentAtMs = sentAtMs)

    /** The rows the list lays a thread out as — what the id lookup is built from. */
    private fun rowsOf(messages: List<FlareMessageData>): List<MessageTimelineRow> =
        messageTimelineRows(messages, currentUserId = "me", unreadFromId = null, zone = zone) { "那天" }

    @Test fun theQuoteLocatesOnlyWithAnIdAHandlerAndNoMultiSelect() {
        assertEquals("m1", messageQuoteLocateId(quote, hasOnLocate = true, multiSelectMode = false))
        assertNull(messageQuoteLocateId(quote, hasOnLocate = false, multiSelectMode = false))
        assertNull(messageQuoteLocateId(quote, hasOnLocate = true, multiSelectMode = true))
        assertNull(messageQuoteLocateId(quote.copy(messageId = null), hasOnLocate = true, multiSelectMode = false))
        assertNull(messageQuoteLocateId(null, hasOnLocate = true, multiSelectMode = false))
    }

    @Test fun theListScrollsToLoadedRowsAndAsksTheHostForTheRest() {
        val rows = mapOf("m1" to 0, "m7" to 6)
        assertEquals(MessageLocateTarget.Row(6), messageLocateTarget("m7", rows, hostLocates = true))
        // A loaded original never goes to the host, and needs no host to be located.
        assertEquals(MessageLocateTarget.Row(0), messageLocateTarget("m1", rows, hostLocates = false))
        assertEquals(MessageLocateTarget.Host, messageLocateTarget("older", rows, hostLocates = true))
        assertNull(messageLocateTarget("older", rows, hostLocates = false))
    }

    /**
     * A quote carries one id — the quoted message's core id — while a message this device sent is drawn on
     * a row keyed by its client id. The list knows each row by both, so the bubble recognises the original
     * and scrolls to it, instead of sending the host off to look for a message that is on screen.
     */
    @Test fun aQuoteFindsARowByTheCoreIdAsWellAsByTheRowId() {
        val messages = listOf(message("cli-1", serverId = "srv-1"), message("srv-2"))
        val index = messageRowIndexByAnyId(rowsOf(messages), messages)
        assertEquals(MessageLocateTarget.Row(0), messageLocateTarget("srv-1", index, hostLocates = true))
        assertEquals(MessageLocateTarget.Row(0), messageLocateTarget("cli-1", index, hostLocates = true))
        // A received message's row id is already the core id; one key, still found.
        assertEquals(MessageLocateTarget.Row(1), messageLocateTarget("srv-2", index, hostLocates = true))
        assertEquals(mapOf("cli-1" to 0, "srv-1" to 0, "srv-2" to 1), index)
        // An id no loaded row has is still the host's to go and read.
        assertEquals(MessageLocateTarget.Host, messageLocateTarget("srv-9", index, hostLocates = true))
    }

    /** The index is into the rows, so a date pill above the thread does not send a quote to the wrong one. */
    @Test fun theIdsPointAtTheRowsPlaceInTheTimelineNotTheMessagesPlace() {
        val at = LocalDateTime.of(2026, 9, 14, 8, 0).atZone(zone).toInstant().toEpochMilli()
        val messages = listOf(message("cli-1", serverId = "srv-1", sentAtMs = at))
        assertEquals(mapOf("cli-1" to 1, "srv-1" to 1), messageRowIndexByAnyId(rowsOf(messages), messages))
    }

    /** A row's own id is what it answers to first: another row's core id never takes it. */
    @Test fun aRowsOwnIdOutranksAnotherRowsCoreId() {
        val messages = listOf(message("cli-1", serverId = "shared"), message("shared"))
        assertEquals(1, messageRowIndexByAnyId(rowsOf(messages), messages)["shared"])
        // Nothing to add when a message has no core id of its own, or when it is the id already drawn.
        val plain = listOf(message("m1"), message("m2", serverId = "m2"))
        assertEquals(mapOf("m1" to 0, "m2" to 1), messageRowIndexByAnyId(rowsOf(plain), plain))
    }

    @Test fun aQuotingMessageKeepsItsBubble() {
        val image = FlareMessageData("m2", "ann", "Ann", FlareImageContent("https://example.com/a.png"))
        assertTrue(messageBubbleChromeless(image))
        assertFalse(messageBubbleChromeless(image.copy(replyTo = quote)))
        assertFalse(messageBubbleChromeless(image.copy(content = FlareTextContent("hi"))))
    }

    @Test fun modelsDefaultToNoQuote() {
        assertNull(FlareMessageData("m", "s", "S", FlareTextContent("x")).replyTo)
        assertNull(FlareReplyTarget("Ann", "hi").messageId)
        // A row with no core id of its own is the common case: the row id is the only id it has.
        assertNull(FlareMessageData("m", "s", "S", FlareTextContent("x")).serverId)
    }

    @Test fun theQuoteLabelNamesTheSenderWhenKnown() {
        val zh = FlareStrings()
        assertEquals("引用 Ann：See you", zh.messageQuoteLabel("Ann", "See you"))
        assertEquals("引用：See you", zh.messageQuoteLabel("", "See you"))
        val en = FlareStrings {
            messageQuoteLabel = { name, summary -> if (name.isEmpty()) "Quoted: $summary" else "Quoted $name: $summary" }
        }
        assertEquals("Quoted Ann: See you", en.messageQuoteLabel("Ann", "See you"))
    }
}
