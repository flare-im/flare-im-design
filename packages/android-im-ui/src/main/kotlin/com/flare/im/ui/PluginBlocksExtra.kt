package com.flare.im.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.CollectionInfo
import androidx.compose.ui.semantics.CollectionItemInfo
import androidx.compose.ui.semantics.collectionInfo
import androidx.compose.ui.semantics.collectionItemInfo
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.SubcomposeAsyncImage
import kotlinx.coroutines.delay
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

// Vocabulary 2 of the resolved plugin view (flare-plugin-protocol blocks.rs / formats.rs / inputs.rs): the blocks
// section, stats, chart, image, qr, hero, steps, banner and timeline, the value formats a field, a stat, a hero or a
// cell may carry, the money input's rules and the document input's side, with the composables [PluginView] draws them
// with. Read leniently like the vocabulary 1 models; `spec/plugin-view-vectors.json` → blocks2, formats2, moneyInput
// and upgradeNotice hold the facts the four kits share.

// ── formats ─────────────────────────────────────────────────────────────────

/**
 * What a value's format adds to its plain text (`ResolvedUiFormat`). A surface that does not know a format draws the
 * plain text; the kit rewrites only [Count] (compact) and [Duration] (the viewer's words), see [PluginFormatRules].
 */
sealed interface PluginValueFormat {
    val kind: String

    /** Minor units as sent; [scale] null: still minor units, the host may scale them by [assetId]. [currency]: the code beside it. */
    data class Money(val minor: String, val scale: Int? = null, val assetId: String? = null, val currency: String? = null) : PluginValueFormat {
        override val kind: String get() = "money"
    }
    data class Enumeration(val raw: String) : PluginValueFormat { override val kind: String get() = "enum" }
    data class Person(val userId: String) : PluginValueFormat { override val kind: String get() = "person" }
    /** [labelled] false: the value is the bare id. */
    data class Reference(val id: String, val labelled: Boolean) : PluginValueFormat { override val kind: String get() = "reference" }
    data class Time(val atMs: Long) : PluginValueFormat { override val kind: String get() = "time" }
    /** A ratio already multiplied by 100; the plain text is already "12.5%". */
    data class Percent(val percent: Double, val decimals: Int) : PluginValueFormat { override val kind: String get() = "percent" }
    data class Duration(val ms: Double) : PluginValueFormat { override val kind: String get() = "duration" }
    data class Count(val count: Double) : PluginValueFormat { override val kind: String get() = "count" }
    /** The plain text is already "1.5 MB". */
    data class Bytes(val bytes: Double) : PluginValueFormat { override val kind: String get() = "bytes" }
}

private fun Map<*, *>.str(key: String): String? = this[key] as? String
/** The widest instant a kit draws, in ms either side of the epoch (the ECMAScript `Date` range, spec blocks2.instants). */
const val PLUGIN_MAX_INSTANT_MS: Long = 8_640_000_000_000_000L

/** An instant in plugin data, or null when it is not a number within ±[PLUGIN_MAX_INSTANT_MS]: left out, never saturated. */
internal fun pluginInstant(value: Any?): Long? =
    (value as? Number)?.toDouble()?.takeIf { it.isFinite() && kotlin.math.abs(it) <= PLUGIN_MAX_INSTANT_MS }?.toLong()

private fun Map<*, *>.num(key: String): Double? = (this[key] as? Number)?.toDouble()?.takeIf { it.isFinite() }
private fun Map<*, *>.flag(key: String): Boolean? = this[key] as? Boolean
private fun Map<*, *>.items(key: String): List<*> = this[key] as? List<*> ?: emptyList<Any?>()

/** A format as the core writes it; null for a kind the kit does not know or a malformed one. */
internal fun pluginValueFormat(raw: Any?): PluginValueFormat? {
    val map = raw as? Map<*, *> ?: return null
    return when (map.str("kind")) {
        "money" -> map.str("minor")?.let { PluginValueFormat.Money(it, map.num("scale")?.toInt(), map.str("assetId"), map.str("currency")) }
        "enum" -> map.str("raw")?.let { PluginValueFormat.Enumeration(it) }
        "person" -> map.str("userId")?.let { PluginValueFormat.Person(it) }
        "reference" -> map.str("id")?.let { PluginValueFormat.Reference(it, map.flag("labelled") ?: false) }
        "time" -> pluginInstant(map["atMs"])?.let { PluginValueFormat.Time(it) }
        "percent" -> map.num("percent")?.let { PluginValueFormat.Percent(it, map.num("decimals")?.toInt() ?: 0) }
        "duration" -> map.num("ms")?.let { PluginValueFormat.Duration(it) }
        "count" -> map.num("count")?.let { PluginValueFormat.Count(it) }
        "bytes" -> map.num("bytes")?.let { PluginValueFormat.Bytes(it) }
        else -> null
    }
}

/**
 * The words a formatted value is drawn with (spec formats2): `count` compact in the viewer's units ("1.2万"),
 * `duration` in the viewer's units ("2 小时 5 分钟"), `money` with its currency (R10); every other format draws the plain
 * text the core wrote.
 */
internal object PluginFormatRules {
    fun text(value: String, format: PluginValueFormat?, strings: FlareStrings): String = when (format) {
        is PluginValueFormat.Count -> compactCount(format.count, strings.pluginFormatCountUnits)
        is PluginValueFormat.Duration -> durationText(format.ms, strings)
        is PluginValueFormat.Money -> money(value, format)
        else -> value
    }

    /** R10: a scaled amount with its currency as the payment confirmation writes it, a leading minus or plus kept; else as sent. */
    fun money(value: String, format: PluginValueFormat.Money): String {
        val currency = format.currency ?: return value
        if (format.scale == null) return value
        val sign = value.take(1).takeIf { it == "-" || it == "+" }.orEmpty()
        return FlarePaymentRules.amountText(value.drop(sign.length), currency)?.let { sign + it } ?: value
    }

    /** The compact units of [units] ("4:万|8:亿": exponent and suffix pairs), largest first; malformed pairs skipped. */
    fun units(units: String): List<Pair<Int, String>> = units.split("|").mapNotNull { pair ->
        val at = pair.indexOf(':')
        if (at < 0) return@mapNotNull null
        val exponent = pair.substring(0, at).toIntOrNull()?.takeIf { it > 0 } ?: return@mapNotNull null
        pair.substring(at + 1).takeIf { it.isNotEmpty() }?.let { exponent to it }
    }.sortedByDescending { it.first }

    /**
     * A count written compact (spec formats2.count): the largest unit the count reaches, one decimal cut (never rounded
     * up) and a trailing ".0" dropped; below every unit, the count itself.
     */
    fun compactCount(count: Double, units: String): String {
        val whole = if (count < 0) -floor(-count) else floor(count)
        val sign = if (whole < 0) "-" else ""
        val n = abs(whole)
        val unit = units(units).firstOrNull { n >= 10.0.pow(it.first) } ?: return sign + integer(n)
        val tenths = floor(n * 10 / 10.0.pow(unit.first))
        val head = floor(tenths / 10)
        val digit = tenths - head * 10
        return sign + (if (digit == 0.0) integer(head) else "${integer(head)}.${integer(digit)}") + unit.second
    }

