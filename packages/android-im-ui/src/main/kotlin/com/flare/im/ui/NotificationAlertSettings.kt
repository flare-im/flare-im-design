package com.flare.im.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier

/** What a notification shows: the sender and the message, the sender only, or neither. */
enum class FlareNotificationPreview { Full, SenderOnly, Hidden }

/** How the phone alerts while the person is using another device. */
enum class FlareMultiDeviceAlert { Delay, Immediate, BadgeOnly }

/**
 * When new messages arrive silently, in device local time. The protocol's shape: minutes after midnight, [weekdays]
 * as bits (bit 0 Monday … bit 6 Sunday, 0 every day); an [endMinute] not after [startMinute] is on the next day.
 */
data class FlareQuietHours(
    val enabled: Boolean = false,
    val startMinute: Int = 22 * 60,
    val endMinute: Int = 8 * 60,
    val weekdays: Int = 0,
    val allowMentions: Boolean = true,
)

/**
 * A person's notification preferences as [NotificationAlertSettings] edits them. The default is what a person who
 * never chose has: quiet hours off (22:00 to 08:00 every day, mentions allowed), full preview, delay.
 */
data class FlareNotificationAlertPreferences(
    val quietHours: FlareQuietHours = FlareQuietHours(),
    val preview: FlareNotificationPreview = FlareNotificationPreview.Full,
    val multiDevice: FlareMultiDeviceAlert = FlareMultiDeviceAlert.Delay,
)

/** Every day, as bits. 0 means the same. */
const val ALL_WEEKDAYS: Int = 0x7f

/** The minute step of the start and end pickers. */
const val QUIET_HOURS_MINUTE_STEP: Int = 5

private const val MINUTES_PER_DAY = 24 * 60

/** A minute of the day as HH:mm, 24-hour; minutes are taken modulo a day. */
fun formatMinuteOfDay(minute: Int): String {
    val m = ((minute % MINUTES_PER_DAY) + MINUTES_PER_DAY) % MINUTES_PER_DAY
    return "${(m / 60).toString().padStart(2, '0')}:${(m % 60).toString().padStart(2, '0')}"
}

/** HH:mm as a minute of the day; anything else reads as midnight. */
fun parseMinuteOfDay(text: String): Int {
    val parts = text.split(":")
    val h = parts.getOrNull(0)?.toIntOrNull() ?: return 0
    val m = parts.getOrNull(1)?.toIntOrNull() ?: return 0
    return h.coerceIn(0, 23) * 60 + m.coerceIn(0, 59)
}

/** Whether the end is on the next day: it is not after the start. */
fun quietHoursEndsNextDay(quietHours: FlareQuietHours): Boolean = quietHours.endMinute <= quietHours.startMinute

/** Whether [day] (0 Monday … 6 Sunday) is in [mask]; 0 is every day. */
fun weekdayIsOn(mask: Int, day: Int): Boolean {
    val days = mask and ALL_WEEKDAYS
    return days == 0 || days and (1 shl day) != 0
}

/** [mask] with [day] turned on or off. 0 starts from all seven; all seven is written 0; no day left changes nothing. */
fun weekdayToggle(mask: Int, day: Int, on: Boolean): Int {
    val days = if (mask and ALL_WEEKDAYS == 0) ALL_WEEKDAYS else mask and ALL_WEEKDAYS
    val next = if (on) days or (1 shl day) else days and (1 shl day).inv()
    if (next == 0) return mask
    return if (next == ALL_WEEKDAYS) 0 else next
}

/** How a weekday mask reads: every day, Monday to Friday, the weekend, or the [days] in week order. */
sealed interface FlareWeekdaySummary {
    data object EveryDay : FlareWeekdaySummary
    data object Weekdays : FlareWeekdaySummary
    data object Weekends : FlareWeekdaySummary
    data class Days(val days: List<Int>) : FlareWeekdaySummary
}

fun weekdaySummary(mask: Int): FlareWeekdaySummary {
    val days = mask and ALL_WEEKDAYS
    return when (days) {
        0, ALL_WEEKDAYS -> FlareWeekdaySummary.EveryDay
        0x1f -> FlareWeekdaySummary.Weekdays
        0x60 -> FlareWeekdaySummary.Weekends
        else -> FlareWeekdaySummary.Days((0..6).filter { days and (1 shl it) != 0 })
    }
}

