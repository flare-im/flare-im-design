package com.flare.im.ui

import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset

// The resolved plugin view (core SDK `ResolvedPluginView`, flare-plugin-protocol ui.rs / blocks.rs / inputs.rs) as
// data. The kit renders this shape and reads no paths; [PluginViewModel.fromJson] reads the core's camelCase JSON as it
// is and skips what a newer protocol adds (unknown block kinds, input kinds and keys). `spec/plugin-view-vectors.json`
// holds the shapes and the render facts the four kits share.

/** A label/value row (v1 `fields`, and the `fields` block). */
data class PluginViewField(val label: String, val value: String)

/** How an action key is drawn; none is the secondary key. */
enum class PluginActionStyle(val wire: String) {
    Primary("primary"), Danger("danger");

    companion object {
        fun fromWire(value: String?): PluginActionStyle? = entries.firstOrNull { it.wire == value }
    }
}

/**
 * A resolved action. Its `target` and `input` stay with the core: the kit hands back the opaque [id] only. [confirm] is
 * asked first in the kit DangerConfirm; [form] lists the input ids [PluginForm] collects first.
 */
data class PluginViewAction(
    val id: String,
    val label: String,
    val style: PluginActionStyle? = null,
    val confirm: String? = null,
    val form: List<String>? = null,
)

/** Semantic colour of a status, a note or a people group, drawn with the `*Text` tokens. */
enum class PluginTone(val wire: String) {
    Neutral("neutral"), Info("info"), Success("success"), Warning("warning"), Danger("danger");

    companion object {
        fun fromWire(value: String?): PluginTone? = entries.firstOrNull { it.wire == value }
    }
}

enum class PluginTextStyle(val wire: String) {
    Body("body"), Title("title"), Secondary("secondary");

    companion object {
        fun fromWire(value: String?): PluginTextStyle = entries.firstOrNull { it.wire == value } ?: Body
    }
}

/** One option of a choices block; [count] and [percent] only while results show. */
data class PluginChoice(
    val index: Int,
    val label: String,
    val selected: Boolean = false,
    val count: Int? = null,
    val percent: Int? = null,
)

/** One display block, by `kind`. `rows` (admin tables) is the Vue kit's only; a native kit skips it with any kind it does not know. */
sealed interface PluginBlock {
    val kind: String
}

/** `text`: a paragraph, cut at [maxLines] with an expand key. */
data class PluginTextBlock(val text: String, val maxLines: Int? = null, val style: PluginTextStyle = PluginTextStyle.Body) : PluginBlock {
    override val kind: String get() = "text"
}

data class PluginFieldsBlock(val fields: List<PluginViewField>) : PluginBlock {
    override val kind: String get() = "fields"
}

/** `choices`: a poll or an RSVP. [action] is the block's own submit action (never among the footer actions). */
data class PluginChoicesBlock(
    val options: List<PluginChoice>,
    val multiple: Boolean = false,
    val voted: Boolean = false,
    val closed: Boolean = false,
    val showResults: Boolean = false,
    val total: Int? = null,
    val inputName: String = "selection",
    val action: PluginViewAction? = null,
) : PluginBlock {
    override val kind: String get() = "choices"

    /** The indices the view says the viewer chose, ascending. */
    val selection: List<Int> get() = options.filter { it.selected }.map { it.index }.sorted()
}

/** One entry of an entries block; [index] is its position in the data, from 1. */
data class PluginEntry(val index: Int, val text: String, val name: String? = null, val userId: String? = null)

/** `entries`: a numbered list (a sign-up chain); [more] offers "see all" (the detail view). */
data class PluginEntriesBlock(
    val items: List<PluginEntry>,
    val numbered: Boolean = true,
    val total: Int = items.size,
    val more: Boolean = false,
    val emptyText: String? = null,
) : PluginBlock {
    override val kind: String get() = "entries"
}

/** One row of a people block: [userIds] is already cut to the block's max. */
data class PluginPeopleGroup(val label: String, val userIds: List<String>, val count: Int = userIds.size, val tone: PluginTone? = null)

data class PluginPeopleBlock(val groups: List<PluginPeopleGroup>) : PluginBlock {
    override val kind: String get() = "people"
}

/** `status`: a badge. */
data class PluginStatusBlock(val label: String? = null, val text: String, val tone: PluginTone = PluginTone.Neutral) : PluginBlock {
    override val kind: String get() = "status"
}

/** `progress`: a bar with "value/total". */
data class PluginProgressBlock(val label: String? = null, val value: Double, val total: Double, val percent: Int) : PluginBlock {
    override val kind: String get() = "progress"
}

/** `time`: an instant or a range in milliseconds, formatted in the device zone; [countdown] counts down to [atMs]. */
data class PluginTimeBlock(val label: String? = null, val atMs: Long, val endMs: Long? = null, val countdown: Boolean = false) : PluginBlock {
    override val kind: String get() = "time"
}

data object PluginDividerBlock : PluginBlock {
    override val kind: String get() = "divider"
}

/** `note`: a tinted note. */
data class PluginNoteBlock(val text: String, val tone: PluginTone? = null) : PluginBlock {
    override val kind: String get() = "note"
}

