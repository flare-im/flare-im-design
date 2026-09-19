package com.flare.im.ui

import java.time.LocalDateTime
import java.time.ZoneId
import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** Date separators in the timeline: where they go, what they say, and how the unread divider sits with them. */
class MessageTimelineTest {
    private val zone: ZoneId = ZoneId.of("Asia/Shanghai")

    private fun at(year: Int, month: Int, day: Int, hour: Int, minute: Int): Long =
        LocalDateTime.of(year, month, day, hour, minute).atZone(zone).toInstant().toEpochMilli()

    private fun message(id: String, sender: String, sentAtMs: Long) =
        FlareMessageData(id = id, senderId = sender, senderName = sender, content = FlareTextContent(id), sentAtMs = sentAtMs)

    /** Rows as short strings: "day:<label>", "unread:<count>", or the message id. */
    private fun rows(messages: List<FlareMessageData>, unreadFromId: String? = null): List<String> =
        messageTimelineRows(messages, currentUserId = "me", unreadFromId = unreadFromId, zone = zone) { ms ->
            FlareTimeFormat.timelineDateLabel(ms, "今天", "昨天", Locale.CHINA, nowMs = at(2026, 9, 14, 18, 30), zone = zone)
        }.map { row ->
            when (row) {
                is MessageTimelineRow.Day -> "day:${row.label}"
                is MessageTimelineRow.Unread -> "unread:${row.count}"
                is MessageTimelineRow.Message -> row.key
            }
        }

    @Test fun theFirstMessageIsDatedAndHoursApartOnOneDayAddNothing() {
        val messages = listOf(message("a", "ann", at(2026, 9, 14, 8, 0)), message("b", "me", at(2026, 9, 14, 17, 45)))
        assertEquals(listOf("day:今天", "a", "b"), rows(messages))
    }

    @Test fun crossingMidnightAddsAPill() {
        val messages = listOf(
            message("a", "ann", at(2026, 9, 12, 23, 58)),
            message("b", "ann", at(2026, 9, 13, 0, 1)),
            message("c", "me", at(2026, 9, 14, 9, 0)),
        )
        assertEquals(listOf("day:9/12", "a", "day:昨天", "b", "day:今天", "c"), rows(messages))
    }

    @Test fun theUnreadDividerComesAfterThePillAndEndsTheRun() {
        val messages = listOf(
            message("a", "ann", at(2026, 9, 13, 22, 0)),
            message("b", "ann", at(2026, 9, 14, 9, 0)),
            message("c", "ann", at(2026, 9, 14, 9, 1)),
            message("d", "me", at(2026, 9, 14, 9, 2)),
        )
        assertEquals(listOf("day:昨天", "a", "day:今天", "unread:2", "b", "c", "d"), rows(messages, unreadFromId = "b"))

        // Inside a day, the divider breaks the sender run: the row above closes it, the first unread row opens one.
        val run = listOf(
            message("r1", "ann", at(2026, 9, 14, 9, 0)),
            message("r2", "ann", at(2026, 9, 14, 9, 1)),
            message("r3", "ann", at(2026, 9, 14, 9, 2)),
            message("r4", "ann", at(2026, 9, 14, 9, 3)),
        )
        val built = messageTimelineRows(run, "me", "r3", zone) { "今天" }
        assertEquals(listOf("day:r1", "r1", "r2", "unread:r3", "r3", "r4"), built.map { it.key })
        assertEquals(
            listOf(MessageGroupPosition.First, MessageGroupPosition.Last, MessageGroupPosition.First, MessageGroupPosition.Last),
            built.filterIsInstance<MessageTimelineRow.Message>().map { it.groupPosition },
        )
        // An unknown id draws no divider.
        assertEquals(listOf("day:今天", "r1", "r2", "r3", "r4"), rows(run, unreadFromId = "gone"))
    }

