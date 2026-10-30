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

/**
 * An entry's or a row's enumerated value as words and a tone (the plugin's `valueLabels`, already translated), such as
 * a ledger line's kind. Drawn as the kit tag; a tone the kit does not know reads as [PluginTone.Neutral].
 */
data class PluginBadge(val text: String, val tone: PluginTone = PluginTone.Neutral)

/** One option of a choices block; [count] and [percent] only while results show. */
data class PluginChoice(
    val index: Int,
    val label: String,
    val selected: Boolean = false,
    val count: Int? = null,
    val percent: Int? = null,
)

/** One display block, by `kind`. A kind the kit does not know is skipped when reading. */
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

/**
 * `choices`: a poll or an RSVP. [action] is the block's own submit action (never among the footer actions).
 * [maxSelections] caps a multiple choice's draft (1..=option count): once the draft is full the other options wait.
 */
data class PluginChoicesBlock(
    val options: List<PluginChoice>,
    val multiple: Boolean = false,
    val voted: Boolean = false,
    val closed: Boolean = false,
    val showResults: Boolean = false,
    val total: Int? = null,
    val inputName: String = "selection",
    val action: PluginViewAction? = null,
    val maxSelections: Int? = null,
) : PluginBlock {
    override val kind: String get() = "choices"

    /** The indices the view says the viewer chose, ascending. */
    val selection: List<Int> get() = options.filter { it.selected }.map { it.index }.sorted()

    /** The cap a multiple choice keeps; none for a single choice or without a positive [maxSelections]. */
    val cap: Int? get() = maxSelections?.takeIf { multiple && it > 0 }
}

/**
 * The group an entry opens in a grouped entries block (a poll option's voters): [label] is data, not translated;
 * [count], [total] and [percent] are drawn when present ("火锅 · 3 票 · 38%").
 */
data class PluginEntryGroup(
    val key: String,
    val label: String,
    val count: Int? = null,
    val total: Int? = null,
    val percent: Int? = null,
)

/**
 * One entry of an entries block; [index] is its position in the data, from 1 (from 1 in each group of a grouped
 * block). [group] is set on the first entry of each group. [badge] draws after the name and the "me" tag, before the
 * text.
 */
data class PluginEntry(
    val index: Int,
    val text: String,
    val name: String? = null,
    val userId: String? = null,
    val group: PluginEntryGroup? = null,
    val badge: PluginBadge? = null,
)

/**
 * `entries`: a list (a sign-up chain, a poll's voters); [more] offers "see all" (the detail view). [grouped]: a group
 * header row goes before every entry that carries a [PluginEntry.group]. [numbered] false shows no numbers.
 */