/** Form input kinds (UiInput). */
enum class PluginInputKind(val wire: String) {
    Text("text"), Textarea("textarea"), Number("number"), Toggle("toggle"), Select("select"), Datetime("datetime"),
    Options("options"), Members("members");

    companion object {
        fun fromWire(value: String?): PluginInputKind? = entries.firstOrNull { it.wire == value }
    }
}

/** One choice of a select input. */
data class PluginInputChoice(val value: String, val label: String)

/**
 * A resolved form input (UiInput): labels translated, `defaultPath` already folded into [default]. [min] / [max] are the
 * number's bounds, or the options' and members' item counts (members max 1 is a single pick); [maxLength] defaults to
 * text 256, textarea 2000, an options item 100. [default] is JSON as [FlareJson] reads it (String, Double, Boolean, List).
 */
data class PluginInput(
    val id: String,
    val kind: PluginInputKind,
    val label: String,
    val required: Boolean = false,
    val placeholder: String? = null,
    val maxLength: Int? = null,
    val min: Double? = null,
    val max: Double? = null,
    val default: Any? = null,
    val choices: List<PluginInputChoice>? = null,
)

/** What is wrong with a submitted value (UiFormIssue). */
enum class PluginFormIssue(val wire: String) {
    Required("required"), Unknown("unknown"), InvalidType("invalidType"), TooLong("tooLong"), OutOfRange("outOfRange"),
    NotAChoice("notAChoice"), TooFewItems("tooFewItems"), TooManyItems("tooManyItems"), InvalidItem("invalidItem"),
    DuplicateItem("duplicateItem");

    companion object {
        fun fromWire(value: String?): PluginFormIssue = entries.firstOrNull { it.wire == value } ?: InvalidType
    }
}

/** One problem with a submitted value (UiFormError), shown under its input. */
data class PluginFormError(val input: String, val issue: PluginFormIssue) {
    companion object {
        /** The core's `[{"input","issue"}]` JSON. */
        fun listFromJson(json: String): List<PluginFormError> =
            (FlareJson.parse(json) as? List<*>).orEmpty().mapNotNull { raw ->
                val map = raw as? Map<*, *> ?: return@mapNotNull null
                val input = map["input"] as? String ?: return@mapNotNull null
                PluginFormError(input, PluginFormIssue.fromWire(map["issue"] as? String))
            }
    }
}

/** What the host's `resolveUser` answers for a user id. */
data class PluginUser(val name: String, val avatarUrl: String? = null)

/** A candidate for a members input. */
data class PluginMember(val userId: String, val name: String, val avatarUrl: String? = null)

/**
 * What `onAction(id, payload)` carries: the chosen option indices (ascending) or the form's values by input id
 * (String, Double, Boolean or a List of String). [toJson] writes it for the core SDK.
 */
data class PluginActionPayload(val selection: List<Int>? = null, val formValues: Map<String, Any?>? = null) {
    fun toJson(): String = pluginJson(buildMap {
        selection?.let { put("selection", it) }
        formValues?.let { put("formValues", it) }
    })

    companion object {
        val Empty = PluginActionPayload()
    }
}

/** A resolved plugin view (core SDK `ResolvedPluginView`). v1 cards (title, fields, actions) read unchanged. */
data class PluginViewModel(
    /** False: only the title shows (a disabled plugin, history). */
    val available: Boolean,
    val title: String,
    val fields: List<PluginViewField> = emptyList(),
    /** Footer actions; block-owned actions are not here. */
    val actions: List<PluginViewAction> = emptyList(),
    /** Display blocks in order; kinds the kit does not know were skipped when reading. */
    val blocks: List<PluginBlock> = emptyList(),
    /** Every input of the document; an action's form names the ones it collects. */
    val inputs: List<PluginInput> = emptyList(),
    /** The contribution has a detail view ("see all"). */
    val detail: Boolean = false,
    /**
     * A detail view's next page: the cursor the host asks the core SDK for ([PluginDetailSheet] draws "load more" with
     * it); null (or blank) on the last page and on cards.
     */
    val nextCursor: String? = null,
) {
    /** The inputs an action's form collects, in the order of `action.form`; ids the view does not hold are dropped. */
    fun formInputs(action: PluginViewAction): List<PluginInput> =
        action.form.orEmpty().mapNotNull { id -> inputs.firstOrNull { it.id == id } }

    companion object {
        /** Reads the core's `ResolvedPluginView` JSON; throws [IllegalArgumentException] on malformed JSON. */
        fun fromJson(json: String): PluginViewModel {
            val root = FlareJson.parse(json) as? Map<*, *> ?: throw IllegalArgumentException("a plugin view is an object")
            return fromMap(root)
        }

        /** Reads a parsed `ResolvedPluginView` (objects as maps, arrays as lists). */
        fun fromMap(map: Map<*, *>): PluginViewModel = PluginViewModel(
            available = map["available"] as? Boolean ?: false,
            title = map["title"] as? String ?: "",
            fields = map.list("fields").mapNotNull { (it as? Map<*, *>)?.field() },
            actions = map.list("actions").mapNotNull { (it as? Map<*, *>)?.action() },
            blocks = map.list("blocks").mapNotNull { (it as? Map<*, *>)?.block() },
            inputs = map.list("inputs").mapNotNull { (it as? Map<*, *>)?.input() },
            detail = map["detail"] as? Boolean ?: false,
            // A blank cursor is the last page.
            nextCursor = (map["nextCursor"] as? String)?.takeIf { it.isNotBlank() },
        )
    }
}

