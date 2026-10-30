package com.flare.im.ui

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.ui.unit.dp
import java.io.File
import java.time.ZoneId
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.runBlocking

/**
 * PluginView v2, PluginForm and PluginDetailSheet without a UI, against `spec/plugin-view-vectors.json`, the table the
 * four kits run: every block's render facts (views), the optimistic choices (optimistic), time and countdown text
 * (time, countdown) and the form's check, values and error texts (form). Copy comes from the strings table.
 */
class PluginViewVectorsTest {
    private val s = FlareStrings()
    private val en = flareStringsEnglish()

    private fun table(): Map<*, *> {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/plugin-view-vectors.json")
            if (candidate.isFile) return FlareJson.parse(candidate.readText()) as Map<*, *>
            dir = dir.parentFile
        }
        error("spec/plugin-view-vectors.json not found above ${File(".").absolutePath}")
    }

    private fun Map<*, *>.map(key: String): Map<*, *> = this[key] as Map<*, *>
    private fun Map<*, *>.list(key: String): List<*> = this[key] as? List<*> ?: emptyList<Any?>()
    private fun Map<*, *>.str(key: String): String? = this[key] as? String
    private fun Map<*, *>.int(key: String): Int? = (this[key] as? Number)?.toInt()
    private fun Map<*, *>.long(key: String): Long? = (this[key] as? Number)?.toLong()
    private fun Map<*, *>.bool(key: String): Boolean? = this[key] as? Boolean

    private fun users(table: Map<*, *>): Map<String, PluginUser> = table.map("users").entries.associate { (id, raw) ->
        val user = raw as Map<*, *>
        id as String to PluginUser(user.str("name")!!, user.str("avatarUrl"))
    }

    private fun views(table: Map<*, *>): Map<String, Pair<PluginViewModel, Map<*, *>>> = cases(table)
        .mapValues { (_, case) -> PluginViewModel.fromMap(case.map("view")) to case.map("expect") }

    /** Every view of the table as this kit reads it, the Vue console tables included (a case may name one). */
    private fun allViews(table: Map<*, *>): Map<String, PluginViewModel> = table.list("views")
        .map { it as Map<*, *> }
        .associate { it.str("id")!! to PluginViewModel.fromMap(it.map("view")) }

    /**
     * The view cases this kit runs, whole (viewerId, displayName and embedded beside the view and its facts): every case
     * but the Vue console's tables, whose facts are a table's (columns, a row's detail, the rows' own load more). The
     * natives draw rows only as a page's list, whose facts are `pageViews`.
     */
    private fun cases(table: Map<*, *>): Map<String, Map<*, *>> = table.list("views")
        .map { it as Map<*, *> }
        .filter { "compose" in it.list("platforms") || it.str("id") !in VUE_TABLES }
        .associateBy { it.str("id")!! }

    // ── view details key (detailKey) and insets ──

    @Test fun theViewDetailsKeyFollowsTheTable() {
        val table = table()
        val views = allViews(table)
        // Every case, the admin page's too: a view with rows draws no details key.
        val cases = table.list("detailKey").map { it as Map<*, *> }
        assertTrue(cases.size >= 9, "the shared table lost detailKey cases")
        for (case in cases) {
            val name = case.str("name")!!
            val base = views.getValue(case.str("view")!!)
            val view = case.bool("detail")?.let { base.copy(detail = it) } ?: base
            val enabled = PluginViewFormat.detailKey(
                view = view,
                embedded = case.bool("embedded") ?: false,
                handled = case.bool("handler") != false,
                busy = case.bool("busy") ?: false,
                busyActionId = case.str("busyActionId"),
            )
            val expect = case.map("expect")
            val key = expect["key"] as Map<*, *>?
            if (key == null) {
                assertNull(enabled, "$name: no key")
            } else {
                assertEquals(key.str("label"), s.pluginViewDetail, name)
                assertEquals(key.bool("enabled"), enabled, "$name: enabled")
            }
            if (expect.containsKey("seeAll")) {
                val more = view.blocks.filterIsInstance<PluginEntriesBlock>().firstOrNull { it.more }
                assertEquals(expect.str("seeAll"), more?.let { PluginViewFormat.seeAll(it.total, s) }, "$name: see all")
            }
        }
        assertEquals("View details", en.pluginViewDetail)
    }

    @Test fun theInsetsFollowTheTable() {
        val insets = table().map("insets")
        assertEquals(PluginViewInset.entries.map { it.name.replaceFirstChar(Char::lowercase) }.toSet(), insets.keys.map { it as String }.toSet())
        fun side(token: Any?) = when (token) {
            "md" -> FlareSizes.spacingMd
            "lg" -> FlareSizes.spacingLg
            "xl" -> FlareSizes.spacingXl
            else -> 0.dp
        }
        for (inset in PluginViewInset.entries) {
            val sides = insets.map(inset.name.replaceFirstChar(Char::lowercase))
            assertEquals(
                PaddingValues(start = side(sides["sides"]), end = side(sides["sides"]), top = side(sides["top"]), bottom = side(sides["bottom"])),
                pluginViewInsetPadding(inset),
                inset.name,
            )
        }
    }

    @Test fun theTableCoversTheNativeViews() {
        val views = views(table())
        for (id in listOf("poll-open-single", "poll-open-multi", "poll-voted-single", "poll-voted-multi", "poll-closed",
            "solitaire-more", "task", "schedule", "announcement", "blocks-misc", "v1", "unavailable", "entries-badges",
            "poll-max-selections", "poll-max-selections-voted", "poll-max-selections-over")) {
            assertNotNull(views[id], "the shared table lost $id")
        }
        assertNull(views["admin-rows"], "a console table is the Vue kit's; natives draw rows as a page list")
    }

    @Test fun everyViewMatchesItsRenderFacts() {
        val table = table()
        val users = users(table)
        val now = table.long("nowMs")!!
        val zone = table.int("utcOffsetMinutes")!!
        for ((id, case) in cases(table)) {
            val view = PluginViewModel.fromMap(case.map("view"))
            val expect = case.map("expect")
            val viewerId = case.str("viewerId")
            val embedded = case.bool("embedded") ?: false
            assertEquals(expect.str("title"), view.title, id)
            val hidden = expect.bool("bodyHidden") ?: false
            assertEquals(hidden, !view.available, id)
            val blocks = if (hidden) emptyList() else view.blocks
            val facts = expect.list("blocks").map { it as Map<*, *> }
            assertEquals(facts.map { it.str("kind") }, blocks.map { it.kind }, "$id blocks")
            blocks.zip(facts).forEachIndexed { index, (block, fact) -> check(block, index, fact, users, now, zone, "$id#$index", viewerId) }
            val fields = if (hidden) emptyList() else view.fields
            assertEquals(expect.list("fields").map { (it as Map<*, *>).let { f -> PluginViewField(f.str("label")!!, f.str("value")!!) } }, fields, "$id fields")
            val actions = if (hidden) emptyList() else view.actions
            val actionFacts = expect.list("actions").map { it as Map<*, *> }
            assertEquals(actionFacts.map { it.str("id") }, actions.map { it.id }, "$id actions")
            for ((action, fact) in actions.zip(actionFacts)) {
                assertEquals(fact.str("label"), action.label, id)
                val variant = when (PluginViewFormat.variant(action)) {
                    FlareButtonVariant.Danger -> "danger"
                    FlareButtonVariant.Primary -> "primary"
                    else -> "secondary"
                }
                assertEquals(fact.str("variant"), variant, "$id ${action.id} variant")
                assertEquals(fact.str("confirm"), action.confirm, "$id ${action.id} confirm")
                assertEquals(fact.bool("form"), !action.form.isNullOrEmpty(), "$id ${action.id} form")
            }
            expect.bool("seeAllOpensDetail")?.let { opens ->
                assertEquals(opens, blocks.any { it is PluginEntriesBlock && it.more }, "$id see all")
            }
            // Protocol v2: the ⋯ menu (keys when embedded) and the reason line.
            if (expect.containsKey("menu")) {
                val menu = PluginViewFormat.menuActions(view)
                val menuFacts = expect.list("menu").map { it as Map<*, *> }
                assertEquals(menuFacts.map { it.str("id") }, menu.map { it.id }, "$id menu")
                for ((action, fact) in menu.zip(menuFacts)) {
                    assertEquals(fact.str("label"), action.label, "$id menu ${action.id}")
                    assertEquals(fact.str("variant"), if (PluginViewFormat.variant(action) == FlareButtonVariant.Danger) "danger" else
                        if (PluginViewFormat.variant(action) == FlareButtonVariant.Primary) "primary" else "secondary", "$id menu ${action.id} variant")
                    assertEquals(fact.str("confirm"), action.confirm, "$id menu ${action.id} confirm")
                    assertEquals(fact.bool("form"), !action.form.isNullOrEmpty(), "$id menu ${action.id} form")
                }
                expect.str("menuPresentation")?.let { assertEquals("keys", it); assertTrue(embedded, "$id: keys only when embedded") }
            }
            if (expect.containsKey("reason")) {
                assertEquals(expect.str("reason"), PluginViewFormat.reasonLine(view, case.str("displayName"), s), "$id reason")
            }
        }
    }

    @Test fun theUnavailableReasonsReadAsTheTableSays() {
        val table = table()
        val reasons = table.list("unavailableReasons").map { it as Map<*, *> }
        assertEquals(PluginUnavailableReason.entries.map { it.wire }, reasons.map { it.str("reason") })
        for (row in reasons) {
            val reason = PluginUnavailableReason.fromWire(row.str("reason"))!!
            assertEquals(row.str("zh"), PluginViewFormat.reasonText(reason, s), reason.wire)
            assertEquals(row.str("zh"), SpecTables.copy(row.str("key")!!, "zh"), "${reason.wire} is the shared copy")
            assertEquals(row.str("en"), SpecTables.copy(row.str("key")!!, "en"), "${reason.wire} en")
        }
        // A read-only copy keeps its content, acts on nothing and draws no menu.
        val copy = views(table).getValue("unbound-copy").first
        assertTrue(copy.available && PluginViewFormat.readOnly(copy))
        assertTrue(PluginViewFormat.menuActions(copy.copy(menuActions = listOf(PluginViewAction("close", "End")))).isEmpty())
        assertNull(PluginViewFormat.reasonLine(copy.copy(unavailableReason = null), "投票", s), "no reason, no line")
    }

    @Test fun groupHeadersReadAsTheTableSays() {
        for (raw in table().list("entryGroupHeaders")) {
            val row = raw as Map<*, *>
            val g = row.map("group")
            val group = PluginEntryGroup(g.str("key")!!, g.str("label")!!, g.int("count"), g.int("total"), g.int("percent"))
            assertEquals(row.str("zh"), PluginViewFormat.groupHeader(group, s), group.label)
            assertEquals(row.str("en"), PluginViewFormat.groupHeader(group, en), "${group.label} en")
        }
        assertEquals("我", s.pluginViewMe)
        assertEquals(SpecTables.copy("pluginViewMore", "zh"), s.pluginViewMore)
    }

    private fun check(block: PluginBlock, index: Int, fact: Map<*, *>, users: Map<String, PluginUser>, now: Long, zone: Int, id: String, viewerId: String? = null) {
        when (block) {
            is PluginTextBlock -> {
                assertEquals(fact.str("text"), block.text, id)
                assertEquals(fact.str("style"), block.style.wire, id)
                assertEquals(fact.int("maxLines"), block.maxLines, id)
            }
            is PluginFieldsBlock -> assertEquals(
                fact.list("fields").map { (it as Map<*, *>).let { f -> PluginViewField(f.str("label")!!, f.str("value")!!) } }, block.fields, id)
            is PluginChoicesBlock -> {
                val state = PluginChoicesInteraction()
                assertEquals(fact.bool("interactive"), state.isInteractive(block, index, locked = false), id)
                assertEquals(fact.bool("multiple"), block.multiple, id)
                val submit = fact["submit"] as? Map<*, *>
                if (submit != null) {
                    assertEquals(submit.str("label"), block.action?.label, id)
                    assertEquals(submit.bool("enabled"), state.submitEnabled(block, index), id)
                } else {
                    assertFalse(block.multiple && block.action != null && !block.closed, "$id has no submit key")
                }
                val options = fact.list("options").map { it as Map<*, *> }
                assertEquals(options.map { it.str("label") }, block.options.map { it.label }, id)
                val chosen = state.shown(block, index).toSet()
                for ((option, f) in block.options.zip(options)) {
                    assertEquals(f.bool("selected"), option.index in chosen, "$id ${option.label} selected")
                    f.bool("enabled")?.let { assertEquals(it, state.optionEnabled(block, index, option.index, locked = false), "$id ${option.label} enabled") }
                    assertEquals(f.str("percentText"), PluginViewFormat.percentText(option, block.showResults), "$id ${option.label} percent")
                    assertEquals(f.str("votesText"), PluginViewFormat.votesText(option, block.showResults, s), "$id ${option.label} votes")
                    assertEquals(f.int("bar"), if (block.showResults) option.percent else null, "$id ${option.label} bar")
                }
                assertEquals(fact.str("footer"), PluginViewFormat.choicesFooter(block, s), "$id footer")
            }
            is PluginEntriesBlock -> {
                val rows = fact.list("rows").map { it as Map<*, *> }
                assertEquals(rows.size, block.items.size, id)
                for ((entry, row) in block.items.zip(rows)) {
                    assertEquals(row.str("number"), PluginViewFormat.entryNumber(block, entry), "$id number")
                    if (row.containsKey("group")) assertEquals(row.str("group"), PluginViewFormat.entryGroupHeader(block, entry, s), "$id group")
                    if (row.containsKey("me")) assertEquals(row.bool("me"), PluginViewFormat.isMe(entry, viewerId), "$id me")
                    assertEquals(row.str("name"), PluginViewFormat.entryName(entry, users), "$id entry ${entry.index} name")
                    assertEquals(row.str("text"), entry.text, id)
                    assertEquals(row.str("userId"), entry.userId, id)
                    if (row.containsKey("badge")) assertEquals(badge(row["badge"]), entry.badge, "$id entry ${entry.index} badge")
                    // The words the table orders (number and avatar have their own facts).
                    if (row.containsKey("order")) assertEquals(
                        row.list("order"),
                        PluginViewFormat.entryParts(block, entry, users, viewerId).filter { it in ORDERED_WORDS }.map { it.name.lowercase() },
                        "$id entry ${entry.index} order",
                    )
                }
                assertEquals(fact.str("seeAll"), if (block.more) PluginViewFormat.seeAll(block.total, s) else null, "$id see all")
                assertEquals(fact.str("empty"), if (block.items.isEmpty()) block.emptyText else null, "$id empty")
            }
            is PluginPeopleBlock -> {
                val groups = fact.list("groups").map { it as Map<*, *> }
                assertEquals(groups.size, block.groups.size, id)
                for ((group, g) in block.groups.zip(groups)) {
                    assertEquals(g.str("label"), group.label, id)
                    assertEquals(g.str("countText"), group.count.toString(), id)
                    assertEquals(g.list("avatars"), group.userIds, id)
                    assertEquals(g.list("names"), group.userIds.map { PluginViewFormat.user(it, users).name }, "$id names")
                    assertEquals(g.str("tone"), (group.tone ?: PluginTone.Neutral).wire, "$id tone")
                }
            }
            is PluginStatusBlock -> {
                assertEquals(fact.str("label"), block.label, id)
                assertEquals(fact.str("text"), block.text, id)
                assertEquals(fact.str("tone"), block.tone.wire, id)
            }
            is PluginProgressBlock -> {
                assertEquals(fact.str("label"), block.label, id)
                assertEquals(fact.str("text"), PluginViewFormat.progressText(block), id)
                assertEquals(fact.int("percent"), block.percent, id)
            }
            is PluginTimeBlock -> {
                assertEquals(fact.str("label"), block.label, id)
                assertEquals(fact.str("text"), PluginViewFormat.timeText(block.atMs, block.endMs, now, s, zone), "$id time")
                val countdown = if (block.countdown) PluginViewFormat.countdown(block.atMs, now, s) else null
                assertEquals(fact.str("countdown"), countdown?.text, "$id countdown")
                assertEquals(fact.int("refreshMs"), countdown?.refreshMs, "$id refresh")
            }
            is PluginDividerBlock -> Unit
            is PluginNoteBlock -> {
                assertEquals(fact.str("text"), block.text, id)
                assertEquals(fact.str("tone"), (block.tone ?: PluginTone.Neutral).wire, id)
            }
            is PluginRowsBlock -> error("$id: rows facts are a page's (pageViews)")
        }
    }

    // ── the cap of a multiple choice (maxSelections) ──

    @Test fun theCapFollowsTheTable() {
        val table = table()
        val views = allViews(table)
        val cases = table.list("maxSelections").map { it as Map<*, *> }
        assertTrue(cases.size >= 5, "the shared table lost maxSelections cases")
        for (case in cases) {
            val name = case.str("name")!!
            val view = views.getValue(case.str("view")!!)
            val (index, block) = view.blocks.withIndex().first { it.value is PluginChoicesBlock }.let { it.index to it.value as PluginChoicesBlock }
            // The same rules run a card, the detail sheet and a page: embedded changes nothing here.
            var state = PluginChoicesInteraction()
            case.list("steps").forEachIndexed { number, raw ->
                val step = raw as Map<*, *>
                val label = "$name step ${number + 1}"
                var emitted: Pair<String, List<Int>>? = null
                (step.int("toggle") ?: step.int("tap"))?.let { option ->
                    val (next, selection) = state.tap(block, index, option, locked = false)
                    state = next
                    if (selection != null) emitted = block.action!!.id to selection
                }
                if (step.bool("submit") == true) {
                    state.submission(block, index, locked = false)?.let { emitted = block.action!!.id to it }
                }
                val emit = step["emit"] as? Map<*, *>
                if (emit != null) {
                    assertEquals(emit.str("actionId"), emitted?.first, label)
                    assertEquals(emit.map("payload").list("selection").map { (it as Number).toInt() }, emitted?.second, label)
                } else {
                    assertNull(emitted, "$label emits nothing")
                }
                (step["selected"] as? List<*>)?.let { selected ->
                    assertEquals(selected.map { (it as Number).toInt() }, state.shown(block, index), "$label selected")
                }
                (step["enabled"] as? List<*>)?.let { enabled ->
                    assertEquals(enabled, block.options.map { state.optionEnabled(block, index, it.index, locked = false) }, "$label enabled")
                }
                step.bool("submitEnabled")?.let { assertEquals(it, state.submitEnabled(block, index), "$label submit") }
            }
        }
        assertEquals(SpecTables.copy("pluginViewMaxSelections", "zh"), s.pluginViewMaxSelections)
        // A single choice, a cap that is not positive and a closed block show no hint.
        val capped = views.getValue("poll-max-selections").blocks.filterIsInstance<PluginChoicesBlock>().first()
        assertEquals("最多选 2 项", PluginViewFormat.choicesFooter(capped, s))
        assertNull(PluginViewFormat.choicesFooter(capped.copy(multiple = false), s))
        assertNull(PluginViewFormat.choicesFooter(capped.copy(maxSelections = 0), s))
        assertEquals(s.pluginViewEnded, PluginViewFormat.choicesFooter(capped.copy(closed = true), s))
        // The total is only the shares' denominator (voters or the sum of the counts): never drawn.
        assertEquals("最多选 2 项", PluginViewFormat.choicesFooter(capped.copy(showResults = true, total = 3), s), "no total after the hint")
    }

    @Test fun badgesReadTheirToneAndAnUnknownOneIsNeutral() {
        val entries = allViews(table()).getValue("entries-badges").blocks.filterIsInstance<PluginEntriesBlock>().first()
        assertEquals(
            listOf(PluginTone.Success, PluginTone.Neutral, PluginTone.Warning, PluginTone.Neutral, null),
            entries.items.map { it.badge?.tone },
        )
        val blank = PluginViewModel.fromJson(
            """{"available":true,"title":"","blocks":[{"kind":"entries","numbered":false,"total":1,"more":false,
               "items":[{"index":1,"text":"x","badge":{"text":"","tone":"info"}}]}]}""",
        )
        assertNull((blank.blocks.single() as PluginEntriesBlock).items.single().badge, "no words, no badge")
    }

    private fun badge(raw: Any?): PluginBadge? = (raw as? Map<*, *>)?.let { PluginBadge(it.str("text")!!, PluginTone.fromWire(it.str("tone"))!!) }

    @Test fun unknownBlocksAndInputsAreSkippedAndPayloadsWriteTheCoresJson() {
        val view = PluginViewModel.fromJson(
            """{"available":true,"title":"Next","fields":[],"actions":[{"id":"a","label":"A","target":{"kind":"operation","operation":"a"},"input":{},"hiddenWhen":[]}],
               "blocks":[{"kind":"chart","series":[]},{"kind":"divider"},{"kind":"rows","source":"list","columns":[],"rows":[],"actions":[]}],
               "inputs":[{"id":"x","kind":"color","label":"X"},{"id":"y","kind":"text","label":"Y"}],"detail":true}""",
        )
        assertEquals(listOf<PluginBlock>(PluginDividerBlock, PluginRowsBlock("list", emptyList(), emptyList())), view.blocks,
            "a kind the kit does not know is skipped; rows read")
        assertEquals(listOf("y"), view.inputs.map { it.id })
        assertEquals(listOf(PluginViewAction("a", "A")), view.actions)
        assertTrue(view.detail)
        val v1 = PluginViewModel.fromJson("""{"available":true,"title":"红包","fields":[{"label":"金额","value":"¥5.00"}],"actions":[{"id":"claim","label":"领取"}]}""")
        assertEquals(PluginViewModel(true, "红包", listOf(PluginViewField("金额", "¥5.00")), listOf(PluginViewAction("claim", "领取"))), v1)
        assertEquals("""{"selection":[0,2]}""", PluginActionPayload(selection = listOf(0, 2)).toJson())
        assertEquals("""{"formValues":{"title":"团建","deadline":1792836000000,"anonymous":true,"options":["a","b\"c"]}}""",
            PluginActionPayload(formValues = linkedMapOf("title" to "团建", "deadline" to 1792836000000.0, "anonymous" to true,
                "options" to listOf("a", "b\"c"))).toJson())
        assertEquals("{}", PluginActionPayload.Empty.toJson())
        assertEquals("""{"formValues":{"title":"x"},"row":{"key":"t1","input":{"taskId":"t1"}}}""",
            PluginActionPayload(formValues = mapOf("title" to "x"), row = PluginActionRow("t1", mapOf("taskId" to "t1"))).toJson())
        assertEquals(listOf(PluginFormError("limit", PluginFormIssue.OutOfRange), PluginFormError("x", PluginFormIssue.InvalidType)),
            PluginFormError.listFromJson("""[{"input":"limit","issue":"outOfRange"},{"input":"x","issue":"brandNew"}]"""))
    }

    @Test fun usersResolveThroughTheHostAndOthersFallBack() = runBlocking {
        val table = table()
        val known = users(table)
        val found = pluginResolvedUsers(listOf("u_alice01", "u_dave9876", "u_alice01"), emptyMap()) { known[it] }
        assertEquals(mapOf("u_alice01" to known.getValue("u_alice01")), found)
        assertTrue(pluginResolvedUsers(listOf("u_alice01"), known) { error("known ids are not asked") }.isEmpty())
        assertTrue(pluginResolvedUsers(listOf("u_x"), emptyMap()) { error("host failure") }.isEmpty(), "a failing host keeps the fallback")
        for (raw in table.list("fallbackNames")) {
            val row = raw as Map<*, *>
            assertEquals(row.str("name"), PluginViewFormat.fallbackName(row.str("userId")!!))
        }
        val ids = PluginViewFormat.userIds(views(table).getValue("solitaire-more").first)
        assertFalse("u_alice01" in ids && ids.count { it == "u_alice01" } > 1, "each id is asked once")
    }

    @Test fun optimisticStepsFollowTheTable() {
        val table = table()
        val views = views(table)
        for (raw in table.list("optimistic")) {
            val scenario = raw as Map<*, *>
            val name = scenario.str("name")!!
            var view = views.getValue(scenario.str("view")!!).first
            fun choices(): Pair<Int, PluginChoicesBlock> {
                view.blocks.forEachIndexed { i, b -> if (b is PluginChoicesBlock) return i to b }
                error("$name has no choices block")
            }
            var state = PluginChoicesInteraction()
            // The host's signals, applied as the view sees them: one value per change (error, busyActionId and
            // settleToken together).
            var signal = PluginHostSignal()
            scenario.list("steps").forEachIndexed { number, rawStep ->
                val step = rawStep as Map<*, *>
                val label = "$name step ${number + 1}"
                var (index, block) = choices()
                val locked = signal.busyActionId != null
                var emitted: Pair<String, List<Int>>? = null
                (step.int("tap") ?: step.int("toggle"))?.let { option ->
                    val (next, selection) = state.tap(block, index, option, locked)
                    state = next
                    val action = block.action
                    if (selection != null && action != null) {
                        state = state.submitted(index, action.id, selection)
                        emitted = action.id to selection
                    }
                }
                if (step.bool("submit") == true) {
                    val selection = state.submission(block, index, locked)
                    val action = block.action
                    if (selection != null && action != null) {
                        state = state.submitted(index, action.id, selection)
                        emitted = action.id to selection
                    }
                }
                (step["host"] as? Map<*, *>)?.let { host ->
                    host.str("view")?.let { next ->
                        view = views.getValue(next).first
                        state = state.viewChanged()
                        choices().let { (i, b) -> index = i; block = b }
                    }
                    var next = signal
                    if (host.containsKey("error")) next = next.copy(error = host.str("error"))
                    if (host.containsKey("busyActionId")) next = next.copy(busyActionId = host.str("busyActionId"))
                    host.int("settleToken")?.let { next = next.copy(settleToken = it) }
                    state = state.hostChanged(signal, next)
                    signal = next
                }
                val emit = step["emit"] as? Map<*, *>
                if (emit != null) {
                    assertEquals(emit.str("actionId"), emitted?.first, label)
                    assertEquals((emit.map("payload")).list("selection").map { (it as Number).toInt() }, emitted?.second, label)
                } else {
                    assertNull(emitted, "$label emits nothing")
                }
                (step["selected"] as? List<*>)?.let { selected ->
                    assertEquals(selected.map { (it as Number).toInt() }, state.shown(block, index), "$label selected")
                }
                step.bool("interactive")?.let {
                    assertEquals(it, state.isInteractive(block, index, signal.busyActionId != null), "$label interactive")
                }
                step.bool("submitEnabled")?.let { assertEquals(it, state.submitEnabled(block, index), "$label submit") }
            }
        }
    }

    @Test fun timeTextFollowsTheTableInBothLanguages() {
        val table = table()
        val now = table.long("nowMs")!!
        val cases = table.list("time").map { it as Map<*, *> }
        assertTrue(cases.size >= 7)
        for (row in cases) {
            val at = row.long("atMs")!!
            val end = row.long("endMs")
            val zone = row.int("utcOffsetMinutes")
            assertEquals(row.str("zh"), PluginViewFormat.timeText(at, end, now, s, zone), row.str("name"))
            assertEquals(row.str("en"), PluginViewFormat.timeText(at, end, now, en, zone), "${row.str("name")} en")
        }
    }

    @Test fun countdownFollowsTheTableAndTurnsOverOnItsBoundary() {
        for (raw in table().list("countdown")) {
            val row = raw as Map<*, *>
            val at = row.long("atMs")!!
            val now = row.long("nowMs")!!
            val name = row.str("name")
            val zh = PluginViewFormat.countdown(at, now, s)
            assertEquals(row.str("zh"), zh.text, name)
            assertEquals(row.int("refreshMs"), zh.refreshMs, "$name refresh")
            assertEquals(row.str("en"), PluginViewFormat.countdown(at, now, en).text, "$name en")
            val delay = PluginViewFormat.countdownDelay(at, now)
            if (delay == null) {
                assertNull(zh.refreshMs, name)
            } else {
                assertTrue(delay <= zh.refreshMs!!, "$name: never later than the cadence")
                assertEquals(zh.text, PluginViewFormat.countdown(at, now + delay - 1, s).text, "$name holds until the next draw")
                if (at - now < 86_400_000) assertNotEquals(zh.text, PluginViewFormat.countdown(at, now + delay, s).text, "$name turns over")
            }
        }
        assertNull(PluginViewFormat.countdownDelay(1, 1))
        assertEquals(1, PluginViewFormat.countdownDelay(3_600_000, 0), "an hour turns into 59:59 next")
    }

    private fun inputs(form: Map<*, *>): List<PluginInput> {
        val wrapper = PluginViewModel.fromMap(mapOf("available" to true, "title" to "", "inputs" to form["inputs"]))
        assertEquals(form.list("inputs").size, wrapper.inputs.size, "every table input reads")
        return wrapper.inputs
    }

    @Test fun theFormStartsFromTheTableDefaults() {
        val form = table().map("form")
        val inputs = inputs(form)
        val state = PluginFormState.initial(inputs, null)
        val options = inputs.first { it.id == "options" }
        val initial = form.map("initial")
        assertEquals(initial.map("options").int("rows"), state.rows("options").size)
        assertEquals(initial.map("options").bool("canAdd"), state.canAddRow(options))
        assertEquals(initial.map("options").bool("canRemove"), state.canRemoveRow(options))
        for (id in listOf("owner", "assignees")) {
            assertEquals(initial.map(id).bool("single"), PluginFormRules.maxItems(inputs.first { it.id == id }) == 1, id)
        }
        for ((id, counter) in initial.map("counters")) {
            assertEquals(counter, PluginFormRules.counter(inputs.first { it.id == id }, state.draft[id]), id as String)
        }
        assertEquals(false, state.draft["anonymous"])
        assertEquals(emptyList<String>(), state.draft["owner"])
    }

    @Test fun theClientCheckAndTheSubmittedValuesFollowTheTable() {
        val form = table().map("form")
        val inputs = inputs(form)
        for (raw in form.list("cases")) {
            val row = raw as Map<*, *>
            val name = row.str("name")!!
            @Suppress("UNCHECKED_CAST")
            val values = row["values"] as Map<String, Any?>
            val state = PluginFormState.initial(inputs, values)
            val expected = row.list("clientErrors").map { (it as Map<*, *>).let { e -> PluginFormError(e.str("input")!!, PluginFormIssue.fromWire(e.str("issue"))) } }
            assertEquals(expected, PluginFormRules.check(inputs, state.draft), name)
            val (next, submitted) = state.submit(inputs)
            assertEquals(row["submitted"], submitted, "$name submitted")
            assertTrue(next.attempted)
            for (error in expected) {
                val input = inputs.first { it.id == error.input }
                assertEquals(PluginFormRules.issueText(error.issue, input, s), next.errorText(input, emptyList(), s), "$name: every issue shows after submit")
            }
        }
    }

    @Test fun issueTextsAndHostErrorsFollowTheTable() {
        val form = table().map("form")
        val inputs = inputs(form)
        val hostErrors = form.list("hostErrors").map { raw ->
            val row = raw as Map<*, *>
            val e = row.map("error")
            val error = PluginFormError(e.str("input")!!, PluginFormIssue.fromWire(e.str("issue")))
            val input = inputs.firstOrNull { it.id == error.input }
            assertEquals(row.str("zh"), PluginFormRules.issueText(error.issue, input, s), error.issue.wire)
            assertEquals(row.str("en"), PluginFormRules.issueText(error.issue, input, en), "${error.issue.wire} en")
            error
        }
        var state = PluginFormState.initial(inputs, null)
        for ((id, text) in form.map("shownPerInput")) {
            assertEquals(text, state.errorText(inputs.first { it.id == id }, hostErrors, s), "$id: the first host error")
        }
        val limit = inputs.first { it.id == "limit" }
        state = state.set("limit", 5.0)
        assertNull(state.errorText(limit, hostErrors, s), "an edited input drops its host error")
        state = state.hostErrorsChanged()
        assertEquals(s.pluginFormOutOfRange, state.errorText(limit, hostErrors, s), "new errors apply again")
        val title = inputs.first { it.id == "title" }
        var fresh = PluginFormState.initial(inputs, null)
        assertNull(fresh.errorText(title, emptyList(), s), "nothing shows before an edit or a submit")
        fresh = fresh.set("title", " ")
        assertEquals(s.pluginFormRequired, fresh.errorText(title, emptyList(), s), "an edited input shows its issue")
    }

    @Test fun optionRowsStayWithinTheirBounds() {
        val inputs = inputs(table().map("form"))
        val options = inputs.first { it.id == "options" }
        var state = PluginFormState.initial(inputs, null)
        state = state.removeRow(options, 0)
        assertEquals(2, state.rows("options").size, "never below max(min, 1)")
        repeat(10) { state = state.addRow(options) }
        assertEquals(5, state.rows("options").size, "never above max")
        assertFalse(state.canAddRow(options))
        state = state.setRow(options, 4, "x").removeRow(options, 0)
        assertEquals(listOf("", "", "", "x"), state.rows("options"))
        val bare = PluginInput("o", PluginInputKind.Options, "O")
        assertEquals(1, PluginFormState.initial(listOf(bare), null).rows("o").size, "no default: one row")
        assertEquals(50, PluginFormRules.maxItems(bare))
        assertEquals(500, PluginFormRules.maxItems(PluginInput("m", PluginInputKind.Members, "M")))
        assertEquals(1, PluginFormRules.length("🎉"), "code points, not UTF-16 units")
    }

    @Test fun datetimePartsRoundTripInTheZone() {
        val zone = ZoneId.of("Asia/Shanghai")
        assertEquals("2026-10-24" to "18:00", pluginDateParts(1792836000000, zone))
        assertEquals(1792836000000, pluginDateTimeMs("2026-10-24" to "18:00", zone))
        assertNull(pluginDateTimeMs("2026-10-24" to "", zone), "a value once both parts are set")
        assertEquals("" to "", pluginDateParts(null, zone))
    }

    @Test fun theDetailSheetLoadsFailsWithRetryAndShowsTheView() {
        val detail = views(table()).getValue("solitaire-more").first
        assertEquals(PluginDetailPhase.Loading, pluginDetailPhase(true, "x", null))
        assertEquals(PluginDetailPhase.Error, pluginDetailPhase(false, "x", null))
        assertEquals(PluginDetailPhase.Loading, pluginDetailPhase(false, null, null))
        assertEquals(PluginDetailPhase.Loaded, pluginDetailPhase(false, "", detail))
        assertEquals(detail.title, pluginDetailHeading(detail, "Card"))
        assertEquals("Card", pluginDetailHeading(null, "Card"))
        assertEquals("加载中", s.loading)
        assertEquals("Loading…", en.loading)
    }

    @Test fun detailPagingFollowsTheTable() {
        val table = table()
        val views = views(table)
        val cases = table.list("detailPaging").map { it as Map<*, *> }
        assertTrue(cases.size >= 4)
        for (row in cases) {
            val name = row.str("name")!!
            val view = views.getValue(row.str("view")!!).first.copy(nextCursor = row.str("nextCursor"))
            val expect = row.map("expect")
            val state = pluginDetailLoadMore(view.nextCursor, requested = null, loadingMore = row.bool("loadingMore") == true)
            if (expect.bool("loadMore") != true) {
                assertEquals(PluginDetailLoadMore.Hidden, state, name)
                continue
            }
            assertEquals(expect.bool("enabled") == true, state is PluginDetailLoadMore.Ready, "$name enabled")
            assertEquals(expect.bool("spinning") == true, state == PluginDetailLoadMore.Loading, "$name spinning")
            if (expect.containsKey("emit")) {
                assertEquals(expect.str("emit"), PluginDetailPaging().tap(view.nextCursor, row.bool("loadingMore") == true).second, "$name emit")
            }
            // Steps: the cursor asked for spins until the merged view moves it on or the host frees it.
            var cursor = view.nextCursor
            var loading = row.bool("loadingMore") == true
            var paging = PluginDetailPaging()
            row.list("steps").forEachIndexed { number, raw ->
                val step = raw as Map<*, *>
                val label = "$name step ${number + 1}"
                (step["host"] as? Map<*, *>)?.let { host ->
                    if (host.containsKey("nextCursor")) cursor = host.str("nextCursor")
                    host.bool("loadingMore")?.let { next ->
                        if (next != loading && !next) paging = paging.released()
                        loading = next
                    }
                    if (!host.str("actionError").isNullOrEmpty()) paging = paging.released()
                    if (host.containsKey("settleToken")) paging = paging.released()
                }
                var emitted: String? = null
                if (step.bool("tap") == true) {
                    val (next, asked) = paging.tap(cursor, loading)
                    paging = next
                    emitted = asked
                }
                if (step.containsKey("emit")) assertEquals(step.str("emit"), emitted, "$label emit")
                val now = paging.key(cursor, loading)
                step.bool("loadMore")?.let { assertEquals(it, now != PluginDetailLoadMore.Hidden, "$label key") }
                step.bool("spinning")?.let { assertEquals(it, now == PluginDetailLoadMore.Loading, "$label spinning") }
                step.bool("enabled")?.let { assertEquals(it, now is PluginDetailLoadMore.Ready, "$label enabled") }
            }
        }
    }

    @Test fun openStreetMapIsCreditedOnTheShownStaticMapOnly() {
        assertEquals("© OpenStreetMap contributors", locationMapAttribution(FlareLocationProvider.Osm, true, s))
        assertEquals(s.locationOsmAttribution, en.locationOsmAttribution, "the same in every language")
        assertNull(locationMapAttribution(FlareLocationProvider.Osm, false, s), "not over the drawn ground")
        assertNull(locationMapAttribution(FlareLocationProvider.Amap, true, s), "never for amap")
    }
}

/** The Vue console's table views: rows as a DataTable with a row's detail and their own load more. */
private val VUE_TABLES = setOf("admin-rows", "admin-rows-empty")

/** The parts of an entry the table's `order` lists. */
private val ORDERED_WORDS = setOf(PluginEntryPart.Name, PluginEntryPart.Me, PluginEntryPart.Badge, PluginEntryPart.Text)