    /**
     * A duration in the viewer's words (spec formats2.duration): whole seconds; under a minute the seconds alone, else
     * the largest unit that is not zero and, when it is not zero, the next one ("2 小时 5 分钟", "1 天").
     */
    fun durationText(ms: Double, strings: FlareStrings): String {
        val total = floor(max(0.0, ms) / 1000).toLong()
        fun unit(template: String, n: Long) = template.replace("{n}", n.toString())
        if (total < 60) return unit(strings.pluginFormatSeconds, total)
        val parts = listOf(
            total / 86_400 to strings.myInviteUnitDays,
            (total % 86_400) / 3_600 to strings.myInviteUnitHours,
            (total % 3_600) / 60 to strings.myInviteUnitMinutes,
            total % 60 to strings.pluginFormatSeconds,
        )
        val first = parts.indexOfFirst { it.first > 0 }
        val next = parts.getOrNull(first + 1)
        return unit(parts[first].second, parts[first].first) + if (next != null && next.first > 0) " " + unit(next.second, next.first) else ""
    }

    private fun integer(value: Double): String = String.format(java.util.Locale.ROOT, "%.0f", value)
}

// ── blocks ──────────────────────────────────────────────────────────────────

/** `section`: blocks under a heading (never a section, rows or protected media), collapsible; [collapsed] is how it starts. */
data class PluginSectionBlock(val label: String? = null, val collapsed: Boolean = false, val blocks: List<PluginBlock>) : PluginBlock {
    override val kind: String get() = "section"
}

/** Which way a figure moved; anything the kit does not know is [Flat]. */
enum class PluginTrendDirection(val wire: String) {
    Up("up"), Down("down"), Flat("flat");

    companion object {
        fun fromWire(value: String?): PluginTrendDirection = entries.firstOrNull { it.wire == value } ?: Flat
    }
}

/** How a figure moved: the text as sent and its direction. */
data class PluginTrend(val text: String, val direction: PluginTrendDirection = PluginTrendDirection.Flat)

/** One figure of a stats block; [value] is the plain text, whatever [format] says. */
data class PluginStat(
    val label: String,
    val value: String,
    val format: PluginValueFormat? = null,
    val trend: PluginTrend? = null,
    val tone: PluginTone? = null,
)

/** `stats`: 2 to 6 figures side by side. */
data class PluginStatsBlock(val items: List<PluginStat>) : PluginBlock {
    override val kind: String get() = "stats"
}

enum class PluginChartKind(val wire: String) {
    Bar("bar"), Line("line"), Donut("donut");

    companion object {
        fun fromWire(value: String?): PluginChartKind? = entries.firstOrNull { it.wire == value }
    }
}

/** One point: its label, the value drawn and the value as text (through the block's format). */
data class PluginChartPoint(val label: String, val value: Double, val text: String)

data class PluginChartSeries(val label: String? = null, val points: List<PluginChartPoint>)

/** `chart`: up to 3 series (a donut draws one) of up to 60 points; [emptyText] shows when no series has a point. */
data class PluginChartBlock(val chartKind: PluginChartKind, val series: List<PluginChartSeries>, val emptyText: String? = null) : PluginBlock {
    override val kind: String get() = "chart"

    /** Some series has a point. */
    val hasPoints: Boolean get() = series.any { it.points.isNotEmpty() }
}

enum class PluginImageAspect(val wire: String, val ratio: Float) {
    Square("1:1", 1f), Standard("4:3", 4f / 3f), Wide("16:9", 16f / 9f), Portrait("3:4", 3f / 4f);

    companion object {
        fun fromWire(value: String?): PluginImageAspect = entries.firstOrNull { it.wire == value } ?: Square
    }
}

/**
 * What the host's `resolveImage` is asked for: a package asset, or a privately uploaded file of the plugin. Never a
 * URL: the host turns either into one.
 */
data class PluginImageSource(val asset: String? = null, val fileId: String? = null)

/** `image`: one picture in a fixed frame; [alt] is what a screen reader says. */
data class PluginImageBlock(
    val asset: String? = null,
    val fileId: String? = null,
    val aspect: PluginImageAspect = PluginImageAspect.Square,
    val alt: String = "",
) : PluginBlock {
    override val kind: String get() = "image"
    val source: PluginImageSource get() = PluginImageSource(asset, fileId)
}

/**
 * What `onQrRefresh` carries: the host runs the query (with `{}`) and passes back a view with the fresh code, read at
 * [valuePath] and [expiresAtPath] in its result.
 */
data class PluginQrRefresh(val operation: String, val valuePath: String, val expiresAtPath: String? = null)

/** `qr`: a QR code of [value]; [refreshOperation] (a query, absent on a read-only copy) returns a fresh one. */
data class PluginQrBlock(
    val value: String,
    val label: String? = null,
    val caption: String? = null,
    val refreshOperation: String? = null,
    val valuePath: String = "",
    val expiresAtPath: String? = null,
    val expiresAtMs: Long? = null,
) : PluginBlock {
    override val kind: String get() = "qr"

    /** The code names an expiry and that instant has come (spec blocks2.qr). */
    fun expired(nowMs: Long): Boolean = expiresAtMs != null && expiresAtMs <= nowMs

    /** How long until the code expires, to draw it again then; null without an expiry or once expired. */
    fun refreshDelay(nowMs: Long): Long? = expiresAtMs?.takeIf { it > nowMs }?.let { it - nowMs }

    /** What the refresh key hands the host; null when the block has no refresh. */
    val refresh: PluginQrRefresh? get() = refreshOperation?.let { PluginQrRefresh(it, valuePath, expiresAtPath) }
}

enum class PluginHeroTone(val wire: String) {
    Neutral("neutral"), Positive("positive"), Warning("warning"), Brand("brand");

    companion object {
        fun fromWire(value: String?): PluginHeroTone = entries.firstOrNull { it.wire == value } ?: Neutral
    }
}

/** `hero`: the page's lead figure (one per document); [amount] draws tabular figures; up to 3 owned [actions]. */
data class PluginHeroBlock(
    val label: String? = null,
    val value: String,
    val amount: Boolean = false,
    val format: PluginValueFormat? = null,
    val subtitle: String? = null,
    val tone: PluginHeroTone = PluginHeroTone.Neutral,
    val actions: List<PluginViewAction> = emptyList(),
    /** The viewer may hide [value] behind an eye toggle. */
    val maskable: Boolean = false,
) : PluginBlock {
    override val kind: String get() = "hero"
}

enum class PluginStepState(val wire: String) {
    Pending("pending"), Current("current"), Done("done"), Failed("failed");

    companion object {
        /** Anything the kit does not know is pending (spec blocks2.steps). */
        fun fromWire(value: String?): PluginStepState = entries.firstOrNull { it.wire == value } ?: Pending
    }
}