// ── reading the core's JSON ─────────────────────────────────────────────────

private fun Map<*, *>.list(key: String): List<*> = this[key] as? List<*> ?: emptyList<Any?>()
private fun Map<*, *>.string(key: String): String? = this[key] as? String
private fun Map<*, *>.int(key: String): Int? = (this[key] as? Number)?.toInt()
private fun Map<*, *>.double(key: String): Double? = (this[key] as? Number)?.toDouble()
private fun Map<*, *>.bool(key: String): Boolean? = this[key] as? Boolean

private fun Map<*, *>.field(): PluginViewField? {
    val label = string("label") ?: return null
    return PluginViewField(label, string("value") ?: "")
}

private fun Map<*, *>.action(): PluginViewAction? {
    val id = string("id") ?: return null
    val label = string("label") ?: return null
    return PluginViewAction(id, label, PluginActionStyle.fromWire(string("style")), string("confirm"),
        (this["form"] as? List<*>)?.filterIsInstance<String>())
}

private fun Map<*, *>.block(): PluginBlock? = when (string("kind")) {
    "text" -> string("text")?.let { PluginTextBlock(it, int("maxLines"), PluginTextStyle.fromWire(string("style"))) }
    "fields" -> PluginFieldsBlock(list("fields").mapNotNull { (it as? Map<*, *>)?.field() })
    "choices" -> {
        val options = list("options").mapNotNull { raw ->
            val o = raw as? Map<*, *> ?: return@mapNotNull null
            val index = o.int("index") ?: return@mapNotNull null
            PluginChoice(index, o.string("label") ?: return@mapNotNull null, o.bool("selected") ?: false, o.int("count"), o.int("percent"))
        }
        PluginChoicesBlock(options, bool("multiple") ?: false, bool("voted") ?: false, bool("closed") ?: false,
            bool("showResults") ?: false, int("total"), string("inputName") ?: "selection",
            (this["action"] as? Map<*, *>)?.action())
    }
    "entries" -> {
        val items = list("items").mapNotNull { raw ->
            val e = raw as? Map<*, *> ?: return@mapNotNull null
            PluginEntry(e.int("index") ?: 0, e.string("text") ?: "", e.string("name"), e.string("userId"))
        }
        PluginEntriesBlock(items, bool("numbered") ?: true, int("total") ?: items.size, bool("more") ?: false, string("emptyText"))
    }
    "people" -> PluginPeopleBlock(list("groups").mapNotNull { raw ->
        val g = raw as? Map<*, *> ?: return@mapNotNull null
        val ids = g.list("userIds").filterIsInstance<String>()
        PluginPeopleGroup(g.string("label") ?: "", ids, g.int("count") ?: ids.size, PluginTone.fromWire(g.string("tone")))
    })
    "status" -> string("text")?.let { PluginStatusBlock(string("label"), it, PluginTone.fromWire(string("tone")) ?: PluginTone.Neutral) }
    "progress" -> {
        val value = double("value") ?: 0.0
        val total = double("total") ?: 0.0
        PluginProgressBlock(string("label"), value, total, int("percent") ?: if (total > 0) Math.round(value / total * 100).toInt() else 0)
    }
    "time" -> double("atMs")?.let { PluginTimeBlock(string("label"), it.toLong(), double("endMs")?.toLong(), bool("countdown") ?: false) }
    "divider" -> PluginDividerBlock
    "note" -> string("text")?.let { PluginNoteBlock(it, PluginTone.fromWire(string("tone"))) }
    else -> null
}

private fun Map<*, *>.input(): PluginInput? {
    val id = string("id") ?: return null
    val kind = PluginInputKind.fromWire(string("kind")) ?: return null
    return PluginInput(
        id = id, kind = kind, label = string("label") ?: "", required = bool("required") ?: false,
        placeholder = string("placeholder"), maxLength = int("maxLength"), min = double("min"), max = double("max"),
        default = this["default"],
        choices = (this["choices"] as? List<*>)?.mapNotNull { raw ->
            val c = raw as? Map<*, *> ?: return@mapNotNull null
            PluginInputChoice(c.string("value") ?: return@mapNotNull null, c.string("label") ?: "")
        },
    )
}

/** JSON text for the kit's own values: maps, lists, strings, booleans, numbers (whole numbers without a fraction). */
internal fun pluginJson(value: Any?): String = buildString { appendPluginJson(value) }

