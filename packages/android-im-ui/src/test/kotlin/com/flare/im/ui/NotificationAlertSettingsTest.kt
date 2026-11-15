package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * `spec/notification-alert-vectors.json`, the table the four kits run: the rows of [NotificationAlertSettings], times,
 * the next-day end, the weekday picks and their words in both languages.
 */
class NotificationAlertSettingsTest {
    private val table = SpecTables.table("notification-alert-vectors.json")

    @Test fun theSectionsListTheRowsOfTheTable() {
        for (row in table.items("rows")) {
            val value = FlareNotificationAlertPreferences(quietHours = FlareQuietHours(enabled = row.bool("quietHoursEnabled")!!))
            val sections = notificationAlertSections(value, disabled = false, strings = FlareStrings())
            val expected = (row["sections"] as List<*>).map { keys -> (keys as List<*>).map { it as String } }
            assertEquals(expected, sections.map { section -> section.items.map { it.key } })
            assertEquals(3, sections.count { !it.footer.isNullOrEmpty() })
        }
    }

    @Test fun aMinuteReadsAsHoursAndMinutes() {
        for (case in table.items("time")) {
            val minute = case.int("minute")!!
            assertEquals(case.str("text"), formatMinuteOfDay(minute))
            if (minute < 1440) assertEquals(minute, parseMinuteOfDay(case.str("text")!!))
        }
    }

    @Test fun theEndReadsAsTheNextDayWhenItIsNotAfterTheStart() {
        for (case in table.items("end")) {
            val quiet = FlareQuietHours(startMinute = case.int("start")!!, endMinute = case.int("end")!!)
            assertEquals(case.bool("nextDay"), quietHoursEndsNextDay(quiet))
            assertEquals(case.str("zh"), quietHoursEndText(quiet))
            assertEquals(case.str("en"), quietHoursEndText(quiet, flareStringsEnglish()))
        }
    }

    @Test fun aWeekdayPickNeverEmptiesTheWeek() {
        for (case in table.items("weekdayToggle")) {
            assertEquals(case.int("result"), weekdayToggle(case.int("mask")!!, case.int("day")!!, case.bool("on")!!), "$case")
        }
        for (case in table.items("weekdayOn")) {
            assertEquals(case.bool("on"), weekdayIsOn(case.int("mask")!!, case.int("day")!!), "$case")
        }
    }

    @Test fun theDaysReadInBothLanguages() {
        for (case in table.items("summary")) {
            val mask = case.int("mask")!!
            val kind = when (weekdaySummary(mask)) {
                FlareWeekdaySummary.EveryDay -> "everyDay"
                FlareWeekdaySummary.Weekdays -> "weekdays"
                FlareWeekdaySummary.Weekends -> "weekends"
                is FlareWeekdaySummary.Days -> "days"
            }
            assertEquals(case.str("kind"), kind)
            assertEquals(case.str("zh"), weekdaySummaryText(mask))
            assertEquals(case.str("en"), weekdaySummaryText(mask, flareStringsEnglish()))
        }
    }

    @Test fun rowsReadTheValueAndTakeNoInputWhileDisabled() {
        val value = FlareNotificationAlertPreferences(
            quietHours = FlareQuietHours(enabled = true, weekdays = 0x1f),
            preview = FlareNotificationPreview.SenderOnly,
            multiDevice = FlareMultiDeviceAlert.BadgeOnly,
        )
        val rows = notificationAlertSections(value, disabled = true, strings = flareStringsEnglish()).flatMap { it.items }
        assertEquals(listOf(null, "22:00", "08:00 next day", "Weekdays", null, "Name only", "Badge only"), rows.map { it.detail })
        assertEquals(true, rows.all { it.disabled })
        assertEquals(FlareNotificationAlertPreferences(), FlareNotificationAlertPreferences(quietHours = FlareQuietHours(startMinute = 1320, endMinute = 480)))
    }
}