data class PluginStep(val label: String, val state: PluginStepState = PluginStepState.Pending)

/** `steps`: a process in 2 to 6 steps. */
data class PluginStepsBlock(val items: List<PluginStep>) : PluginBlock {
    override val kind: String get() = "steps"
}

enum class PluginBannerTone(val wire: String, val status: FlareStatusTone) {
    Info("info", FlareStatusTone.Info), Success("success", FlareStatusTone.Success),
    Warning("warning", FlareStatusTone.Warning), Danger("danger", FlareStatusTone.Danger);

    companion object {
        fun fromWire(value: String?): PluginBannerTone = entries.firstOrNull { it.wire == value } ?: Info
    }
}

/** `banner`: a prominent notice (at most 2 per document) with an optional owned [action] (absent on a read-only copy). */
data class PluginBannerBlock(val tone: PluginBannerTone = PluginBannerTone.Info, val text: String, val action: PluginViewAction? = null) : PluginBlock {
    override val kind: String get() = "banner"
}

data class PluginTimelineItem(val atMs: Long, val title: String, val detail: String? = null, val status: PluginBadge? = null)

/** `timeline`: up to 50 dated items, in the plugin's order. */
/** One item of a protected media block; nothing about its content is in the view. */
data class PluginProtectedItem(val id: String, val label: String, val mediaType: String? = null, val input: Any? = null) {
    val isImage: Boolean get() = mediaType?.startsWith("image/") ?: true
}

/**
 * `protected-media`: private material read one item at a time through [action] — with a stated reason when
 * [reasonInput] is declared (a console), with one tap on the owner's own page (no [reasonInput]; owner-scoped).
 */
data class PluginProtectedMediaBlock(
    val label: String? = null,
    val items: List<PluginProtectedItem>,
    /** Absent on a read-only copy. */
    val action: PluginViewAction? = null,
    val inputName: String,
    val reasonInput: String? = null,
    /** Reads the action's result (a JSON pointer): the address to draw. */
    val urlPath: String,
    val emptyText: String? = null,
) : PluginBlock {
    override val kind: String get() = "protected-media"

    /** Whether a read first asks the viewer why (spec/capability-ui-vectors.json protectedMediaReason). */
    val asksReason: Boolean get() = reasonInput != null

    /** The read handed to the host for [item] with [reason] (empty when none is asked). */
    fun read(item: PluginProtectedItem, reason: String): PluginProtectedMediaRead? {
        val action = action ?: return null
        val values = linkedMapOf<String, Any?>(inputName to item.id)
        reasonInput?.let { values[it] = reason }
        return PluginProtectedMediaRead(action, item, reason, urlPath, values)
    }
}

/** What the host has for a protected media item. */
data class PluginProtectedMediaState(
    /** The read's address: the server's short-lived https address (`?grant=`), or a data:image the host fetched. */
    val url: String? = null,
    val loading: Boolean = false,
    val error: String? = null,
)

/** A protected media read for the host to run and audit. */
data class PluginProtectedMediaRead(
    val action: PluginViewAction,
    val item: PluginProtectedItem,
    /** Empty when the block asks for none. */
    val reason: String,
    val urlPath: String,
    /** The item under `inputName` and, when declared, the reason. */
    val formValues: Map<String, Any?>,
)

data class PluginTimelineBlock(val items: List<PluginTimelineItem>, val emptyText: String? = null) : PluginBlock {
    override val kind: String get() = "timeline"
}

/**
 * `result`: how a money, real-name or red packet action came out (R7). [title] and [tone] are the label the plugin's
 * values gave [state]; [unmapped] marks a state outside them (drawn as the unknown status). [amount] is the plain text
 * of the amount with [format]; [description] says what happens next.
 */
data class PluginResultBlock(
    val state: String,
    val title: String,
    val tone: PluginTone = PluginTone.Neutral,
    val unmapped: Boolean = false,
    val amount: String? = null,
    val format: PluginValueFormat? = null,
    val description: String? = null,
) : PluginBlock {
    override val kind: String get() = "result"
}

private fun Map<*, *>.tone(key: String): PluginTone? = PluginTone.fromWire(str(key))

private fun pluginBadgeValue(raw: Any?): PluginBadge? {
    val map = raw as? Map<*, *> ?: return null
    val text = map.str("text")?.takeIf { it.isNotEmpty() } ?: return null
    return PluginBadge(text, map.tone("tone") ?: PluginTone.Neutral, map.flag("unmapped") ?: false)
}

