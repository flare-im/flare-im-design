package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * FlarePluginPage without a UI, against `spec/plugin-view-vectors.json`: what a page draws (pageViews), what its actions
 * carry (pageActions), its paging (pagePaging) and its filters (pageFilters, filterInputs). The rules are the ones the
 * composable runs: the page phase, the view's parts, the action steps, the paging state and the filter rows.
 */
class PluginPageVectorsTest {
    private val s = FlareStrings()
    private val table = SpecTables.table("plugin-view-vectors.json")
    private val nowMs = table.long("nowMs")!!
    private val zone = table.int("utcOffsetMinutes")!!

    private fun pageCases(): Map<String, Map<*, *>> = table.items("pageViews").associateBy { it.str("id")!! }

    private fun page(id: String): PluginPageViewModel = PluginPageViewModel.fromMap(pageCases().getValue(id).obj("view")!!)

    private fun ref(id: String): PluginPageRef = pageCases().getValue(id).obj("page")!!.let { PluginPageRef(it.str("pluginId")!!, it.str("page")!!) }

    private fun filtersOf(raw: Any?): Map<String, Any?> = (raw as? Map<*, *>)?.entries?.associate { (k, v) -> k.toString() to v }.orEmpty()

    private fun variant(action: PluginViewAction): String = when (PluginViewFormat.variant(action)) {
        FlareButtonVariant.Danger -> "danger"
        FlareButtonVariant.Primary -> "primary"
        else -> "secondary"
    }

    private fun badge(raw: Any?): PluginBadge? = (raw as? Map<*, *>)?.let { PluginBadge(it.str("text")!!, PluginTone.fromWire(it.str("tone"))!!) }

    private fun rows(view: PluginViewModel): PluginRowsBlock = view.blocks.filterIsInstance<PluginRowsBlock>().single()

    /** The keys of the rows a view draws, read from its parts (the lazy list's identities). */
    private fun drawnRowKeys(view: PluginViewModel): List<String> {
        val parts = pluginViewParts(view, embedded = true, quote = false, reasonLine = null,
            keys = PluginViewFormat.keys(view, embedded = true), detailKey = null, failure = null, strings = s)
        assertEquals(parts.size, parts.map { it.key }.toSet().size, "every part has its own key")
        return parts.filterIsInstance<PluginViewPart.Row>().map { it.row.key }
    }

    // ── pageViews ──