private fun StringBuilder.appendPluginJson(value: Any?) {
    when (value) {
        null -> append("null")
        is Boolean -> append(value)
        is Number -> {
            val d = value.toDouble()
            if (d.isFinite() && d == Math.floor(d) && Math.abs(d) < 9.007199254740992E15) append(d.toLong()) else append(d)
        }
        is String -> {
            append('"')
            for (c in value) when {
                c == '"' -> append("\\\"")
                c == '\\' -> append("\\\\")
                c == '\n' -> append("\\n")
                c == '\r' -> append("\\r")
                c == '\t' -> append("\\t")
                c < ' ' -> append("\\u").append(c.code.toString(16).padStart(4, '0'))
                else -> append(c)
            }
            append('"')
        }
        is Map<*, *> -> {
            append('{')
            value.entries.forEachIndexed { i, (k, v) ->
                if (i > 0) append(',')
                appendPluginJson(k.toString()); append(':'); appendPluginJson(v)
            }
            append('}')
        }
        is Iterable<*> -> {
            append('[')
            value.forEachIndexed { i, v -> if (i > 0) append(','); appendPluginJson(v) }
            append(']')
        }
        else -> appendPluginJson(value.toString())
    }
}

// ── shared rules (spec/plugin-view-vectors.json → rules) ─────────────────────

/** A countdown's text and when to draw it again (null once the moment has passed). */
internal data class PluginCountdown(val text: String, val refreshMs: Int?)

/** One local calendar minute. */
internal data class PluginWallClock(val year: Int, val month: Int, val day: Int, val hour: Int, val minute: Int)