/** A vocabulary 2 block as the core writes it; null for another kind or a malformed one. */
internal fun pluginExtraBlock(map: Map<*, *>): PluginBlock? = when (map.str("kind")) {
    "section" -> PluginSectionBlock(
        label = map.str("label"),
        collapsed = map.flag("collapsed") ?: false,
        // A nested section or rows block is not allowed: dropped like an unknown kind.
        blocks = map.items("blocks").mapNotNull { (it as? Map<*, *>)?.let(::pluginBlockOf) }
            .filterNot { it is PluginSectionBlock || it is PluginRowsBlock || it is PluginProtectedMediaBlock },
    )
    "stats" -> PluginStatsBlock(map.items("items").mapNotNull { raw ->
        val item = raw as? Map<*, *> ?: return@mapNotNull null
        PluginStat(
            label = item.str("label") ?: "",
            value = item.str("value") ?: "",
            format = pluginValueFormat(item["format"]),
            trend = (item["trend"] as? Map<*, *>)?.let { PluginTrend(it.str("text") ?: "", PluginTrendDirection.fromWire(it.str("direction"))) },
            tone = item.tone("tone"),
        )
    })
    "chart" -> PluginChartKind.fromWire(map.str("chartKind"))?.let { chartKind ->
        PluginChartBlock(
            chartKind = chartKind,
            series = map.items("series").mapNotNull { raw ->
                val series = raw as? Map<*, *> ?: return@mapNotNull null
                PluginChartSeries(series.str("label"), series.items("points").mapNotNull { point ->
                    val p = point as? Map<*, *> ?: return@mapNotNull null
                    val value = p.num("value") ?: return@mapNotNull null
                    PluginChartPoint(p.str("label") ?: "", value, p.str("text") ?: PluginViewFormat.number(value))
                })
            },
            emptyText = map.str("emptyText"),
        )
    }
    "image" -> PluginImageBlock(map.str("asset"), map.str("fileId"), PluginImageAspect.fromWire(map.str("aspect")), map.str("alt") ?: "")
    "qr" -> map.str("value")?.let {
        PluginQrBlock(it, map.str("label"), map.str("caption"), map.str("refreshOperation"), map.str("valuePath") ?: "",
            map.str("expiresAtPath"), pluginInstant(map["expiresAtMs"]))
    }
    "hero" -> PluginHeroBlock(
        label = map.str("label"),
        value = map.str("value") ?: "",
        amount = map.flag("amount") ?: false,
        format = pluginValueFormat(map["format"]),
        subtitle = map.str("subtitle"),
        tone = PluginHeroTone.fromWire(map.str("tone")),
        actions = map.items("actions").mapNotNull { (it as? Map<*, *>)?.let(::pluginActionOf) },
        maskable = map.flag("maskable") ?: false,
    )
    "steps" -> PluginStepsBlock(map.items("items").mapNotNull { raw ->
        val step = raw as? Map<*, *> ?: return@mapNotNull null
        PluginStep(step.str("label") ?: "", PluginStepState.fromWire(step.str("state")))
    })
    "banner" -> map.str("text")?.let {
        PluginBannerBlock(PluginBannerTone.fromWire(map.str("tone")), it, (map["action"] as? Map<*, *>)?.let(::pluginActionOf))
    }
    "timeline" -> PluginTimelineBlock(
        items = map.items("items").mapNotNull { raw ->
            val item = raw as? Map<*, *> ?: return@mapNotNull null
            val at = pluginInstant(item["atMs"]) ?: return@mapNotNull null
            PluginTimelineItem(at, item.str("title") ?: "", item.str("detail"), pluginBadgeValue(item["status"]))
        },
        emptyText = map.str("emptyText"),
    )
    "protected-media" -> {
        val inputName = map.str("inputName")?.takeIf { it.isNotEmpty() }
        val urlPath = map.str("urlPath")?.takeIf { it.isNotEmpty() }
        if (inputName == null || urlPath == null) null else PluginProtectedMediaBlock(
            label = map.str("label"),
            items = map.items("items").mapNotNull { raw ->
                val item = raw as? Map<*, *> ?: return@mapNotNull null
                val id = item.str("id")?.takeIf { it.isNotEmpty() } ?: return@mapNotNull null
                PluginProtectedItem(id, item.str("label") ?: "", item.str("mediaType"), item["input"])
            },
            action = (map["action"] as? Map<*, *>)?.let(::pluginActionOf),
            inputName = inputName,
            reasonInput = map.str("reasonInput")?.takeIf { it.isNotEmpty() },
            urlPath = urlPath,
            emptyText = map.str("emptyText"),
        )
    }
    "result" -> map.str("state")?.let { state ->
        PluginResultBlock(
            state = state,
            title = map.str("title") ?: state,
            tone = map.tone("tone") ?: PluginTone.Neutral,
            unmapped = map.flag("unmapped") ?: false,
            amount = map.str("amount")?.takeIf { it.isNotBlank() },
            format = pluginValueFormat(map["format"]),
            description = map.str("description")?.takeIf { it.isNotBlank() },
        )
    }
    else -> null
}

/** The blocks in reading order with every section's children after it (spec blocks2.flatten). */
internal fun pluginFlatBlocks(blocks: List<PluginBlock>): List<PluginBlock> =
    blocks.flatMap { if (it is PluginSectionBlock) listOf(it) + it.blocks else listOf(it) }

// ── chart geometry ──────────────────────────────────────────────────────────

/** One slice of a donut: the point it draws, its start and its sweep as fractions of the whole. */
internal data class PluginDonutSlice(val index: Int, val start: Double, val sweep: Double)

internal object PluginChartRules {
    /**
     * A donut's slices (spec blocks2.donut): every point with a positive finite value, its start and sweep as fractions
     * of the sum of those values, in point order; nothing when no value is positive.
     */
    fun donutSlices(points: List<PluginChartPoint>): List<PluginDonutSlice> {
        val shown = points.withIndex().filter { it.value.value.isFinite() && it.value.value > 0 }
        val total = shown.sumOf { it.value.value }
        if (total <= 0) return emptyList()
        var start = 0.0
        return shown.map { (index, point) ->
            val sweep = point.value / total
            PluginDonutSlice(index, start, sweep).also { start += sweep }
        }
    }

    /**
     * The value range a bar or line chart scales to (spec blocks2.chartDomain, the kits' chart geometry): from 0, or
     * below it to the next round step past the smallest negative value, up to the next round step (1, 2, 2.5, 5 or 10
     * times a power of ten) past the largest value; nothing but zeros scales to 0..1.
     */
    fun range(series: List<PluginChartSeries>): Pair<Double, Double> {
        val values = series.flatMap { s -> s.points.map { it.value } }.filter { it.isFinite() }
        val high = niceCeil(max(0.0, values.maxOrNull() ?: 0.0))
        val lowest = min(0.0, values.minOrNull() ?: 0.0)
        val low = if (lowest < 0) -niceCeil(-lowest) else 0.0
        return if (high > low) low to high else 0.0 to 1.0
    }

    /** The round step at or above [value] (0 for none). */
    fun niceCeil(value: Double): Double {
        if (!(value > 0) || !value.isFinite()) return 0.0
        val magnitude = Math.pow(10.0, kotlin.math.floor(kotlin.math.log10(value)))
        // Rounded so floating-point noise never moves a value across a step.
        val fraction = Math.round(value / magnitude * 1e9) / 1e9
        val step = when {
            fraction <= 1 -> 1.0
            fraction <= 2 -> 2.0
            fraction <= 2.5 -> 2.5
            fraction <= 5 -> 5.0
            else -> 10.0
        }
        return step * magnitude
    }

    /** The labels along the x axis: the longest series' point labels. */
    fun labels(series: List<PluginChartSeries>): List<String> = series.maxByOrNull { it.points.size }?.points?.map { it.label }.orEmpty()

    /** What a screen reader says: each series' label and its points as "label text". */
    fun summary(block: PluginChartBlock): String = block.series.joinToString("; ") { series ->
        listOfNotNull(series.label?.takeIf { it.isNotEmpty() }, series.points.joinToString(", ") { "${it.label} ${it.text}" }.takeIf { it.isNotEmpty() })
            .joinToString(": ")
    }
}

// ── inputs ──────────────────────────────────────────────────────────────────

/** The amount rules of a money input, read by the core SDK: no paths are left. Bounds are decimal strings. */
data class PluginMoneyRules(val currency: String? = null, val scale: Int? = null, val min: String? = null, val max: String? = null) {
    /** The scale that applies: a declared one in 0..18, else 2. */
    val effectiveScale: Int get() = scale?.takeIf { it in 0..18 } ?: 2
}

/** Which side of an identity document a document input captures. */
enum class PluginDocumentSide(val wire: String) {
    Front("front"), Back("back"), Holding("holding");

    companion object {
        fun fromWire(value: String?): PluginDocumentSide? = entries.firstOrNull { it.wire == value }
    }
}

internal fun pluginMoneyRules(raw: Any?): PluginMoneyRules? {
    val map = raw as? Map<*, *> ?: return null
    return PluginMoneyRules(map.str("currency"), map.num("scale")?.toInt(), map.str("min"), map.str("max"))
}

internal object PluginMoneyInputRules {
    /**
     * What a money field holds once typed (spec moneyInput.typed): the locale's decimal separator, when it is not ".",
     * becomes "." so a comma-decimal keyboard (de_DE, fr_FR) enters fractions; the protocol only reads ".".
     */
    fun typed(text: String, decimalSeparator: String): String =
        if (decimalSeparator.isEmpty() || decimalSeparator == ".") text else text.replace(decimalSeparator, ".")