    @Test fun everyPageDrawsWhatTheTableSays() {
        val cases = pageCases()
        assertTrue(cases.size >= 8, "the shared table lost pageViews")
        for (id in listOf("wallet", "wallet-empty", "history", "tasks", "unavailable-catalog-unreachable")) {
            assertTrue(id in cases, "the shared table lost pageViews.$id")
        }
        for ((id, case) in cases) {
            val page = PluginPageViewModel.fromMap(case.obj("view")!!)
            val view = page.view
            val expect = case.obj("expect")!!
            val phase = pluginPagePhase(loading = false, error = null, view = page)
            assertEquals(expect.str("state"), phase.name.lowercase(), "$id state")
            assertEquals(expect.str("heading"), pluginPageTitle(page, case.str("title")), "$id heading")
            val loaded = phase == PluginPagePhase.Loaded
            assertEquals(expect.items("fields").map { PluginViewField(it.str("label")!!, it.str("value")!!) },
                if (loaded) view.fields else emptyList(), "$id fields")

            val blocks = if (loaded) view.blocks else emptyList()
            val facts = expect.items("blocks")
            assertEquals(facts.map { it.str("kind") }, blocks.map { it.kind }, "$id blocks")
            for ((block, fact) in blocks.zip(facts)) when (block) {
                is PluginNoteBlock -> {
                    assertEquals(fact.str("text"), block.text, id)
                    assertEquals(fact.str("tone"), (block.tone ?: PluginTone.Neutral).wire, id)
                }
                is PluginRowsBlock -> {
                    assertEquals("list", fact.str("layout"), "$id: every kit draws a page's rows as a list")
                    val items = fact.items("items")
                    val drawn = PluginViewFormat.rowsOnce(block.rows)
                    assertEquals(items.map { it.str("key") }, drawn.map { it.key }, "$id row keys")
                    assertEquals(items.map { it.str("key") }, drawnRowKeys(view), "$id parts")
                    for ((row, item) in drawn.zip(items)) {
                        val lines = PluginViewFormat.rowLines(block, row, nowMs, s, zone)
                        assertEquals(badge(item["badge"]), row.badge, "$id ${row.key} badge")
                        assertEquals(item.str("primary"), lines.primary, "$id ${row.key} primary")
                        assertEquals(item.str("secondary"), lines.secondary, "$id ${row.key} secondary")
                        val keys = PluginViewFormat.rowActions(block, row).map { (action, _) ->
                            mapOf("id" to action.id, "label" to action.label, "variant" to variant(action))
                        }
                        assertEquals(item["actions"], keys, "$id ${row.key} actions")
                    }
                    assertEquals(fact.str("empty"), PluginViewFormat.rowsEmpty(block, s), "$id empty")
                }
                else -> error("$id: no page facts for ${block.kind}")
            }

            val actions = if (loaded) PluginViewFormat.keys(view, embedded = true) else emptyList()
            assertEquals(expect.items("actions").map { it.str("id") }, actions.map { it.id }, "$id actions")
            for ((action, fact) in actions.zip(expect.items("actions"))) {
                assertEquals(fact.str("label"), action.label, "$id ${action.id}")
                assertEquals(fact.str("variant"), variant(action), "$id ${action.id} variant")
                assertEquals(fact.str("confirm"), action.confirm, "$id ${action.id} confirm")
                assertEquals(fact.bool("form"), !action.form.isNullOrEmpty(), "$id ${action.id} form")
            }

            val filters = if (loaded) pluginPageFilters(view, filtersOf(case["filters"]), s.pluginViewAll) else emptyList()
            assertEquals(
                expect.items("filters").map { listOf(it.str("input"), it.str("label"), it["tabs"], it.str("selected")) },
                filters.map { f -> listOf(f.input.id, f.input.label, f.tabs.map { it.label }, f.tabs.first { it.value == f.selected }.label) },
                "$id filters",
            )
            val more = if (loaded) PluginDetailPaging().key(view.nextCursor, loadingMore = false) else PluginDetailLoadMore.Hidden
            assertEquals(expect.bool("loadMore"), more != PluginDetailLoadMore.Hidden, "$id load more")
            assertEquals(expect.bool("refresh"), pluginPageRefreshes(phase, handled = true), "$id refresh")
            assertEquals(expect.str("empty"), if (phase == PluginPagePhase.Unavailable) pluginPageUnavailableText(view, s) else null, "$id empty")
            assertEquals(expect.bool("retry"), phase == PluginPagePhase.Unavailable && pluginPageUnavailableRetry(view), "$id retry")
            if (!loaded) assertNull(page.data, "$id: an unavailable page has no data")
        }
        assertEquals(SpecTables.copy("pluginViewEmpty", "zh"), s.pluginViewEmpty)
        assertEquals(SpecTables.copy("pluginViewAll", "zh"), s.pluginViewAll)
    }