internal object PluginViewFormat {
    private val MONTHS = listOf("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

    /** The name drawn for a user id the host could not resolve: its last 4 characters (the whole id when shorter). */
    fun fallbackName(userId: String): String = if (userId.length > 4) userId.takeLast(4) else userId

    /** The user drawn for an id: the host's answer, else initials over the fallback name. */
    fun user(userId: String, resolved: Map<String, PluginUser>): PluginUser = resolved[userId] ?: PluginUser(fallbackName(userId))

    /** An entry's name: its own, else the resolved user's, else the fallback; null when it names no one. */
    fun entryName(entry: PluginEntry, resolved: Map<String, PluginUser>): String? {
        entry.name?.takeIf { it.isNotEmpty() }?.let { return it }
        val userId = entry.userId?.takeIf { it.isNotEmpty() } ?: return null
        return user(userId, resolved).name
    }

    /** The user ids a view names whose names come from the host. */
    fun userIds(view: PluginViewModel): List<String> {
        val ids = LinkedHashSet<String>()
        for (block in view.blocks) when (block) {
            is PluginPeopleBlock -> block.groups.forEach { ids.addAll(it.userIds) }
            is PluginEntriesBlock -> block.items.forEach { e ->
                val id = e.userId
                if (!id.isNullOrEmpty() && e.name.isNullOrEmpty()) ids.add(id)
            }
            else -> Unit
        }
        return ids.toList()
    }

    fun votes(count: Int, strings: FlareStrings): String = strings.pluginViewVotes.replace("{count}", count.toString())

    fun seeAll(total: Int, strings: FlareStrings): String = strings.pluginViewSeeAll.replace("{count}", total.toString())

    /**
     * Whether a card draws its own view details key (spec rules.detailKey): the view has a detail, is available and is
     * not embedded, and no entries block shows its see all.
     */
    fun showsDetailKey(view: PluginViewModel, embedded: Boolean): Boolean =
        view.detail && view.available && !embedded && view.blocks.none { it is PluginEntriesBlock && it.more }

    /**
     * The card's view details key: null when it draws none (also without a host [handled] openDetail), else whether
     * it is enabled — it waits while [busy] or an action is in flight.
     */
    fun detailKey(view: PluginViewModel, embedded: Boolean, handled: Boolean, busy: Boolean, busyActionId: String?): Boolean? =
        if (handled && showsDetailKey(view, embedded)) !(busy || busyActionId != null) else null

    /** The line an embedded view (no title row) shows while unavailable: its title, so it still says what it was. */
    fun unavailableLine(view: PluginViewModel, embedded: Boolean): String? =
        view.title.takeIf { embedded && !view.available && it.isNotEmpty() }

    /** The line under a choices block: ended, and the total while results show. */
    fun choicesFooter(block: PluginChoicesBlock, strings: FlareStrings): String? {
        val parts = buildList {
            if (block.closed) add(strings.pluginViewEnded)
            if (block.showResults && block.total != null) add(votes(block.total, strings))
        }
        return parts.takeIf { it.isNotEmpty() }?.joinToString(" · ")
    }

    fun percentText(option: PluginChoice, showResults: Boolean): String? =
        if (showResults && option.percent != null) "${option.percent}%" else null

    fun votesText(option: PluginChoice, showResults: Boolean, strings: FlareStrings): String? =
        if (showResults && option.count != null) votes(option.count, strings) else null

    /** A number as a progress block writes it: whole numbers without a fraction. */
    fun number(value: Double): String {
        if (value == Math.floor(value) && Math.abs(value) < 1e15) return value.toLong().toString()
        return String.format(java.util.Locale.ROOT, "%.2f", value).trimEnd('0').trimEnd('.')
    }

    fun progressText(block: PluginProgressBlock): String = "${number(block.value)}/${number(block.total)}"

    /** style danger → the danger key, primary → the primary key, none → the secondary key. */
    fun variant(action: PluginViewAction): FlareButtonVariant = when (action.style) {
        PluginActionStyle.Danger -> FlareButtonVariant.Danger
        PluginActionStyle.Primary -> FlareButtonVariant.Primary
        null -> FlareButtonVariant.Secondary
    }

    fun wallClock(ms: Long, utcOffsetMinutes: Int?): PluginWallClock {
        val instant = Instant.ofEpochMilli(ms)
        val offset = utcOffsetMinutes?.let { ZoneOffset.ofTotalSeconds(it * 60) } ?: ZoneId.systemDefault().rules.getOffset(instant)
        val local = instant.atOffset(offset)
        return PluginWallClock(local.year, local.monthValue, local.dayOfMonth, local.hour, local.minute)
    }

    private fun pad2(n: Int): String = n.toString().padStart(2, '0')

    /** Renders a date-time pattern: y year, M month, MMM Jan..Dec, d day, HH hour, mm minute; the rest is literal. */
    fun render(pattern: String, at: PluginWallClock): String {
        val out = StringBuilder()
        var i = 0
        while (i < pattern.length) {
            val c = pattern[i]
            if (c !in "yMdHm") { out.append(c); i++; continue }
            var j = i
            while (j < pattern.length && pattern[j] == c) j++
            when (val run = pattern.substring(i, j)) {
                "y" -> out.append(at.year)
                "M" -> out.append(at.month)
                "MMM" -> out.append(MONTHS[(at.month - 1).coerceIn(0, 11)])
                "d" -> out.append(at.day)
                "HH" -> out.append(pad2(at.hour))
                "mm" -> out.append(pad2(at.minute))
                else -> out.append(run)
            }
            i = j
        }
        return out.toString()
    }

    /** One instant as the time blocks write it: the year only outside the current one. */
    fun dateTime(ms: Long, nowMs: Long, strings: FlareStrings, utcOffsetMinutes: Int?): String {
        val at = wallClock(ms, utcOffsetMinutes)
        val now = wallClock(nowMs, utcOffsetMinutes)
        return render(if (at.year == now.year) strings.pluginViewDateTimeFormat else strings.pluginViewDateTimeYearFormat, at)
    }

    /** A time block's text: an instant, a range on one day ("…14:00–15:00") or across days ("… – …"). */
    fun timeText(atMs: Long, endMs: Long?, nowMs: Long, strings: FlareStrings, utcOffsetMinutes: Int?): String {
        val start = dateTime(atMs, nowMs, strings, utcOffsetMinutes)
        if (endMs == null) return start
        val a = wallClock(atMs, utcOffsetMinutes)
        val b = wallClock(endMs, utcOffsetMinutes)
        if (a.year == b.year && a.month == b.month && a.day == b.day) return "$start–${pad2(b.hour)}:${pad2(b.minute)}"
        return "$start – ${dateTime(endMs, nowMs, strings, utcOffsetMinutes)}"
    }

    /**
     * The countdown to [atMs]: mm:ss under an hour (each second), hours and minutes under a day, days and hours beyond
     * (each minute), and the deadline-passed text once it is reached.
     */
    fun countdown(atMs: Long, nowMs: Long, strings: FlareStrings): PluginCountdown {
        val r = atMs - nowMs
        if (r <= 0) return PluginCountdown(strings.pluginViewDeadlinePassed, null)
        fun unit(template: String, n: Long) = template.replace("{n}", n.toString())
        if (r < 3_600_000) {
            val s = (r / 1000).toInt()
            return PluginCountdown(strings.pluginViewRemaining.replace("{time}", "${pad2(s / 60)}:${pad2(s % 60)}"), 1000)
        }
        val time = if (r < 86_400_000) {
            val h = r / 3_600_000
            val m = (r % 3_600_000) / 60_000
            unit(strings.myInviteUnitHours, h) + if (m > 0) " " + unit(strings.myInviteUnitMinutes, m) else ""
        } else {
            val d = r / 86_400_000
            val h = (r % 86_400_000) / 3_600_000
            unit(strings.myInviteUnitDays, d) + if (h > 0) " " + unit(strings.myInviteUnitHours, h) else ""
        }
        return PluginCountdown(strings.pluginViewRemaining.replace("{time}", time), 60_000)
    }

    /**
     * How long until the countdown's text changes: the next whole second (under an hour) or minute, so the text turns
     * over on the boundary; null once it has passed.
     */
    fun countdownDelay(atMs: Long, nowMs: Long): Long? {
        val r = atMs - nowMs
        if (r <= 0) return null
        val step = if (r < 3_600_000) 1000L else 60_000L
        return r % step + 1
    }
}

/**
 * The choices blocks' local state: the multiple-choice drafts (by block position) and the submit awaiting the host. A
 * submitted selection shows at once and pauses the block until a new view arrives (the truth) or the host reports a
 * failure (`error` turns non-empty, or the host settles — `settleToken` moves, or `busyActionId` leaves the action —
 * while `error` or `formErrors` is set), which reverts it. A clean settle keeps the mark until the new view.
 */
internal data class PluginChoicesInteraction(
    val drafts: Map<Int, List<Int>> = emptyMap(),
    val pending: Pending? = null,
) {
    data class Pending(val block: Int, val actionId: String, val selection: List<Int>)

    fun isInteractive(block: PluginChoicesBlock, index: Int, locked: Boolean): Boolean =
        block.action != null && !block.closed && !locked && pending?.block != index

    /** The indices drawn as chosen: the submit awaiting the host, else the draft, else the view's. */
    fun shown(block: PluginChoicesBlock, index: Int): List<Int> {
        pending?.takeIf { it.block == index }?.let { return it.selection }
        if (block.multiple && block.action != null && !block.closed) return drafts[index] ?: block.selection
        return block.selection
    }

    /** The multiple submit key: a non-empty draft that differs from the view's selection. */
    fun submitEnabled(block: PluginChoicesBlock, index: Int): Boolean {
        val draft = drafts[index] ?: block.selection
        return draft.isNotEmpty() && draft.toSet() != block.selection.toSet()
    }

    /**
     * A tap on an option: the next state and, for a single choice, the selection to submit (none for the only selected
     * option). A multiple choice toggles its draft.
     */
    fun tap(block: PluginChoicesBlock, index: Int, option: Int, locked: Boolean): Pair<PluginChoicesInteraction, List<Int>?> {
        if (!isInteractive(block, index, locked)) return this to null
        if (block.multiple) {
            val draft = (drafts[index] ?: block.selection).toMutableSet()
            if (!draft.remove(option)) draft.add(option)
            return copy(drafts = drafts + (index to draft.sorted())) to null
        }
        return this to (if (block.selection == listOf(option)) null else listOf(option))
    }

    /** The multiple draft to submit, ascending; null while the key is off. */
    fun submission(block: PluginChoicesBlock, index: Int, locked: Boolean): List<Int>? {
        if (!block.multiple || !isInteractive(block, index, locked) || !submitEnabled(block, index)) return null
        return (drafts[index] ?: block.selection).sorted()
    }

    /** The selection went to the host: it shows until settled. */
    fun submitted(index: Int, actionId: String, selection: List<Int>): PluginChoicesInteraction =
        copy(pending = Pending(index, actionId, selection.sorted()))

    /** A new view is the truth. */
    fun viewChanged(): PluginChoicesInteraction = PluginChoicesInteraction()

    fun revert(): PluginChoicesInteraction {
        val p = pending ?: return this
        return PluginChoicesInteraction(drafts = drafts - p.block, pending = null)
    }

    fun errorChanged(old: String?, new: String?): PluginChoicesInteraction =
        if (!new.isNullOrEmpty() && new != old) revert() else this

    /** The fallback settle: `busyActionId` left the pending action. */
    fun busyActionChanged(
        old: String?,
        new: String?,
        error: String?,
        formErrors: List<PluginFormError> = emptyList(),
    ): PluginChoicesInteraction =
        if (old != null && old != new && pending?.actionId == old) settled(error, formErrors) else this

    /**
     * The host settled the action (`settleToken` moved): a result with an error or form errors reverts the submit, read
     * now, so the same error text as before still reverts; a clean one keeps the mark until the new view.
     */
    fun settled(error: String?, formErrors: List<PluginFormError> = emptyList()): PluginChoicesInteraction =
        if (pluginResultFailed(error, formErrors)) revert() else this

    /**
     * One host change, seen whole: a new error reverts; `settleToken` moving or `busyActionId` leaving the pending
     * action settles. Signals arriving together settle once (settling is idempotent).
     */
    fun hostChanged(old: PluginHostSignal, new: PluginHostSignal): PluginChoicesInteraction {
        var next = errorChanged(old.error, new.error)
        if (new.settleToken != old.settleToken) next = next.settled(new.error, new.formErrors)
        return next.busyActionChanged(old.busyActionId, new.busyActionId, new.error, new.formErrors)
    }
}

// ── settling ────────────────────────────────────────────────────────────────

/** A result reports a failure: an error text or form errors. */
internal fun pluginResultFailed(error: String?, formErrors: List<PluginFormError>): Boolean =
    !error.isNullOrEmpty() || formErrors.isNotEmpty()

/**
 * What the host reports about the card's actions, observed as one value so every field of a change is read together:
 * a host may set the error, clear `busyActionId` and move `settleToken` in a single update.
 */
internal data class PluginHostSignal(
    val busy: Boolean = false,
    val busyActionId: String? = null,
    val error: String? = null,
    val formErrors: List<PluginFormError> = emptyList(),
    val settleToken: Int = 0,
) {
    val failed: Boolean get() = pluginResultFailed(error, formErrors)
}

/** What a host change does to an open form the user submitted: nothing yet, close it (a clean result) or keep it. */
internal enum class PluginFormSettle { Wait, Close, Keep }

/**
 * The form of [actionId] settles when `settleToken` moves, or (the fallback) when the card or that action stops being
 * busy: it closes on a clean result and stays open with the error or the form errors.
 */
internal fun pluginFormSettle(old: PluginHostSignal, new: PluginHostSignal, actionId: String): PluginFormSettle {
    val wasPending = old.busy || old.busyActionId == actionId
    val pending = new.busy || new.busyActionId == actionId
    if (new.settleToken == old.settleToken && !(wasPending && !pending)) return PluginFormSettle.Wait
    return if (new.failed) PluginFormSettle.Keep else PluginFormSettle.Close
}

// ── forms ───────────────────────────────────────────────────────────────────

internal object PluginFormRules {
    fun maxLength(input: PluginInput): Int? = input.maxLength ?: when (input.kind) {
        PluginInputKind.Text -> 256
        PluginInputKind.Textarea -> 2000
        PluginInputKind.Options -> 100
        else -> null
    }

