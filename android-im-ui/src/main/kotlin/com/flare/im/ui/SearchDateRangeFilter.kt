package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZoneOffset

/** Inclusive UTC epoch milliseconds; absent bounds mean unrestricted. */
data class FlareSearchTimeRange(val fromTime: Long? = null, val toTime: Long? = null)

/** The two local date strings a pair of DatePickers is bound to; "" means unset. */
data class FlareSearchDateDraft(val from: String, val to: String)

fun sameSearchTimeRange(a: FlareSearchTimeRange, b: FlareSearchTimeRange): Boolean =
    a.fromTime == b.fromTime && a.toTime == b.toTime

private const val MAX_SAFE_INTEGER = 9007199254740991L
private val DATE_PATTERN = Regex("""^\d{4}-\d{2}-\d{2}$""")

private fun searchDate(date: String): LocalDate? {
    val trimmed = date.trim()
    if (!DATE_PATTERN.matches(trimmed)) return null
    // ISO_LOCAL_DATE resolves strictly, so 2026-02-30 and 2026-13-01 both fail here.
    return runCatching { LocalDate.parse(trimmed) }.getOrNull()
}

private fun searchZone(tzOffsetMinutes: Int?): ZoneId? =
    if (tzOffsetMinutes == null) ZoneId.systemDefault()
    else runCatching { ZoneOffset.ofTotalSeconds(tzOffsetMinutes * 60) }.getOrNull()

private fun atLocalTime(date: String, time: LocalTime, tzOffsetMinutes: Int?): Long? {
    val day = searchDate(date) ?: return null
    val zone = searchZone(tzOffsetMinutes) ?: return null
    return day.atTime(time).atZone(zone).toInstant().toEpochMilli()
}

/**
 * Inclusive lower bound: 00:00:00.000 of [date]; null when the string is not a real date.
 * [tzOffsetMinutes] is minutes **east of UTC** (UTC+8 → 480); null uses the device zone
 * for that calendar date.
 */
fun dayStartMs(date: String, tzOffsetMinutes: Int? = null): Long? =
    atLocalTime(date, LocalTime.of(0, 0, 0, 0), tzOffsetMinutes)

/** Inclusive upper bound: 23:59:59.999 of [date]; null for a non-date. */
fun dayEndMs(date: String, tzOffsetMinutes: Int? = null): Long? =
    atLocalTime(date, LocalTime.of(23, 59, 59, 999_000_000), tzOffsetMinutes)

private fun usableTime(time: Long?): Boolean = time != null && time >= 0 && time <= MAX_SAFE_INTEGER

/**
 * Build the range two DatePickers describe. Both blank is *unrestricted* (an empty range),
 * not an error. Null means the host must not submit: an unparsable date, an instant before
 * the epoch, or `from` after `to`.
 */
fun rangeFromDates(from: String, to: String, tzOffsetMinutes: Int? = null): FlareSearchTimeRange? {
    var fromTime: Long? = null
    var toTime: Long? = null
    if (from.trim().isNotEmpty()) {
        val parsed = dayStartMs(from, tzOffsetMinutes)
        if (!usableTime(parsed)) return null
        fromTime = parsed
    }
    if (to.trim().isNotEmpty()) {
        val parsed = dayEndMs(to, tzOffsetMinutes)
        if (!usableTime(parsed)) return null
        toTime = parsed
    }
    if (fromTime != null && toTime != null && fromTime > toTime) return null
    return FlareSearchTimeRange(fromTime, toTime)
}

private fun dateString(time: Long?, tzOffsetMinutes: Int?): String {
    if (time == null || time < 0) return ""
    val zone = searchZone(tzOffsetMinutes) ?: return ""
    val day = Instant.ofEpochMilli(time).atZone(zone).toLocalDate()
    return "%04d-%02d-%02d".format(day.year, day.monthValue, day.dayOfMonth)
}

/** Fill the DatePickers back from a range; an absent bound stays "". */
fun datesFromRange(range: FlareSearchTimeRange, tzOffsetMinutes: Int? = null): FlareSearchDateDraft =
    FlareSearchDateDraft(
        from = dateString(range.fromTime, tzOffsetMinutes),
        to = dateString(range.toTime, tzOffsetMinutes),
    )