/** The name of [day] (0 Monday … 6 Sunday) in [strings]. */
fun weekdayName(day: Int, strings: FlareStrings = FlareStrings()): String = when (day) {
    0 -> strings.weekdayMonday
    1 -> strings.weekdayTuesday
    2 -> strings.weekdayWednesday
    3 -> strings.weekdayThursday
    4 -> strings.weekdayFriday
    5 -> strings.weekdaySaturday
    else -> strings.weekdaySunday
}

/** The words of the Repeat row for [mask]. */
fun weekdaySummaryText(mask: Int, strings: FlareStrings = FlareStrings()): String = when (val summary = weekdaySummary(mask)) {
    FlareWeekdaySummary.EveryDay -> strings.weekdayEveryDay
    FlareWeekdaySummary.Weekdays -> strings.weekdayWeekdays
    FlareWeekdaySummary.Weekends -> strings.weekdayWeekends
    is FlareWeekdaySummary.Days -> summary.days.joinToString(strings.displayNameSeparator) { weekdayName(it, strings) }
}

/** The words of the Ends row: the time, on the next day when it is not after the start. */
fun quietHoursEndText(quietHours: FlareQuietHours, strings: FlareStrings = FlareStrings()): String {
    val time = formatMinuteOfDay(quietHours.endMinute)
    return if (quietHoursEndsNextDay(quietHours)) strings.quietHoursNextDay(time) else time
}

/** The words of [preview] in a settings row. */
fun notificationPreviewText(preview: FlareNotificationPreview, strings: FlareStrings = FlareStrings()): String = when (preview) {
    FlareNotificationPreview.Full -> strings.notificationPreviewFull
    FlareNotificationPreview.SenderOnly -> strings.notificationPreviewSenderOnly
    FlareNotificationPreview.Hidden -> strings.notificationPreviewHidden
}

/** The words of [policy] in a settings row. */
fun multiDeviceAlertText(policy: FlareMultiDeviceAlert, strings: FlareStrings = FlareStrings()): String = when (policy) {
    FlareMultiDeviceAlert.Delay -> strings.multiDeviceDelay
    FlareMultiDeviceAlert.Immediate -> strings.multiDeviceImmediate
    FlareMultiDeviceAlert.BadgeOnly -> strings.multiDeviceBadgeOnly
}

/** Row keys of the sections. */
internal const val QUIET_HOURS_ROW = "quietHours"
internal const val QUIET_HOURS_START_ROW = "quietHoursStart"
internal const val QUIET_HOURS_END_ROW = "quietHoursEnd"
internal const val QUIET_HOURS_REPEAT_ROW = "quietHoursRepeat"
internal const val QUIET_HOURS_ALLOW_MENTIONS_ROW = "quietHoursAllowMentions"
internal const val NOTIFICATION_PREVIEW_ROW = "notificationPreview"
internal const val MULTI_DEVICE_ROW = "multiDevice"
private const val WEEKDAY_ROW_PREFIX = "weekday:"

/** The three sections for [value]: quiet hours, preview, and the other-device behaviour, each with its footer. */
internal fun notificationAlertSections(
    value: FlareNotificationAlertPreferences,
    disabled: Boolean,
    strings: FlareStrings,
): List<SettingsSection> {
    val quiet = value.quietHours
    val quietRows = buildList {
        add(SettingsItem(key = QUIET_HOURS_ROW, label = strings.quietHoursLabel, kind = FlareSettingKind.Toggle, value = quiet.enabled, disabled = disabled))
        if (quiet.enabled) {
            add(SettingsItem(key = QUIET_HOURS_START_ROW, label = strings.quietHoursStart, detail = formatMinuteOfDay(quiet.startMinute), disabled = disabled))
            add(SettingsItem(key = QUIET_HOURS_END_ROW, label = strings.quietHoursEnd, detail = quietHoursEndText(quiet, strings), disabled = disabled))
            add(SettingsItem(key = QUIET_HOURS_REPEAT_ROW, label = strings.quietHoursRepeat, detail = weekdaySummaryText(quiet.weekdays, strings), disabled = disabled))
            add(SettingsItem(key = QUIET_HOURS_ALLOW_MENTIONS_ROW, label = strings.quietHoursAllowMentions, kind = FlareSettingKind.Toggle, value = quiet.allowMentions, disabled = disabled))
        }
    }
    return listOf(
        SettingsSection(title = strings.quietHoursTitle, items = quietRows, footer = strings.quietHoursFooter),
        SettingsSection(
            title = strings.notificationPreviewTitle,
            items = listOf(SettingsItem(key = NOTIFICATION_PREVIEW_ROW, label = strings.notificationPreviewLabel, detail = notificationPreviewText(value.preview, strings), disabled = disabled)),
            footer = strings.notificationPreviewFooter,
        ),
        SettingsSection(
            title = strings.multiDeviceTitle,
            items = listOf(SettingsItem(key = MULTI_DEVICE_ROW, label = strings.multiDeviceLabel, detail = multiDeviceAlertText(value.multiDevice, strings), disabled = disabled)),
            footer = strings.multiDeviceFooter,
        ),
    )
}