    /** The most option rows or members of an input (options 50, members 500 when absent). */
    fun maxItems(input: PluginInput): Int = input.max?.toInt() ?: when (input.kind) {
        PluginInputKind.Options -> 50
        PluginInputKind.Members -> 500
        else -> 1
    }

    /** The fewest option rows the editor keeps. */
    fun minRows(input: PluginInput): Int = maxOf((input.min ?: 1.0).toInt(), 1)

    /** Characters as the core counts them: Unicode code points. */
    fun length(text: String): Int = text.codePointCount(0, text.length)

    /** JavaScript's `trim`: whitespace and line terminators at both ends. */
    fun trimmed(text: String): String = text.trim { it.isWhitespace() || it == '﻿' || it == ' ' }

    private fun text(value: Any?): String = when (value) {
        is String -> value
        is Number -> PluginViewFormat.number(value.toDouble())
        is Boolean -> value.toString()
        else -> ""
    }

    /** The editable draft of one input: `values[id]`, else its default. */
    fun draftValue(input: PluginInput, values: Map<String, Any?>?): Any? {
        val raw = if (values != null && values.containsKey(input.id)) values[input.id] else input.default
        return when (input.kind) {
            PluginInputKind.Toggle -> when (raw) {
                is Boolean -> raw
                is Number -> raw.toDouble() != 0.0
                is String -> raw.isNotEmpty()
                null -> false
                else -> true
            }
            PluginInputKind.Options -> (raw as? List<*>)?.map { text(it) } ?: List(minRows(input)) { "" }
            PluginInputKind.Members -> (raw as? List<*>)?.filterIsInstance<String>() ?: emptyList<String>()
            PluginInputKind.Text, PluginInputKind.Textarea, PluginInputKind.Select -> raw as? String ?: ""
            PluginInputKind.Number, PluginInputKind.Datetime -> (raw as? Number)?.toDouble()?.takeIf { it.isFinite() }
        }
    }