    @Test fun aSenderRunNeverContinuesAcrossADatePill() {
        // Two minutes apart share a run by time, but midnight falls between them.
        val messages = listOf(
            message("a", "ann", at(2026, 9, 13, 23, 57)),
            message("b", "ann", at(2026, 9, 13, 23, 58)),
            message("c", "ann", at(2026, 9, 14, 0, 0)),
            message("d", "ann", at(2026, 9, 14, 0, 1)),
        )
        val built = messageTimelineRows(messages, "me", null, zone) { "day" }
        assertEquals(listOf("day:a", "a", "b", "day:c", "c", "d"), built.map { it.key })
        assertEquals(
            listOf(MessageGroupPosition.First, MessageGroupPosition.Last, MessageGroupPosition.First, MessageGroupPosition.Last),
            built.filterIsInstance<MessageTimelineRow.Message>().map { it.groupPosition },
        )
        // A lone message between two pills stands alone.
        val lone = listOf(
            message("x", "ann", at(2026, 9, 13, 23, 59)),
            message("y", "ann", at(2026, 9, 14, 0, 0)),
            message("z", "ann", at(2026, 9, 15, 0, 0)),
        )
        assertEquals(
            List(3) { MessageGroupPosition.Single },
            messageTimelineRows(lone, "me", null, zone) { "day" }.filterIsInstance<MessageTimelineRow.Message>().map { it.groupPosition },
        )
        // The pill and the unread divider at the same message break the run once.
        val both = messageTimelineRows(messages, "me", "c", zone) { "day" }
        assertEquals(listOf("day:a", "a", "b", "day:c", "unread:c", "c", "d"), both.map { it.key })
        assertEquals(
            listOf(MessageGroupPosition.First, MessageGroupPosition.Last, MessageGroupPosition.First, MessageGroupPosition.Last),
            both.filterIsInstance<MessageTimelineRow.Message>().map { it.groupPosition },
        )
    }

    @Test fun anUndatedMessageNeitherGetsNorResetsAPill() {
        val messages = listOf(message("a", "ann", at(2026, 9, 14, 8, 0)), message("pending", "me", 0), message("b", "ann", at(2026, 9, 14, 9, 0)))
        assertEquals(listOf("day:今天", "a", "pending", "b"), rows(messages))
    }

    @Test fun labelsNameTodayYesterdayTheDateAndTheYearWhenItDiffers() {
        val now = at(2026, 9, 14, 18, 30)
        fun label(ms: Long, locale: Locale) = FlareTimeFormat.timelineDateLabel(ms, "Today", "Yesterday", locale, now, zone)
        assertEquals("Today", label(at(2026, 9, 14, 0, 0), Locale.US))
        assertEquals("Yesterday", label(at(2026, 9, 13, 23, 59), Locale.US))
        assertEquals("9/1", label(at(2026, 9, 1, 8, 0), Locale.US))
        assertEquals("12/31/2025", label(at(2025, 12, 31, 8, 0), Locale.US))
        assertEquals("2025/12/31", FlareTimeFormat.timelineDateLabel(at(2025, 12, 31, 8, 0), "今天", "昨天", Locale.CHINA, now, zone))
        assertEquals("01.09", label(at(2026, 9, 1, 8, 0), Locale.GERMANY))
        // New Year's Eve seen on New Year's Day is yesterday, not last year's date.
        assertEquals("Yesterday", FlareTimeFormat.timelineDateLabel(at(2025, 12, 31, 23, 0), "Today", "Yesterday", Locale.US, at(2026, 1, 1, 8, 0), zone))
    }

    @Test fun theDayIsDecidedInTheLocalZone() {
        assertTrue(FlareTimeFormat.startsTimelineDay(0, at(2026, 9, 14, 8, 0), zone))
        assertFalse(FlareTimeFormat.startsTimelineDay(at(2026, 9, 14, 8, 0), 0, zone))
        assertFalse(FlareTimeFormat.startsTimelineDay(at(2026, 9, 14, 0, 1), at(2026, 9, 14, 23, 59), zone))
        assertTrue(FlareTimeFormat.startsTimelineDay(at(2026, 9, 13, 23, 59), at(2026, 9, 14, 0, 1), zone))
        // The same instants are one day in UTC (15:59 and 16:01 on the 13th).
        assertFalse(FlareTimeFormat.startsTimelineDay(at(2026, 9, 13, 23, 59), at(2026, 9, 14, 0, 1), ZoneId.of("UTC")))
        assertEquals(flareLocalEpochDay(at(2026, 9, 14, 12, 0), zone), java.time.LocalDate.of(2026, 9, 14).toEpochDay())
    }

    @Test fun todayIsAKitString() {
        assertEquals("今天" to "昨天", FlareStrings().today to FlareStrings().yesterday)
        assertEquals("Today", FlareStrings { today = "Today" }.today)
    }
}
