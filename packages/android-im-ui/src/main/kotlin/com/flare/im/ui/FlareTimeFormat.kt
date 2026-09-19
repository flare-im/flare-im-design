package com.flare.im.ui

import java.text.DateFormat
import java.text.SimpleDateFormat
import java.time.Instant
import java.time.ZoneId
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.ConcurrentHashMap

/**
 * Locale-aware time labels for host-formatted data (`FlareMessageData.timeLabel`,
 * `ConversationRowData.timestampLabel`) and the timeline's date separators, with the rules every
 * platform shares:
 *
 * - [messageTime]: hour and minute in the locale's convention — a two-digit 24-hour
 *   clock ("09:05") where the locale counts 24 hours, the locale's own 12-hour form
 *   ("9:05 AM", "上午9:05") where it does not.
 * - [conversationTime]: [messageTime] on the same calendar day, the host's
 *   `yesterday` label on the previous one, numeric month/day in the locale's order
 *   within the year, numeric year/month/day before it.
 * - [timelineDateLabel]: the same day buckets with the host's `today` word for the current day;
 *   [startsTimelineDay] decides where a separator goes.
 *
 * Calendar days are taken in the local time zone, from numeric fields; formatters are built once
 * per locale and shape, never per row.
 */
object FlareTimeFormat {
    fun messageTime(epochMs: Long, locale: Locale = Locale.getDefault()): String =
        formatIn(cachedFormat(locale, FlareDateShape.Clock), epochMs, ZoneId.systemDefault())

    fun conversationTime(
        epochMs: Long,
        yesterday: String,
        locale: Locale = Locale.getDefault(),
        nowMs: Long = System.currentTimeMillis(),
    ): String {
        val zone = ZoneId.systemDefault()
        val day = flareLocalEpochDay(epochMs, zone)
        val today = flareLocalEpochDay(nowMs, zone)
        return when (day) {
            today -> messageTime(epochMs, locale)
            today - 1 -> yesterday
            else -> dayLabel(epochMs, nowMs, locale, zone)
        }
    }

    /**
     * The label of a timeline date separator. Every bubble already shows its own time, so separators
     * mark days only: the host's [today] and [yesterday] words, then the locale's numeric month and day
     * in the current year, with the year when it differs.
     */
    fun timelineDateLabel(
        epochMs: Long,
        today: String,
        yesterday: String,
        locale: Locale = Locale.getDefault(),
        nowMs: Long = System.currentTimeMillis(),
        zone: ZoneId = ZoneId.systemDefault(),
    ): String {
        val day = flareLocalEpochDay(epochMs, zone)
        val current = flareLocalEpochDay(nowMs, zone)
        return when (day) {
            current -> today
            current - 1 -> yesterday
            else -> dayLabel(epochMs, nowMs, locale, zone)
        }
    }

    /**
     * True when a date separator belongs before the message sent at [currentMs]: the first dated
     * message ([previousMs] is 0) or one on another local calendar day than [previousMs]. An undated
     * message ([currentMs] is 0) gets none. Time gaps within a day never do.
     */
    fun startsTimelineDay(previousMs: Long, currentMs: Long, zone: ZoneId = ZoneId.systemDefault()): Boolean {
        if (currentMs <= 0) return false
        if (previousMs <= 0) return true
        return flareLocalEpochDay(previousMs, zone) != flareLocalEpochDay(currentMs, zone)
    }

    private fun dayLabel(epochMs: Long, nowMs: Long, locale: Locale, zone: ZoneId): String {
        val sameYear = Instant.ofEpochMilli(epochMs).atZone(zone).year == Instant.ofEpochMilli(nowMs).atZone(zone).year
        return formatIn(cachedFormat(locale, if (sameYear) FlareDateShape.MonthDay else FlareDateShape.FullDate), epochMs, zone)
    }

    private fun clockFormat(locale: Locale): DateFormat {
        val short = DateFormat.getTimeInstance(DateFormat.SHORT, locale)
        val pattern = (short as? SimpleDateFormat)?.toPattern().orEmpty()
        return when {
            !flareUsesTwelveHourClock(locale, pattern) -> SimpleDateFormat("HH:mm", locale)
            patternFields(pattern).any { it == 'h' || it == 'K' } -> short
            else -> SimpleDateFormat("h:mm a", locale)
        }
    }

    private enum class FlareDateShape { Clock, MonthDay, FullDate }

    private val formats = ConcurrentHashMap<Pair<Locale, FlareDateShape>, DateFormat>()

    private fun cachedFormat(locale: Locale, shape: FlareDateShape): DateFormat = formats.getOrPut(locale to shape) {
        when (shape) {
            FlareDateShape.Clock -> clockFormat(locale)
            FlareDateShape.MonthDay -> SimpleDateFormat(flareMonthDayPattern(shortDatePattern(locale)), locale)
            FlareDateShape.FullDate -> SimpleDateFormat(flareFullYearPattern(shortDatePattern(locale)), locale)
        }
    }

    private fun shortDatePattern(locale: Locale): String =
        (DateFormat.getDateInstance(DateFormat.SHORT, locale) as? SimpleDateFormat)?.toPattern() ?: "y/M/d"

