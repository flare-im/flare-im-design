package com.flare.im.ui

import java.time.LocalDateTime
import java.time.ZoneId
import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** Shared time-label rules: locale clock, calendar-day buckets, local time zone. */
class FlareTimeFormatTest {
    /** A local wall-clock time, so the rules read the same in every time zone. */
    private fun at(year: Int, month: Int, day: Int, hour: Int, minute: Int): Long =
        LocalDateTime.of(year, month, day, hour, minute).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()

    /** Newer locale data separates "AM" with a narrow no-break space; the rules do not depend on which space. */
    private fun spaced(label: String) = label.replace('\u202F', ' ').replace('\u00A0', ' ')

    private val now = at(2026, 9, 14, 18, 30)

    @Test fun messageTimeFollowsTheLocaleClock() {
        assertEquals("9:05 AM", spaced(FlareTimeFormat.messageTime(at(2026, 9, 14, 9, 5), Locale.US)))
        assertEquals("9:30 PM", spaced(FlareTimeFormat.messageTime(at(2026, 9, 14, 21, 30), Locale.US)))
        assertEquals("09:05", FlareTimeFormat.messageTime(at(2026, 9, 14, 9, 5), Locale.CHINA))
        assertEquals("21:30", FlareTimeFormat.messageTime(at(2026, 9, 14, 21, 30), Locale.CHINA))
        // A 24-hour clock always shows two hour digits, even where the short pattern has one (ja "H:mm").
        assertEquals("09:05", FlareTimeFormat.messageTime(at(2026, 9, 14, 9, 5), Locale.JAPAN))
        // A 12-hour locale keeps its own day-period placement.
        assertEquals("上午9:05", FlareTimeFormat.messageTime(at(2026, 9, 14, 9, 5), Locale.TAIWAN))
    }

    @Test fun conversationTimeBucketsByCalendarDay() {
        // Same day: the message time.
        assertEquals("9:05 AM", spaced(FlareTimeFormat.conversationTime(at(2026, 9, 14, 9, 5), "Yesterday", Locale.US, now)))
        assertEquals("09:05", FlareTimeFormat.conversationTime(at(2026, 9, 14, 9, 5), "昨天", Locale.CHINA, now))
        // Any time on the previous calendar day, however close to now.
        assertEquals("Yesterday", FlareTimeFormat.conversationTime(at(2026, 9, 13, 23, 59), "Yesterday", Locale.US, now))
        assertEquals("昨天", FlareTimeFormat.conversationTime(at(2026, 9, 13, 0, 1), "昨天", Locale.CHINA, now))
        // Earlier this year: numeric month/day in the locale's order.
        assertEquals("9/1", FlareTimeFormat.conversationTime(at(2026, 9, 1, 8, 0), "Yesterday", Locale.US, now))
        assertEquals("9/1", FlareTimeFormat.conversationTime(at(2026, 9, 1, 8, 0), "昨天", Locale.CHINA, now))
        assertEquals("01.09", FlareTimeFormat.conversationTime(at(2026, 9, 1, 8, 0), "Gestern", Locale.GERMANY, now))
        // Another year: numeric year/month/day.
        assertEquals("12/31/2025", FlareTimeFormat.conversationTime(at(2025, 12, 31, 8, 0), "Yesterday", Locale.US, now))
        assertEquals("2025/12/31", FlareTimeFormat.conversationTime(at(2025, 12, 31, 8, 0), "昨天", Locale.CHINA, now))
        // New Year's Eve seen on New Year's Day is still yesterday.
        assertEquals("Yesterday", FlareTimeFormat.conversationTime(at(2025, 12, 31, 23, 0), "Yesterday", Locale.US, at(2026, 1, 1, 8, 0)))
    }

    @Test fun yesterdayLabelIsAKitString() {
        assertEquals("昨天", FlareStrings().yesterday)
        assertEquals("Yesterday", FlareStrings { yesterday = "Yesterday" }.yesterday)
    }

    @Test fun shortDatePatternsDropOrWidenTheirYear() {
        assertEquals("M/d", flareMonthDayPattern("M/d/yy"))
        assertEquals("M/d", flareMonthDayPattern("y/M/d"))
        assertEquals("dd.MM", flareMonthDayPattern("dd.MM.yy"))
        assertEquals("M. d.", flareMonthDayPattern("yy. M. d."))
        assertEquals("M月d日", flareMonthDayPattern("y年M月d日"))
        assertEquals("'Day' d/M", flareMonthDayPattern("'Day' d/M/y"))
        assertEquals("M/d/y", flareFullYearPattern("M/d/yy"))
        assertEquals("dd.MM.y", flareFullYearPattern("dd.MM.yy"))
    }

    @Test fun hourCycleComesFromTheRegion() {
        // The region decides, whatever the platform's short pattern says.
        assertTrue(flareUsesTwelveHourClock(Locale.US, "HH:mm"))
        assertFalse(flareUsesTwelveHourClock(Locale.CHINA, "ah:mm"))
        assertTrue(flareUsesTwelveHourClock(Locale.KOREA, "HH:mm"))
        assertFalse(flareUsesTwelveHourClock(Locale.UK, "h:mm a"))
        // Language-specific entries: French in Canada keeps 24 hours.
        assertTrue(flareUsesTwelveHourClock(Locale.CANADA, "HH:mm"))
        assertFalse(flareUsesTwelveHourClock(Locale.CANADA_FRENCH, "h:mm a"))
        // No region: the locale's own short pattern decides.
        assertTrue(flareUsesTwelveHourClock(Locale.ENGLISH, "h:mm a"))
        assertFalse(flareUsesTwelveHourClock(Locale.GERMAN, "HH:mm"))
    }
}
