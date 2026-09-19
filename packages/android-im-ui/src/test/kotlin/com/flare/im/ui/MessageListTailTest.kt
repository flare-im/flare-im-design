package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The reading position of [MessageList] (Vue `MessageList.vue` tail following): a conversation opens at its
 * newest message, new messages follow a reader who is at the bottom (and their own always do), a reader who
 * scrolled up keeps their place and is told how many messages sit below, and loading older messages keeps the
 * message they are reading where it is.
 */
class MessageListTailTest {
    private fun message(id: String, sender: String = "peer") =
        FlareMessageData(id = id, senderId = sender, senderName = sender, content = FlareTextContent(id), sentAtMs = 0)

    private fun viewport(
        firstKey: Any? = "m1",
        firstOffset: Int = 0,
        lastIndex: Int = 9,
        lastKey: Any? = "m10",
        lastEnd: Int = 900,
        lastSize: Int = 60,
        totalRows: Int = 10,
        viewportEnd: Int = 900,
        viewportSize: Int = 900,
        scrolling: Boolean = false,
    ) = MessageListViewport(firstKey, firstOffset, lastIndex, lastKey, lastEnd, lastSize, totalRows, viewportEnd, viewportSize, scrolling)

    // MARK: opening

    @Test fun aConversationWithMoreMessagesThanFitOpensAtTheNewest() {
        val loaded = (1..40).map { message("m$it") }
        // Nothing was rendered before (first render, or another conversation): no growth to follow, so the
        // list is sent to its last row — the newest message — however many are loaded.
        assertNull(messageListGrowth(previousIds = emptySet(), messages = loaded))
        assertNull(messageListGrowth(previousIds = setOf("x1", "x2"), messages = loaded))
        val tail = MessageListTail()
        tail.browse("m40")
        tail.follow()
        assertTrue(tail.followTail)
        assertNull(tail.anchorId)
    }

    // MARK: appending

    @Test fun anAppendedMessageFollowsAReaderAtTheBottomAndTheirOwnAlways() {
        val appended = listOf(message("m41"))
        // At the bottom, or still following: the new message comes into view.
        assertTrue(messageListFollowsAppend(followTail = true, atBottom = false, appended = appended, currentUserId = "me"))
        assertTrue(messageListFollowsAppend(followTail = false, atBottom = true, appended = appended, currentUserId = "me"))
        // Scrolled up: someone else's message does not move the list.
        assertEquals(false, messageListFollowsAppend(followTail = false, atBottom = false, appended = appended, currentUserId = "me"))
        // The reader's own message always takes them to the newest, wherever they were.
        assertTrue(messageListFollowsAppend(false, false, listOf(message("m42", sender = "me")), "me"))
        // Nothing appended asks for nothing.
        assertEquals(false, messageListFollowsAppend(followTail = true, atBottom = true, appended = emptyList(), currentUserId = "me"))
    }

    @Test fun anAppendedMessageWhileScrolledUpIsCountedBelowTheReader() {
        val messages = (1..12).map { message("m$it") }
        // The anchor is the newest message when the reader left the bottom: everything after it is below them.
        assertEquals(0, messageListBelowCount(messages, "m12"))
        assertEquals(3, messageListBelowCount(messages, "m9"))
        // No anchor (the reader is following) counts nothing, and an anchor that is no longer loaded counts nothing.
        assertEquals(0, messageListBelowCount(messages, null))
        assertEquals(0, messageListBelowCount(messages, "gone"))
    }

    @Test fun growthSeparatesOlderPagesFromNewMessages() {
        val rendered = (5..10).map { message("m$it") }
        val withOlder = (1..10).map { message("m$it") }
        assertEquals(4, messageListGrowth(rendered.map { it.id }.toSet(), withOlder)?.prepended)
        assertEquals(emptyList(), messageListGrowth(rendered.map { it.id }.toSet(), withOlder)?.appended)
        val withNewer = (5..12).map { message("m$it") }
        val appended = messageListGrowth(rendered.map { it.id }.toSet(), withNewer)
        assertEquals(0, appended?.prepended)
        assertEquals(listOf("m11", "m12"), appended?.appended?.map { it.id })
    }