    /** A [DateFormat] is not thread-safe and keeps its own time zone: format under its lock, in [zone]. */
    private fun formatIn(format: DateFormat, epochMs: Long, zone: ZoneId): String = synchronized(format) {
        format.timeZone = TimeZone.getTimeZone(zone)
        format.format(Date(epochMs))
    }
}

/** The local calendar day of [epochMs] in [zone], as days since the epoch: numeric, no formatter. */
internal fun flareLocalEpochDay(epochMs: Long, zone: ZoneId): Long {
    val offsetMs = zone.rules.getOffset(Instant.ofEpochMilli(epochMs)).totalSeconds * 1000L
    return Math.floorDiv(epochMs + offsetMs, 86_400_000L)
}

/**
 * Regions whose preferred hour cycle is 12-hour (CLDR supplemental `timeData`, the data
 * behind the `j` skeleton that ICU, Foundation and `Intl` resolve). The platform's short
 * time pattern is not used for this: JDK and older ICU builds disagree with CLDR for
 * regions such as CN (`ah:mm`) and MX (`HH:mm`).
 */
private val twelveHourRegions = setOf(
    "AC", "AE", "AG", "AL", "AQ", "AR", "AS", "AU", "BB", "BD", "BH", "BM", "BN", "BO", "BQ", "BS", "BT",
    "CA", "CC", "CL", "CO", "CP", "CQ", "CR", "CU", "CW", "CY", "DJ", "DM", "DO", "DZ", "EC", "EG", "EH",
    "ER", "ET", "FJ", "FM", "GD", "GH", "GM", "GR", "GT", "GU", "GY", "HK", "HM", "HN", "HT", "IN", "IQ",
    "JM", "JO", "KH", "KI", "KN", "KP", "KR", "KW", "KY", "LB", "LC", "LR", "LS", "LY", "MH", "MO", "MP",
    "MR", "MV", "MW", "MX", "MY", "NA", "NI", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PR", "PS", "PW",
    "PY", "QA", "SA", "SB", "SD", "SG", "SL", "SO", "SS", "SV", "SY", "SZ", "TA", "TC", "TD", "TK", "TN",
    "TO", "TT", "TV", "TW", "UM", "US", "UY", "VC", "VE", "VG", "VI", "VU", "WS", "YE", "ZM",
)

/** Language-specific `timeData` entries that keep a 24-hour clock inside a 12-hour region. */
private val twentyFourHourLocales = setOf("fr-CA", "fr-HT", "nl-BQ", "nl-CW", "en-CC", "en-MV", "en-TK", "en-TV")

/**
 * Whether [locale] reads time on a 12-hour clock. Without a region the locale's own
 * [shortTimePattern] decides.
 */
internal fun flareUsesTwelveHourClock(locale: Locale, shortTimePattern: String): Boolean {
    val region = locale.country.uppercase(Locale.ROOT)
    return when {
        region.isEmpty() -> patternFields(shortTimePattern).any { it == 'h' || it == 'K' }
        "${locale.language}-$region" in twentyFourHourLocales -> false
        else -> region in twelveHourRegions
    }
}

/** A short date pattern without its year: the year field goes with the separator that joined it. */
internal fun flareMonthDayPattern(shortDatePattern: String): String {
    val parts = patternParts(shortDatePattern)
    val year = parts.indexOfFirst { it.field == 'y' }
    if (year < 0) return shortDatePattern
    val fieldBefore = parts.subList(0, year).any { it.field != null }
    val separator = if (fieldBefore) year - 1 else year + 1
    val drop = setOfNotNull(year, separator.takeIf { parts.getOrNull(it)?.field == null && it in parts.indices })
    return parts.filterIndexed { index, _ -> index !in drop }.joinToString("") { it.text }
}

/** A short date pattern with a full year ("M/d/yy" → "M/d/y"). */
internal fun flareFullYearPattern(shortDatePattern: String): String =
    patternParts(shortDatePattern).joinToString("") { if (it.field == 'y') "y" else it.text }

/** One run of a date pattern: a field (repeated letter) or literal text, quotes kept as written. */
private data class PatternPart(val field: Char?, val text: String)

private fun patternParts(pattern: String): List<PatternPart> {
    val parts = mutableListOf<PatternPart>()
    val literal = StringBuilder()
    fun flushLiteral() { if (literal.isNotEmpty()) { parts += PatternPart(null, literal.toString()); literal.clear() } }
    var i = 0
    while (i < pattern.length) {
        val c = pattern[i]
        when {
            c == '\'' -> {
                var j = i + 1
                while (j < pattern.length) {
                    if (pattern[j] != '\'') j++
                    else if (j + 1 < pattern.length && pattern[j + 1] == '\'') j += 2
                    else break
                }
                val end = minOf(j + 1, pattern.length)
                literal.append(pattern, i, end)
                i = end
            }
            c in 'a'..'z' || c in 'A'..'Z' -> {
                flushLiteral()
                var j = i
                while (j < pattern.length && pattern[j] == c) j++
                parts += PatternPart(c, pattern.substring(i, j))
                i = j
            }
            else -> { literal.append(c); i++ }
        }
    }
    flushLiteral()
    return parts
}

private fun patternFields(pattern: String): List<Char> = patternParts(pattern).mapNotNull { it.field }