    @Test fun thePageWaitsFailsWithRetryOrShowsTheView() {
        val wallet = page("wallet")
        assertEquals(PluginPagePhase.Loading, pluginPagePhase(true, null, null))
        assertEquals(PluginPagePhase.Loading, pluginPagePhase(true, "失败", null), "the error waits until the load stops")
        assertEquals(PluginPagePhase.Error, pluginPagePhase(false, "失败", null))
        assertEquals(PluginPagePhase.Loading, pluginPagePhase(false, null, null), "nothing yet is still loading")
        assertEquals(PluginPagePhase.Loaded, pluginPagePhase(false, "刷新失败", wallet), "a failed refresh keeps the view (and its banner)")
        assertEquals(PluginPagePhase.Unavailable, pluginPagePhase(false, null, page("unavailable-disabled")))
        assertEquals("钱包", pluginPageTitle(null, "钱包"))
        assertEquals("钱包", pluginPageTitle(page("unavailable-disabled"), "钱包"), "an unavailable page keeps the host's title")
        assertFalse(pluginPageRefreshes(PluginPagePhase.Loaded, handled = false))
        assertTrue(pluginPageRefreshKey(FlarePointerKind.Fine, canRefresh = true))
        assertFalse(pluginPageRefreshKey(FlarePointerKind.Coarse, canRefresh = true), "touch pulls instead")
        assertEquals(mapOf<String, Any?>("balanceText" to "¥128.50", "escrowText" to "¥20.00", "currency" to "CNY"), wallet.data)
    }

    // ── pageActions ──

    /** An action tapped on a page: a view or menu action, or a row's. */
    private fun tap(view: PluginViewModel, tap: Map<*, *>): PluginActionRun {
        val actionId = tap.str("action")!!
        val rowKey = tap.str("row") ?: return PluginActionRun(PluginViewFormat.keys(view, embedded = true).first { it.id == actionId }, PluginActionPayload.Empty, null)
        val block = rows(view)
        val row = PluginViewFormat.rowsOnce(block.rows).first { it.key == rowKey }
        val (action, bound) = PluginViewFormat.rowActions(block, row).first { it.first.id == actionId }
        return PluginActionRun(action, PluginActionPayload(row = PluginActionRow(row.key, bound.input)), null)
    }

    private fun assertEmitted(expected: Any?, step: PluginActionStep?, ref: PluginPageRef, page: PluginPageViewModel, label: String) {
        if (expected == null) {
            assertFalse(step is PluginActionStep.Emit, "$label emits nothing")
            return
        }
        val emit = assertIs<PluginActionStep.Emit>(step, label)
        val want = expected as Map<*, *>
        assertEquals(want.str("actionId"), emit.run.action.id, label)
        // The payload as the host hands it to the core SDK.
        assertEquals(want["payload"], FlareJson.parse(PluginPageActionPayload.of(ref, page, emit.payload).toJson()), "$label payload")
    }

    @Test fun pageActionsCarryWhatTheTableSays() {
        val cases = table.items("pageActions")
        assertTrue(cases.size >= 8, "the shared table lost pageActions")
        for (case in cases) {
            val name = case.str("name")!!
            val id = case.str("view")!!
            val page = page(id)
            val ref = ref(id)
            var step: PluginActionStep? = null
            var form: PluginFormState? = null
            // The row action last handed over (action id, row key) and the host's action in flight (rules.pageRows).
            var rowRun: Pair<String, String>? = null
            var busyActionId: String? = null
            case.items("steps").forEachIndexed { number, raw ->
                val label = "$name step ${number + 1}"
                raw.obj("tap")?.let { step = tap(page.view, it).start() }
                when (val confirm = raw["confirm"]) {
                    is String -> {
                        val asking = assertIs<PluginActionStep.Confirm>(step, "$label asks first")
                        assertEquals(confirm, asking.run.action.confirm, label)
                    }
                    true -> step = assertIs<PluginActionStep.Confirm>(step, label).run.confirmed()
                }
                if (raw.bool("cancel") == true) {
                    assertIs<PluginActionStep.Confirm>(step, label)
                    step = null
                }
                if (raw.containsKey("form")) {
                    val collecting = assertIs<PluginActionStep.Form>(step, "$label collects a form")
                    val inputs = page.view.formInputs(collecting.run.action)
                    assertEquals(raw["form"], inputs.map { it.label }, label)
                    form = PluginFormState.initial(inputs, null)
                }
                raw.obj("fill")?.let { fill -> fill.forEach { (input, value) -> form = form!!.set(input as String, value) } }
                if (raw.bool("submit") == true) {
                    val collecting = assertIs<PluginActionStep.Form>(step, label)
                    val (_, values) = form!!.submit(page.view.formInputs(collecting.run.action))
                    step = collecting.run.submitted(values!!)
                }
                if (raw.containsKey("emit")) assertEmitted(raw["emit"], step, ref, page, label)
                (step as? PluginActionStep.Emit)?.let { sent -> sent.payload.row?.let { rowRun = sent.run.action.id to it.key } }
                raw.obj("host")?.let { host -> if (host.containsKey("busyActionId")) busyActionId = host.str("busyActionId") }
                if (raw.containsKey("spinningRows")) {
                    val block = rows(page.view)
                    val spun = PluginViewFormat.rowsOnce(block.rows).filter { row ->
                        PluginViewFormat.rowActions(block, row).any { (action, _) -> busyActionId == action.id && rowRun == (action.id to row.key) }
                    }
                    assertEquals(raw["spinningRows"], spun.map { it.key }, "$label spinning rows")
                }
                // Any action in flight holds every row key (the view is locked).
                raw.bool("rowKeysEnabled")?.let { assertEquals(it, busyActionId == null, "$label row keys") }
            }
        }
    }