data class PluginEntriesBlock(
    val items: List<PluginEntry>,
    val numbered: Boolean = true,
    val total: Int = items.size,
    val more: Boolean = false,
    val emptyText: String? = null,
    val grouped: Boolean = false,
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

/** How a rows column writes its cells: as sent, or a time (`timeMs`) in the device zone. */
enum class PluginRowsFormat(val wire: String) {
    Text("text"), Time("time");

    companion object {
        fun fromWire(value: String?): PluginRowsFormat = entries.firstOrNull { it.wire == value } ?: Text
    }
}

data class PluginRowsColumn(val label: String, val format: PluginRowsFormat = PluginRowsFormat.Text)

/** One cell of a row; a time column's cell carries [timeMs]. */
data class PluginRowCell(val text: String, val timeMs: Long? = null)

/** A row's action: the id of one of the block's actions and the input the view bound for it, handed back as is. */
data class PluginRowAction(val id: String, val input: Any? = null)

/** One row, identified by [key]; [badge] leads its first line. */
data class PluginRow(
    val key: String,
    val cells: List<PluginRowCell>,
    val actions: List<PluginRowAction> = emptyList(),
    val badge: PluginBadge? = null,
)

/**
 * `rows`: a plugin page's list (one per page; the rows page with the page). Every kit draws it as a list — the badge
 * and the first cell, the other cells, the row's action keys — and draws a key once (the first). [filters] names the
 * view inputs the page shows as its filters; null means every input, an empty list none.
 */
data class PluginRowsBlock(
    val source: String,
    val columns: List<PluginRowsColumn>,
    val rows: List<PluginRow>,
    val actions: List<PluginViewAction> = emptyList(),
    val emptyText: String? = null,
    val filters: List<String>? = null,
) : PluginBlock {
    override val kind: String get() = "rows"
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

/** The row a rows action runs on: its key and the input the view bound for that action (`rows[].actions[].input`). */
data class PluginActionRow(val key: String, val input: Any? = null)

/**
 * What `onAction(id, payload)` carries: the chosen option indices (ascending), the form's values by input id (String,
 * Double, Boolean or a List of String) and, for a rows action, its [row]. [toJson] writes it for the core SDK.
 */
data class PluginActionPayload(
    val selection: List<Int>? = null,
    val formValues: Map<String, Any?>? = null,
    val row: PluginActionRow? = null,
) {
    fun toJson(): String = pluginJson(buildMap {
        selection?.let { put("selection", it) }
        formValues?.let { put("formValues", it) }
        row?.let { put("row", it.toMap()) }
    })

    companion object {
        val Empty = PluginActionPayload()
    }
}

private fun PluginActionRow.toMap(): Map<String, Any?> = linkedMapOf("key" to key, "input" to input)

/** The page a [FlarePluginPage] shows, as the core SDK's page action request names it. */
data class PluginPageRef(val pluginId: String, val page: String)

/**
 * A resolved plugin page (the core SDK's `pluginPage` result): the page's [view] — a detail-shaped view whose
 * `nextCursor` is the page's next page (rows and entries page with it) — and [data], what the page was resolved
 * against, which every page action carries back. An unavailable page is `{available: false, title: "",
 * unavailableReason}` and has no data.
 */
data class PluginPageViewModel(val view: PluginViewModel, val data: Map<String, Any?>? = null) {
    companion object {
        /** Reads the core's page JSON; throws [IllegalArgumentException] on malformed JSON. */
        fun fromJson(json: String): PluginPageViewModel {
            val root = FlareJson.parse(json) as? Map<*, *> ?: throw IllegalArgumentException("a plugin page is an object")
            return fromMap(root)
        }

        /** Reads a parsed page (objects as maps, arrays as lists). */
        fun fromMap(map: Map<*, *>): PluginPageViewModel = PluginPageViewModel(
            view = PluginViewModel.fromMap(map),
            data = (map["data"] as? Map<*, *>)?.entries?.associate { (k, v) -> k.toString() to v },
        )
    }
}

/**
 * What [FlarePluginPage]'s `onAction(id, payload)` carries: the core SDK's page action request without the platform
 * and the gesture — the [page], the view's [data] when it has one, the [row] of a rows action, the [selection] of a
 * choices submit and the [formValues] of a collected form. The host passes it to the core as it is.
 */
data class PluginPageActionPayload(
    val page: PluginPageRef,
    val data: Map<String, Any?>? = null,
    val row: PluginActionRow? = null,
    val selection: List<Int>? = null,
    val formValues: Map<String, Any?>? = null,
) {
    fun toJson(): String = pluginJson(buildMap {
        put("page", linkedMapOf("pluginId" to page.pluginId, "page" to page.page))
        data?.let { put("data", it) }
        row?.let { put("row", it.toMap()) }
        selection?.let { put("selection", it) }
        formValues?.let { put("formValues", it) }
    })

    companion object {
        /** An action run on [page]: the page, [view]'s data when it has one, and what the action itself carries. */
        fun of(page: PluginPageRef, view: PluginPageViewModel?, payload: PluginActionPayload): PluginPageActionPayload =
            PluginPageActionPayload(page, view?.data, payload.row, payload.selection, payload.formValues)
    }
}

/**
 * Why a view is unavailable or read-only (`ResolvedPluginView.unavailableReason`, docs/design/plugin-platform-v2 §4).
 * [UnboundCopy] keeps the view available but read-only: a forwarded or forged copy of a card.
 */
enum class PluginUnavailableReason(val wire: String) {
    Disabled("disabled"),
    NotInstalled("not_installed"),
    NoPermission("no_permission"),
    UnsupportedPlatform("unsupported_platform"),
    IncompatibleVersion("incompatible_version"),
    CatalogUnreachable("catalog_unreachable"),
    UnboundCopy("unbound_copy");

    companion object {
        fun fromWire(value: String?): PluginUnavailableReason? = entries.firstOrNull { it.wire == value }
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
     * A detail or page view's next page: the cursor the host asks the core SDK for ([PluginDetailSheet] and
     * [FlarePluginPage] draw "load more" with it); null (or blank) on the last page and on cards.
     */
    val nextCursor: String? = null,
    /** The actions the plugin placed in the card's ⋯ menu (`placement: "menu"`), in order; run like [actions]. */
    val menuActions: List<PluginViewAction> = emptyList(),
    /** Why the view is unavailable, or read-only ([PluginUnavailableReason.UnboundCopy]); null otherwise. */
    val unavailableReason: PluginUnavailableReason? = null,
    val presentation: Map<String, Any?>? = null,
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
            menuActions = map.list("menuActions").mapNotNull { (it as? Map<*, *>)?.action() },
            unavailableReason = PluginUnavailableReason.fromWire(map["unavailableReason"] as? String),
            presentation = (map["presentation"] as? Map<*, *>)?.entries?.filter { it.key is String }?.associate { it.key as String to it.value },
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
            (this["action"] as? Map<*, *>)?.action(), int("maxSelections"))
    }
    "entries" -> {
        val items = list("items").mapNotNull { raw ->
            val e = raw as? Map<*, *> ?: return@mapNotNull null
            val group = (e["group"] as? Map<*, *>)?.let { g ->
                val key = g.string("key") ?: return@let null
                PluginEntryGroup(key, g.string("label") ?: "", g.int("count"), g.int("total"), g.int("percent"))
            }
            PluginEntry(e.int("index") ?: 0, e.string("text") ?: "", e.string("name"), e.string("userId"), group, e.badge())
        }
        PluginEntriesBlock(items, bool("numbered") ?: true, int("total") ?: items.size, bool("more") ?: false, string("emptyText"),
            bool("grouped") ?: false)
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
    "rows" -> PluginRowsBlock(
        source = string("source") ?: "",
        columns = list("columns").mapNotNull { raw ->
            val c = raw as? Map<*, *> ?: return@mapNotNull null
            PluginRowsColumn(c.string("label") ?: "", PluginRowsFormat.fromWire(c.string("format")))
        },
        rows = list("rows").mapNotNull { raw ->
            val r = raw as? Map<*, *> ?: return@mapNotNull null
            val key = r.string("key") ?: return@mapNotNull null
            PluginRow(
                key = key,
                cells = r.list("cells").map { cell ->
                    val c = cell as? Map<*, *>
                    PluginRowCell(c?.string("text") ?: "", (c?.get("timeMs") as? Number)?.toLong())
                },
                actions = r.list("actions").mapNotNull { a -> (a as? Map<*, *>)?.let { m -> m.string("id")?.let { PluginRowAction(it, m["input"]) } } },
                badge = r.badge(),
            )
        },
        actions = list("actions").mapNotNull { (it as? Map<*, *>)?.action() },
        emptyText = string("emptyText"),
        filters = (this["filters"] as? List<*>)?.filterIsInstance<String>(),
    )
    else -> null
}

/** An entry's or a row's `badge`; none without words. A tone the kit does not know draws neutral. */
private fun Map<*, *>.badge(): PluginBadge? {
    val badge = this["badge"] as? Map<*, *> ?: return null
    val text = badge.string("text")?.takeIf { it.isNotEmpty() } ?: return null
    return PluginBadge(text, PluginTone.fromWire(badge.string("tone")) ?: PluginTone.Neutral)
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

/** What an entry row draws, in drawing order. */
internal enum class PluginEntryPart { Number, Avatar, Name, Me, Badge, Text }

/** A row's first line (after its badge) and second line (the other cells), as a list item draws them. */
internal data class PluginRowLines(val primary: String, val secondary: String?)

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

    /** "{count} 票" in the plural form [locale] takes for [count] (spec/plural-vectors.json). */
    fun votes(count: Int, strings: FlareStrings, locale: java.util.Locale = java.util.Locale.ROOT): String =
        flarePlural(count.toLong(), strings.pluginViewVotesOne, strings.pluginViewVotes, locale)

    /** An entry's number: its index in a numbered block, none in a block with `numbered` false. */
    fun entryNumber(block: PluginEntriesBlock, entry: PluginEntry): String? = if (block.numbered) entry.index.toString() else null

    /**
     * The header a group opens with (spec/plugin-view-vectors.json `entryGroupHeaders`): the label, the votes when the
     * count is there, the percent when it is there, joined by " · ".
     */
    fun groupHeader(group: PluginEntryGroup, strings: FlareStrings, locale: java.util.Locale = java.util.Locale.ROOT): String = buildList {
        add(group.label)
        group.count?.let { add(votes(it, strings, locale)) }
        group.percent?.let { add("$it%") }
    }.joinToString(" · ")

    /** The header drawn before [entry] in [block]: only grouped blocks have them, on the entries that open a group. */
    fun entryGroupHeader(
        block: PluginEntriesBlock,
        entry: PluginEntry,
        strings: FlareStrings,
        locale: java.util.Locale = java.util.Locale.ROOT,
    ): String? = entry.group?.takeIf { block.grouped }?.let { groupHeader(it, strings, locale) }

    /** The viewer's own row carries the "me" tag. */
    fun isMe(entry: PluginEntry, viewerId: String?): Boolean = !viewerId.isNullOrEmpty() && entry.userId == viewerId

    /**
     * What an entry draws, in drawing order (spec rules.badge): number, avatar, name, the "me" tag, the badge, then the
     * text; a part it does not have is left out, so no gap is left for it.
     */
    fun entryParts(block: PluginEntriesBlock, entry: PluginEntry, resolved: Map<String, PluginUser>, viewerId: String?): List<PluginEntryPart> =
        buildList {
            if (entryNumber(block, entry) != null) add(PluginEntryPart.Number)
            if (!entry.userId.isNullOrEmpty()) add(PluginEntryPart.Avatar)
            if (entryName(entry, resolved) != null) add(PluginEntryPart.Name)
            if (isMe(entry, viewerId)) add(PluginEntryPart.Me)
            if (entry.badge != null) add(PluginEntryPart.Badge)
            add(PluginEntryPart.Text)
        }

    /** The rows a list draws: in order, each key once — the first stays (spec rules.pageRows). */
    fun rowsOnce(rows: List<PluginRow>): List<PluginRow> {
        val seen = HashSet<String>()
        return rows.filter { seen.add(it.key) }
    }

    /**
     * A row's two lines (spec rules.pageRows): the first cell, and the other cells in column order — time columns
     * written as in `time`, blank cells skipped — joined with " · ", or none when nothing is left.
     */
    fun rowLines(block: PluginRowsBlock, row: PluginRow, nowMs: Long, strings: FlareStrings, utcOffsetMinutes: Int?): PluginRowLines {
        val texts = block.columns.mapIndexed { index, column ->
            val cell = row.cells.getOrNull(index)
            val at = cell?.timeMs
            if (column.format == PluginRowsFormat.Time && at != null) dateTime(at, nowMs, strings, utcOffsetMinutes) else cell?.text.orEmpty()
        }
        val rest = texts.drop(1).filter { it.isNotBlank() }
        return PluginRowLines(texts.firstOrNull().orEmpty(), rest.takeIf { it.isNotEmpty() }?.joinToString(" · "))
    }

    /** A row's action keys: the block actions it lists, each with the input the view bound for it. */
    fun rowActions(block: PluginRowsBlock, row: PluginRow): List<Pair<PluginViewAction, PluginRowAction>> =
        row.actions.mapNotNull { bound -> block.actions.firstOrNull { it.id == bound.id }?.let { it to bound } }

    /** A rows block without rows says so: its own text, else the kit's. */
    fun rowsEmpty(block: PluginRowsBlock, strings: FlareStrings): String? =
        if (block.rows.isNotEmpty()) null else block.emptyText?.takeIf { it.isNotEmpty() } ?: strings.pluginViewEmpty

    /**
     * The view's inputs a page shows as filters, in input order (spec rules.rows, filterInputs): the ones its rows block
     * lists, or every input when it lists none; an empty list, none.
     */
    fun filterInputs(view: PluginViewModel): List<PluginInput> {
        val listed = view.blocks.firstNotNullOfOrNull { it as? PluginRowsBlock }?.filters ?: return view.inputs
        return view.inputs.filter { it.id in listed }
    }

    /** The action keys a view draws: its actions, and on an embedded view (no title row, no ⋯ key) its menu actions after them. */
    fun keys(view: PluginViewModel, embedded: Boolean): List<PluginViewAction> =
        if (embedded) view.actions + menuActions(view) else view.actions

    /** The words for an unavailable reason (spec/plugin-view-vectors.json `unavailableReasons`). */
    fun reasonText(reason: PluginUnavailableReason, strings: FlareStrings): String = when (reason) {
        PluginUnavailableReason.Disabled -> strings.pluginViewUnavailableDisabled
        PluginUnavailableReason.NotInstalled -> strings.pluginViewUnavailableNotInstalled
        PluginUnavailableReason.NoPermission -> strings.pluginViewUnavailableNoPermission
        PluginUnavailableReason.UnsupportedPlatform -> strings.pluginViewUnavailableUnsupportedPlatform
        PluginUnavailableReason.IncompatibleVersion -> strings.pluginViewUnavailableIncompatibleVersion
        PluginUnavailableReason.CatalogUnreachable -> strings.pluginViewUnavailableCatalogUnreachable
        PluginUnavailableReason.UnboundCopy -> strings.pluginViewUnavailableUnboundCopy
    }

    /**
     * The reason line of a view (spec rules.unavailableReason): an unavailable view says why, led by the envelope's
     * [displayName] ("投票 · 插件已停用"); a read-only copy closes with its own line; no reason, no line.
     */
    fun reasonLine(view: PluginViewModel, displayName: String?, strings: FlareStrings): String? {
        val reason = view.unavailableReason ?: return null
        val text = reasonText(reason, strings)
        if (reason == PluginUnavailableReason.UnboundCopy) return text
        if (view.available) return null
        return displayName?.trim()?.takeIf { it.isNotEmpty() }?.let { "$it · $text" } ?: text
    }

    /** A view the viewer may look at but not act on: a read-only copy. */
    fun readOnly(view: PluginViewModel): Boolean = view.unavailableReason == PluginUnavailableReason.UnboundCopy

    /** The card's ⋯ menu: its menu actions, none on an unavailable view or a read-only copy. */
    fun menuActions(view: PluginViewModel): List<PluginViewAction> =
        if (!view.available || readOnly(view)) emptyList() else view.menuActions

    fun seeAll(total: Int, strings: FlareStrings): String = strings.pluginViewSeeAll.replace("{count}", total.toString())

    /**
     * Whether a card draws its own view details key (spec rules.detailKey): the view has a detail, is available and is
     * not embedded, no entries block shows its see all and it has no rows.
     */
    fun showsDetailKey(view: PluginViewModel, embedded: Boolean): Boolean =
        view.detail && view.available && !embedded && view.blocks.none { it is PluginRowsBlock || (it is PluginEntriesBlock && it.more) }

    /**
     * The card's view details key: null when it draws none (also without a host [handled] openDetail), else whether
     * it is enabled — it waits while [busy] or an action is in flight.
     */
    fun detailKey(view: PluginViewModel, embedded: Boolean, handled: Boolean, busy: Boolean, busyActionId: String?): Boolean? =
        if (handled && showsDetailKey(view, embedded)) !(busy || busyActionId != null) else null

    /** The line an embedded view (no title row) shows while unavailable: its title, so it still says what it was. */
    fun unavailableLine(view: PluginViewModel, embedded: Boolean): String? =
        view.title.takeIf { embedded && !view.available && it.isNotEmpty() }

    /**
     * The line under a choices block: the cap while the block can be chosen ("最多选 2 项"), then ended. The block's
     * total is only the denominator of the shares — a voter count or the sum of the counts — so it is never drawn: "N 票"
     * belongs to the options, and how many took part is the plugin's own row (spec rules.choices).
     */
    fun choicesFooter(block: PluginChoicesBlock, strings: FlareStrings): String? {
        val parts = buildList {
            val cap = block.cap
            if (cap != null && block.action != null && !block.closed) add(strings.pluginViewMaxSelections.replace("{n}", cap.toString()))
            if (block.closed) add(strings.pluginViewEnded)
        }
        return parts.takeIf { it.isNotEmpty() }?.joinToString(" · ")
    }

    fun percentText(option: PluginChoice, showResults: Boolean): String? =
        if (showResults && option.percent != null) "${option.percent}%" else null

    fun votesText(option: PluginChoice, showResults: Boolean, strings: FlareStrings, locale: java.util.Locale = java.util.Locale.ROOT): String? =
        if (showResults && option.count != null) votes(option.count, strings, locale) else null

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

    /**
     * The multiple submit key: a non-empty draft that differs from the view's selection and fits the cap (a selection
     * above a lowered cap has to shrink first).
     */
    fun submitEnabled(block: PluginChoicesBlock, index: Int): Boolean {
        val draft = drafts[index] ?: block.selection
        val cap = block.cap
        return draft.isNotEmpty() && draft.toSet() != block.selection.toSet() && (cap == null || draft.size <= cap)
    }

    /**
     * Whether the cap holds [option] back (spec rules.maxSelections): the draft is full and does not hold it. The
     * options in the draft stay tappable, so unticking one frees the rest.
     */
    fun capped(block: PluginChoicesBlock, index: Int, option: Int): Boolean {
        val cap = block.cap ?: return false
        val draft = shown(block, index)
        return draft.size >= cap && option !in draft
    }

    /** Whether [option] takes a tap: the block can be chosen and the cap does not hold the option back. */
    fun optionEnabled(block: PluginChoicesBlock, index: Int, option: Int, locked: Boolean): Boolean =
        isInteractive(block, index, locked) && !capped(block, index, option)

    /**
     * A tap on an option: the next state and, for a single choice, the selection to submit (none for the only selected
     * option). A multiple choice toggles its draft; an option the cap holds back ignores the tap.
     */
    fun tap(block: PluginChoicesBlock, index: Int, option: Int, locked: Boolean): Pair<PluginChoicesInteraction, List<Int>?> {
        if (!optionEnabled(block, index, option, locked)) return this to null
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
    fun trimmed(text: String): String = text.trim { it.isWhitespace() || it == '\uFEFF' || it == '\u00A0' }

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