    // MARK: keeping a place

    @Test fun loadingOlderKeepsTheMessageTheReaderIsOn() {
        // The rows laid out before, top first; after the older page the same message sits further down the list.
        val visible = listOf<Pair<Any, Int>>("day:m5" to -20, "m5" to 12, "m6" to 300)
        val rowIndexAfterPrepend = mapOf("m5" to 41, "m6" to 42)
        assertEquals(41 to 12, messageListReadingAnchor(visible, rowIndexAfterPrepend))
        // A message that the prepend replaced is skipped for the next one that is still loaded.
        assertEquals(42 to 300, messageListReadingAnchor(visible, mapOf("m6" to 42)))
        // None of the laid-out rows survived: the kit keeps no anchor rather than guessing one.
        assertNull(messageListReadingAnchor(visible, emptyMap()))
    }

    // MARK: what a new layout asks for

    @Test fun aReadersOwnScrollDecidesBetweenFollowingAndBrowsing() {
        val bottom = viewport()
        val up = viewport(firstKey = "m1", firstOffset = -400, lastIndex = 6, lastKey = "m7", lastEnd = 400, scrolling = true)
        // Scrolled away from the end while a scroll is in progress: browse.
        assertEquals(MessageListTailAction.Browse, messageListTailAction(bottom, up, followTail = true, slackPx = 80))
        // Scrolled back to the end: follow again.
        val backDown = viewport(firstOffset = -10, scrolling = true)
        assertEquals(MessageListTailAction.Follow, messageListTailAction(up, backDown, followTail = false, slackPx = 80))
        // Within the slack still counts as the bottom.
        val nearBottom = viewport(firstOffset = -10, lastEnd = 960, scrolling = true)
        assertEquals(MessageListTailAction.Follow, messageListTailAction(up, nearBottom, followTail = false, slackPx = 80))
    }

    @Test fun aGrowingFooterOrAResizeKeepsAFollowingReaderAtTheEnd() {
        val bottom = viewport()
        // A typing row appears (one more row) under a reader at the end: back to the end.
        val taller = viewport(lastIndex = 10, lastKey = "typing", lastEnd = 980, totalRows = 11)
        assertEquals(MessageListTailAction.SettleAtEnd, messageListTailAction(bottom, taller, followTail = true, slackPx = 80))
        // The same change under a reader who is browsing moves nothing.
        assertEquals(MessageListTailAction.None, messageListTailAction(bottom, taller, followTail = false, slackPx = 80))
        // The keyboard opening (a shorter viewport) also settles a following reader at the end.
        val shorter = viewport(viewportEnd = 500, viewportSize = 500, lastEnd = 900)
        assertEquals(MessageListTailAction.SettleAtEnd, messageListTailAction(bottom, shorter, followTail = true, slackPx = 80))
        // Nothing changed: nothing to do.
        assertEquals(MessageListTailAction.None, messageListTailAction(bottom, viewport(), followTail = true, slackPx = 80))
    }

    @Test fun theKitsOwnJumpsDecideNothing() {
        val up = viewport(firstKey = "m1", firstOffset = -400, lastIndex = 6, lastKey = "m7", lastEnd = 400)
        val bottom = viewport()
        // The first row moved without a scroll in progress (the kit jumped): the reading position is unchanged.
        assertEquals(MessageListTailAction.None, messageListTailAction(bottom, up, followTail = false, slackPx = 80))
        // An empty list is "at the end" and asks for nothing.
        val empty = viewport(firstKey = null, lastIndex = -1, lastKey = null, lastEnd = 0, lastSize = 0, totalRows = 0)
        assertTrue(empty.atEnd)
        assertTrue(empty.atBottom(80))
    }
}