    /**
     * The amount typed, as the protocol writes decimals (spec moneyInput.normalize): spaces gone, leading zeros of the
     * whole part dropped (one kept), a leading "." gets a "0", a trailing "." goes. Anything else stays for the check.
     */
    fun amount(typed: String): String {
        var text = typed.filterNot { it.isWhitespace() }
        if (text.startsWith(".")) text = "0$text"
        if (text.endsWith(".")) text = text.dropLast(1)
        val at = text.indexOf('.')
        val whole = if (at < 0) text else text.substring(0, at)
        val rest = if (at < 0) "" else text.substring(at)
        val trimmed = if (whole.isNotEmpty() && whole.all { it in '0'..'9' }) whole.trimStart('0').ifEmpty { "0" } else whole
        return trimmed + rest
    }

    /** A decimal the protocol accepts: no sign or exponent, no leading zero, ≤30 whole and ≤[scale] fraction digits. */
    fun isDecimal(amount: String, scale: Int): Boolean {
        val match = Regex("^([0-9]+)(?:\\.([0-9]+))?$").matchEntire(amount) ?: return false
        val whole = match.groupValues[1]
        val fraction = match.groups[2]?.value
        return whole.length <= 30 && (whole == "0" || !whole.startsWith("0")) && (fraction == null || fraction.length <= scale)
    }

    /** The order of two decimals [isDecimal] accepts: negative, 0 or positive. */
    fun compare(a: String, b: String): Int {
        fun split(s: String): Pair<String, String> {
            val at = s.indexOf('.')
            return if (at < 0) s to "" else s.substring(0, at) to s.substring(at + 1).trimEnd('0')
        }
        val (aw, af) = split(a)
        val (bw, bf) = split(b)
        if (aw.length != bw.length) return aw.length.compareTo(bw.length)
        if (aw != bw) return aw.compareTo(bw)
        val width = max(af.length, bf.length)
        return af.padEnd(width, '0').compareTo(bf.padEnd(width, '0'))
    }

    /** The light check of a money draft (spec moneyInput.check): what the core SDK will say about the amount. */
    fun check(input: PluginInput, draft: Any?): PluginFormIssue? {
        val amount = amount(draft as? String ?: "")
        if (amount.isEmpty()) return if (input.required) PluginFormIssue.Required else null
        val rules = input.money
        if (rules == null || rules.currency.isNullOrEmpty() || !isDecimal(amount, rules.effectiveScale)) return PluginFormIssue.InvalidType
        if (rules.min != null && compare(amount, rules.min) < 0) return PluginFormIssue.OutOfRange
        if (rules.max != null && compare(amount, rules.max) > 0) return PluginFormIssue.OutOfRange
        return null
    }

    /** What submit hands over: `{amount, currency}`, null while no amount was typed. */
    fun value(input: PluginInput, draft: Any?): Map<String, String>? {
        val amount = amount(draft as? String ?: "")
        val currency = input.money?.currency?.takeIf { it.isNotEmpty() } ?: return null
        return if (amount.isEmpty()) null else linkedMapOf("amount" to amount, "currency" to currency)
    }

    /** The draft: the amount as typed (a `{amount}` value or a string); the currency comes from the input. */
    fun draft(raw: Any?): String = raw as? String ?: (raw as? Map<*, *>)?.get("amount") as? String ?: ""
}

// ── upgrade ─────────────────────────────────────────────────────────────────

/** What the engine's `update.plugin_upgrade_status` answers for a placeholder's `minBuild`. */
data class PluginUpgradeStatus(
    /** A build at least `minBuild` is offered to this device. */
    val available: Boolean,
    val build: Long? = null,
) {
    companion object {
        /** Reads the engine's `{available, build?}` JSON; null when it is not an object. */
        fun fromJson(json: String): PluginUpgradeStatus? {
            val map = FlareJson.parse(json) as? Map<*, *> ?: return null
            return PluginUpgradeStatus(map.flag("available") ?: false, map.num("build")?.toLong())
        }
    }
}

/**
 * What an upgrade notice offers (spec upgradeNotice): [Update] — a newer build is offered to this device and the host
 * handles the update, so the key shows; [NotAvailable] — no build for this device yet (also while it rolls out
 * elsewhere), only the copy; [Description] — the status is not known yet, or there is no handler.
 */
enum class PluginUpgradeMode {
    Update, NotAvailable, Description;

    companion object {
        fun of(status: PluginUpgradeStatus?, canUpdate: Boolean): PluginUpgradeMode = when {
            status?.available == true -> if (canUpdate) Update else Description
            status != null -> NotAvailable
            else -> Description
        }
    }
}

// ── composables ─────────────────────────────────────────────────────────────

/** A section: its label as a collapsible header ([PluginSectionBlock.collapsed] is how it starts) and its blocks. */
@Composable
internal fun PluginSectionBlockView(block: PluginSectionBlock, child: @Composable (Int, PluginBlock) -> Unit) {
    val colors = flareColors()
    val strings = flareStrings()
    val label = block.label?.takeIf { it.isNotEmpty() }
    var expanded by remember(block.label, block.collapsed) { mutableStateOf(!block.collapsed) }
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
        if (label != null) {
            Row(
                Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTargetMin)
                    .clickable(role = Role.Button) { expanded = !expanded }
                    .semantics(mergeDescendants = true) {
                        heading()
                        stateDescription = if (expanded) strings.collapse else strings.expand
                    },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
            ) {
                Text(label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f))
                FlareIcon(if (expanded) "chevron-up" else "chevron-down", size = FlareSizes.iconSizeSm, tint = colors.textTertiary)
            }
        }
        if (expanded || label == null) block.blocks.forEachIndexed { index, item -> child(index, item) }
    }
}

/** The colour of a stat's value: its tone's ink, else the primary text. */
@Composable
internal fun pluginStatColor(tone: PluginTone?): Color =
    if (tone == null || tone == PluginTone.Neutral) flareColors().textPrimary else pluginToneText(tone)

/** Columns of a stats grid: three for three or six figures, else two. */
internal fun pluginStatsColumns(count: Int): Int = if (count == 3 || count == 6) 3 else 2