/** Neither bound set — the "no time limit" state. */
fun unrestrictedRange(range: FlareSearchTimeRange): Boolean =
    range.fromTime == null && range.toTime == null

/**
 * Which preset chip is selected. Matching is by value, not by id, because a host may rebuild
 * its option objects on every recomposition.
 */
fun matchedOptionId(value: FlareSearchTimeRange, options: List<FlareSearchRangeOption>): String? =
    options.firstOrNull { it.fromTime == value.fromTime && it.toTime == value.toTime }?.id

/**
 * Whether the custom start/end area is expanded: never without [allowCustom], always when the
 * host forces it, otherwise whenever the current value is a real range no preset covers.
 */
fun shouldOpenCustomRange(
    value: FlareSearchTimeRange,
    options: List<FlareSearchRangeOption>,
    allowCustom: Boolean,
    customActive: Boolean = false,
): Boolean {
    if (!allowCustom) return false
    if (customActive) return true
    return !unrestrictedRange(value) && matchedOptionId(value, options) == null
}

/**
 * Time-range filter for search. Host-supplied presets are chips; "custom" expands a start/end
 * pair built from the shared [DatePicker]. The component owns no clock — it never computes
 * "today" itself — and emits one [FlareSearchTimeRange] in inclusive UTC epoch milliseconds
 * that the host folds into its search criteria.
 * Spec: General/SearchDateRangeFilter (`SearchDateRangeFilter`).
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun SearchDateRangeFilter(
    value: FlareSearchTimeRange,
    onChange: (FlareSearchTimeRange) -> Unit,
    options: List<FlareSearchRangeOption> = emptyList(),
    allowCustom: Boolean = true,
    customActive: Boolean = false,
    minDate: String? = null,
    maxDate: String? = null,
    tzOffsetMinutes: Int? = null,
    disabled: Boolean = false,
    onClear: (() -> Unit)? = null,
    title: String = "时间范围",
    customText: String = "自定义",
    fromLabel: String = "起始日期",
    toLabel: String = "结束日期",
    clearText: String = "清除",
    unlimitedText: String = "不限时间",
    invalidText: String = "起始日期不能晚于结束日期",
) {
    val colors = flareColors()
    // Keyed on `value`: an illegal draft (which emits nothing) survives until it is fixed,
    // and a range the host actually accepted re-seeds the pickers.
    var draft by remember(value, tzOffsetMinutes) { mutableStateOf(datesFromRange(value, tzOffsetMinutes)) }
    val forcedOpen = shouldOpenCustomRange(value, options, allowCustom, customActive)
    var customOpen by rememberSaveable { mutableStateOf(forcedOpen) }
    LaunchedEffect(forcedOpen) { if (forcedOpen) customOpen = true }

    val selectedId = matchedOptionId(value, options)
    val showCustom = allowCustom && customOpen
    val invalid = allowCustom && rangeFromDates(draft.from, draft.to, tzOffsetMinutes) == null
    val unrestricted = unrestrictedRange(value)

    fun commit(next: FlareSearchDateDraft) {
        draft = next
        val range = rangeFromDates(next.from, next.to, tzOffsetMinutes) ?: return
        if (!sameSearchTimeRange(range, value)) onChange(range)
    }

    val summary = when {
        unrestricted -> unlimitedText
        selectedId != null -> options.first { it.id == selectedId }.label
        else -> {
            val dates = datesFromRange(value, tzOffsetMinutes)
            listOfNotNull(
                if (dates.from.isNotEmpty()) "$fromLabel ${dates.from}" else null,
                if (dates.to.isNotEmpty()) "$toLabel ${dates.to}" else null,
            ).joinToString(" · ").ifEmpty { unlimitedText }
        }
    }

    Column(
        modifier = Modifier.fillMaxWidth().semantics { contentDescription = title },
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl.value.sp, fontWeight = FontWeight.SemiBold)

        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            options.forEach { option ->
                Chip(
                    label = option.label,
                    selected = selectedId == option.id,
                    disabled = disabled || !option.isValid,
                    colors = colors,
                ) {
                    val next = FlareSearchTimeRange(option.fromTime, option.toTime)
                    if (!sameSearchTimeRange(next, value)) onChange(next)
                }
            }
            if (allowCustom) {
                Chip(
                    label = customText,
                    icon = "calendar",
                    selected = showCustom,
                    disabled = disabled,
                    colors = colors,
                ) { customOpen = !customOpen }
            }
        }

        if (showCustom) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(FlareSizes.radiusLg))
                    .background(colors.bgSecondary)
                    .padding(FlareSizes.spacingMd),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
            ) {
                DateField(fromLabel, draft.from, minDate, maxDate, disabled, clearText, colors) {
                    commit(draft.copy(from = it))
                }
                DateField(toLabel, draft.to, minDate, maxDate, disabled, clearText, colors) {
                    commit(draft.copy(to = it))
                }
            }
        }

        if (invalid) {
            Row(verticalAlignment = Alignment.Top) {
                FlareIcon("warning", size = 16.dp, tint = colors.warning)
                Spacer(Modifier.width(FlareSizes.spacingXs))
                Text(invalidText, color = colors.warning, fontSize = FlareSizes.fontSizeMd.value.sp)
            }
        }

        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                summary,
                color = colors.textSecondary,
                fontSize = FlareSizes.fontSizeMd.value.sp,
                modifier = Modifier.weight(1f).semantics { liveRegion = LiveRegionMode.Polite },
            )
            if (onClear != null && !unrestricted) {
                OutlinedButton(
                    onClick = { onClear() },
                    enabled = !disabled,
                    shape = RoundedCornerShape(FlareSizes.radiusMd),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = colors.textPrimary,
                        disabledContentColor = colors.textDisabled,
                    ),
                    modifier = Modifier.defaultMinSize(
                        minWidth = FlareSizes.touchTarget,
                        minHeight = FlareSizes.touchTarget,
                    ),
                ) {
                    Text(clearText, fontSize = FlareSizes.fontSizeMd.value.sp)
                }
            }
        }
    }
}

@Composable
private fun DateField(
    label: String,
    value: String,
    minDate: String?,
    maxDate: String?,
    disabled: Boolean,
    clearText: String,
    colors: FlareColors,
    onPick: (String) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
        Text(label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp)
        Row(verticalAlignment = Alignment.CenterVertically) {
            DatePicker(
                value = value,
                placeholder = label,
                size = FlareControlSize.Lg,
                min = minDate,
                max = maxDate,
                title = label,
                disabled = disabled,
                onChange = onPick,
            )
            if (value.isNotEmpty()) {
                Spacer(Modifier.width(FlareSizes.spacingXs))
                Row(
                    modifier = Modifier
                        .defaultMinSize(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget)
                        .clip(RoundedCornerShape(FlareSizes.radiusFull))
                        .then(if (disabled) Modifier else Modifier.clickable { onPick("") })
                        .semantics { contentDescription = "$clearText $label" },
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    FlareIcon(
                        "close",
                        size = 14.dp,
                        tint = if (disabled) colors.textDisabled else colors.textSecondary,
                    )
                }
            }
        }
    }
}

@Composable
private fun Chip(
    label: String,
    selected: Boolean,
    disabled: Boolean,
    colors: FlareColors,
    icon: String? = null,
    onClick: () -> Unit,
) {
    val shape = RoundedCornerShape(FlareSizes.radiusFull)
    val foreground = when {
        disabled -> colors.textDisabled
        selected -> colors.primary
        else -> colors.textPrimary
    }
    Row(
        modifier = Modifier
            .defaultMinSize(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget)
            .clip(shape)
            .background(
                when {
                    disabled -> colors.bgDisabled
                    selected -> colors.bgSelected
                    else -> colors.bgPrimary
                },
            )
            .border(1.dp, if (selected && !disabled) colors.primary else colors.borderPrimary, shape)
            .then(if (disabled) Modifier else Modifier.clickable { onClick() })
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm)
            .semantics { this.selected = selected },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        if (icon != null) {
            FlareIcon(icon, size = 16.dp, tint = foreground)
            Spacer(Modifier.width(FlareSizes.spacingXs))
        }
        Text(label, color = foreground, fontSize = FlareSizes.fontSizeLg.value.sp)
    }
}