    fun draft(inputs: List<PluginInput>, values: Map<String, Any?>?): Map<String, Any?> =
        LinkedHashMap<String, Any?>().apply { inputs.forEach { putIfAbsent(it.id, draftValue(it, values)) } }

    private fun items(value: Any?): List<String> = (value as? List<*>).orEmpty().map { trimmed(text(it)) }.filter { it.isNotEmpty() }

    /** The client's light check of one input: required and length. */
    fun check(input: PluginInput, draft: Any?): PluginFormIssue? {
        val limit = maxLength(input)
        return when (input.kind) {
            PluginInputKind.Text, PluginInputKind.Textarea -> {
                val value = trimmed(draft as? String ?: "")
                when {
                    input.required && value.isEmpty() -> PluginFormIssue.Required
                    limit != null && length(value) > limit -> PluginFormIssue.TooLong
                    else -> null
                }
            }
            PluginInputKind.Number, PluginInputKind.Datetime -> if (input.required && draft !is Number) PluginFormIssue.Required else null
            PluginInputKind.Select -> if (input.required && (draft as? String).isNullOrEmpty()) PluginFormIssue.Required else null
            PluginInputKind.Options -> {
                val rows = items(draft)
                when {
                    input.required && rows.isEmpty() -> PluginFormIssue.Required
                    limit != null && rows.any { length(it) > limit } -> PluginFormIssue.TooLong
                    else -> null
                }
            }
            PluginInputKind.Members -> if (input.required && (draft as? List<*>).isNullOrEmpty()) PluginFormIssue.Required else null
            PluginInputKind.Toggle -> null
        }
    }

    fun check(inputs: List<PluginInput>, draft: Map<String, Any?>): List<PluginFormError> =
        inputs.mapNotNull { input -> check(input, draft[input.id])?.let { PluginFormError(input.id, it) } }

    /** What submit hands over: trimmed text, cleaned option rows, only the inputs with a value. */
    fun values(inputs: List<PluginInput>, draft: Map<String, Any?>): Map<String, Any?> {
        val out = LinkedHashMap<String, Any?>()
        for (input in inputs) {
            val value = draft[input.id]
            when (input.kind) {
                PluginInputKind.Text, PluginInputKind.Textarea -> trimmed(value as? String ?: "").takeIf { it.isNotEmpty() }?.let { out[input.id] = it }
                PluginInputKind.Number, PluginInputKind.Datetime -> (value as? Number)?.toDouble()?.takeIf { it.isFinite() }?.let { out[input.id] = it }
                PluginInputKind.Toggle -> out[input.id] = value as? Boolean ?: false
                PluginInputKind.Select -> (value as? String)?.takeIf { it.isNotEmpty() }?.let { out[input.id] = it }
                PluginInputKind.Options -> items(value).takeIf { it.isNotEmpty() }?.let { out[input.id] = it }
                PluginInputKind.Members -> (value as? List<*>)?.filterIsInstance<String>()?.takeIf { it.isNotEmpty() }?.let { out[input.id] = it }
            }
        }
        return out
    }