/** 2 to 6 figures in a grid of [pluginStatsColumns] columns. */
@Composable
internal fun PluginStatsBlockView(block: PluginStatsBlock) {
    val colors = flareColors()
    val strings = flareStrings()
    val locale = flareLocale()
    val columns = pluginStatsColumns(block.items.size)
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        block.items.chunked(columns).forEach { line ->
            Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                line.forEach { item ->
                    Column(
                        Modifier.weight(1f).fillMaxHeight().clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgSecondary)
                            .padding(FlareSizes.spacingSm).semantics(mergeDescendants = true) {},
                        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs),
                    ) {
                        Text(item.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        // R10: a card's secondary figure is fontSize.3xl 18/600 in tabular digits; an amount reads its currency.
                        val text = PluginFormatRules.text(item.value, item.format, strings)
                        Text(text, color = pluginStatColor(item.tone),
                            fontSize = FlareSizes.fontSize3xl, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis,
                            style = FlareTabularFigures,
                            // A description replaces the merged words, so it carries the label too.
                            modifier = Modifier.semantics { contentDescription = "${item.label} ${FlarePaymentRules.spokenAmount(text, locale)}" })
                        item.trend?.takeIf { it.text.isNotEmpty() }?.let { PluginTrendView(it) }
                    }
                }
                // A short last line keeps the grid's column width.
                repeat(columns - line.size) { Box(Modifier.weight(1f)) }
            }
        }
    }
}

/** The words of a trend's direction, said with its text. */
internal fun pluginTrendWords(direction: PluginTrendDirection, strings: FlareStrings): String = when (direction) {
    PluginTrendDirection.Up -> strings.pluginViewTrendUp
    PluginTrendDirection.Down -> strings.pluginViewTrendDown
    PluginTrendDirection.Flat -> strings.pluginViewTrendFlat
}

/** A trend: an arrow (none when flat) and the text, success up, error down, secondary flat; the direction is said. */
@Composable
internal fun PluginTrendView(trend: PluginTrend) {
    val colors = flareColors()
    val strings = flareStrings()
    val ink = when (trend.direction) {
        PluginTrendDirection.Up -> colors.successText
        PluginTrendDirection.Down -> colors.errorText
        PluginTrendDirection.Flat -> colors.textSecondary
    }
    Row(
        Modifier.semantics(mergeDescendants = true) { contentDescription = "${pluginTrendWords(trend.direction, strings)} ${trend.text}" },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs),
    ) {
        if (trend.direction != PluginTrendDirection.Flat) {
            Box(Modifier.rotate(if (trend.direction == PluginTrendDirection.Up) 180f else 0f)) {
                FlareIcon("arrow-down", size = 12.dp, tint = ink)
            }
        }
        Text(trend.text, color = ink, fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.Medium)
    }
}

/** The colours of a chart's series (and a donut's slices, in turn): the chart tokens `colors.chart.series1..6`, in order, never the status colours. */
@Composable
internal fun pluginChartPalette(): List<Color> {
    val colors = flareColors()
    return listOf(colors.chartSeries1, colors.chartSeries2, colors.chartSeries3, colors.chartSeries4, colors.chartSeries5, colors.chartSeries6)
}

/**
 * A bar, line or donut chart over resolved points, drawn on a [Canvas] with kit tokens; the empty text when no series has
 * a point. Several series name their colours in a legend; a donut names its points.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun PluginChartBlockView(block: PluginChartBlock) {
    val colors = flareColors()
    val strings = flareStrings()
    val palette = pluginChartPalette()
    if (!block.hasPoints) {
        Text(block.emptyText?.takeIf { it.isNotEmpty() } ?: strings.pluginViewEmpty, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd)
        return
    }
    Column(
        Modifier.fillMaxWidth().semantics(mergeDescendants = true) { contentDescription = PluginChartRules.summary(block) },
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        if (block.chartKind == PluginChartKind.Donut) {
            val slices = PluginChartRules.donutSlices(block.series.firstOrNull()?.points.orEmpty())
            val track = colors.bgTertiary
            Canvas(Modifier.fillMaxWidth().height(140.dp)) {
                val side = min(size.width, size.height)
                val ring = side * 0.18f
                val diameter = side - ring
                val topLeft = Offset((size.width - diameter) / 2, (size.height - diameter) / 2)
                drawArc(track, 0f, 360f, false, topLeft, Size(diameter, diameter), style = Stroke(ring))
                slices.forEach { slice ->
                    drawArc(palette[slice.index % palette.size], (slice.start * 360 - 90).toFloat(), (slice.sweep * 360).toFloat(), false,
                        topLeft, Size(diameter, diameter), style = Stroke(ring))
                }
            }
        } else {
            val series = block.series.filter { it.points.isNotEmpty() }
            val (low, high) = PluginChartRules.range(series)
            val labels = PluginChartRules.labels(series)
            val axis = colors.borderSecondary
            val line = block.chartKind == PluginChartKind.Line
            Canvas(Modifier.fillMaxWidth().height(120.dp)) {
                fun y(value: Double): Float = size.height - ((value - low) / (high - low)).toFloat() * size.height
                drawLine(axis, Offset(0f, y(0.0)), Offset(size.width, y(0.0)), strokeWidth = 1.dp.toPx())
                val slot = size.width / max(labels.size, 1)
                series.forEachIndexed { s, item ->
                    val color = palette[s % palette.size]
                    if (line) {
                        val path = Path()
                        item.points.forEachIndexed { i, point ->
                            val x = slot * (i + 0.5f)
                            if (i == 0) path.moveTo(x, y(point.value)) else path.lineTo(x, y(point.value))
                        }
                        drawPath(path, color, style = Stroke(2.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round))
                        if (item.points.size == 1) drawCircle(color, 3.dp.toPx(), Offset(slot * 0.5f, y(item.points[0].value)))
                    } else {
                        val group = slot * 0.7f
                        val width = group / series.size
                        item.points.forEachIndexed { i, point ->
                            val x = slot * i + (slot - group) / 2 + width * s
                            val top = min(y(point.value), y(0.0))
                            drawRoundRect(color, Offset(x + 1f, top), Size(max(width - 2f, 1f), abs(y(point.value) - y(0.0))),
                                CornerRadius(min(FlareSizes.radiusXs.toPx(), width / 2)))
                        }
                    }
                }
            }
            if (labels.isNotEmpty()) Row(Modifier.fillMaxWidth()) {
                labels.forEachIndexed { index, label ->
                    // Long series keep every fourth label so the axis stays legible.
                    Text(if (labels.size > 12 && index % 4 != 0) "" else label, color = colors.textTertiary, fontSize = FlareSizes.fontSizeXs,
                        maxLines = 1, textAlign = TextAlign.Center, modifier = Modifier.weight(1f))
                }
            }
        }
        val legend: List<Pair<String, String?>> = when {
            block.chartKind == PluginChartKind.Donut -> block.series.firstOrNull()?.points.orEmpty().map { it.label to it.text }
            block.series.size > 1 -> block.series.map { (it.label ?: "") to null }
            else -> emptyList()
        }
        if (legend.isNotEmpty()) FlowRow(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
            legend.forEachIndexed { index, (label, text) ->
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs)) {
                    Box(Modifier.size(8.dp).clip(CircleShape).background(palette[index % palette.size]))
                    Text(label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
                    text?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeSm) }
                }
            }
        }
    }
}

/**
 * A picture in its fixed frame, asked of the host ([resolveImage]); while it loads or when it cannot be shown the frame
 * keeps its ratio and says so. [PluginImageBlock.alt] is what a screen reader says.
 */