/** The picker a row opens. */
private enum class AlertPicker { Start, End, Repeat, Preview, MultiDevice }

/**
 * A person's notification preferences as settings sections. Spec: Profile/NotificationAlertSettings
 * (`NotificationAlertSettings`).
 *
 * Do not disturb: the Quiet hours switch and, while it is on, Starts, Ends (read as the next day when it is not after
 * the start), Repeat and Alert me when mentioned. Notification content: Preview. Multiple devices: While active
 * elsewhere. Each section has its footer. Starts and Ends open the [TimePicker] sheet, Repeat a kit [BottomSheet] of
 * seven day switches that never empties, Preview and While active elsewhere a kit sheet with a vertical [RadioGroup]
 * that applies the pick and closes. Every row reports the whole next value through [onChange]; the host saves it.
 * The value is the protocol's shape (spec/notification-alert-vectors.json). [disabled] stops the rows (while the host
 * saves or cannot write); a picker already open stays open and its pick still goes through [onChange].
 *
 * This form draws a list of its own; a settings page that is already one [SettingsList] places the sections among
 * its own with the `sectionContent` form.
 */
@Composable
fun NotificationAlertSettings(
    value: FlareNotificationAlertPreferences,
    disabled: Boolean = false,
    onChange: ((FlareNotificationAlertPreferences) -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    NotificationAlertSettings(value, disabled, onChange) { sections, select, toggle ->
        Column(modifier.fillMaxWidth()) {
            SettingsList(sections = sections, onSelect = { select(it) }, onToggle = { item, on -> toggle(item, on) }, scrollable = false)
        }
    }
}

/**
 * The section form of [NotificationAlertSettings], for a settings page that is already one [SettingsList]: the host
 * draws the list in [sectionContent] and gets the three sections with `select` and `toggle`, which run a row of the
 * group (a picker, a switch) and return whether the row was one; the host handles the rows they return false for. Rows
 * are keyed quietHours, quietHoursStart, quietHoursEnd, quietHoursRepeat, quietHoursAllowMentions,
 * notificationPreview and multiDevice.
 *
 * ```kotlin
 * NotificationAlertSettings(value = prefs, onChange = { notifications.updateSettings(it) }) { alerts, select, toggle ->
 *     SettingsList(
 *         sections = listOf(general) + alerts + listOf(about),
 *         onSelect = { if (!select(it)) openPage(it) },
 *         onToggle = { item, on -> if (!toggle(item, on)) setOwn(item, on) },
 *     )
 * }
 * ```
 */
@Composable
fun NotificationAlertSettings(
    value: FlareNotificationAlertPreferences,
    disabled: Boolean = false,
    onChange: ((FlareNotificationAlertPreferences) -> Unit)? = null,
    sectionContent: @Composable (
        sections: List<SettingsSection>,
        select: (SettingsItem) -> Boolean,
        toggle: (SettingsItem, Boolean) -> Boolean,
    ) -> Unit,
) {
    val strings = flareStrings()
    val current by rememberUpdatedState(value)
    val enabled by rememberUpdatedState(!disabled)
    val report by rememberUpdatedState(onChange)
    var picker by rememberSaveable { mutableStateOf<AlertPicker?>(null) }
    // The time and day rows belong to quiet hours: when they go, so do their pickers. Disabling only stops the rows;
    // a picker already open keeps working.
    LaunchedEffect(value.quietHours.enabled) {
        if (!value.quietHours.enabled && (picker == AlertPicker.Start || picker == AlertPicker.End || picker == AlertPicker.Repeat)) picker = null
    }
    fun change(next: FlareNotificationAlertPreferences) {
        report?.invoke(next)
    }
    fun changeQuietHours(next: FlareQuietHours) = change(current.copy(quietHours = next))
    fun open(next: AlertPicker) {
        if (enabled) picker = next
    }
    fun switchQuietHours(next: FlareQuietHours) {
        if (enabled) changeQuietHours(next)
    }

    sectionContent(
        notificationAlertSections(value, disabled, strings),
        { item ->
            when (item.key) {
                QUIET_HOURS_START_ROW -> { open(AlertPicker.Start); true }
                QUIET_HOURS_END_ROW -> { open(AlertPicker.End); true }
                QUIET_HOURS_REPEAT_ROW -> { open(AlertPicker.Repeat); true }
                NOTIFICATION_PREVIEW_ROW -> { open(AlertPicker.Preview); true }
                MULTI_DEVICE_ROW -> { open(AlertPicker.MultiDevice); true }
                else -> false
            }
        },
        { item, on ->
            when (item.key) {
                QUIET_HOURS_ROW -> { switchQuietHours(current.quietHours.copy(enabled = on)); true }
                QUIET_HOURS_ALLOW_MENTIONS_ROW -> { switchQuietHours(current.quietHours.copy(allowMentions = on)); true }
                else -> false
            }
        },
    )

    when (picker) {
        AlertPicker.Start, AlertPicker.End -> {
            val end = picker == AlertPicker.End
            TimePickerSheet(
                value = formatMinuteOfDay(if (end) value.quietHours.endMinute else value.quietHours.startMinute),
                title = if (end) strings.quietHoursEnd else strings.quietHoursStart,
                minuteStep = QUIET_HOURS_MINUTE_STEP,
                cancelLabel = strings.cancel,
                confirmLabel = strings.confirm,
                onDismiss = { picker = null },
                onConfirm = { picked ->
                    val minute = parseMinuteOfDay(picked)
                    changeQuietHours(if (end) current.quietHours.copy(endMinute = minute) else current.quietHours.copy(startMinute = minute))
                    picker = null
                },
            )
        }
        AlertPicker.Repeat -> BottomSheet(onClose = { picker = null }, title = strings.quietHoursRepeat) {
            val mask = value.quietHours.weekdays
            val onCount = (0..6).count { weekdayIsOn(mask, it) }
            Column(Modifier.fillMaxWidth().weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(bottom = FlareSizes.spacingLg)) {
                SettingsList(
                    sections = listOf(
                        SettingsSection(
                            items = (0..6).map { day ->
                                val on = weekdayIsOn(mask, day)
                                // The last day left cannot be turned off.
                                SettingsItem(key = "$WEEKDAY_ROW_PREFIX$day", label = weekdayName(day, strings), kind = FlareSettingKind.Toggle, value = on, disabled = on && onCount == 1)
                            },
                        ),
                    ),
                    onToggle = { item, on ->
                        val day = item.key.removePrefix(WEEKDAY_ROW_PREFIX).toIntOrNull()
                        if (day != null) {
                            val latest = current.quietHours.weekdays
                            val next = weekdayToggle(latest, day, on)
                            if (next != latest) changeQuietHours(current.quietHours.copy(weekdays = next))
                        }
                    },
                    scrollable = false,
                )
            }
        }
        AlertPicker.Preview -> ChoiceSheet(
            title = strings.notificationPreviewLabel,
            options = FlareNotificationPreview.entries.map { FlareSelectOption(it.name, notificationPreviewText(it, strings)) },
            value = value.preview.name,
            onPick = { name ->
                picker = null
                FlareNotificationPreview.entries.firstOrNull { it.name == name }?.let { change(current.copy(preview = it)) }
            },
            onClose = { picker = null },
        )
        AlertPicker.MultiDevice -> ChoiceSheet(
            title = strings.multiDeviceLabel,
            options = FlareMultiDeviceAlert.entries.map { FlareSelectOption(it.name, multiDeviceAlertText(it, strings)) },
            value = value.multiDevice.name,
            onPick = { name ->
                picker = null
                FlareMultiDeviceAlert.entries.firstOrNull { it.name == name }?.let { change(current.copy(multiDevice = it)) }
            },
            onClose = { picker = null },
        )
        null -> Unit
    }
}

/** A kit sheet with a vertical radio group; a pick applies and closes it. */
@Composable
private fun ChoiceSheet(
    title: String,
    options: List<FlareSelectOption>,
    value: String,
    onPick: (String) -> Unit,
    onClose: () -> Unit,
) {
    BottomSheet(onClose = onClose, title = title) {
        Column(
            Modifier.fillMaxWidth().padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingSm, bottom = FlareSizes.spacingLg),
        ) {
            RadioGroup(options = options, value = value, vertical = true, onSelect = onPick)
        }
    }
}