    /** The words for one form error under its input. */
    fun issueText(issue: PluginFormIssue, input: PluginInput?, strings: FlareStrings): String = when (issue) {
        PluginFormIssue.Required -> strings.pluginFormRequired
        PluginFormIssue.TooLong -> strings.pluginFormTooLong
        PluginFormIssue.OutOfRange -> strings.pluginFormOutOfRange
        PluginFormIssue.DuplicateItem -> strings.pluginFormDuplicateItem
        PluginFormIssue.TooFewItems -> strings.pluginFormTooFewItems.replace("{n}", ((input?.min ?: 1.0).toInt()).toString())
        PluginFormIssue.TooManyItems -> strings.pluginFormTooManyItems.replace("{n}", (input?.let { maxItems(it) } ?: 1).toString())
        else -> strings.pluginFormInvalid
    }

    /** "{length}/{maxLength}" under a text or textarea. */
    fun counter(input: PluginInput, draft: Any?): String? {
        if (input.kind != PluginInputKind.Text && input.kind != PluginInputKind.Textarea) return null
        val limit = maxLength(input) ?: return null
        return "${length(trimmed(draft as? String ?: ""))}/$limit"
    }
}

/**
 * A form being filled in: the draft, which inputs were edited (their client issue shows; their host error is spent)
 * and whether submit was tried (every issue shows).
 */
internal data class PluginFormState(
    val draft: Map<String, Any?>,
    val edited: Set<String> = emptySet(),
    val editedSinceErrors: Set<String> = emptySet(),
    val attempted: Boolean = false,
) {
    companion object {
        fun initial(inputs: List<PluginInput>, values: Map<String, Any?>?) = PluginFormState(PluginFormRules.draft(inputs, values))
    }

    fun set(id: String, value: Any?): PluginFormState =
        copy(draft = draft + (id to value), edited = edited + id, editedSinceErrors = editedSinceErrors + id)

    /** New host errors apply again to every input. */
    fun hostErrorsChanged(): PluginFormState = copy(editedSinceErrors = emptySet())

    /** The text under an input: the host's first error for it, else the client's issue once it may show. */
    fun errorText(input: PluginInput, hostErrors: List<PluginFormError>, strings: FlareStrings): String? {
        if (input.id !in editedSinceErrors) {
            hostErrors.firstOrNull { it.input == input.id }?.let { return PluginFormRules.issueText(it.issue, input, strings) }
        }
        if (!attempted && input.id !in edited) return null
        return PluginFormRules.check(input, draft[input.id])?.let { PluginFormRules.issueText(it, input, strings) }
    }

    /** Runs the check: the next state, and the values to submit (null, with every issue showing, when one fails). */
    fun submit(inputs: List<PluginInput>): Pair<PluginFormState, Map<String, Any?>?> {
        val next = copy(attempted = true)
        if (PluginFormRules.check(inputs, draft).isNotEmpty()) return next to null
        return next to PluginFormRules.values(inputs, draft)
    }

    fun rows(id: String): List<String> = (draft[id] as? List<*>).orEmpty().map { it as? String ?: "" }

    fun canAddRow(input: PluginInput): Boolean = rows(input.id).size < PluginFormRules.maxItems(input)

    fun canRemoveRow(input: PluginInput): Boolean = rows(input.id).size > PluginFormRules.minRows(input)

    fun setRow(input: PluginInput, index: Int, value: String): PluginFormState {
        val rows = rows(input.id)
        if (index !in rows.indices) return this
        return set(input.id, rows.toMutableList().also { it[index] = value })
    }

    fun addRow(input: PluginInput): PluginFormState = if (canAddRow(input)) set(input.id, rows(input.id) + "") else this

    fun removeRow(input: PluginInput, index: Int): PluginFormState {
        val rows = rows(input.id)
        if (!canRemoveRow(input) || index !in rows.indices) return this
        return set(input.id, rows.toMutableList().also { it.removeAt(index) })
    }
}

/** The detail sheet's three states. */
internal enum class PluginDetailPhase { Loading, Error, Loaded }

/** What the detail sheet shows: loading wins, then the error, then the view; nothing yet is still loading. */
internal fun pluginDetailPhase(loading: Boolean, error: String?, view: PluginViewModel?): PluginDetailPhase = when {
    loading -> PluginDetailPhase.Loading
    !error.isNullOrEmpty() -> PluginDetailPhase.Error
    view == null -> PluginDetailPhase.Loading
    else -> PluginDetailPhase.Loaded
}

/** The detail sheet's title: the view's, else the host's. */
internal fun pluginDetailHeading(view: PluginViewModel?, title: String?): String =
    view?.title?.takeIf { it.isNotEmpty() } ?: title.orEmpty()

/** The credit a static map carries: OpenStreetMap's for the osm provider, none for amap; only over a shown picture. */
internal fun locationMapAttribution(provider: FlareLocationProvider, pictureShown: Boolean, strings: FlareStrings): String? =
    if (pictureShown && provider == FlareLocationProvider.Osm) strings.locationOsmAttribution else null