/**
 * The address of a resolved image the kit draws: what the host fetched or keeps on the device (https:, file:, content:,
 * an absolute path, data:image), never a page, a script or plain http; anything else reads as unavailable.
 */
internal fun pluginImageAddress(url: String): String? {
    val lower = url.trim().lowercase()
    val allowed = listOf("https://", "file://", "content://", "data:image/").any { lower.startsWith(it) } ||
        (lower.startsWith("/") && !lower.startsWith("//"))
    return url.trim().takeIf { allowed }
}

@Composable
internal fun PluginImageBlockView(block: PluginImageBlock, resolveImage: (suspend (PluginImageSource) -> String?)?) {
    val colors = flareColors()
    val strings = flareStrings()
    var url by remember(block.source) { mutableStateOf<String?>(null) }
    var failed by remember(block.source) { mutableStateOf(false) }
    LaunchedEffect(block.source, resolveImage) {
        val resolve = resolveImage ?: return@LaunchedEffect
        url = runCatching { resolve(block.source) }.getOrNull()?.let(::pluginImageAddress)
        failed = url == null
    }
    val shape = RoundedCornerShape(FlareSizes.radiusMd)
    val unavailable: @Composable () -> Unit = {
        Column(Modifier.fillMaxSize().padding(FlareSizes.spacingSm), horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs, Alignment.CenterVertically)) {
            FlareIcon("image", size = FlareSizes.iconSizeMd, tint = colors.textTertiary)
            Text(strings.pluginViewImageUnavailable, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, textAlign = TextAlign.Center)
        }
    }
    val spinner: @Composable () -> Unit = {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeMd), color = colors.primaryText, strokeWidth = 2.dp)
        }
    }
    Box(
        Modifier.fillMaxWidth().aspectRatio(block.aspect.ratio).clip(shape).background(colors.bgSecondary)
            .semantics(mergeDescendants = true) { contentDescription = block.alt; role = Role.Image },
    ) {
        val shown = url
        when {
            shown != null -> SubcomposeAsyncImage(model = shown, contentDescription = null, contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(), loading = { spinner() }, error = { unavailable() })
            failed || resolveImage == null -> unavailable()
            else -> spinner()
        }
    }
}

/**
 * A QR code in the kit frame (dark on light whatever the theme), its label above and caption below. Once its expiry has
 * come the code is covered and says so, and a block with a refresh then offers the refresh key, which hands the host the
 * query to run ([onRefresh]). It redraws at the expiry.
 */
@Composable
internal fun PluginQrBlockView(block: PluginQrBlock, onRefresh: ((PluginQrRefresh) -> Unit)?, disabled: Boolean) {
    val colors = flareColors()
    val strings = flareStrings()
    // `expiresAtMs` is the server's clock, so now is the server's too (spec/server-clock-vectors.json).
    var now by remember(block) { mutableLongStateOf(FlareServerClock.nowMs()) }
    LaunchedEffect(block) {
        val wait = block.refreshDelay(FlareServerClock.nowMs()) ?: return@LaunchedEffect
        delay(wait)
        now = FlareServerClock.nowMs()
    }
    val symbol = remember(block.value) { block.value.takeIf { it.isNotEmpty() }?.let(QrEncoder::encodeText) }
    val expired = block.expired(now)
    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        block.label?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.SemiBold) }
        Box(Modifier.widthIn(max = 200.dp)) {
            FlareQrFrame(symbol = symbol, label = block.label ?: strings.qrCode)
            if (expired) Box(
                Modifier.matchParentSize().clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgPrimary.copy(alpha = 0.92f))
                    .padding(FlareSizes.spacingSm),
                contentAlignment = Alignment.Center,
            ) {
                Text(strings.pluginViewQrExpired, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.Medium,
                    textAlign = TextAlign.Center)
            }
        }
        block.caption?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, textAlign = TextAlign.Center) }
        // Refresh is offered once the code has expired, as in every kit.
        val refresh = block.refresh
        if (expired && refresh != null && onRefresh != null) {
            Button(label = strings.pluginViewQrRefresh, variant = FlareButtonVariant.Primary,
                size = FlareControlSize.Sm, disabled = disabled, icon = "refresh", onClick = { onRefresh(refresh) })
        }
    }
}

/** The ink of a hero's value. */
@Composable
internal fun pluginHeroColor(tone: PluginHeroTone): Color {
    val colors = flareColors()
    return when (tone) {
        PluginHeroTone.Neutral -> colors.textPrimary
        PluginHeroTone.Positive -> colors.successText
        PluginHeroTone.Warning -> colors.warningText
        // R10: the lead amount is never brand purple.
        PluginHeroTone.Brand -> colors.textPrimary
    }
}

/** The test tag of a maskable hero's eye toggle (rules.heroMask). */
internal const val PLUGIN_HERO_MASK_TAG = "flare-plugin-hero-mask"

/** The lead figure of a page: the label, the value large, the subtitle and up to 3 keys it owns, the first primary. */
@Composable
internal fun PluginHeroBlockView(block: PluginHeroBlock, busyActionId: String?, disabled: Boolean, onAction: ((PluginViewAction) -> Unit)?) {
    val colors = flareColors()
    val strings = flareStrings()
    val locale = flareLocale()
    // A maskable hero starts shown; the eye hides it for this view only.
    var hidden by remember(block) { mutableStateOf(false) }
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
        if (!block.label.isNullOrEmpty() || block.maskable) Row(verticalAlignment = Alignment.CenterVertically) {
            block.label?.takeIf { it.isNotEmpty() }?.let {
                Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd, modifier = Modifier.weight(1f, fill = false))
            }
            if (block.maskable) {
                // R10: the eye is a toggle (pressed while the balance is hidden), as the account view's.
                Box(Modifier.testTag(PLUGIN_HERO_MASK_TAG)) {
                    FlareIconControl(label = if (hidden) strings.accountShowBalance else strings.accountHideBalance, onClick = { hidden = !hidden }, checked = hidden) {
                        FlareIcon(if (hidden) "eye-off" else "eye", size = FlareSizes.iconSizeMd, tint = colors.textSecondary)
                    }
                }
            }
        }
        val shown = PluginFormatRules.text(block.value, block.format, strings)
        Text(
            if (block.maskable && hidden) PluginViewFormat.MASKED_VALUE else shown,
            color = pluginHeroColor(block.tone),
            // R10: component.amountHeroFontSize 32/700, tabular for an amount; hidden reads "balance hidden".
            fontSize = FlareSizes.componentAmountHeroFontSize.value.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis,
            modifier = Modifier.semantics {
                // R11: an amount reads its currency's name, never the bare symbol.
                contentDescription = if (block.maskable && hidden) strings.accountBalanceHidden
                else listOfNotNull(block.label, if (block.amount) FlarePaymentRules.spokenAmount(shown, locale) else shown).joinToString(" ")
            },
            style = if (block.amount) androidx.compose.ui.text.TextStyle(fontFeatureSettings = "tnum") else androidx.compose.ui.text.TextStyle.Default,
        )
        block.subtitle?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm) }
        if (block.actions.isNotEmpty()) Row(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingXs), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            block.actions.forEachIndexed { index, action ->
                Box(Modifier.weight(1f)) {
                    Button(
                        label = action.label,
                        variant = when {
                            action.style == PluginActionStyle.Danger -> FlareButtonVariant.Danger
                            index == 0 -> FlareButtonVariant.Primary
                            else -> FlareButtonVariant.Secondary
                        },
                        size = FlareControlSize.Sm, loading = busyActionId == action.id,
                        disabled = (disabled && busyActionId != action.id) || onAction == null, block = true,
                        onClick = { onAction?.invoke(action) },
                    )
                }
            }
        }
    }
}