    @Test fun aPagePayloadWritesThePageFirstAndOnlyWhatItHas() {
        val ref = PluginPageRef("x.tasks", "x.tasks.mine")
        assertEquals("""{"page":{"pluginId":"x.tasks","page":"x.tasks.mine"}}""", PluginPageActionPayload(ref).toJson())
        assertEquals(
            """{"page":{"pluginId":"x.tasks","page":"x.tasks.mine"},"data":{"owner":"u_bob0002"},"selection":[1,3]}""",
            PluginPageActionPayload.of(ref, PluginPageViewModel(PluginViewModel(true, ""), mapOf("owner" to "u_bob0002")),
                PluginActionPayload(selection = listOf(1, 3))).toJson(),
        )
    }

    // ── pagePaging ──

    @Test fun pagingFollowsTheTable() {
        val cases = table.items("pagePaging")
        assertTrue(cases.size >= 3, "the shared table lost pagePaging")
        for (case in cases) {
            val name = case.str("name")!!
            val id = case.str("view")!!
            val ref = ref(id)
            var page = page(id)
            var paging = PluginDetailPaging()
            var loading = false
            case.items("steps").forEachIndexed { number, step ->
                val label = "$name step ${number + 1}"
                var emitted: Any? = null
                var action: PluginActionStep? = null
                step.obj("host")?.let { host ->
                    host.obj("view")?.let { page = PluginPageViewModel.fromMap(it) }
                    host.bool("loadingMore")?.let { next ->
                        if (loading && !next) paging = paging.released()
                        loading = next
                    }
                    if (!host.str("actionError").isNullOrEmpty()) paging = paging.released()
                    if (host.containsKey("settleToken")) paging = paging.released()
                    // FlarePluginPage releases the key when a refresh ends.
                    if (host.bool("refreshing") == false) paging = paging.released()
                }
                when (val tap = step["tap"]) {
                    "loadMore" -> {
                        val (next, asked) = paging.tap(page.view.nextCursor, loading)
                        paging = next
                        emitted = asked
                    }
                    is Map<*, *> -> action = tap(page.view, tap).start()
                }
                if (step.containsKey("emit")) {
                    if (step["tap"] is Map<*, *>) assertEmitted(step["emit"], action, ref, page, label)
                    else assertEquals(step["emit"], emitted, "$label emit")
                }
                val key = paging.key(page.view.nextCursor, loading)
                step.bool("spinning")?.let { assertEquals(it, key == PluginDetailLoadMore.Loading, "$label spinning") }
                step.bool("enabled")?.let { assertEquals(it, key is PluginDetailLoadMore.Ready, "$label enabled") }
                step.bool("loadMore")?.let { assertEquals(it, key != PluginDetailLoadMore.Hidden, "$label load more") }
                (step["rowKeys"] as? List<*>)?.let { assertEquals(it, drawnRowKeys(page.view), "$label rows") }
                (step["primaries"] as? List<*>)?.let { primaries ->
                    val block = rows(page.view)
                    assertEquals(primaries, PluginViewFormat.rowsOnce(block.rows).map { PluginViewFormat.rowLines(block, it, nowMs, s, zone).primary },
                        "$label the first of a repeated key stays")
                }
            }
        }
    }

