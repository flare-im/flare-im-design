package com.flare.im.ui

import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class SearchDateRangeFilterTest {
    private val cst = 480 // UTC+8, minutes east of UTC
    private val est = -300 // UTC-5

    private fun iso(ms: Long?): String? =
        ms?.let { Instant.ofEpochMilli(it).atZone(ZoneOffset.UTC).toString() }

    @Test fun dayBoundsAnchorToTheGivenZone() {
        assertEquals("2026-03-15T00:00Z", iso(dayStartMs("2026-03-15", 0)))
        assertEquals("2026-03-15T23:59:59.999Z", iso(dayEndMs("2026-03-15", 0)))
        assertEquals("2026-03-14T16:00Z", iso(dayStartMs("2026-03-15", cst)))
        assertEquals("2026-03-15T15:59:59.999Z", iso(dayEndMs("2026-03-15", cst)))
        assertEquals("2026-03-15T05:00Z", iso(dayStartMs("2026-03-15", est)))
        assertEquals("2026-03-16T04:59:59.999Z", iso(dayEndMs("2026-03-15", est)))
    }

    @Test fun oneInclusiveDayAndBoundaries() {
        for (tz in listOf(0, cst, est)) {
            assertEquals(86_399_999L, dayEndMs("2026-03-15", tz)!! - dayStartMs("2026-03-15", tz)!!, "tz $tz")
        }
        assertEquals("1970-01-01T00:00Z", iso(dayStartMs("1970-01-01", 0)))
        assertEquals("2026-02-28T23:59:59.999Z", iso(dayEndMs("2026-02-28", 0)))
        assertEquals("2024-02-29T00:00Z", iso(dayStartMs("2024-02-29", 0)))
        assertEquals("2026-12-31T23:59:59.999Z", iso(dayEndMs("2026-12-31", 0)))
    }

    @Test fun rejectsAnythingThatIsNotARealDate() {
        for (bad in listOf("", "   ", "2026-3-15", "15/03/2026", "2026-13-01", "2026-00-10",
                           "2026-02-30", "2026-04-31", "today")) {
            assertNull(dayStartMs(bad, 0), bad)
            assertNull(dayEndMs(bad, 0), bad)
        }
    }

    @Test fun deviceZoneIsUsedWithoutAnOffset() {
        val start = Instant.ofEpochMilli(dayStartMs("2026-03-15")!!).atZone(ZoneId.systemDefault())
        val end = Instant.ofEpochMilli(dayEndMs("2026-03-15")!!).atZone(ZoneId.systemDefault())
        assertEquals(listOf(2026, 3, 15, 0, 0, 0), listOf(start.year, start.monthValue, start.dayOfMonth,
            start.hour, start.minute, start.second))
        assertEquals(listOf(15, 23, 59, 59, 999_000_000), listOf(end.dayOfMonth, end.hour, end.minute,
            end.second, end.nano))
    }

    @Test fun rangeCoversTheWholeDayAndSpansMonths() {
        val sameDay = rangeFromDates("2026-03-15", "2026-03-15", cst)!!
        assertEquals("2026-03-14T16:00Z", iso(sameDay.fromTime))
        assertEquals("2026-03-15T15:59:59.999Z", iso(sameDay.toTime))
        val month = rangeFromDates("2026-01-28", "2026-02-03", 0)!!
        assertEquals("2026-01-28T00:00Z", iso(month.fromTime))
        assertEquals("2026-02-03T23:59:59.999Z", iso(month.toTime))
        val year = rangeFromDates("2025-12-30", "2026-01-02", cst)!!
        assertEquals("2025-12-29T16:00Z", iso(year.fromTime))
        assertEquals("2026-01-02T15:59:59.999Z", iso(year.toTime))
    }

    @Test fun openEndsAndUnrestricted() {
        val fromOnly = rangeFromDates("2026-03-15", "", cst)!!
        assertEquals(dayStartMs("2026-03-15", cst), fromOnly.fromTime)
        assertNull(fromOnly.toTime)
        val toOnly = rangeFromDates("", "2026-03-15", cst)!!
        assertNull(toOnly.fromTime)
        assertEquals(dayEndMs("2026-03-15", cst), toOnly.toTime)
        assertTrue(unrestrictedRange(rangeFromDates("", "", cst)!!))
    }

    @Test fun refusesIllegalRanges() {
        assertNull(rangeFromDates("2026-03-16", "2026-03-15", cst))
        assertNull(rangeFromDates("2027-01-01", "2026-12-31", 0))
        assertNotNull(rangeFromDates("2026-03-15", "2026-03-15", cst))
        assertNull(rangeFromDates("2026-02-30", "2026-03-15", 0))
        assertNull(rangeFromDates("2026-03-15", "tomorrow", 0))
        assertNull(rangeFromDates("1969-12-31", "", 0))
        assertNull(rangeFromDates("", "1969-12-31", 0))
    }

    @Test fun datesFromRangeRoundTrips() {
        for (tz in listOf(0, cst, est)) {
            val range = rangeFromDates("2026-03-15", "2026-04-02", tz)!!
            assertEquals(FlareSearchDateDraft("2026-03-15", "2026-04-02"), datesFromRange(range, tz), "tz $tz")
        }
        val local = rangeFromDates("2026-03-15", "2026-04-02")!!
        assertEquals(FlareSearchDateDraft("2026-03-15", "2026-04-02"), datesFromRange(local))
        assertEquals(FlareSearchDateDraft("", ""), datesFromRange(FlareSearchTimeRange(), cst))
        assertEquals(FlareSearchDateDraft("", ""), datesFromRange(FlareSearchTimeRange(fromTime = -1), cst))
        assertEquals(
            FlareSearchDateDraft("2026-03-14", "2026-03-15"),
            datesFromRange(rangeFromDates("2026-03-15", "2026-03-15", cst)!!, est),
        )
    }

    @Test fun matchedOptionIdMatchesByValue() {
        val options = listOf(
            FlareSearchRangeOption("today", "今天", 1000, 2000),
            FlareSearchRangeOption("week", "近 7 天", 500),
            FlareSearchRangeOption("all", "不限时间"),
        )
        assertEquals("today", matchedOptionId(FlareSearchTimeRange(1000, 2000), options))
        assertEquals("week", matchedOptionId(FlareSearchTimeRange(500), options))
        assertEquals("all", matchedOptionId(FlareSearchTimeRange(), options))
        assertNull(matchedOptionId(FlareSearchTimeRange(1000, 2001), options))
        assertNull(matchedOptionId(FlareSearchTimeRange(toTime = 500), options))
        assertNull(matchedOptionId(FlareSearchTimeRange(1000, 2000), emptyList()))
    }

    @Test fun customAreaOpensOnlyForAnUncoveredValueOrAForcedHost() {
        val options = listOf(FlareSearchRangeOption("today", "今天", 1000, 2000))
        assertFalse(shouldOpenCustomRange(FlareSearchTimeRange(7), options, allowCustom = false, customActive = true))
        assertTrue(shouldOpenCustomRange(FlareSearchTimeRange(), options, allowCustom = true, customActive = true))
        assertTrue(shouldOpenCustomRange(FlareSearchTimeRange(7, 9), options, allowCustom = true))
        assertFalse(shouldOpenCustomRange(FlareSearchTimeRange(1000, 2000), options, allowCustom = true))
        assertFalse(shouldOpenCustomRange(FlareSearchTimeRange(), options, allowCustom = true))
    }
}