/** The words of a step's state, said with its label. */
internal fun pluginStepWords(state: PluginStepState, strings: FlareStrings): String = when (state) {
    PluginStepState.Pending -> strings.pluginViewStepPending
    PluginStepState.Current -> strings.pluginViewStepCurrent
    PluginStepState.Done -> strings.pluginViewStepDone
    PluginStepState.Failed -> strings.pluginViewStepFailed
}

/** §12.5: what a step reads — "第 N 步，共 M 步", then its label and state. */
internal fun pluginStepSpoken(step: PluginStep, index: Int, count: Int, strings: FlareStrings): String =
    strings.pluginViewStepPosition.replace("{index}", (index + 1).toString()).replace("{count}", count.toString()) +
        ", ${step.label}, ${pluginStepWords(step.state, strings)}"

/**
 * Steps in a row: a 20 marker per step (done: a check, failed: a cross, current: the brand ring round its number,
 * pending: an outline round its number — §12.5, Vue) joined by a line, the label under each; each says its state.
 */
@Composable
internal fun PluginStepsBlockView(block: PluginStepsBlock) {
    val colors = flareColors()
    val strings = flareStrings()
    // §12.5: each step reads its place in the row ("step N of M" through the platform's collection words) and its state.
    Row(
        Modifier.fillMaxWidth().semantics { collectionInfo = CollectionInfo(rowCount = 1, columnCount = block.items.size) },
        verticalAlignment = Alignment.Top,
    ) {
        block.items.forEachIndexed { index, step ->
            Column(
                Modifier.weight(1f).semantics(mergeDescendants = true) {
                    contentDescription = pluginStepSpoken(step, index, block.items.size, strings)
                    collectionItemInfo = CollectionItemInfo(rowIndex = 0, rowSpan = 1, columnIndex = index, columnSpan = 1)
                },
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
            ) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    val before = if (index > 0) block.items[index - 1].state == PluginStepState.Done else null
                    val after = if (index < block.items.lastIndex) step.state == PluginStepState.Done else null
                    Box(Modifier.weight(1f).height(2.dp).background(when (before) { null -> Color.Transparent; true -> colors.primary; false -> colors.borderSecondary }))
                    PluginStepMarker(step.state, index + 1)
                    Box(Modifier.weight(1f).height(2.dp).background(when (after) { null -> Color.Transparent; true -> colors.primary; false -> colors.borderSecondary }))
                }
                Text(
                    step.label, fontSize = FlareSizes.fontSizeSm, textAlign = TextAlign.Center,
                    fontWeight = if (step.state == PluginStepState.Current) FontWeight.Medium else FontWeight.Normal,
                    color = when (step.state) {
                        PluginStepState.Current -> colors.textPrimary
                        PluginStepState.Failed -> colors.errorText
                        else -> colors.textSecondary
                    },
                )
            }
        }
    }
}

@Composable
private fun PluginStepMarker(state: PluginStepState, number: Int) {
    val colors = flareColors()
    val side = 20.dp
    when (state) {
        PluginStepState.Done -> Box(Modifier.size(side).clip(CircleShape).background(colors.primary), contentAlignment = Alignment.Center) {
            FlareIcon("check", size = 12.dp, tint = Color.White)
        }
        PluginStepState.Current -> PluginStepNumber(number, colors.primary, colors.primaryText)
        PluginStepState.Failed -> Box(Modifier.size(side).clip(CircleShape).background(colors.error), contentAlignment = Alignment.Center) {
            FlareIcon("close", size = 11.dp, tint = Color.White)
        }
        PluginStepState.Pending -> PluginStepNumber(number, colors.borderSecondary, colors.textTertiary)
    }
}

/** A step's number in a 2-wide ring on the page colour (Vue `.flare-plugin-steps__marker`). */
@Composable
private fun PluginStepNumber(number: Int, ring: Color, ink: Color) {
    Box(Modifier.size(20.dp).clip(CircleShape).background(flareColors().bgPrimary).border(2.dp, ring, CircleShape), contentAlignment = Alignment.Center) {
        Text(number.toString(), color = ink, fontSize = FlareSizes.fontSizeXs)
    }
}

/** A banner: the kit status banner in its tone, with the action it owns as the banner's key. */
@Composable
internal fun PluginBannerBlockView(block: PluginBannerBlock, disabled: Boolean, onAction: ((PluginViewAction) -> Unit)?) {
    val action = block.action?.takeIf { onAction != null && !disabled }
    StatusBanner(text = block.text, tone = block.tone.status, actionText = action?.label,
        onAction = action?.let { owned -> { onAction?.invoke(owned); Unit } })
}

/**
 * A timeline: a dot and a line per item, its time (as the time blocks write it), title, detail and status badge; the
 * empty text when it has no item.
 */
@Composable
internal fun PluginTimelineBlockView(block: PluginTimelineBlock) {
    val colors = flareColors()
    val strings = flareStrings()
    if (block.items.isEmpty()) {
        // R8: an empty data block is the compact empty state.
        EmptyState(title = block.emptyText?.takeIf { it.isNotEmpty() } ?: strings.pluginViewEmpty, icon = "clock", compact = true)
        return
    }
    // The server's clock, like every other plugin time (spec/server-clock-vectors.json).
    val now = remember(block) { FlareServerClock.nowMs() }
    Column(Modifier.fillMaxWidth()) {
        block.items.forEachIndexed { index, item ->
            Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                Column(Modifier.width(8.dp).fillMaxHeight(), horizontalAlignment = Alignment.CenterHorizontally) {
                    Box(Modifier.padding(top = 6.dp).size(8.dp).clip(CircleShape).background(if (index == 0) colors.primary else colors.borderHover))
                    if (index < block.items.lastIndex) Box(Modifier.width(1.dp).weight(1f).background(colors.borderSecondary))
                }
                Column(
                    Modifier.weight(1f).padding(bottom = if (index < block.items.lastIndex) FlareSizes.spacingMd else 0.dp)
                        .semantics(mergeDescendants = true) {},
                    verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                        Text(item.title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
                        item.status?.let { PluginBadgeTag(it) }
                    }
                    item.detail?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm) }
                    Text(PluginViewFormat.dateTime(item.atMs, now, strings, null), color = colors.textTertiary, fontSize = FlareSizes.fontSizeXs)
                }
            }
        }
    }
}