    // ── pageFilters and filterInputs ──

    @Test fun filtersFollowTheTable() {
        val cases = table.items("pageFilters")
        assertTrue(cases.size >= 5, "the shared table lost pageFilters")
        // The ledger's case: a text input the rows list is not a tab, and its value the host holds stays in what is emitted.
        assertTrue(cases.any { it.str("view") == "history" && filtersOf(it["filters"]).containsKey("keyword") },
            "the shared table lost the case that keeps the host's other filters")
        for (case in cases) {
            val name = case.str("name")!!
            val view = page(case.str("view")!!).view
            var filters = filtersOf(case["filters"])
            var refreshing = false
            var loadingMore = false
            case.items("steps").forEachIndexed { number, step ->
                val label = "$name step ${number + 1}"
                step.obj("host")?.let { host ->
                    if (host.containsKey("filters")) filters = filtersOf(host["filters"])
                    host.bool("refreshing")?.let { refreshing = it }
                    host.bool("loadingMore")?.let { loadingMore = it }
                }
                val rows = pluginPageFilters(view, filters, s.pluginViewAll)
                step.obj("tabs")?.let { tabs ->
                    assertEquals<Map<*, *>>(tabs, rows.associate { f -> f.input.id to f.tabs.map { it.label } }, "$label tabs")
                }
                step.obj("selected")?.let { selected ->
                    for ((input, tab) in selected) {
                        val f = rows.first { it.input.id == input }
                        assertEquals(tab, f.tabs.first { it.value == f.selected }.label, "$label selected $input")
                    }
                }
                step.obj("choose")?.let { choose ->
                    val f = rows.first { it.input.id == choose.str("input") }
                    val tab = f.tabs.first { it.label == choose.str("tab") }
                    val emitted = pluginPageFilterChoice(f, tab.value, refreshing || loadingMore, filters)
                    assertEquals(filtersOf(step["emit"]).takeIf { step["emit"] != null }, emitted, "$label emit")
                }
                step.bool("enabled")?.let { assertEquals(it, !(refreshing || loadingMore), "$label enabled") }
            }
        }
    }

    @Test fun theFilterInputsFollowTheTable() {
        val spec = table.obj("filterInputs")!!
        val ids = (spec["inputs"] as List<*>).map { it as String }
        val inputs = ids.map { PluginInput(it, PluginInputKind.Text, it) }
        for (case in spec.items("cases")) {
            val listed = (case["filters"] as? List<*>)?.map { it as String }
            val view = PluginViewModel(true, "", blocks = listOf(PluginRowsBlock("s", emptyList(), emptyList(), filters = listed)), inputs = inputs)
            assertEquals(case["expect"], PluginViewFormat.filterInputs(view).map { it.id }, case.str("name"))
        }
        val noRows = PluginViewModel(true, "", inputs = listOf(PluginInput("kind", PluginInputKind.Select, "类型", choices = listOf(PluginInputChoice("a", "A")))))
        assertTrue(pluginPageFilters(noRows, emptyMap(), s.pluginViewAll).isEmpty(), "no rows block, no filter row")
    }
}
