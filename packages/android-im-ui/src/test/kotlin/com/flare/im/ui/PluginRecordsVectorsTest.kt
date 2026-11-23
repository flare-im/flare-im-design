package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Records pages without a UI, against `spec/plugin-view-vectors.json` pageTabs and rowsIcon (4.7 of
 * docs/plugin-experience.md): the tabs FlarePluginPage draws and the page a choice opens, and the ledger line a rows
 * block with an icon draws for each row, with person cells named, and which rows are one control (rowTap, R2.3). The
 * rules are the ones the composables run.
 */
class PluginRecordsVectorsTest {
    private val s = FlareStrings()
    private val table = SpecTables.table("plugin-view-vectors.json")
    private val nowMs = table.long("nowMs")!!
    private val users = table.obj("users")!!.entries.associate { (id, user) -> id.toString() to PluginUser((user as Map<*, *>).str("name")!!) }
    private fun compose(name: String) = table.items(name).filter { (it["platforms"] as List<*>).contains("compose") }
    private fun page(raw: Any?): PluginPageViewModel? = (raw as? Map<*, *>)?.let { view ->
        PluginPageViewModel.fromMap(mapOf("available" to true, "title" to "页", "fields" to emptyList<Any>(), "actions" to emptyList<Any>()) + view.entries.associate { (k, v) -> k.toString() to v })
    }

    @Test fun pageTabs() {
        for (case in compose("pageTabs")) {
            val name = case.str("name")
            val shown = case.obj("page")!!.str("page")!!
            val expect = case.obj("expect")!!
            val views = (case["views"] as? List<*>) ?: listOf(case["view"])
            for (raw in views) {
                // A previous page drew its tabs: they are what the kit remembers while this one loads.
                val last = page(case["previous"])?.let { pluginPageTabs(it, "flare.redpacket.page.received", emptyList()) }.orEmpty()
                val tabs = pluginPageTabs(page(raw), shown, last)
                val labels = expect["tabs"] as? List<*>
                if (labels == null) { assertTrue(tabs.isEmpty(), "$name: no control"); continue }
                assertEquals(labels, tabs.map { it.label }, "$name: labels")
                assertEquals(expect.int("selected"), tabs.indexOfFirst { it.selected }, "$name: selected")
                case.int("choose")?.let { assertEquals(expect.str("emitted"), pluginPageTabChoice(tabs, it), "$name: emitted") }
            }
        }
    }

    @Test fun rowsIcon() {
        for (case in compose("rowsIcon")) {
            val name = case.str("name")
            val view = PluginViewModel.fromMap(mapOf("available" to true, "title" to "", "fields" to emptyList<Any>(),
                "actions" to emptyList<Any>(), "blocks" to listOf(case.obj("block")!!)))
            val block = view.blocks.filterIsInstance<PluginRowsBlock>().single()
            val expect = case.obj("expect")!!
            expect.obj("empty")?.let { empty ->
                assertEquals(empty.str("icon"), block.icon, "$name: empty icon")
                assertEquals(empty.str("title"), PluginViewFormat.rowsEmpty(block, s), "$name: empty text")
                return@let
            }
            expect.items("rows").forEachIndexed { index, want ->
                val row = PluginViewFormat.namedRow(block.rows[index], users)
                if (want.str("icon") == null) {
                    assertNull(block.icon, "$name: no icon")
                    assertFalse(pluginRowsAreRecords(block), "$name: not records")
                    return@forEachIndexed
                }
                assertTrue(pluginRowsAreRecords(block), name)
                assertEquals(want.str("icon"), row.icon ?: block.icon, "$name: icon")
                val line = pluginLedgerLine(block, row, nowMs, s)
                assertEquals(want.str("title"), line.title, "$name: title")
                assertEquals(want.str("line"), line.line, "$name: line")
                assertEquals(want.str("value"), line.value, "$name: value")
                assertEquals(want.items("tags").map { it.str("text") to it.str("tone") },
                    line.tags.map { it.text to it.tone?.let { tone -> tone.name.lowercase() } }, "$name: tags")
            }
        }
    }

    @Test fun rowTap() {
        for (case in compose("rowTap")) {
            val name = case.str("name")
            val view = PluginViewModel.fromMap(mapOf("available" to true, "title" to "", "fields" to emptyList<Any>(),
                "actions" to emptyList<Any>(), "blocks" to listOf(case.obj("block")!!)))
            val block = view.blocks.filterIsInstance<PluginRowsBlock>().single()
            val expect = case.obj("expect")!!
            expect.items("rows").forEachIndexed { index, want ->
                val row = block.rows[index]
                assertEquals(want.str("key"), row.key, "$name: order")
                val tap = PluginViewFormat.rowTap(block, row)
                assertEquals(want.str("tap"), tap?.first?.id, "$name: tap ${row.key}")
                // The composable draws no key for a tappable row, and ends it with the chevron.
                val keys = if (tap != null) emptyList() else PluginViewFormat.rowActions(block, row).map { it.first.id }
                assertEquals(want["keys"], keys, "$name: keys ${row.key}")
                assertEquals(want.bool("chevron"), tap != null, "$name: chevron ${row.key}")
            }
            expect.obj("emit")?.let { emit ->
                val row = block.rows.single { it.key == emit.str("rowKey") }
                val (action, bound) = PluginViewFormat.rowTap(block, row)!!
                assertEquals(emit.str("actionId"), action.id, "$name: emitted action")
                assertEquals(emit["input"], bound.input, "$name: emitted input")
            }
        }
    }
}
